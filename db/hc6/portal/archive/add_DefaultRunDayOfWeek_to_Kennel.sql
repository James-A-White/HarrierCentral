-- =====================================================================
-- Run-once migration: add HC.Kennel.DefaultRunDayOfWeek (SMALLINT)
-- Date: 2026-07-06
--
-- Retires the DefaultRunStartTime day-of-week hack: the kennel's default
-- run weekday was smuggled into the FRACTIONAL SECONDS of the TIME(7)
-- column (portal decoded it as millisecond ~/ 100 → 1..7 ISO weekday,
-- e.g. 16:00:00.4000000 = 16:00 on Thursday). This migration:
--   1. Adds a real DefaultRunDayOfWeek SMALLINT column (1=Mon .. 7=Sun).
--   2. Backfills it from the encoded fractional seconds (invalid → 1).
--   3. Normalises DefaultRunStartTime to a pure time-of-day (fraction
--      stripped) so the hack is fully gone.
--
-- HC.Kennel participates in the mobile sync. Its updatedAt-stamping
-- trigger (trgUpdateModifiedOnDateForKennels) must be DISABLED around
-- this migration — the backfill UPDATE touches every row and would
-- otherwise restamp updatedAt on all kennels, forcing a full kennel
-- re-sync to every client. Re-enable after.
--
-- The backfill deliberately does NOT touch updatedAt, so clients keep
-- their existing kennel rows (they don't need the new column — the
-- day-of-week is portal-only).
--
-- Idempotent: safe to re-run; the column is only added if missing and
-- the backfill only rewrites rows that still carry a fractional part.
-- Deploy order: run this FIRST, then deploy SPs (they reference the new
-- column), then the portal.
-- =====================================================================
SET XACT_ABORT ON;
GO

DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HC.Kennel') AND name = 'DefaultRunDayOfWeek'
)
    ALTER TABLE [HC].[Kennel] ADD [DefaultRunDayOfWeek] SMALLINT NULL;
GO

-- Backfill: decode weekday from the fractional seconds; strip the fraction
-- from the time. Only touches rows not yet migrated.
UPDATE k SET
    DefaultRunDayOfWeek = CASE
        WHEN DATEPART(MILLISECOND, k.DefaultRunStartTime) / 100 BETWEEN 1 AND 7
            THEN DATEPART(MILLISECOND, k.DefaultRunStartTime) / 100
        ELSE 1
    END,
    DefaultRunStartTime = CAST(CONVERT(varchar(8), k.DefaultRunStartTime, 108) AS TIME(7))
FROM HC.Kennel k
WHERE k.DefaultRunDayOfWeek IS NULL
   OR DATEPART(MILLISECOND, k.DefaultRunStartTime) <> 0;
GO

ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO

-- Verification
SELECT
    COUNT(*)                                                        AS TotalKennels,
    SUM(CASE WHEN DefaultRunDayOfWeek IS NULL THEN 1 ELSE 0 END)    AS StillNull,
    SUM(CASE WHEN DATEPART(MILLISECOND, DefaultRunStartTime) <> 0
             THEN 1 ELSE 0 END)                                     AS StillEncoded
FROM HC.Kennel;
GO
