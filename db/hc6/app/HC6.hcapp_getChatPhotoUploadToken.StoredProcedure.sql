CREATE OR ALTER PROCEDURE [HC6].[hcapp_getChatPhotoUploadToken]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @photoGuid   UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getChatPhotoUploadToken
-- Description: Authenticates a request to upload one chat photo
--   (E9.F1.S11, 2026-09-29). Called by the API function
--   GetChatPhotoUploadToken, which then signs a 15-minute, write-only SAS
--   for chat-photos/<yyyy>/<MM>/<userId>-<photoGuid>.jpg.
--
--   The path carries the uploader's id, taken from the token — never from
--   the request — so a hasher can only ever write under their own name.
--   Posting the photo to a chat is a separate act (the send SPs), gated
--   there by who may post in that thread, and HC6.ChatMessageKindError
--   refuses any "photo" that is not in this container.
-- Parameters: @photoGuid — client-chosen, names the file
-- Returns: rowset 0 — { success, errorCode, errorType }
--          rowset 1 — { userId } on success; the error detail on failure
-- Author: Harrier Central
-- Created: 2026-09-29
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 124, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@photoGuid IS NULL OR @photoGuid = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing photoGuid',
            '@photoGuid is required', @procName, @userId);
    SELECT 0 AS success, 1984 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1984 AS errorCode,
           'Missing parameter' AS errorTitle,
           'The photo could not be uploaded. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT @userId AS userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getChatPhotoUploadToken',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
