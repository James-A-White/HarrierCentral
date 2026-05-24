CREATE OR ALTER PROCEDURE [HC6].[hcapp_updatePhotoStatus]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @photoId    UNIQUEIDENTIFIER,
    @action     TINYINT
    -- Action values:
    --   1 = delete         → soft-delete: set DeletedAt (row kept, always recoverable)
    --   2 = keep private   → status 0, clear DeletedAt
    --   3 = share          → status 2, clear DeletedAt
    --   4 = run gallery    → status 3, clear DeletedAt
    --   5 = home gallery   → status 4, clear DeletedAt
    --   6 = event cover    → status 5, clear DeletedAt
    -- Any action 2–6 on a soft-deleted photo restores it with the new status.

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updatePhotoStatus
-- Description: Allows an authorised reviewer to action a photo. Works
--   on photos of any status (pending, approved, private, soft-deleted) —
--   this supports re-review from the Reviewed tab as well as initial
--   review from the Pending tab.
--   Action 1 soft-deletes (sets DeletedAt). Actions 2–6 clear DeletedAt
--   and set the new status, effectively restoring deleted photos if needed.
--   Caller must hold Hash Flash (0x20), GM (0x02), VGM (0x04), or RA (0x08).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @photoId     - UUID of the photo to action
--   @action      - 1=delete, 2=keep_private, 3=share, 4=gallery,
--                  5=home_gallery, 6=event_cover
-- Returns:
--   On success (rowset 0): { success, errorCode, errorType }
--   On success (rowset 1): { photoId, newStatus, deletedAt }
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-20
-- Updated: 2026-05-21 — expanded actions (3→6), expanded roles
-- Updated: 2026-05-23 — soft delete (DeletedAt) replaces hard delete;
--   removed status=1-only restriction to allow re-review
-- HC5 Source: None — new for HC6 KennelPhotos
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 33,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@action NOT IN (1, 2, 3, 4, 5, 6))
BEGIN
    SET @errorCode = 1233; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid action',
            CONCAT('@action must be 1–6; received: ', @action), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid action' AS errorTitle,
           'The requested action is not valid. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

DECLARE @photoKennelId UNIQUEIDENTIFIER;
DECLARE @photoEventId  UNIQUEIDENTIFIER;
DECLARE @photoBlobUrl  NVARCHAR(500);

SELECT @photoKennelId = KennelId,
       @photoEventId  = EventId,
       @photoBlobUrl  = BlobUrl
FROM HC.KennelPhotos
WHERE id = @photoId;

IF (@photoKennelId IS NULL)
BEGIN
    SET @errorCode = 1333; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Photo not found',
            'No KennelPhoto row exists with the supplied photoId', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Photo not found' AS errorTitle,
           'The photo could not be found.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Verify caller holds an approval role for this kennel
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @photoKennelId;

IF (@mmRoleFlags & 0x0000002E = 0)
BEGIN
    SET @errorCode = 1333; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised to review photos',
            'Caller does not hold Hash Flash, GM, VGM or RA role for this kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to review photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Map action → new status (only used for non-delete actions)
DECLARE @newStatus TINYINT = CASE @action
    WHEN 2 THEN 0
    WHEN 3 THEN 2
    WHEN 4 THEN 3
    WHEN 5 THEN 4
    WHEN 6 THEN 5
    ELSE 0
END;

DECLARE @newDeletedAt DATETIME2 = CASE WHEN @action = 1 THEN GETUTCDATE() ELSE NULL END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF (@action = 1)
    BEGIN
        -- Soft delete: set DeletedAt, leave Status unchanged
        UPDATE HC.KennelPhotos
        SET DeletedAt = GETUTCDATE(),
            UpdatedAt = GETUTCDATE()
        WHERE id = @photoId;
    END
    ELSE
    BEGIN
        -- Any approval/rejection action: set new status, clear DeletedAt
        UPDATE HC.KennelPhotos
        SET Status    = @newStatus,
            DeletedAt = NULL,
            UpdatedAt = GETUTCDATE()
        WHERE id = @photoId;

        IF (@action = 6 AND @photoEventId IS NOT NULL)
            UPDATE HC.Event
            SET EventCoverPhotoUrl = @photoBlobUrl
            WHERE id = @photoEventId;
    END

    COMMIT TRANSACTION;
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT @photoId AS photoId, @newStatus AS newStatus, @newDeletedAt AS deletedAt;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 19 AS errorType;
    SELECT @errorId AS errorId, 19 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
