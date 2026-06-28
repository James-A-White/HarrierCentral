-- =====================================================================
-- Run-once migration: add RegionId + CityId to HC.Event
-- Date: 2026-06-28
-- Purpose: Store per-run Region and City defaults (for the cascading
--          Country -> Region -> City selector in the run editor).
--          HC.Event already has CountryId; this completes the hierarchy.
--
-- HC.Event is a mobile-synced table. Adding NULLABLE columns with no
-- default is a metadata-only operation in SQL Server and does NOT touch
-- existing rows, so the updatedAt trigger would not fire anyway — but we
-- disable it during the ALTER as belt-and-suspenders, per the project
-- rule (never ALTER a synced table with the updatedAt trigger live).
--
-- Columns are NULLABLE with no FK, matching the existing CountryId column
-- on HC.Event (which also has no FK constraint).
--
-- This is a run-once script; it lives in archive/ so the deploy globs
-- (non-recursive over db/hc6/portal/*.sql) never re-run it.
-- =====================================================================

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- 1. Disable the updatedAt-stamping trigger so the ALTER can't cascade a
--    bogus updatedAt onto every row (forcing a full re-sync to all clients).
ALTER TABLE [HC].[Event] DISABLE TRIGGER [trgUpdateModifiedOnDateForEvent];

-- 2. Add the nullable columns (metadata-only).
IF COL_LENGTH('HC.Event', 'RegionId') IS NULL
    ALTER TABLE [HC].[Event] ADD [RegionId] [uniqueidentifier] NULL;

IF COL_LENGTH('HC.Event', 'CityId') IS NULL
    ALTER TABLE [HC].[Event] ADD [CityId] [uniqueidentifier] NULL;

-- 3. Re-enable the trigger.
ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgUpdateModifiedOnDateForEvent];

COMMIT TRANSACTION;
GO
