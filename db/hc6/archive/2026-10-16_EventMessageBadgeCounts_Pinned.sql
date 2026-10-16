-- =====================================================================
-- Run-once (2026-10-16, E9.F1.S33). Idempotent.
-- HC.EventMessageBadgeCounts.Pinned: a thread's pin, for a thread whose pin
-- has no other home — the kennel's private Mismanagement chat (MessageType
-- 100). The general kennel chat keeps HasherKennelMap.Pinned, runs
-- HasherEventMap.Pinned, rooms HC.Hasher.Unpinned*Rooms, DMs
-- HasherFriendMap.Pinned. NULL = never chosen = unpinned (James: start
-- unpinned; each kennel thread pinned on its own).
-- The table is not synced to phones and has no triggers, so the ALTER
-- re-stamps nothing.
-- =====================================================================
SET NOCOUNT ON;
IF COL_LENGTH('HC.EventMessageBadgeCounts', 'Pinned') IS NULL
    ALTER TABLE HC.EventMessageBadgeCounts ADD Pinned SMALLINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE major_id = OBJECT_ID('HC.EventMessageBadgeCounts')
                 AND minor_id = COLUMNPROPERTY(OBJECT_ID('HC.EventMessageBadgeCounts'), 'Pinned', 'ColumnId')
                 AND name = 'MS_Description')
    EXEC sp_addextendedproperty @name = N'MS_Description',
        @value = N'The thread''s pin where it has no other home: the kennel Mismanagement chat (MessageType 100, E9.F1.S33). NULL = never chosen = unpinned. Other threads pin on HasherKennelMap / HasherEventMap / HasherFriendMap.Pinned and HC.Hasher.Unpinned*Rooms.',
        @level0type = N'SCHEMA', @level0name = N'HC',
        @level1type = N'TABLE',  @level1name = N'EventMessageBadgeCounts',
        @level2type = N'COLUMN', @level2name = N'Pinned';
GO
SELECT COL_LENGTH('HC.EventMessageBadgeCounts', 'Pinned') AS pinnedBytes;
