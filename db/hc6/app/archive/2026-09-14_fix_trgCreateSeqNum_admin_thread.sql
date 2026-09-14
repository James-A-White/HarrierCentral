-- =====================================================================
-- Run-once: make HC.trgCreateSeqNum number the admin channel too.
--
-- WHY
--   The trigger numbers messages per thread, where a thread is
--   COALESCE(EventId, KennelId). The Harrier Central admin channel is the
--   third kind of thread and has BOTH keys NULL, so its thread key is NULL
--   — and the trigger's join is
--
--       ON a.threadId = COALESCE(em.eventId, em.KennelId)
--
--   which is NULL = NULL for those rows, and therefore never true. No row
--   matched, so every admin message would have kept the column default of
--   0 for ever.
--
--   That fails silently and in three places at once: the unread test is
--   `MessageSequenceCount > @lastRead`, so 0 > 0 means the badge NEVER
--   lights; the delta fetch is `> @sinceSequenceCount`, so an incremental
--   read returns NOTHING; and the read receipt stores 0. The room would
--   have looked like it worked on a full load and quietly failed at
--   everything else.
--
-- THE FIX
--   The join becomes NULL-safe via EXISTS/INTERSECT — T-SQL's way of saying
--   "equal, and NULL equals NULL" — rather than a sentinel GUID, which
--   CLAUDE.md rightly calls a smell.
--
--   The thread key also gains MessageType, because James wants a room per
--   ROLE next (RAs, Hash Flashes, ...) and every one of those is global:
--   EventId and KennelId both NULL, exactly like this one. Keyed on the NULL
--   alone, every global room would share ONE numbering sequence and each
--   room's badge would count the others' messages. MessageType is what tells
--   them apart — 1 is super admins — so it belongs in the key. It is 0 on
--   all 1,227 event and kennel rows, so their numbering is unchanged.
--
--   ⚠ This makes MessageType the room discriminator for global rooms. It
--   must stay 0 for event and kennel chat; giving an event message a
--   non-zero MessageType would split that run's thread in two.
--
-- SAFETY
--   * Zero existing rows have both keys NULL (verified 2026-09-14: 1,226
--     event + 1 kennel), so no stored message changes number.
--   * HC.EventMessage is in NO sync SP, so there is no re-sync to trigger.
--   * A CREATE OR ALTER TRIGGER writes no rows; only the definition changes.
--   * trgEventMessageActivityCount filters `WHERE EventId IS NOT NULL`, so
--     it already ignores admin rows.
--
-- Author: Harrier Central
-- Created: 2026-09-14
-- =====================================================================

CREATE OR ALTER TRIGGER [HC].[trgCreateSeqNum]
   ON  [HC].[EventMessage]
   AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update only rows from the same thread(s) as the inserted messages.
    -- Thread key = eventId for run chats, KennelId for kennel chats, and
    -- (thread key, MessageType) for a global room such as the admin channel.
    ;WITH affected AS (
        SELECT DISTINCT COALESCE(eventId, KennelId) AS threadId, MessageType
        FROM inserted
    ),
    cte AS (
        SELECT
            em.id,
            -- Thread = the event, or the kennel, or — when neither is set —
            -- the global room named by MessageType.
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(em.eventId, em.KennelId), em.MessageType
                ORDER BY em.createdAt ASC, em.id
            ) AS RowNum
        FROM HC.EventMessage em
        INNER JOIN affected a
            -- NULL-safe equality. Plain `=` is never true when both sides are
            -- NULL, which silently excluded the admin thread. INTERSECT
            -- compares NULL to NULL as equal.
            ON EXISTS (
                SELECT a.threadId, a.MessageType
                INTERSECT
                SELECT COALESCE(em.eventId, em.KennelId), em.MessageType
            )
    )
    UPDATE em
    SET em.MessageSequenceCount = cte.RowNum
    FROM HC.EventMessage em
    INNER JOIN cte ON cte.id = em.id;
END
GO
