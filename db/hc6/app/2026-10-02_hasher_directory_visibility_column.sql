-- =====================================================================
-- RUN-ONCE — James runs this (CLAUDE.md: ALTER on a synced table).
-- E9.F1.S26 hasher search: who may find this hasher in search.
--
-- A NEW nullable column, not the old IncludeInGlobalHashDirectory (James,
-- 2026-10-02): every hasher starts as NULL = "not asked", with no reset
-- UPDATE, so no row is stamped and no phone re-downloads the hasher table.
-- The old flag stays as it is and drives nothing.
--
--   NULL  not asked yet (the app shows the question)
--   0     nobody
--   1     people I have run with (both attended the same run)
--   2     members of a kennel I am a member of
--   3     anyone on Harrier Central
--   +16   may also be found by first / last name
--
-- NOT synced to any phone: the column is added to no sync rowset; the app
-- asks the server at launch whether its own hasher has answered.
--
-- Writing it must never stamp the row (James, 2026-10-02). Checked against
-- the live triggers on 2026-10-02: none stamps updatedAt for this column —
-- trgUpdateModifiedOnDateForNames fires only for the name/photo columns,
-- trgUpdateModifiedOnDateForHasher only re-biases an updatedAt the caller
-- set, and the other five are gated on their own columns (trgSafeDelete is
-- INSTEAD OF DELETE). So the rule lives in the WRITER: the SP that saves
-- the answer updates DirectoryVisibility alone and never sets updatedAt,
-- and DirectoryVisibility must not be added to any trigger's UPDATE() list.
--
-- The UpdatedAt triggers are disabled around the ALTER so no row is stamped
-- (a nullable column with no default should not touch rows; this is the
-- belt to that brace).
-- Afterwards: archive this file to db/hc6/app/archive/.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasher ON HC.Hasher;
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForNames  ON HC.Hasher;

IF COL_LENGTH('HC.Hasher', 'DirectoryVisibility') IS NULL
    ALTER TABLE HC.Hasher ADD DirectoryVisibility SMALLINT NULL;

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasher ON HC.Hasher;
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForNames  ON HC.Hasher;
COMMIT TRANSACTION;

SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Hasher');  -- all 0
SELECT COL_LENGTH('HC.Hasher', 'DirectoryVisibility') AS bytes;                      -- 2
