-- =====================================================================
-- Run-once migration: add HC.Kennel.TrailTypesConfigJson
-- Feature: PackTrack trail types (declare + filter by trail type)
-- Date: 2026-06-26
--
-- HC.Kennel participates in the mobile sync. Its updatedAt-stamping
-- trigger (trgUpdateModifiedOnDateForKennels) would restamp every row on
-- an ALTER, forcing an unnecessary full re-sync to every client. Disable
-- it around the column add, then re-enable. (A nullable NVARCHAR add is
-- metadata-only so the trigger shouldn't fire anyway — we follow the
-- prescribed procedure regardless.)
--
-- Idempotent: safe to re-run; the column is only added if missing.
-- Mirrors the sibling config column TrailSymbolsConfigJson NVARCHAR(4000).
-- Statements are GO-separated so the DDL and control-of-flow don't share
-- a batch.
-- =====================================================================
SET XACT_ABORT ON;
GO

DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HC.Kennel') AND name = 'TrailTypesConfigJson'
)
    ALTER TABLE [HC].[Kennel] ADD [TrailTypesConfigJson] NVARCHAR(4000) NULL;
GO

ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO
