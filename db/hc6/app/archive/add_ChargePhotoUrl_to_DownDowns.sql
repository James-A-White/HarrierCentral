-- =====================================================================
-- Run-once migration: add ChargePhotoUrl to HC.DownDowns
-- Created: 2026-06-09
--
-- IMPORTANT: HC.DownDowns is NOT a mobile sync table (not in
-- EnumDataTables), so there is no UpdatedAt trigger to disable.
-- Safe to run directly.
--
-- After running, archive this file:
--   mv db/hc6/app/add_ChargePhotoUrl_to_DownDowns.sql db/hc6/app/archive/
-- =====================================================================

ALTER TABLE [HC].[DownDowns]
    ADD [ChargePhotoUrl] NVARCHAR(MAX) NULL;
