CREATE OR ALTER PROCEDURE [HC6].[hcportal_getRunEmailContext]

    @deviceId          UNIQUEIDENTIFIER = NULL,
    @accessToken       NVARCHAR(1000)   = NULL,
    @publicEventId     UNIQUEIDENTIFIER = NULL,
    @includeRecipients SMALLINT         = 0

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getRunEmailContext
-- Description: The portal's door to run emails (E9.F6.S6–S9, portal
--   parity 2026-10-09): authenticates the portal device, checks the
--   hasher may create/edit runs for the kennel (HC6.CheckKennelPermission,
--   the same gate as the app), then hands over to
--   HC6.nonApi_runEmailContext — the one place the send list is built.
--   Called by the RunEmail API endpoint with client = 'portal'.
-- Parameters:
--   @deviceId / @accessToken - portal device auth (standard token)
--   @publicEventId           - the run, by its public id
--   @includeRecipients       - 1 = also return the recipient rowset
-- Returns: on error { Success = 0, ErrorMessage }; otherwise the three
--   rowsets of nonApi_runEmailContext.
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @hasherId UNIQUEIDENTIFIER, @callerType INT;

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF (@publicEventId IS NULL)
BEGIN
    SELECT 0 AS Success, 'publicEventId is required' AS ErrorMessage;
    RETURN;
END

DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER;
SELECT @eventId = e.id, @kennelId = e.KennelId
FROM HC.Event e
WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND e.removed = 0;

IF (@eventId IS NULL)
BEGIN
    SELECT 0 AS Success, 'That run no longer exists.' AS ErrorMessage;
    RETURN;
END

DECLARE @isHare SMALLINT = 0, @allowed SMALLINT = 0;
IF EXISTS (SELECT 1 FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @hasherId AND hem.IsHare = 1)
    SET @isHare = 1;
EXEC HC6.CheckKennelPermission @userId = @hasherId, @kennelId = @kennelId, @functionKey = 'createEditRuns',
     @isHareOfEvent = @isHare, @allowed = @allowed OUTPUT;
IF (@allowed = 0)
BEGIN
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (NEWID(), '<portal>', 'Not authorised', 'User may not edit runs for this kennel', @procName, @hasherId, @kennelId, @eventId);
    SELECT 0 AS Success, 'You cannot send emails for this run.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    EXEC HC6.nonApi_runEmailContext @eventId = @eventId, @userId = @hasherId, @includeRecipients = @includeRecipients;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_getRunEmailContext', ERROR_MESSAGE(), @procName, @hasherId, @eventId);
    THROW;
END CATCH
