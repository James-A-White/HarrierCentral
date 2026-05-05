-- =====================================================================
-- Run-once migration: add PageLayoutJson column to HC.KennelWebsite
-- Archive this file after executing.
-- Created: 2026-05-05
-- =====================================================================
ALTER TABLE [HC].[KennelWebsite]
    ADD [PageLayoutJson] NVARCHAR(MAX) NULL;
GO
