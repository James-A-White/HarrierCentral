-- =====================================================================
-- Run-once migration: HC.ClientErrorLog — add AppVersion / BuildNumber
-- Date: 2026-09-09
-- Why: a client session log carried no record of the build that wrote it,
--      so errors could not be attributed to a release or confirmed gone.
-- Safe: HC.ClientErrorLog is NOT a synced table and has no UpdatedAt
--       trigger, so ADD COLUMN stamps nothing and triggers no re-sync.
-- After running: move this file to db/hc6/app/archive/ (deploy globs
--       only pick up HC6.*.StoredProcedure.sql, so it will not re-run,
--       but the archive convention still applies).
-- =====================================================================
IF COL_LENGTH('HC.ClientErrorLog', 'AppVersion') IS NULL
    ALTER TABLE HC.ClientErrorLog ADD AppVersion NVARCHAR(25) NULL;
GO
IF COL_LENGTH('HC.ClientErrorLog', 'BuildNumber') IS NULL
    ALTER TABLE HC.ClientErrorLog ADD BuildNumber NVARCHAR(25) NULL;
GO
