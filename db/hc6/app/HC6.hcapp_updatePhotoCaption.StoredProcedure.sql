CREATE OR ALTER PROCEDURE [HC6].[hcapp_updatePhotoCaption]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @photoId     UNIQUEIDENTIFIER,
    @description NVARCHAR(MAX) = NULL  -- NULL clears the caption

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updatePhotoCaption
-- Description: Allows an authorised reviewer (Hash Flash, GM, VGM, RA)
--   to add, edit, or clear the caption on a kennel photo. Operates on
--   photos of any status. Passing NULL for @description clears the
--   existing caption.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @photoId     - UUID of the photo to update
--   @description - New caption text (NULL = clear existing caption)
-- Returns:
--   On success (rowset 0): { success, errorCode, errorType }
--   On success (rowset 1): { photoId, description }
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-30
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
    @spNumber     = 92,
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

DECLARE @photoKennelId UNIQUEIDENTIFIER;

SELECT @photoKennelId = KennelId
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

-- Verify caller holds a reviewer role for this kennel
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @photoKennelId;

IF (@mmRoleFlags & 0x0000002E = 0)
BEGIN
    SET @errorCode = 1333; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised to edit photo caption',
            'Caller does not hold Hash Flash, GM, VGM or RA role for this kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to edit captions for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE HC.KennelPhotos
    SET Description = @description,
        UpdatedAt   = GETUTCDATE()
    WHERE id = @photoId;

    COMMIT TRANSACTION;
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT @photoId AS photoId, @description AS description;

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
