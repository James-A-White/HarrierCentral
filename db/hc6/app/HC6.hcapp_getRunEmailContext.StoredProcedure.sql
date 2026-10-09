CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunEmailContext]

    @deviceId          UNIQUEIDENTIFIER = NULL,
    @accessToken       NVARCHAR(1000)   = NULL,
    @eventId           UNIQUEIDENTIFIER = NULL,
    @includeRecipients SMALLINT         = 0

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunEmailContext
-- Description: Everything the API needs to draft or send a run email
--   (E9.F6.S6–S9). Called by the RunEmail API endpoint on behalf of the
--   app, with the app's own device token (procName = this SP).
--
--   The caller must be allowed to create/edit runs for the kennel (the
--   same gate as hcapp_addEditEvent) — anyone who may save the run may
--   send it.
--
--   Delegates to HC6.nonApi_runEmailContext (shared with the portal).
--   The send list follows the app's email-alert dialog EXACTLY
--   (James, 2026-10-09; EnumEmailAlertState 0 = use kennel setting,
--   1 = on, 2 = off):
--     run setting 1            -> send, whatever the kennel says
--     run setting 2            -> never
--     run setting 0 or no row  -> kennel setting 1 sends; 0 or 2 does not
--   Removed accounts and accounts without an email never. The sender IS
--   included when they qualify — that is how a hare raiser sees their own
--   email, and how James tests on HCTEST.
-- Parameters:
--   @deviceId / @accessToken - app device auth
--   @eventId                 - the run
--   @includeRecipients       - 1 = also return the recipient rowset
-- Returns:
--   On error (rowset 0): standard HC6 error detail
--   On success:
--     rowset 0 — the run: eventId, eventNumber, eventName, isCountedRun,
--               publicEventId, startLocal (wall-clock), hares, venue,
--               street, city, postCode, description, priceMembers,
--               priceNonMembers, currencySymbol, kennelId, kennelName,
--               kennelShortName, kennelSlug, kennelLogo, senderName,
--               instruction (the kennel's saved drafting instruction)
--     rowset 1 — emailSendCount, emailLastSentAt, emailLastSentCount,
--               recipientCount
--     rowset 2 — (only when @includeRecipients = 1) hasherId, email,
--               displayName
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);

DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName_self,
    @spNumber     = 151,
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
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1510; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Null or empty eventId', 'eventId is required', @procName_self, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing run' AS errorTitle, 'No run was given.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = e.KennelId
FROM HC.Event e
WHERE e.id = @eventId AND e.deleted = 0 AND e.removed = 0;

IF (@kennelId IS NULL)
BEGIN
    SET @errorCode = 1511; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Run not found', 'No live run with this id', @procName_self, @userId, @eventId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Run not found' AS errorTitle, 'That run no longer exists.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

DECLARE @isHare SMALLINT = 0, @allowed SMALLINT = 0;
IF EXISTS (SELECT 1 FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @userId AND hem.IsHare = 1)
    SET @isHare = 1;
EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'createEditRuns',
     @isHareOfEvent = @isHare, @allowed = @allowed OUTPUT;
IF (@allowed = 0)
BEGIN
    SET @errorCode = 1512; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised', 'User may not edit runs for this kennel', @procName_self, @userId, @kennelId, @eventId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle, 'You cannot send emails for this run.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

BEGIN TRY
    -- The context and the send list are built in ONE place, shared with the
    -- portal's hcportal_getRunEmailContext.
    EXEC HC6.nonApi_runEmailContext @eventId = @eventId, @userId = @userId, @includeRecipients = @includeRecipients;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getRunEmailContext',
            ERROR_MESSAGE(), @procName_self, @userId, @eventId);
    THROW;
END CATCH
