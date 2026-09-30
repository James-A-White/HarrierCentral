CREATE OR ALTER PROCEDURE [HC6].[hcportal_reactToChatMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @messageId   UNIQUEIDENTIFIER = NULL,
    @reaction    NVARCHAR(20)     = NULL,
    @on          SMALLINT         = 1
AS
-- =====================================================================
-- Procedure: HC6.hcportal_reactToChatMessage
-- Description: Adds or removes the portal user's emoji reaction on a run
--   chat message (E9.F1.S22, 2026-09-30). The rule and the write are
--   HC6.nonApi_reactToChatMessage — the same one the app and the web use.
--   No push from the portal (the run's chat refreshes on its next fetch).
-- Parameters: @messageId; @reaction — a code from HC6.ChatReactionCatalog;
--   @on 1 add / 0 remove. Standard portal token (no param string).
-- Returns: rowset 0 — { Success, ErrorMessage, reactions } where
--   reactions is the message's JSON after the change (NULL when none).
-- Author: Harrier Central
-- Created: 2026-09-30
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @hasherId UNIQUEIDENTIFIER, @callerType INT;

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL,
     @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF (@authError IS NOT NULL)
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage, CAST(NULL AS NVARCHAR(MAX)) AS reactions;
    RETURN;
END

IF (@messageId IS NULL OR @reaction IS NULL)
BEGIN
    SELECT 0 AS Success, 'messageId and reaction are required' AS ErrorMessage, CAST(NULL AS NVARCHAR(MAX)) AS reactions;
    RETURN;
END

BEGIN TRY
    DECLARE @outcome SMALLINT, @reactions NVARCHAR(MAX);
    DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER, @threadId UNIQUEIDENTIFIER;
    DECLARE @messageType INT, @authorId UNIQUEIDENTIFIER;
    EXEC HC6.nonApi_reactToChatMessage
        @userId = @hasherId, @messageId = @messageId, @reaction = @reaction, @on = @on,
        @outcome = @outcome OUTPUT, @reactions = @reactions OUTPUT,
        @eventId = @eventId OUTPUT, @kennelId = @kennelId OUTPUT, @threadId = @threadId OUTPUT,
        @messageType = @messageType OUTPUT, @authorId = @authorId OUTPUT;

    SELECT CASE WHEN @outcome = 1 THEN 1 ELSE 0 END AS Success,
           CASE @outcome
               WHEN 1 THEN NULL
               WHEN 3 THEN 'You can''t react in that chat.'
               WHEN 4 THEN 'That reaction isn''t available.'
               ELSE 'That message is no longer in the chat.' END AS ErrorMessage,
           @reactions AS reactions;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_reactToChatMessage',
            ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, CAST(NULL AS NVARCHAR(MAX)) AS reactions;
END CATCH
GO
