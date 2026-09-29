-- =====================================================================
-- RUN-ONCE: Direct messages (E9.F1.S7/S18/S19, James 2026-09-29)
-- docs/chat_direct_messages_plan.md
--
-- HC.HasherFriendMap carries the friendship, the request and the block.
-- Two columns it lacks: the thread the pair talks in (both direction rows
-- share it) and a Removed flag for "unfriended by this side". NOT a synced
-- table, no updatedAt trigger: the ALTER stamps nothing.
--
-- The three-way preference needs NO change: it is two bits of
-- HC.Hasher.Preferences (0x4000|0x8000), and 0 = friends only.
--
-- Idempotent. Run BEFORE the SPs. Archive to db/hc6/app/archive/ after.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('HC.HasherFriendMap', 'ThreadId') IS NULL
    ALTER TABLE HC.HasherFriendMap ADD ThreadId UNIQUEIDENTIFIER NULL;

IF COL_LENGTH('HC.HasherFriendMap', 'Removed') IS NULL
    ALTER TABLE HC.HasherFriendMap
        ADD Removed SMALLINT NOT NULL CONSTRAINT DF_HasherFriendMap_Removed DEFAULT (0);

-- A column added above cannot be named again in the SAME batch (the batch
-- is compiled before the ALTER runs), so the indexes are their own batch.
-- The transaction spans both: sqlcmd keeps one session across GO.
GO

-- The thread readers and the unread function look rows up by ThreadId.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HasherFriendMap_ThreadId' AND object_id = OBJECT_ID('HC.HasherFriendMap'))
    CREATE NONCLUSTERED INDEX IX_HasherFriendMap_ThreadId ON HC.HasherFriendMap (ThreadId) INCLUDE (UserId, Friend_UserId, Removed, Ignore, FriendSince) WHERE ThreadId IS NOT NULL;

-- DM messages and their read marks are found by ThreadId as well.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EventMessage_ThreadId' AND object_id = OBJECT_ID('HC.EventMessage'))
    CREATE NONCLUSTERED INDEX IX_EventMessage_ThreadId ON HC.EventMessage (ThreadId, MessageSequenceCount) INCLUDE (UserId, Removed, createdAt) WHERE ThreadId IS NOT NULL;

COMMIT TRANSACTION;
GO

SELECT COL_LENGTH('HC.HasherFriendMap', 'ThreadId') AS threadIdCol, COL_LENGTH('HC.HasherFriendMap', 'Removed') AS removedCol,
       (SELECT COUNT(*) FROM sys.indexes WHERE name IN ('IX_HasherFriendMap_ThreadId', 'IX_EventMessage_ThreadId')) AS indexes;
