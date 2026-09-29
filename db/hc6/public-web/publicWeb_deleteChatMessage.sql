-- =====================================================================
-- Procedure: HC6.publicWeb_deleteChatMessage
-- Description: A web member deletes a chat message (E9.F1.S13/S14)
--   through the app's own hcapp_deleteChatMessage. All the authorization
--   lives there (and in HC6.nonApi_deleteChatMessage), so this wrapper
--   adds no checks of its own that could drift from the app's.
-- Parameters: @deviceId, @accessToken (signed for hcapp_deleteChatMessage),
--             @messageId — the message, as the web received it
-- Returns: hcapp_deleteChatMessage's envelope
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_deleteChatMessage]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @messageId   UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_deleteChatMessage
        @deviceId    = @deviceId,
        @accessToken = @accessToken,
        @messageId   = @messageId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_deleteChatMessage',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
