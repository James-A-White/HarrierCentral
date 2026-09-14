-- =====================================================================
-- Run-once: give chat ONE thread key that covers every kind of room —
-- including the ones not built yet.
--
-- Supersedes 2026-09-14_fix_trgCreateSeqNum_admin_thread.sql, which was
-- never run.
--
-- WHY NOW
--   Nothing about the admin channel has deployed, so this is the last
--   moment any of it is free. Three kinds of chat exist today and two more
--   are coming (James, 2026-09-14): a room per ROLE — RAs with RAs, Hash
--   Flashes with Hash Flashes — and one-to-one DMs between any two hashers.
--   DMs are explicitly NOT being built yet; the instruction is only that
--   the architecture must not prevent them.
--
--   It very nearly did, in one specific place.
--
-- THE FORECLOSURE
--   HC.EventMessageBadgeCounts keys a badge on (UserId, EventId, KennelId).
--   Every global room and every DM has BOTH those keys NULL, so a hasher
--   can only ever have ONE such row. As written, the admin channel's MERGE
--   would have created that row and claimed it. The first role room, and
--   every DM thread, would then have collided with it: one shared unread
--   count for every private conversation a person has.
--
--   There are 632 badge rows today — 616 event, 16 kennel, and ZERO with
--   both keys NULL. So the global space is empty and this costs nothing.
--   After the channel ships it would have meant migrating live badge rows
--   belonging to real conversations.
--
-- THE KEY
--   thread = COALESCE(EventId, KennelId, ThreadId)  +  MessageType
--
--     run chat     EventId set                      MessageType 0
--     kennel chat  KennelId set                     MessageType 0
--     global room  all three NULL                   MessageType names the room (1 = super admins)
--     DM (later)   ThreadId = the conversation      MessageType names the kind
--
--   MessageType is an existing INT and is 0 on all 1,227 stored rows, so
--   nothing already there changes meaning. It stays a small self-describing
--   enum rather than a well-known GUID, which would be the sentinel
--   CLAUDE.md rightly calls a smell.
--
--   ThreadId is RESERVED AND UNUSED by this change. Nothing reads or writes
--   it yet. It exists so that DMs are a feature, not a migration: adding it
--   here costs one metadata-only ALTER in a window already open, and folding
--   it into the thread key now means the sequence trigger never needs
--   touching again. Every row is NULL today, so COALESCE ignores it and
--   behaviour is identical.
--
-- SAFETY
--   * 0 rows have both keys NULL in either table, so nothing is renumbered
--     and no badge moves.
--   * NEITHER table is in any sync SP, and NEITHER has an UpdatedAt trigger,
--     so the usual disable-before-ALTER dance does not apply and no row is
--     stamped. (Verified 2026-09-14: EventMessage carries trgCreateSeqNum
--     and trgEventMessageActivityCount only; the badge table has none.)
--   * ALTER TABLE does not fire DML triggers.
--   * There is no unique index on the badge table's logical key — only the
--     PK on id — so widening the key rebuilds nothing.
--   * trgEventMessageActivityCount already filters `WHERE EventId IS NOT
--     NULL`, so it ignores every global and DM row.
--
-- ORDER: run this BEFORE deploying hcapp_sendAdminMessage /
--   hcapp_getAdminMessages. They read the new columns, and SQL Server binds
--   columns of an EXISTING table at CREATE time — a missing column is an
--   error then, not at runtime.
--
-- Author: Harrier Central
-- Created: 2026-09-14
-- =====================================================================

SET XACT_ABORT ON;

-- ---------------------------------------------------------------------
-- 1. The reserved thread key. Nullable, no default: metadata-only.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.EventMessage', 'ThreadId') IS NULL
    ALTER TABLE HC.EventMessage ADD ThreadId UNIQUEIDENTIFIER NULL;
GO

-- ---------------------------------------------------------------------
-- 2. The badge key gains the same two discriminators, so one hasher can
--    hold a separate unread count per room and, later, per conversation.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.EventMessageBadgeCounts', 'MessageType') IS NULL
    ALTER TABLE HC.EventMessageBadgeCounts
        ADD MessageType INT NOT NULL CONSTRAINT DF_EventMessageBadgeCounts_MessageType DEFAULT (0);
GO

IF COL_LENGTH('HC.EventMessageBadgeCounts', 'ThreadId') IS NULL
    ALTER TABLE HC.EventMessageBadgeCounts ADD ThreadId UNIQUEIDENTIFIER NULL;
GO

-- ---------------------------------------------------------------------
-- 2b. Participation, per hasher per room (James, 2026-09-14). THREE states,
--     not a mute boolean:
--
--       0  participate, with push notifications   (the default)
--       1  participate, no push — badges only
--       2  do not participate — the room is not even listed
--
--     This row is already the per-user, per-room record, so the preference
--     belongs on it rather than anywhere new. DEFAULT 0 means a room added
--     to the catalog later starts switched on for everyone eligible, which
--     is what makes a new room discoverable at all; someone who wants quiet
--     sets 1 or 2 and that choice survives, because the row persists.
--
--     State 2 hides the room from the list but NOT from the settings
--     console — otherwise opting out would be a one-way door with no way
--     back. hcapp_getChatRooms takes @includeOptedOut for exactly that.
--
--     ⚠ Honest limit: nothing pushes for a global room yet — the API shim's
--     notification switch has no case for room messages — so state 0 and
--     state 1 behave identically TODAY. The distinction is stored and
--     returned so the preference is already correct when push is built, and
--     so nobody has to re-answer the question later.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.EventMessageBadgeCounts', 'ParticipationState') IS NULL
    ALTER TABLE HC.EventMessageBadgeCounts
        ADD ParticipationState SMALLINT NOT NULL
            CONSTRAINT DF_EventMessageBadgeCounts_ParticipationState DEFAULT (0);
GO

-- ---------------------------------------------------------------------
-- 3. Number messages per thread, where "thread" now means all four kinds.
--
--    The bug this also fixes: the join was
--        ON a.threadId = COALESCE(em.eventId, em.KennelId)
--    which is NULL = NULL for any global room — never true. No row matched,
--    so every admin message would have kept the column default of 0 for
--    ever, silently killing the badge (`> @lastRead` is 0 > 0), the delta
--    fetch (`> @sinceSequenceCount`) and the read receipt at once. A full
--    load would have looked perfect.
-- ---------------------------------------------------------------------
CREATE OR ALTER TRIGGER [HC].[trgCreateSeqNum]
   ON  [HC].[EventMessage]
   AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update only rows from the same thread(s) as the inserted messages.
    ;WITH affected AS (
        SELECT DISTINCT COALESCE(eventId, KennelId, ThreadId) AS threadId, MessageType
        FROM inserted
    ),
    cte AS (
        SELECT
            em.id,
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(em.eventId, em.KennelId, em.ThreadId), em.MessageType
                ORDER BY em.createdAt ASC, em.id
            ) AS RowNum
        FROM HC.EventMessage em
        INNER JOIN affected a
            -- NULL-safe equality: a global room's thread key IS NULL, and
            -- plain `=` is never true when both sides are NULL. INTERSECT
            -- compares NULL to NULL as equal.
            ON EXISTS (
                SELECT a.threadId, a.MessageType
                INTERSECT
                SELECT COALESCE(em.eventId, em.KennelId, em.ThreadId), em.MessageType
            )
    )
    UPDATE em
    SET em.MessageSequenceCount = cte.RowNum
    FROM HC.EventMessage em
    INNER JOIN cte ON cte.id = em.id;
END
GO
