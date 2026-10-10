CREATE OR ALTER PROCEDURE [HC6].[hcportal_clearEmailBounce]
    @deviceId      UNIQUEIDENTIFIER = NULL,
    @accessToken   NVARCHAR(1000)   = NULL,
    @publicEventId UNIQUEIDENTIFIER = NULL,
    @hasherId      UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_clearEmailBounce
-- Description: The portal's door to clearing a hasher's bounced or
--   suspect email status from "Who gets the email" (E19.F4.S5; parity
--   with HC6.hcapp_clearEmailBounce — same gate, same shared worker
--   HC6.nonApi_resetEmailStatus). The caller may edit runs for this run's
--   kennel, and the hasher has a live row for the kennel or a row for the
--   run. Never clears the member's own block.
-- Parameters: @deviceId/@accessToken (portal auth), @publicEventId, @hasherId
-- Returns: { Success, ErrorMessage, hasherId, emailStatus }
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @userId UNIQUEIDENTIFIER, @callerType INT;
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @userId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF (@publicEventId IS NULL OR @hasherId IS NULL)
BEGIN
    SELECT 0 AS Success, 'The run or the hasher was missing.' AS ErrorMessage;
    RETURN;
END

DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER;
SELECT @eventId = e.id, @kennelId = e.KennelId
FROM HC.Event e WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND e.removed = 0;
IF (@eventId IS NULL)
BEGIN
    SELECT 0 AS Success, 'That run no longer exists.' AS ErrorMessage;
    RETURN;
END

DECLARE @isHare SMALLINT = 0, @allowed SMALLINT = 0;
IF EXISTS (SELECT 1 FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @userId AND hem.IsHare = 1)
    SET @isHare = 1;
EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'createEditRuns',
     @isHareOfEvent = @isHare, @allowed = @allowed OUTPUT;
IF (@allowed = 0)
BEGIN
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (NEWID(), '<portal>', 'Not authorised', 'User may not edit runs for this kennel', @procName, @userId, @kennelId, @eventId);
    SELECT 0 AS Success, 'You cannot manage emails for this run.' AS ErrorMessage;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap k WHERE k.KennelId = @kennelId AND k.UserId = @hasherId AND k.removed = 0)
   AND NOT EXISTS (SELECT 1 FROM HC.HasherEventMap m WHERE m.EventId = @eventId AND m.UserId = @hasherId)
BEGIN
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (NEWID(), '<portal>', 'Not in audience', CONCAT('hasher ', @hasherId, ' has no row for this kennel or run'), @procName, @userId, @kennelId, @eventId);
    SELECT 0 AS Success, 'That hasher is not in this run''s email list.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    DECLARE @reason NVARCHAR(100) = CONCAT('cleared by admin ', LOWER(CAST(@userId AS NVARCHAR(40))));
    DECLARE @r TABLE (Success INT, ErrorMessage NVARCHAR(MAX));
    INSERT @r EXEC HC6.nonApi_resetEmailStatus @hasherId = @hasherId, @reason = @reason;
    IF EXISTS (SELECT 1 FROM @r WHERE Success <> 1)
        THROW 50000, 'nonApi_resetEmailStatus failed', 1;
    SELECT 1 AS Success, NULL AS ErrorMessage, LOWER(CAST(@hasherId AS NVARCHAR(40))) AS hasherId,
           (SELECT h.EmailStatus FROM HC.Hasher h WHERE h.id = @hasherId) AS emailStatus;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_clearEmailBounce', ERROR_MESSAGE(), @procName, @userId, @eventId);
    SELECT 0 AS Success, 'The bounce could not be cleared. Please try again.' AS ErrorMessage, NULL AS hasherId, NULL AS emailStatus;
END CATCH
