CREATE OR ALTER PROCEDURE [HC6].[hcapp_getDirectMessages]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @threadId           UNIQUEIDENTIFIER = NULL,
    @sinceSequenceCount INT              = NULL,
    @reactionsSince     DATETIMEOFFSET(7) = NULL,
    @markRead           SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getDirectMessages
-- Description: Reads a direct-message thread (E9.F1.S7) in
--   hcapp_getRoomMessages' shape. The caller must hold a HasherFriendMap
--   row for the thread — ended (Removed) still reads, blocked hides the
--   other side's messages like every reader.
-- Returns:
--   Rowset 0: messages, newest first (+ messageKind, canDelete)
--   Rowset 1: { unreadCount, newestSequenceCount, canSend, otherPublicHasherId,
--               otherDisplayName, otherPhoto, muted }
--   Rowset 2: { removedId }
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 135, @param = NULL,
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

DECLARE @otherId UNIQUEIDENTIFIER, @mineRemoved SMALLINT, @mineIgnore SMALLINT, @minePref SMALLINT;
SELECT @otherId = f.Friend_UserId, @mineRemoved = f.Removed, @mineIgnore = f.Ignore, @minePref = f.FriendNotificationPreference
FROM HC.HasherFriendMap f WHERE f.UserId = @userId AND f.ThreadId = @threadId;

IF (@threadId IS NULL OR @otherId IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No such conversation',
            CONCAT('thread=', COALESCE(CAST(@threadId AS NVARCHAR(40)), 'null')), @procName, @userId);
    SELECT @errorId AS errorId, 3 AS errorType, 2015 AS errorCode,
           'Not found' AS errorTitle, 'That conversation could not be found.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY

DECLARE @mayModerate SMALLINT;
EXEC HC6.nonApi_mayModerateChat @userId = @userId, @allowed = @mayModerate OUTPUT;   -- a DM: SuperAdmin only

DECLARE @newestSeq INT = (SELECT MAX(em.MessageSequenceCount) FROM HC.EventMessage em WHERE em.ThreadId = @threadId AND em.Removed = 0);
DECLARE @lastRead INT = ISNULL((SELECT b.LastSequenceCount FROM HC.EventMessageBadgeCounts b
    WHERE b.UserId = @userId AND b.EventId IS NULL AND b.KennelId IS NULL AND b.ThreadId = @threadId AND b.MessageType = 0), 0);

SELECT
    UPPER(msg.id)                                                    AS id,
    'text'                                                           AS type,
    msg.MessageContent                                               AS text,
    UPPER(msg.ThreadId)                                              AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)  AS createdAt,
    UPPER(h.PublicHasherId)                                          AS authorId,
    h.DisplayName                                                    AS authorFirstName,
    h.Photo                                                          AS authorImageUrl,
    msg.MessageSequenceCount                                         AS sequenceCount,
    msg.MessageKind                                                  AS messageKind,
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
WHERE msg.ThreadId = @threadId
  AND msg.Removed = 0
  AND h.Removed = 0
  AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = msg.UserId AND blk.Ignore = 1)
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount > @sinceSequenceCount)
ORDER BY msg.createdAt DESC;

DECLARE @canSend SMALLINT = CASE WHEN @mineRemoved = 0 AND @mineIgnore = 0 AND EXISTS (
    SELECT 1 FROM HC.HasherFriendMap t WHERE t.UserId = @otherId AND t.Friend_UserId = @userId
      AND t.ThreadId = @threadId AND t.Removed = 0 AND t.Ignore = 0) THEN 1 ELSE 0 END;

SELECT
    (SELECT COUNT(*) FROM HC.EventMessage em
      WHERE em.ThreadId = @threadId AND em.Removed = 0 AND em.UserId <> @userId
        AND em.MessageSequenceCount > @lastRead
        AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                        WHERE blk.UserId = @userId AND blk.Friend_UserId = em.UserId AND blk.Ignore = 1)) AS unreadCount,
    ISNULL(@newestSeq, 0)                                    AS newestSequenceCount,
    @canSend                                                 AS canSend,
    UPPER(CAST(h.PublicHasherId AS NVARCHAR(40)))            AS otherPublicHasherId,
    h.DisplayName                                            AS otherDisplayName,
    h.Photo                                                  AS otherPhoto,
    CAST(CASE WHEN @minePref = 3 THEN 1 ELSE 0 END AS SMALLINT) AS muted
FROM HC.Hasher h WHERE h.id = @otherId;

IF (@markRead = 1 AND @newestSeq IS NOT NULL)
BEGIN
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @newestSeq)) AS Source (UserId, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.EventId IS NULL AND Target.KennelId IS NULL
        AND Target.ThreadId = @threadId AND Target.MessageType = 0)
    WHEN MATCHED THEN UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount, Target.LastReadAt = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, EventId, KennelId, ThreadId, MessageType, LastSequenceCount, LastReadAt)
        VALUES (Source.UserId, NULL, NULL, @threadId, 0, Source.LastSequenceCount, SYSDATETIMEOFFSET());
END

SELECT UPPER(msg.id) AS removedId FROM HC.EventMessage msg WHERE msg.ThreadId = @threadId AND msg.Removed = 1;

-- Reactions on messages the caller ALREADY holds (E9.F1.S22): a reaction
-- changes an OLD row, and the delta above is by sequence count, so these
-- come as their own rowset — followed by the server time to pass back as
-- @reactionsSince. Both are last, so an older client's rowset positions
-- are what they were. Empty (never absent) when nothing changed.
SELECT UPPER(msg.id) AS id, msg.ReactionsJson AS reactions
FROM HC.EventMessage msg
WHERE msg.ThreadId = @threadId
  AND msg.Removed = 0
  AND @reactionsSince IS NOT NULL
  AND msg.ReactionsUpdatedAt > @reactionsSince
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount <= @sinceSequenceCount);
SELECT SYSDATETIMEOFFSET() AS reactionsAsOf;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getDirectMessages', ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
