CREATE OR ALTER PROCEDURE [HC6].[hcapp_updatePhotoStatus]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @photoId    UNIQUEIDENTIFIER,
    @action     TINYINT
    -- Action values (cumulative — higher levels imply all lower ones):
    --   1 = delete         → hard-delete the row (inappropriate content)
    --   2 = keep private   → status 0  (back to uploader-only)
    --   3 = share          → status 2  (visible to all HC users on run maps)
    --   4 = run gallery    → status 3  (+ appears in run photo gallery)
    --   5 = home gallery   → status 4  (+ appears on kennel home page)
    --   6 = event cover    → status 5  (+ set as run cover photo)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updatePhotoStatus
-- Description: Allows an authorised reviewer to action a pending photo.
--   Caller must hold one of the following roles in MismanagementRoleFlags
--   for the photo's kennel: Hash Flash (0x20), GM (0x02), VGM (0x04),
--   or RA (0x08). The photo must be in pending_review status (1).
--   Actions 3–6 are cumulative approvals (each implies all lower levels).
--   Actions 1–2 are rejections. Action 6 stubs the EventCoverPhotoUrl
--   update — wire to HC.Event once the column is added.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @photoId     - UUID of the photo to action
--   @action      - 1=delete, 2=keep_private, 3=share, 4=gallery,
--                  5=home_gallery, 6=event_cover
-- Returns:
--   On success (rowset 0): { success, errorCode, errorType }
--   On success (rowset 1): { photoId, newStatus } (absent for action=1)
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-20
-- Updated: 2026-05-21 — expanded actions (3→6), expanded roles
--   (Hash Flash only → Hash Flash + GM + VGM + RA)
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

-- Validate action
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

-- Look up photo
DECLARE @photoKennelId UNIQUEIDENTIFIER;
DECLARE @photoStatus   TINYINT;
DECLARE @photoEventId  UNIQUEIDENTIFIER;
DECLARE @photoBlobUrl  NVARCHAR(500);

SELECT @photoKennelId = KennelId,
       @photoStatus   = Status,
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

-- Verify caller holds an approval role for this kennel:
-- Hash Flash (0x20) OR GM (0x02) OR VGM (0x04) OR RA (0x08) = 0x2E
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoleFlags, 0)
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

-- Photo must be pending_review (status=1) to be actioned
IF (@photoStatus <> 1)
BEGIN
    SET @errorCode = 1233; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Photo not pending review',
            CONCAT('Photo status is ', @photoStatus, '; only status=1 photos can be actioned'), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Photo already reviewed' AS errorTitle,
           'This photo has already been reviewed.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Map action → new status
-- 1=delete, 2=keep_private(0), 3=share(2), 4=gallery(3), 5=home_gallery(4), 6=event_cover(5)
DECLARE @newStatus TINYINT = CASE @action
    WHEN 2 THEN 0
    WHEN 3 THEN 2
    WHEN 4 THEN 3
    WHEN 5 THEN 4
    WHEN 6 THEN 5
    ELSE 0
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF (@action = 1)
    BEGIN
        DELETE FROM HC.KennelPhotos WHERE id = @photoId;
        COMMIT TRANSACTION;
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
        -- No rowset 1 on delete
    END
    ELSE
    BEGIN
        UPDATE HC.KennelPhotos
        SET Status    = @newStatus,
            UpdatedAt = GETUTCDATE()
        WHERE id = @photoId;

        IF (@action = 6 AND @photoEventId IS NOT NULL)
            UPDATE HC.Event
            SET EventCoverPhotoUrl = @photoBlobUrl
            WHERE id = @photoEventId;

        COMMIT TRANSACTION;
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
        SELECT @photoId AS photoId, @newStatus AS newStatus;
    END

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
