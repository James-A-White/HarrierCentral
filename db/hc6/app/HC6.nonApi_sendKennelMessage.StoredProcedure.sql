CREATE OR ALTER PROCEDURE [HC6].[nonApi_sendKennelMessage]
    @userId                      UNIQUEIDENTIFIER,
    @kennelId                    UNIQUEIDENTIFIER = NULL,
    @messageId                   UNIQUEIDENTIFIER = NULL,
    @messageTitle                NVARCHAR(250)    = NULL,
    @messageContent              NVARCHAR(MAX)    = NULL,
    @messageReleasabilityFlags   INT              = NULL,
    @messageKind                 SMALLINT         = 0,
    @replyToMessageId            UNIQUEIDENTIFIER = NULL,
    @kennelThread                SMALLINT         = 0,
    @hcVersion                   NVARCHAR(100)    = NULL,
    @callerProcName              NVARCHAR(128)    = NULL,
    @errorCode                   INT              = NULL OUTPUT,
    @errorType                   INT              = NULL OUTPUT,
    @errorId                     UNIQUEIDENTIFIER = NULL OUTPUT,
    @errorTitle                  NVARCHAR(200)    = NULL OUTPUT,
    @errorUserMessage            NVARCHAR(500)    = NULL OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_sendKennelMessage
-- Description: THE post to one of a kennel's two chat threads (E9.F1.S33,
--   2026-10-16): the body of hcapp_sendKennelMessage moved here verbatim so
--   the app (hcapp_sendKennelMessage, and the web through it) and the
--   portal (hcportal_sendKennelMessage) post by ONE set of rules — the
--   Mismanagement gate and push audience (HC6.KennelChatPushAudience) above
--   all. The caller authenticates and passes @userId.
--   On a refusal returns NO rowset and sets the error OUTPUTs (logged here);
--   on success returns hcapp_sendKennelMessage's three rowsets.
-- Errors: 1901 missing fields, 1902 too long, 1903 bad kind, 1913 not in
--   mismanagement / unknown thread, 1933 unexpected (the message was not
--   stored). A failure AFTER the message is stored is logged and swallowed.
-- Returns: MessageDetails, FullPushRecipients, SilentPushRecipients.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none
-- Breaking Changes: none (new)
-- Idempotency: client-id — @messageId; a resend of a stored message writes nothing and pushes nobody
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @errorCode = NULL; SET @errorType = NULL; SET @errorId = NULL;
SET @errorTitle = NULL; SET @errorUserMessage = NULL;
DECLARE @procName NVARCHAR(128) = COALESCE(@callerProcName, OBJECT_NAME(@@PROCID));

IF (@messageId IS NULL OR @kennelId IS NULL
    OR LEN(COALESCE(@messageContent, '')) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Missing required fields',
            'messageId, kennelId and messageContent are required', @procName, @userId);
    SET @errorType = 2; SET @errorCode = 1901;
    SET @errorTitle = 'Missing fields';
    SET @errorUserMessage = 'The message could not be sent. Please try again.';
    RETURN;
END

-- The column is NVARCHAR(4000) since 2026-09-23 and this parameter is MAX so
-- that an over-long message is REFUSED, not cut: an NVARCHAR(500) parameter
-- silently truncated the first admin-room announcement at exactly 500
-- characters, with no error and no log (James, 2026-09-23). LEN counts
-- UTF-16 code units, the same measure the column enforces.
IF (LEN(@messageContent) > 4000)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Message too long',
            CONCAT('kennelId=', CAST(@kennelId AS VARCHAR(40)), ' contentLen=', LEN(@messageContent)),
            @procName, @userId);
    SET @errorType = 2; SET @errorCode = 1902;
    SET @errorTitle = 'Message too long';
    SET @errorUserMessage = CONCAT('Messages can be up to 4,000 characters; this one is ', LEN(@messageContent),
                  '. Please shorten it and send again.');
    RETURN;
END

DECLARE @messageType INT = HC6.KennelThreadMessageType(@kennelThread);
IF (@messageType IS NULL
    OR (@messageType <> 0 AND HC6.UserInKennelMismanagement(@userId, @kennelId) = 0))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Not in kennel mismanagement',
            CONCAT('kennelId=', CAST(@kennelId AS VARCHAR(40)), ' kennelThread=', @kennelThread),
            @procName, @userId);
    SET @errorType = 13; SET @errorCode = 1913;
    SET @errorTitle = 'Not available';
    SET @errorUserMessage = 'This chat is only for the kennel''s mismanagement.';
    RETURN;
END

-- A photo must be one of ours, a location a well-formed map link.
SET @messageKind = COALESCE(@messageKind, 0);
DECLARE @kindError NVARCHAR(200) = HC6.ChatMessageKindError(@messageKind, @messageContent);
IF (@kindError IS NOT NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Bad message kind',
            CONCAT('kind=', @messageKind, ' content=', LEFT(@messageContent, 300)), @procName, @userId);
    SET @errorType = 2; SET @errorCode = 1903;
    SET @errorTitle = 'Message not sent';
    SET @errorUserMessage = @kindError;
    RETURN;
