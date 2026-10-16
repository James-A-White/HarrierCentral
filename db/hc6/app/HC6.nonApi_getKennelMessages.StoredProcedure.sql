CREATE OR ALTER PROCEDURE [HC6].[nonApi_getKennelMessages]
    @userId             UNIQUEIDENTIFIER,
    @kennelId           UNIQUEIDENTIFIER = NULL,
    @sinceSequenceCount INT              = NULL,
    @reactionsSince     DATETIMEOFFSET(7) = NULL,
    @kennelThread       SMALLINT         = 0,
    @hcVersion          NVARCHAR(100)    = NULL,   -- the caller's client version, for HC.ErrorLog
    @callerProcName     NVARCHAR(128)    = NULL,   -- the wrapper's name, for HC.ErrorLog
    @errorCode          INT              = NULL OUTPUT,
    @errorType          INT              = NULL OUTPUT,
    @errorId            UNIQUEIDENTIFIER = NULL OUTPUT,
    @errorTitle         NVARCHAR(200)    = NULL OUTPUT,
    @errorUserMessage   NVARCHAR(500)    = NULL OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getKennelMessages
-- Description: THE read of one of a kennel's two chat threads (E9.F1.S33,
--   2026-10-16): the body of hcapp_getKennelMessages moved here verbatim, so
--   the app (hcapp_getKennelMessages), the web (publicWeb_getChatMessages,
--   through the app SP) and the portal (hcportal_getKennelMessages) read a
--   kennel chat by ONE set of rules — the Mismanagement gate above all.
--   The caller authenticates and passes @userId; this never sees a token.
--   On a refusal it returns NO rowset and sets @errorCode (logged here);
--   the wrapper turns that into its own error envelope. On success it
--   returns the four rowsets of hcapp_getKennelMessages.
-- Parameters: as hcapp_getKennelMessages, plus @hcVersion / @callerProcName
--   for the error log and the error OUTPUTs.
--   @kennelThread: 0 general chat, 1 Mismanagement (members only).
-- Returns: Messages, RemovedIds, ReactionUpdates, ReactionsAsOf — or nothing
--   with @errorCode set (1901 no kennel, 1913 not in mismanagement).
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none
-- Breaking Changes: none (new)
-- Idempotency: read-only — the bell write sets a state (0 → 1, never toggled)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @errorCode = NULL; SET @errorType = NULL; SET @errorId = NULL;
SET @errorTitle = NULL; SET @errorUserMessage = NULL;
DECLARE @procName NVARCHAR(128) = COALESCE(@callerProcName, OBJECT_NAME(@@PROCID));

BEGIN TRY

IF (@kennelId IS NULL)
BEGIN
    SET @errorId = NEWID(); SET @errorCode = 1901; SET @errorType = 2;
    SET @errorTitle = 'Missing kennel'; SET @errorUserMessage = 'A kennel must be specified.';
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Null kennelId', 'kennelId is required', @procName, @userId);
    RETURN;
END

DECLARE @messageType INT = HC6.KennelThreadMessageType(@kennelThread);
IF (@messageType IS NULL
    OR (@messageType <> 0 AND HC6.UserInKennelMismanagement(@userId, @kennelId) = 0))
BEGIN
    SET @errorId = NEWID(); SET @errorCode = 1913; SET @errorType = 13;
    SET @errorTitle = 'Not available';
    SET @errorUserMessage = 'This chat is only for the kennel''s mismanagement.';
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Not in kennel mismanagement',
            CONCAT('kennelId=', CAST(@kennelId AS VARCHAR(40)), ' kennelThread=', @kennelThread),
            @procName, @userId);
    RETURN;
END

