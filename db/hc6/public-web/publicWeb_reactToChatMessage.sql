-- =====================================================================
-- Procedure: HC6.publicWeb_reactToChatMessage
-- Description: A web member adds or removes an emoji reaction on a chat
--   message (E9.F1.S22) through the app's own hcapp_reactToChatMessage.
--   All the authorization lives there (and in
--   HC6.nonApi_reactToChatMessage), so this wrapper adds no checks of its
--   own that could drift from the app's. The API-only rowsets (push
--   detail, device tokens) are stripped by PublicWebAdminApi's caller
--   shape: the web reads the first rowset's `success` row and nothing
--   else, and the browser is not a push target.
-- Parameters: @deviceId, @accessToken (signed for hcapp_reactToChatMessage),
--             @messageId, @reaction (catalog code), @on 1 add / 0 remove
-- Returns: hcapp_reactToChatMessage's rowsets
-- Author: Harrier Central
-- Created: 2026-09-30
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_reactToChatMessage]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @messageId   UNIQUEIDENTIFIER = NULL,
    @reaction    NVARCHAR(20)     = NULL,
    @on          SMALLINT         = 1
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_reactToChatMessage
        @deviceId    = @deviceId,
        @accessToken = @accessToken,
        @messageId   = @messageId,
        @reaction    = @reaction,
        @on          = @on;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_reactToChatMessage',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