END

-- Anyone may post in a kennel's chat (James, 2026-10-11). The sender used to
-- need a HasherKennelMap row; a visitor or a hasher thinking of joining is
-- exactly who a kennel chat is for. Who is PUSHED is unchanged: the audience
-- below is still drawn from HasherKennelMap.

DECLARE @publicKennelId UNIQUEIDENTIFIER, @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicKennelId = k.PublicKennelId FROM HC.Kennel k WHERE k.id = @kennelId;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;
SET @messageReleasabilityFlags = COALESCE(@messageReleasabilityFlags, 63);
SET @messageTitle = COALESCE(@messageTitle, '');

-- A resend of a message this sender already stored (2026-10-13): writes
-- nothing, returns the stored message and empty push rowsets. The phone
-- resends the same @messageId when a reply is lost; the second INSERT used
-- to hit the primary key and report a delivered message as unsent.
DECLARE @isResend SMALLINT = CASE WHEN EXISTS (
        SELECT 1 FROM HC.EventMessage
        WHERE id = @messageId AND UserId = @userId AND KennelId = @kennelId AND EventId IS NULL
          AND MessageType = @messageType) THEN 1 ELSE 0 END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF (@isResend = 0)
    BEGIN

    -- A reply quotes a message of THIS thread (E9.F1.S21). Anything else —
    -- a stale id, another chat's message — sends as a plain message rather
    -- than failing the send; the quote is decoration, the text is the point.
    IF (@replyToMessageId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HC.EventMessage r
                                                    WHERE r.id = @replyToMessageId AND r.KennelId = @kennelId AND r.EventId IS NULL
                                                      AND r.MessageType = @messageType))
        SET @replyToMessageId = NULL;

    -- Posting joins the kennel's chat (James, 2026-10-11). A hasher with no
    -- HasherKennelMap row gets one with the bell ON, so the replies reach
    -- them, and the thread lists in their Chats (HC6.UserUnreadChatThreads
    -- counts a kennel chat you posted in as yours). Following = 0 explicitly:
    -- the column DEFAULTS to 1, and following is the hasher's own choice.
    -- MemberSince NULL for the same reason: they are not a member.
    -- A row whose bell was never chosen (0) has it turned on; an explicit
    -- Off (2), Silver Bell (3) or On before the run (4) is never overridden.
    -- It is the KENNEL bell, so it also enables that kennel's RSVP and
    -- check-in reminders (James chose this over a chat-only setting).
    -- (KennelId, UserId) is unique INCLUDING removed rows, so the existence
    -- test ignores `removed`; a removed row is left alone, never revived.
    IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap WITH (UPDLOCK, HOLDLOCK)
                   WHERE UserId = @userId AND KennelId = @kennelId)
        INSERT HC.HasherKennelMap (UserId, KennelId, Following, MemberSince, KennelNotificationPreference)
        VALUES (@userId, @kennelId, 0, NULL, 1);
    ELSE
        UPDATE HC.HasherKennelMap SET KennelNotificationPreference = 1
         WHERE UserId = @userId AND KennelId = @kennelId
           AND removed = 0 AND KennelNotificationPreference = 0;

    INSERT INTO HC.EventMessage
        ([id], [KennelId], [PublicKennelId], [UserId], [PublicHasherId],
         [MessageTitle], [MessageContent], [MessageReleasabilityFlags], [MessageKind], [ReplyToMessageId],
         [MessageType])
    VALUES
        (@messageId, @kennelId, @publicKennelId, @userId, @publicHasherId,
         @messageTitle, @messageContent, @messageReleasabilityFlags, @messageKind, @replyToMessageId,
         @messageType);

    DECLARE @messageSequenceCount INT;
    SELECT @messageSequenceCount = em.MessageSequenceCount
    FROM HC.EventMessage em WHERE em.id = @messageId;

    -- Sender never sees their own message as unread
    -- Per thread: the (UserId, KennelId, MessageType) row, so posting in one
    -- of the kennel's two threads never marks the other read.
    MERGE INTO HC.EventMessageBadgeCounts WITH (HOLDLOCK) AS Target
    USING (VALUES (@userId, @kennelId, @messageType, @messageSequenceCount))
          AS Source (UserId, KennelId, MessageType, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.KennelId = Source.KennelId
        AND Target.EventId IS NULL AND Target.MessageType = Source.MessageType)
    WHEN MATCHED THEN
        UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, KennelId, MessageType, LastSequenceCount)
        VALUES (Source.UserId, Source.KennelId, Source.MessageType, Source.LastSequenceCount);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SET @errorType = 5; SET @errorCode = 1933;
    SET @errorTitle = 'Unexpected error';
    SET @errorUserMessage = 'The message could not be sent. Please try again.';
    RETURN;
