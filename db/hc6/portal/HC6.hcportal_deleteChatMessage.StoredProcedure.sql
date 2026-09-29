CREATE OR ALTER PROCEDURE [HC6].[hcportal_deleteChatMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @messageId   UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_deleteChatMessage
-- Description: Deletes one chat message from the portal (E9.F1.S13/S14,
--   2026-09-29): the caller's own, or anyone's if they moderate that
--   thread. The rule is HC6.nonApi_deleteChatMessage — the same one the
--   app and the web use.
-- Parameters: @messageId — HC.EventMessage.id. The token is bound to it
--   (@callerParamString), as portal tokens are to their target.
-- Returns: standard portal envelope { Success, ErrorMessage }
-- Author: Harrier Central
-- Created: 2026-09-29
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @hasherId UNIQUEIDENTIFIER, @callerType INT;
DECLARE @param NVARCHAR(500) = CAST(@messageId AS NVARCHAR(40));

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @param,
     @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF (@authError IS NOT NULL)
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF (@messageId IS NULL)
BEGIN
    SELECT 0 AS Success, 'messageId is required' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    DECLARE @outcome SMALLINT, @errorId UNIQUEIDENTIFIER;
    EXEC HC6.nonApi_deleteChatMessage
        @userId = @hasherId, @messageId = @messageId,
        @callerProcName = @procName, @hcVersion = '<portal>',
        @outcome = @outcome OUTPUT, @errorId = @errorId OUTPUT;

    SELECT CASE WHEN @outcome = 1 THEN 1 ELSE 0 END AS Success,
           CASE @outcome
               WHEN 1 THEN NULL
               WHEN 3 THEN 'You can delete your own messages. Only a chat administrator can delete someone else''s.'
               ELSE 'That message is no longer in the chat.' END AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_deleteChatMessage',
            ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
