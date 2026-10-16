CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendKennelMessage]
    @deviceId                    UNIQUEIDENTIFIER = NULL,
    @accessToken                 NVARCHAR(1000)   = NULL,
    @kennelId                    UNIQUEIDENTIFIER = NULL,
    @messageId                   UNIQUEIDENTIFIER = NULL,
    @messageTitle                NVARCHAR(250)    = NULL,
    @messageContent              NVARCHAR(MAX)    = NULL,
    @messageReleasabilityFlags   INT              = NULL,
    -- 0 text, 1 photo, 2 location (E9.F1.S11/S12, 2026-09-29). Optional,
    -- so every existing caller still sends text.
    @messageKind                 SMALLINT         = 0,
    @replyToMessageId UNIQUEIDENTIFIER = NULL,
    -- 0 the kennel's general chat, 1 its private Mismanagement chat
    -- (E9.F1.S33). Optional: every existing caller posts to the general chat.
    @kennelThread     SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendKennelMessage
-- Description: Sends a message to a KENNEL-LEVEL chat thread (an
--   EventMessage row with KennelId set and EventId NULL). Mirrors
--   hcapp_sendEventMessage's three-rowset contract so the API shim's
--   push dispatch works unchanged. Preference resolution uses
--   KennelNotificationPreference only (no event-level override exists
--   for a kennel thread); onBeforeRun(4) is treated as a full push.
-- Parameters: mirror hcapp_sendEventMessage with @kennelId in place of
--   @eventId.
-- Returns:
--   Rowset 0: message detail (sender optimistic-UI confirmation)
--   Rowset 1: full push recipients { UserId, FcmToken, BadgeTotal }
--   Rowset 2: silent in-app recipients { UserId, FcmToken, BadgeTotal }
--   BadgeTotal (2026-09-28): the recipient's unread total for the app icon.
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — kennel chat, design of record)
-- Breaking Changes: none
--   2026-10-16 (E9.F1.S33): optional @kennelThread. The message is stored
--   under that thread's MessageType (HC6.KennelThreadMessageType); the
--   resend, reply and read-mark checks are of that thread only. Thread 1,
--   the private Mismanagement chat, is refused (errorType 13) unless
--   HC6.UserInKennelMismanagement, and pushes ONLY the kennel's
--   mismanagement (every office or app access flag), on builds at or
--   above HC6.MinBuildForKennelMismanagement — releasability flags do not
--   widen it. Rowset 0 gains KennelThread and ThreadKind ('kennel' /
--   'kennelMisman') for the API's push payload. Additive. The post is
--   HC6.nonApi_sendKennelMessage (shared with the portal); this SP
--   authenticates and formats errors.
--   2026-10-11 (E9.F1.S30): anyone may post; the follower refusal is
--   gone. Posting creates a HasherKennelMap row (Following 0, bell on) or
--   turns a never-chosen bell (0) on. No rowset change.
--   2026-09-29: optional @messageKind (photo / location). Rowset 0's
--   MessageContent is now HC6.ChatMessagePreview — it is the push body —
--   and rowset 0 gains MessageKind. Additive for every caller.
-- Idempotency: client-id — @messageId; a resend of a stored message writes nothing and pushes nobody
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 64, @param = NULL,
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

-- The post itself is HC6.nonApi_sendKennelMessage (2026-10-16), shared with
-- the portal's hcportal_sendKennelMessage. Its three rowsets come straight
-- through; a refusal comes back as OUTPUTs and is answered here in the
-- app's error envelope, exactly as before.
DECLARE @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);
DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);
BEGIN TRY
    EXEC HC6.nonApi_sendKennelMessage
        @userId = @userId, @kennelId = @kennelId, @messageId = @messageId,
        @messageTitle = @messageTitle, @messageContent = @messageContent,
        @messageReleasabilityFlags = @messageReleasabilityFlags, @messageKind = @messageKind,
        @replyToMessageId = @replyToMessageId, @kennelThread = @kennelThread,
        @hcVersion = @hcv, @callerProcName = @procName,
        @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
        @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;

    IF (@errorCode IS NOT NULL)
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               @eTitle AS errorTitle, @eMsg AS errorUserMessage, @procName AS errorProc;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcv, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
