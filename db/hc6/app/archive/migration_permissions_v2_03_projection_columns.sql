-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions V2, Phase 2a: projection columns
-- =====================================================================
-- Adds the compiled-JSON projection columns the client reads.
--   • HC.ServerStatus: global matrix JSON + watermark (singleton, NOT synced → plain ALTER).
--   • HC.Kennel: per-kennel override JSON (synced table → UpdatedAt trigger MUST be
--     disabled around the ALTER, per project rule, to avoid full re-replication).
-- Additive, nullable columns. HC5-safe: no SELECT * / positional INSERT on either
-- table (verified); every reader uses explicit column lists.
--
-- ⚠️  RUN MANUALLY, ONCE. Not picked up by deploy_hc6.sh. Archive after running.
-- =====================================================================
SET XACT_ABORT ON;
GO

-- 1. ServerStatus — global matrix JSON + high-water mark (plain ALTER; not synced).
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.ServerStatus') AND name = 'PermissionMatrixJson')
    ALTER TABLE [HC].[ServerStatus] ADD [PermissionMatrixJson] NVARCHAR(MAX) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.ServerStatus') AND name = 'PermissionMatrixUpdatedAt')
    ALTER TABLE [HC].[ServerStatus] ADD [PermissionMatrixUpdatedAt] DATETIMEOFFSET(7) NULL;
GO

-- 2. HC.Kennel — per-kennel override JSON (synced table → trigger-disable dance).
DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.Kennel') AND name = 'PermissionOverrideJson')
    ALTER TABLE [HC].[Kennel] ADD [PermissionOverrideJson] NVARCHAR(MAX) NULL;
GO
ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
GO
