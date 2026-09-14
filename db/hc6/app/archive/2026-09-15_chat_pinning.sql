-- =====================================================================
-- Run-once: pinned chats (E9.F1.S8).
--
-- ⚠ JAMES MUST RUN THIS BY HAND. Per CLAUDE.md, an ALTER on a synced table
--   is never run autonomously, and all three tables here are synced.
--
-- WHY THESE COLUMNS, ON THESE TABLES
--   Pin must survive a reload and follow the hasher between devices, so it
--   lives on the server — and on records that ALREADY sync, so it costs no
--   new synced table and no new sync rowset (James, 2026-09-14).
--
--     HasherEventMap.Pinned   a run's chat      two-state, default 0
--     HasherKennelMap.Pinned  a kennel's chat   THREE-state (see below)
--     Hasher.Unpinned*Rooms   the role rooms    mirrors of the grant fields
--
--   The room mirrors go on HC.Hasher, not HasherKennelMap, even though they
--   mirror HKM's bitfields: a room is GLOBAL while MismanagementRoles and
--   AppAccessFlags are per-kennel, and a hasher with 225 kennel rows has no
--   answer to "which row holds the pin". They mirror in SHAPE — same bit,
--   same meaning, read with the column the room catalog names — not in
--   location.
--
-- WHY "UNPINNED" AND NOT "PINNED"
--   Home kennel and every role room default to PINNED (James, 2026-09-14).
--   A bitfield of pins would start at 0 for everyone, meaning nothing
--   pinned — the exact opposite of the rule — and would need a write every
--   time anyone gained a role, from paths spread across seven schemas.
--   Storing the DEVIATIONS inverts that: 0 means "all my rooms pinned",
--   needs no backfill, and a room added to the catalog next year arrives
--   pinned for everyone eligible with nothing to remember.
--
--   HasherKennelMap.Pinned is NULLABLE for the same reason, as a tri-state
--   override: NULL = whatever this kennel defaults to (pinned if
--   IsHomeKennel), 0 = explicitly unpinned, 1 = explicitly pinned. Without
--   the NULL there is no way to say "I turned my home kennel off" that
--   survives, and no way to add a future auto-pin rule without a backfill.
--
--   HasherEventMap.Pinned needs only two states: a run NEVER auto-pins, and
--   a run pin never expires — "it would be strange to have the system
--   arbitrarily undo an action that a user took" (James, 2026-09-14).
--
-- NO HOUSEKEEPING ON ROLE CHANGE
--   Access is DERIVED by HC6.UserMayEnterChatRoom from live HasherKennelMap
--   rows, never read from a cached bitfield. So a stale pin bit for a role
--   someone no longer holds is inert — the room is not listed because access
--   says no — and if they hold that role again later their old preference is
--   correctly restored. Nothing has to be cleared when a role changes, which
--   matters because 77 objects across seven schemas (HC3, HC3W, HC4, HC5,
--   HC6, HC, HC_BACKUP) write those two bitfields, including legacy paths
--   and the Google Sheets import that we could not hook reliably.
--
-- TRIGGERS
--   Each ALTER is wrapped in DISABLE/ENABLE of that table's UpdatedAt
--   trigger. Leaving it on stamps every row, and the sync then pushes the
--   whole table to every client: 136,425 HEM rows, 16,265 HKM, 10,284
--   Hasher. The ENABLE is in the same batch as its ALTER so a failure
--   cannot leave a trigger off.
--
-- ORDER: run this BEFORE deploying the SPs that read the new columns —
--   SQL Server binds columns of an existing table at CREATE PROCEDURE time.
--
-- Author: Harrier Central
-- Created: 2026-09-15
-- =====================================================================

SET XACT_ABORT ON;

-- ---------------------------------------------------------------------
-- 1. Run chats. Two-state, default unpinned.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.HasherEventMap', 'Pinned') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
    ALTER TABLE HC.HasherEventMap
        ADD Pinned SMALLINT NOT NULL CONSTRAINT DF_HasherEventMap_Pinned DEFAULT (0);
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
END
GO

-- ---------------------------------------------------------------------
-- 2. Kennel chats. NULLABLE — the third state is "use the default", which
--    is pinned when IsHomeKennel and unpinned otherwise.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.HasherKennelMap', 'Pinned') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherKennelMap ON HC.HasherKennelMap;
    ALTER TABLE HC.HasherKennelMap ADD Pinned SMALLINT NULL;
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherKennelMap ON HC.HasherKennelMap;
END
GO

-- ---------------------------------------------------------------------
-- 3. The room mirrors. Both count DEVIATIONS: a set bit means "I turned
--    that room off", so 0 is the default of everything pinned.
--    HC.Hasher carries TWO UpdatedAt triggers; both must be off.
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.Hasher', 'UnpinnedMismanagementRooms') IS NULL
   OR COL_LENGTH('HC.Hasher', 'UnpinnedAppAccessRooms') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasher ON HC.Hasher;
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForNames  ON HC.Hasher;

    IF COL_LENGTH('HC.Hasher', 'UnpinnedMismanagementRooms') IS NULL
        ALTER TABLE HC.Hasher
            ADD UnpinnedMismanagementRooms INT NOT NULL
                CONSTRAINT DF_Hasher_UnpinnedMismanagementRooms DEFAULT (0);

    IF COL_LENGTH('HC.Hasher', 'UnpinnedAppAccessRooms') IS NULL
        ALTER TABLE HC.Hasher
            ADD UnpinnedAppAccessRooms INT NOT NULL
                CONSTRAINT DF_Hasher_UnpinnedAppAccessRooms DEFAULT (0);

    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasher ON HC.Hasher;
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForNames  ON HC.Hasher;
END
GO

-- ---------------------------------------------------------------------
-- 4. Verification. Every trigger must be back ON.
-- ---------------------------------------------------------------------
SELECT t.name AS TriggerName, t.is_disabled AS IsDisabled_MustBeZero
FROM sys.triggers t
WHERE t.name IN ('trgUpdateModifiedOnDateForHasherEventMap',
                 'trgUpdateModifiedOnDateForHasherKennelMap',
                 'trgUpdateModifiedOnDateForHasher',
                 'trgUpdateModifiedOnDateForNames');
GO
