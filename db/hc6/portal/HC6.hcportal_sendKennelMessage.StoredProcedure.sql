CREATE OR ALTER PROCEDURE [HC6].[hcportal_sendKennelMessage]
    @deviceId                  UNIQUEIDENTIFIER = NULL,
    @accessToken               NVARCHAR(1000)   = NULL,
    @publicKennelId            UNIQUEIDENTIFIER = NULL,
    @messageId                 UNIQUEIDENTIFIER = NULL,
    @messageTitle              NVARCHAR(250)    = NULL,
    @messageContent            NVARCHAR(MAX)    = NULL,
    @messageReleasabilityFlags INT              = NULL,
    @messageKind               SMALLINT         = 0,
    @replyToMessageId          UNIQUEIDENTIFIER = NULL,
    @kennelThread              SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcportal_sendKennelMessage
-- Description: Posts to one of a kennel's two chat threads from the portal
--   (E9.F1.S33), through HC6.nonApi_sendKennelMessage — the same SP the
--   app's hcapp_sendKennelMessage posts through, so the Mismanagement gate,
--   the stored row and the push audience are identical. The API shim
--   (PortalApiHC6) pushes from rowsets 1 and 2 with the app's kennel-chat
--   push code. Service accounts may not post.
-- Parameters: @publicKennelId, @messageId (the token's paramString is
--   '<deviceSecret>:<publicKennelId>:<messageId>', binding it to this
--   message), @messageTitle, @messageContent, @messageReleasabilityFlags,
--   @messageKind, @replyToMessageId, @kennelThread (0 general, 1 Mismanagement).
-- Returns: MessageDetails, FullPushRecipients, SilentPushRecipients (as
--   hcapp_sendKennelMessage); on error { Success 0, ErrorMessage }.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none (new — the portal had no kennel chat; E9.F1.S33)
-- Breaking Changes: none (new)
-- Idempotency: client-id — @messageId minted once per message; a resend of a stored message writes nothing and pushes nobody
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @authError NVARCHAR(255);
DECLARE @hasherId UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER, @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);

DECLARE @msgCallerParam NVARCHAR(73) =
    CAST(@publicKennelId AS NVARCHAR(36)) + ':' + CAST(@messageId AS NVARCHAR(36));
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @msgCallerParam,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END
IF @callerType != 0
BEGIN
    SELECT 0 AS Success, 'Service accounts may not send kennel messages' AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = k.id FROM HC.Kennel k
WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
IF (@kennelId IS NULL)
BEGIN
    SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    EXEC HC6.nonApi_sendKennelMessage
        @userId = @hasherId, @kennelId = @kennelId, @messageId = @messageId,
        @messageTitle = @messageTitle, @messageContent = @messageContent,
        @messageReleasabilityFlags = @messageReleasabilityFlags, @messageKind = @messageKind,
        @replyToMessageId = @replyToMessageId, @kennelThread = @kennelThread,
        @hcVersion = @hcv, @callerProcName = @procName,
        @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
        @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;
    IF (@errorCode IS NOT NULL)
        SELECT 0 AS Success, @eMsg AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcv, 'Unhandled error in hcportal_sendKennelMessage', ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
