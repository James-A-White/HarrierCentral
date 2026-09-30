CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelMessages]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @kennelId           UNIQUEIDENTIFIER = NULL,
    @sinceSequenceCount INT              = NULL,
    @reactionsSince     DATETIMEOFFSET(7) = NULL
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

BEGIN TRY

IF (@kennelId IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Null kennelId', 'kennelId is required', @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1901 AS errorCode,
           'Missing kennel' AS errorTitle, 'A kennel must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

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
  AND msg.Removed = 0
  AND h.Removed = 0
  -- Messages from a hasher the reader has blocked are hidden (E9.F1.S16).
  AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = msg.UserId AND blk.Ignore = 1)
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount > @sinceSequenceCount)
ORDER BY msg.createdAt DESC;

SELECT UPPER(msg.id) AS removedId
FROM HC.EventMessage msg
WHERE msg.KennelId = @kennelId AND msg.EventId IS NULL AND msg.Removed = 1;

-- Reactions on messages the caller ALREADY holds (E9.F1.S22): a reaction
-- changes an OLD row, and the delta above is by sequence count, so these
-- come as their own rowset — followed by the server time to pass back as
-- @reactionsSince. Both are last, so an older client's rowset positions
-- are what they were. Empty (never absent) when nothing changed.
SELECT UPPER(msg.id) AS id, msg.ReactionsJson AS reactions
FROM HC.EventMessage msg
WHERE msg.KennelId = @kennelId AND msg.EventId IS NULL
  AND msg.Removed = 0
  AND @reactionsSince IS NOT NULL
  AND msg.ReactionsUpdatedAt > @reactionsSince
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount <= @sinceSequenceCount);
SELECT SYSDATETIMEOFFSET() AS reactionsAsOf;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getKennelMessages',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
