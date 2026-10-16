CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelMessages]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @kennelId           UNIQUEIDENTIFIER = NULL,
    @sinceSequenceCount INT              = NULL,
    @reactionsSince     DATETIMEOFFSET(7) = NULL,
    -- 0 the kennel's general chat, 1 its private Mismanagement chat
    -- (E9.F1.S33). Optional: every existing caller reads the general chat.
    @kennelThread       SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getKennelMessages
-- Description: Returns messages for a KENNEL-LEVEL chat thread
--   (EventMessage rows with KennelId = @kennelId, EventId NULL). Mirrors
--   hcapp_getEventMessages' rowset shape so the app's ChatPageController
--   parses it unchanged (roomId = PublicKennelId).
-- Parameters:
--   @kennelId           - Kennel whose thread to read
--   @sinceSequenceCount - Delta fetch: only messages with a higher
--                         MessageSequenceCount (NULL = full fetch)
-- Returns: message rows, newest-first (same columns as getEventMessages)
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — kennel chat, design of record)
-- Breaking Changes: none
--   2026-09-29 (E9.F1.S11-S14): adds messageKind (0 text, 1 photo,
--   2 location) and canDelete to each message, and a LAST rowset
--   { removedId } — every removed message in the thread, so a client
--   that already drew one can drop it (a delta fetch by sequence number
--   never sees a deletion). Clients find it by its column name. Additive.
--   2026-10-11 (E9.F1.S30): a full fetch turns a never-chosen kennel bell
--   (0) on. No rowset change.
--   2026-10-16 (E9.F1.S33): optional @kennelThread. Every read is now of
--   ONE thread's MessageType (HC6.KennelThreadMessageType), so a private
--   Mismanagement message can never appear in the general chat. Thread 1
--   is refused (errorType 13) unless HC6.UserInKennelMismanagement.
-- Idempotency: read-only — the bell write sets a state (0 → 1, never toggled)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 65, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);

BEGIN TRY

-- The read itself is HC6.nonApi_getKennelMessages (2026-10-16), shared with
-- the portal's hcportal_getKennelMessages so both read by one set of rules.
DECLARE @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);
EXEC HC6.nonApi_getKennelMessages
    @userId = @userId, @kennelId = @kennelId, @sinceSequenceCount = @sinceSequenceCount,
    @reactionsSince = @reactionsSince, @kennelThread = @kennelThread,
    @hcVersion = @hcv, @callerProcName = @procName,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;

IF (@errorCode IS NOT NULL)
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @eTitle AS errorTitle, @eMsg AS errorUserMessage, @procName AS errorProc;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getKennelMessages',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
