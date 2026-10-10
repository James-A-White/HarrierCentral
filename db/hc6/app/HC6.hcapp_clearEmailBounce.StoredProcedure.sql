CREATE OR ALTER PROCEDURE [HC6].[hcapp_clearEmailBounce]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL,
    @hasherId    UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_clearEmailBounce
-- Description: An admin clears a hasher's bounced (or suspect) email
--   status from the "Who gets the email" card (E19.F4.S5, James
--   2026-10-10) — after checking the address with them, or when the
--   mailbox was only full. The status goes back to Unknown and the next
--   run email is sent to them again; if it bounces again, the delivery
--   report marks it again. Never clears a member's own block
--   (EmailBlocked) — that is theirs, not the admin's.
--
--   Gate: the caller may edit runs for this run's kennel (the same gate as
--   sending the email), and the hasher is someone this run's email could
--   reach — a live row for the kennel or an attendance/RSVP row for the
--   run. The work is HC6.nonApi_resetEmailStatus, shared with the address-
--   change path; it never touches updatedAt.
-- Parameters: @deviceId/@accessToken (app device auth), @eventId (the run
--   whose audience the admin is looking at), @hasherId (whose status).
-- Returns:
--   On error: standard HC6 error detail (rowset 0)
--   On success: rowset 0 { success, errorCode, errorType }
--               rowset 1 adHocData { adHocDataId, hasherId, emailStatus }
-- Author: Harrier Central
-- Created: 2026-10-10
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
    @spNumber     = 153,
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

IF (@eventId IS NULL OR @hasherId IS NULL)
BEGIN
    SET @errorCode = 1530; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing parameter', 'eventId and hasherId are required', @procName_self, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing details' AS errorTitle, 'The run or the hasher was missing.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = e.KennelId FROM HC.Event e WHERE e.id = @eventId AND e.deleted = 0 AND e.removed = 0;
IF (@kennelId IS NULL)
BEGIN
    SET @errorCode = 1531; SET @errorType = 3; SET @errorId = NEWID();
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
    SET @errorCode = 1532; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised', 'User may not edit runs for this kennel', @procName_self, @userId, @kennelId, @eventId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not allowed' AS errorTitle, 'You cannot manage emails for this run.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap k WHERE k.KennelId = @kennelId AND k.UserId = @hasherId AND k.removed = 0)
   AND NOT EXISTS (SELECT 1 FROM HC.HasherEventMap m WHERE m.EventId = @eventId AND m.UserId = @hasherId)
BEGIN
    SET @errorCode = 1533; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not in audience', CONCAT('hasher ', @hasherId, ' has no row for this kennel or run'), @procName_self, @userId, @kennelId, @eventId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not allowed' AS errorTitle, 'That hasher is not in this run''s email list.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @reason NVARCHAR(100) = CONCAT('cleared by admin ', LOWER(CAST(@userId AS NVARCHAR(40))));
    DECLARE @r TABLE (Success INT, ErrorMessage NVARCHAR(MAX));
    INSERT @r EXEC HC6.nonApi_resetEmailStatus @hasherId = @hasherId, @reason = @reason;
    IF EXISTS (SELECT 1 FROM @r WHERE Success <> 1)
        THROW 50000, 'nonApi_resetEmailStatus failed', 1;

    SELECT 1 AS success, 0 AS errorCode, 0 AS errorType;
    SELECT 1 AS adHocDataId, LOWER(CAST(@hasherId AS NVARCHAR(40))) AS hasherId,
           (SELECT h.EmailStatus FROM HC.Hasher h WHERE h.id = @hasherId) AS emailStatus;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in clearEmailBounce', ERROR_MESSAGE(), @procName_self, @userId, @eventId);
    SELECT @errorId AS errorId, 5 AS errorType, 1539 AS errorCode,
           'Something went wrong' AS errorTitle, 'The bounce could not be cleared. Please try again.' AS errorUserMessage, @procName_self AS errorProc;
END CATCH