END CATCH

-- The message is COMMITTED by this point (2026-10-13, as sendRoomMessage).
-- Everything below ran outside any TRY, so a failure here was an unlogged
-- raw 500 for a message that had been stored. Now it is logged and
-- swallowed, never re-thrown.
BEGIN TRY

-- ---------------------------------------------------------------
-- Rowset 0: message detail
-- ---------------------------------------------------------------

SELECT
    msg.id                                   AS MessageId,
    msg.KennelId                             AS KennelId,
    msg.PublicKennelId                       AS PublicKennelId,
    h.PublicHasherId                         AS UserId,
    h.DisplayName                            AS UserDisplayName,
    h.Photo                                  AS UserPhoto,
    h.DisplayName + ' - ' + msg.MessageTitle AS MessageTitle,
    -- The preview, not the raw URL: the shim uses this as the push body.
    HC6.ChatMessagePreview(msg.MessageKind, msg.MessageContent) AS MessageContent,
    msg.MessageKind                          AS MessageKind,
    msg.MessageReleasabilityFlags            AS MessageReleasabilityFlags,
    0                                        AS EventChatMessageCount,
    msg.MessageType                          AS MessageType,
    -- Added 2026-09-18: a kennel push carries the short name so the phone can
    -- title the thread it opens. Additive, so older clients ignore it.
    k.KennelShortName                        AS KennelShortName,
    -- E9.F1.S33: which of the kennel's threads, for the push payload.
    CAST(COALESCE(@kennelThread, 0) AS SMALLINT) AS KennelThread,
    CASE WHEN @messageType = 0 THEN 'kennel' ELSE 'kennelMisman' END AS ThreadKind
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
LEFT JOIN HC.Kennel k  ON k.id = msg.KennelId
WHERE msg.id = @messageId AND msg.removed = 0 AND h.Removed = 0;

-- ---------------------------------------------------------------
-- Push recipients (rewritten 2026-09-17 — see hcapp_sendEventMessage for
-- the full reasoning). Only a hasher who actually chose a kennel
-- notification setting is pushed: 0 means never touched and is not
-- consent, which is the gate nonApi_checkReminders has always used
-- (`IN (1, 3, 4)`). One push per device, not per device row: DISTINCT on
-- the token, no retired rows, and nothing to a device that has not signed
-- in for 180 days (James, 2026-09-17; the next sign-in re-arms it).
-- A kennel message is not tied to a run, so "on before the run" (4) has no
-- window to sit inside and is treated as on, as it always was here.
-- ---------------------------------------------------------------
-- The audience is HC6.KennelChatPushAudience (2026-10-16, E9.F1.S33): the
-- rules that were written out here, moved verbatim so the weekly
-- Mismanagement reminder pushes to exactly the same people.
SELECT a.UserId, a.FcmToken, a.Pref
INTO #pushAudience
FROM HC6.KennelChatPushAudience(@kennelId, @messageType, @messageReleasabilityFlags, @userId) a;

-- A resend notifies nobody: its first send already did.
IF (@isResend = 1) DELETE FROM #pushAudience;

-- Rowset 1: visible push notification recipients
-- BadgeTotal: the recipient's unread total for the app ICON (HC6.UserUnreadChatTotal,
-- the same rule as the in-app badges); the API puts it in aps.badge (2026-09-28).
-- NULL below HC6.MinBuildForIconBadge(): an older app never lowers the icon.
SELECT DISTINCT a.UserId, a.FcmToken,
    CASE WHEN EXISTS (SELECT 1 FROM HC.Device dv WHERE dv.FcmToken = a.FcmToken
                    AND TRY_CAST(dv.BuildNumber AS INT) >= HC6.MinBuildForIconBadge())
     THEN bt.BadgeTotal END AS BadgeTotal FROM #pushAudience a
CROSS APPLY HC6.UserUnreadChatTotal(a.UserId, a.FcmToken) bt WHERE a.Pref IN (1, 4);

-- Rowset 2: silent (data-only) recipients — "on but muted"
SELECT DISTINCT a.UserId, a.FcmToken,
    CASE WHEN EXISTS (SELECT 1 FROM HC.Device dv WHERE dv.FcmToken = a.FcmToken
                    AND TRY_CAST(dv.BuildNumber AS INT) >= HC6.MinBuildForIconBadge())
     THEN bt.BadgeTotal END AS BadgeTotal FROM #pushAudience a
CROSS APPLY HC6.UserUnreadChatTotal(a.UserId, a.FcmToken) bt WHERE a.Pref = 3;

DROP TABLE #pushAudience;

END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcVersion,
            'Push audience failed in sendKennelMessage', ERROR_MESSAGE(), @procName, @userId);
    -- Swallowed on purpose: the message is stored. See the note above the TRY.
END CATCH
GO
