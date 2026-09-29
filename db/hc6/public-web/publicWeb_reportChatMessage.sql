-- =====================================================================
-- Procedure: HC6.publicWeb_reportChatMessage
-- Description: The web member's door to hcapp_reportChatMessage (E9.F1.S16/S17,
--   2026-09-29). Everything that decides anything lives in the app SP, so
--   this wrapper adds no checks that could drift from the app's.
-- Parameters: @deviceId, @accessToken (signed for hcapp_reportChatMessage),
--   the app SP's own
-- Returns: hcapp_reportChatMessage's rowsets
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_reportChatMessage]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @messageId UNIQUEIDENTIFIER = NULL,
    @reason NVARCHAR(MAX) = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_reportChatMessage @deviceId = @deviceId, @accessToken = @accessToken, @messageId = @messageId, @reason = @reason;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_reportChatMessage', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
