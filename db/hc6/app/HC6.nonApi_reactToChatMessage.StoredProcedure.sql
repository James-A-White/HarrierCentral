CREATE OR ALTER PROCEDURE [HC6].[nonApi_reactToChatMessage]
    @userId      UNIQUEIDENTIFIER,
    @messageId   UNIQUEIDENTIFIER,
    @reaction    NVARCHAR(20),
    @on          SMALLINT,
    @outcome     SMALLINT          OUTPUT,   -- 1 ok, 2 no such message, 3 not allowed, 4 unknown reaction
    @reactions   NVARCHAR(MAX)     OUTPUT,   -- the message's ReactionsJson after the change
    @eventId     UNIQUEIDENTIFIER  OUTPUT,   -- the thread, for the caller's push detail
    @kennelId    UNIQUEIDENTIFIER  OUTPUT,
    @threadId    UNIQUEIDENTIFIER  OUTPUT,
    @messageType INT               OUTPUT,
    @authorId    UNIQUEIDENTIFIER  OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_reactToChatMessage
-- Description: Adds or removes ONE reaction by ONE hasher on ONE message
--   (E9.F1.S22, James 2026-09-30). The one place HC.EventMessage.
--   ReactionsJson is written; hcapp_ / hcportal_ / publicWeb_ wrappers
--   authenticate and reply, and this decides.
--
--   Storage is a JSON column, not a table (James: "JSON column please"):
--   {"beer":["<PublicHasherId>",...],"thumbs":[...]} keyed by the
--   catalog's ASCII code (an emoji equals '' in this collation), holding
--   PUBLIC hasher ids because that is what a chat message carries as its
--   authorId, so a client can tell "mine" without another lookup. Read-
--   modify-write under UPDLOCK, HOLDLOCK on the row: two people reacting
--   to the same message serialise on it, which at hash-chat volume is
--   nothing. ReactionsUpdatedAt is stamped so the readers can hand back
--   reactions on messages a client already holds.
--
--   Who may react: anyone who may READ the message — a room by
--   HC6.UserMayEnterChatRoom, a DM by holding a HasherFriendMap row for
--   the thread, a run or kennel chat as its reader allows (no gate) —
--   except a message from a hasher the caller has blocked, which the
--   reader would never have shown. A deleted message cannot be reacted to.
-- Parameters: @userId (internal id), @messageId, @reaction (catalog code),
--   @on 1 add / 0 remove.
-- Returns: nothing; the OUTPUTs above.
-- Author: Harrier Central
-- Created: 2026-09-30
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @outcome = 2; SET @reactions = NULL;
SET @eventId = NULL; SET @kennelId = NULL; SET @threadId = NULL; SET @messageType = NULL; SET @authorId = NULL;

IF (@userId IS NULL OR @messageId IS NULL) RETURN;

IF NOT EXISTS (SELECT 1 FROM HC6.ChatReactionCatalog() c WHERE c.Code = @reaction)
BEGIN
    SET @outcome = 4;
    RETURN;
END

DECLARE @removed SMALLINT;
SELECT @eventId = m.EventId, @kennelId = m.KennelId, @threadId = m.ThreadId,
       @messageType = m.MessageType, @authorId = m.UserId, @removed = m.Removed
FROM HC.EventMessage m WHERE m.id = @messageId;
IF (@authorId IS NULL OR @removed = 1) RETURN;   -- outcome 2

-- Same visibility as the readers.
DECLARE @allowed SMALLINT = 1;
IF (@threadId IS NOT NULL)
    SET @allowed = CASE WHEN EXISTS (SELECT 1 FROM HC.HasherFriendMap f
                                     WHERE f.UserId = @userId AND f.ThreadId = @threadId) THEN 1 ELSE 0 END;
ELSE IF (@eventId IS NULL AND @kennelId IS NULL)
    SET @allowed = HC6.UserMayEnterChatRoom(@userId, @messageType);
IF (@allowed = 1 AND EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                             WHERE blk.UserId = @userId AND blk.Friend_UserId = @authorId AND blk.Ignore = 1))
    SET @allowed = 0;
IF (@allowed = 0)
BEGIN
    SET @outcome = 3;
    RETURN;
END

DECLARE @who NVARCHAR(36);
SELECT @who = UPPER(CAST(h.PublicHasherId AS NVARCHAR(36))) FROM HC.Hasher h WHERE h.id = @userId;
IF (@who IS NULL) BEGIN SET @outcome = 3; RETURN; END

BEGIN TRANSACTION;

DECLARE @json NVARCHAR(MAX);
SELECT @json = m.ReactionsJson
FROM HC.EventMessage m WITH (UPDLOCK, HOLDLOCK)
WHERE m.id = @messageId;

-- The JSON as rows: one per (code, hasher). A malformed value — there
-- should never be one, but it is a text column — is treated as empty
-- rather than failing the tap.
DECLARE @t TABLE (Code NVARCHAR(20) NOT NULL, Who NVARCHAR(36) NOT NULL);
IF (@json IS NOT NULL AND ISJSON(@json) = 1)
    INSERT @t (Code, Who)
    SELECT o.[key], UPPER(a.[value])
    FROM OPENJSON(@json) o
    CROSS APPLY OPENJSON(o.[value]) a
    WHERE o.[type] = 4 AND a.[type] = 1;   -- key → array of strings only

DELETE FROM @t WHERE Code = @reaction AND Who = @who;
IF (@on = 1) INSERT @t (Code, Who) VALUES (@reaction, @who);

-- Rebuilt in catalog order, hand-assembled: the codes are ASCII words from
-- the catalog and the ids are GUIDs, so nothing needs escaping, and
-- FOR JSON cannot make a dynamic-key object.
SELECT @reactions = N'{' + STRING_AGG(x.Pair, N',') WITHIN GROUP (ORDER BY x.SortOrder) + N'}'
FROM (
    SELECT c.SortOrder,
           N'"' + c.Code + N'":[' + STRING_AGG(N'"' + t.Who + N'"', N',') + N']' AS Pair
    FROM @t t
    JOIN HC6.ChatReactionCatalog() c ON c.Code = t.Code
    GROUP BY c.Code, c.SortOrder
) x;

UPDATE HC.EventMessage
   SET ReactionsJson = @reactions,
       ReactionsUpdatedAt = SYSDATETIMEOFFSET()
 WHERE id = @messageId;

COMMIT TRANSACTION;
SET @outcome = 1;
GO
