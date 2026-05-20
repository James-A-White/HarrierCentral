CREATE OR ALTER PROCEDURE [HC6].[hcapp_updatePhotoStatus]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @photoId    UNIQUEIDENTIFIER,
    @action     TINYINT
    -- Action values:
    --   1 = approve    → status becomes 2 (public)
    --   2 = keep private → status becomes 0 (private)
    --   3 = delete     → row is hard-deleted

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updatePhotoStatus
-- Description: Allows a Hash Flash to action a photo that a member has
--   shared for review. The caller must hold the mmRoleFlagHashFlash role
--   (0x00000020) in MismanagementRoleFlags for the photo's kennel.
--   The photo must be in pending_review status (1) — the Hash Flash only
--   sees photos that members have chosen to share.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @photoId     - UUID of the photo to action
--   @action      - 1=approve, 2=keep private, 3=delete
-- Returns:
--   On success (rowset 0): { success, errorCode, errorType }
--   On success (rowset 1): { photoId, newStatus } (absent for action=3)
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-20
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
IF (@action NOT IN (1, 2, 3))
BEGIN
    SET @errorCode = 1233; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid action',
            CONCAT('@action must be 1, 2, or 3; received: ', @action), @procName, @userId);
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

SELECT @photoKennelId = KennelId, @photoStatus = Status
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

-- Verify caller is Hash Flash for this kennel (0x00000020)
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoleFlags, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @photoKennelId;

IF (@mmRoleFlags & 0x00000020 = 0)
BEGIN
    SET @errorCode = 1333; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not Hash Flash',
            'Caller does not hold the Hash Flash role for this kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to review photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Photo must be pending_review (status=1) for the Hash Flash to action it
IF (@photoStatus <> 1)
BEGIN
    SET @errorCode = 1233; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Photo not pending review',
            CONCAT('Photo status is ', @photoStatus, '; only pending_review (1) photos can be actioned'), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Photo already reviewed' AS errorTitle,
           'This photo has already been reviewed.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    IF (@action = 1)
    BEGIN
        UPDATE HC.KennelPhotos SET Status = 2, UpdatedAt = GETUTCDATE() WHERE id = @photoId;
        COMMIT TRANSACTION;
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
        SELECT @photoId AS photoId, 2 AS newStatus;
    END
    ELSE IF (@action = 2)
    BEGIN
        UPDATE HC.KennelPhotos SET Status = 0, UpdatedAt = GETUTCDATE() WHERE id = @photoId;
        COMMIT TRANSACTION;
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
        SELECT @photoId AS photoId, 0 AS newStatus;
    END
    ELSE IF (@action = 3)
    BEGIN
        DELETE FROM HC.KennelPhotos WHERE id = @photoId;
        COMMIT TRANSACTION;
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
        -- No rowset 1 on delete — the photo no longer exists
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
