-- =====================================================================
-- Run-once: chat replies and emoji reactions (E9.F1.S21 / S22, James
-- 2026-09-30). Three nullable columns on HC.EventMessage — no new table:
--   ReplyToMessageId   the message this one quotes (same thread), or NULL
--   ReactionsJson      {"beer":["<PublicHasherId>",...],"thumbs":[...]}
--                      by code, never by glyph: in this database's
--                      collation an emoji compares EQUAL to '' (memory
--                      sql-collation-emoji-blank), so a glyph could never
--                      be a key or a WHERE. Maintained only by
--                      HC6.nonApi_reactToChatMessage under UPDLOCK.
--   ReactionsUpdatedAt when the JSON last changed — the readers' watermark
--                      for "reactions on messages you already have", since
--                      a reaction changes an OLD row and the delta fetch
--                      is by MessageSequenceCount.
-- HC.EventMessage is NOT a synced table (no phone holds it), so the
-- ADD COLUMN needs no trigger dance; trgEventMessageActivityCount ignores
-- an UPDATE that touches neither Removed nor EventId.
-- After executing, move this file to archive/.
-- =====================================================================
ALTER TABLE HC.EventMessage ADD
    ReplyToMessageId   UNIQUEIDENTIFIER  NULL,
    ReactionsJson      NVARCHAR(MAX)     NULL,
    ReactionsUpdatedAt DATETIMEOFFSET(7) NULL;
GO
