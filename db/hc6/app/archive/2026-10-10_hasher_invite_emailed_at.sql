-- =====================================================================
-- Run-once (2026-10-10, James): HC.Hasher.InviteEmailedAt — when this
-- hasher was last emailed their invite code by a kennel's "Email invite
-- codes" (E2.F2.S6). The send skips anyone invited in the last 7 days.
-- On HC.Hasher, not HC.HasherKennelMap: the HKM updatedAt trigger stamps
-- every update and would re-sync the row to phones; the Hasher triggers
-- fire only on updatedAt / name / photo / removed changes.
-- Synced table: its triggers are disabled around the ALTER
-- (CLAUDE.md), so no row is restamped. Idempotent. Archive after running.
-- =====================================================================
SET XACT_ABORT ON;
IF COL_LENGTH('HC.Hasher', 'InviteEmailedAt') IS NULL
BEGIN
    -- All four HC.Hasher triggers were enabled on 2026-10-10, so ALL restores
    -- exactly that state (abort if any is already disabled, rather than enable it).
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Hasher') AND is_disabled = 1)
        THROW 50000, 'An HC.Hasher trigger is already disabled; re-enabling ALL would change that. Stopping.', 1;
    DISABLE TRIGGER ALL ON HC.Hasher;
    ALTER TABLE HC.Hasher ADD InviteEmailedAt DATETIMEOFFSET(7) NULL;
    ENABLE TRIGGER ALL ON HC.Hasher;
END
SELECT COL_LENGTH('HC.Hasher', 'InviteEmailedAt') AS InviteEmailedAtBytes,
       (SELECT COUNT(*) FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Hasher') AND is_disabled = 1) AS disabledTriggers;