-- Opening the chat turns the kennel bell on (James, 2026-10-11, E9.F1.S30)
-- — only where the hasher already has a HasherKennelMap row and never chose
-- a setting (0). An explicit Off (2), Silver Bell (3) or On before the run
-- (4) is theirs and is never overridden; a visitor with no row is left
-- alone (posting creates the row — see hcapp_sendKennelMessage). The full
-- fetch is the open; a delta fetch is the same chat already open, and the
-- web polls this SP, so it is not repeated there. The bell is the KENNEL
-- bell: it also enables that kennel's RSVP and check-in reminders.
IF (@sinceSequenceCount IS NULL)
    UPDATE HC.HasherKennelMap SET KennelNotificationPreference = 1
     WHERE UserId = @userId AND KennelId = @kennelId
       AND removed = 0 AND KennelNotificationPreference = 0;

DECLARE @mayModerate SMALLINT;
EXEC HC6.nonApi_mayModerateChat @userId = @userId, @kennelId = @kennelId, @allowed = @mayModerate OUTPUT;

SELECT
    UPPER(msg.id)                                                    AS id,
    'text'                                                           AS type,
    msg.MessageContent                                               AS text,
    msg.PublicKennelId                                               AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)  AS createdAt,
    UPPER(h.PublicHasherId)                                          AS authorId,
    h.DisplayName                                                    AS authorFirstName,
    h.Photo                                                          AS authorImageUrl,
    msg.MessageSequenceCount                                         AS sequenceCount,
    msg.MessageKind                                          AS messageKind,
    CAST(CASE WHEN msg.UserId = @userId OR @mayModerate = 1 THEN 1 ELSE 0 END AS SMALLINT) AS canDelete,
    UPPER(msg.ReplyToMessageId)                                      AS replyToMessageId,
    CASE WHEN rp.id IS NULL OR rp.Removed = 1 THEN NULL ELSE LEFT(rp.MessageContent, 200) END AS replyToText,
    rp.MessageKind                                                   AS replyToKind,
    rh.DisplayName                                                   AS replyToAuthor,
    CAST(CASE WHEN rp.id IS NOT NULL AND rp.Removed = 1 THEN 1 ELSE 0 END AS SMALLINT) AS replyToRemoved,
    msg.ReactionsJson                                                AS reactions
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
-- The quoted message and its author, for replies (E9.F1.S21); a deleted
-- original quotes as nothing (replyToRemoved = 1) rather than its text.
LEFT JOIN HC.EventMessage rp ON rp.id = msg.ReplyToMessageId
LEFT JOIN HC.Hasher rh ON rh.id = rp.UserId
WHERE msg.KennelId = @kennelId
  AND msg.EventId IS NULL
  AND msg.MessageType = @messageType
  AND msg.Removed = 0
  AND h.Removed = 0
  -- Messages from a hasher the reader has blocked are hidden (E9.F1.S16).
  AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = msg.UserId AND blk.Ignore = 1)
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount > @sinceSequenceCount)
ORDER BY msg.createdAt DESC;

SELECT UPPER(msg.id) AS removedId
FROM HC.EventMessage msg
WHERE msg.KennelId = @kennelId AND msg.EventId IS NULL AND msg.MessageType = @messageType
  AND msg.Removed = 1;

-- Reactions on messages the caller ALREADY holds (E9.F1.S22): a reaction
-- changes an OLD row, and the delta above is by sequence count, so these
-- come as their own rowset — followed by the server time to pass back as
-- @reactionsSince. Both are last, so an older client's rowset positions
-- are what they were. Empty (never absent) when nothing changed.
SELECT UPPER(msg.id) AS id, msg.ReactionsJson AS reactions
FROM HC.EventMessage msg
WHERE msg.KennelId = @kennelId AND msg.EventId IS NULL AND msg.MessageType = @messageType
  AND msg.Removed = 0
  AND @reactionsSince IS NOT NULL
  AND msg.ReactionsUpdatedAt > @reactionsSince
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount <= @sinceSequenceCount);
SELECT SYSDATETIMEOFFSET() AS reactionsAsOf;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcVersion, 'Unhandled error in getKennelMessages',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
