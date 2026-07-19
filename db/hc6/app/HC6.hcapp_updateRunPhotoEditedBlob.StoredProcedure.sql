CREATE OR ALTER PROCEDURE [HC6].[hcapp_updateRunPhotoEditedBlob]

    @deviceId      UNIQUEIDENTIFIER,
    @accessToken   NVARCHAR(1000),
    @kennelId      UNIQUEIDENTIFIER,
    @photoId       UNIQUEIDENTIFIER,
    @editedBlobUrl NVARCHAR(500)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updateRunPhotoEditedBlob
-- Description: Saves the URL of a Hash-Flash-edited (cropped) version
--   of a run photo. The original BlobUrl is never modified — this SP
--   writes only to EditedBlobUrl. Callers should always start a re-edit
--   from the original BlobUrl, not from EditedBlobUrl.
--   Auth: Hash Flash (0x20), GM (0x02), VGM (0x04), or RA (0x08).
-- Parameters:
--   @deviceId      - Registered device UUID
--   @accessToken   - Token validated against DeviceSecret
--   @kennelId      - Kennel that owns the photo (auth scope)
--   @photoId       - Photo to update
--   @editedBlobUrl - Blob URL of the cropped version
-- Returns:
--   On success (rowset 0): { success=1, errorCode=NULL, errorType=NULL }
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
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
    @spNumber     = 48,
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

-- Validate required parameters
IF (@photoId  IS NULL OR @photoId  = '00000000-0000-0000-0000-000000000000'
 OR @kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000'
 OR LEN(LTRIM(RTRIM(ISNULL(@editedBlobUrl, '')))) = 0)
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing parameter',
            '@photoId, @kennelId and @editedBlobUrl are all required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Auth: Hash Flash / GM / VGM / RA for this kennel
-- Authorization: feature "Edit photo status / caption" (see /hc-authorizations).
DECLARE @photoAllowed SMALLINT;
EXEC HC6.CheckKennelPermission @userId, @kennelId, 0x0000002E, 0x00000100, @photoAllowed OUTPUT;

IF (@photoAllowed = 0)
BEGIN
    SET @errorCode = 1334; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised',
            'Caller lacks Hash Flash / GM / VGM / RA role', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to edit photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    UPDATE HC.KennelPhotos
    SET EditedBlobUrl = @editedBlobUrl,
        UpdatedAt     = GETUTCDATE()
    WHERE id       = @photoId
      AND KennelId = @kennelId;

    IF (@@ROWCOUNT = 0)
    BEGIN
        SET @errorCode = 4040; SET @errorType = 3; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Photo not found',
                'No photo matched @photoId + @kennelId', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Photo not found' AS errorTitle,
               'The photo could not be found. It may have been removed.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
