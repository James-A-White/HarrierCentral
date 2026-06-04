-- =====================================================================
-- Run-once migration: add IsMobile column to HC.Device
--
-- IsMobile: 1 = mobile app device (hcapp_ path), 0 = browser/portal device
--   (hcportal_ path).
--
-- IMPORTANT — TRIGGER NOTICE:
--   HC.Device is a synced table and has an updatedAt trigger.
--   Although adding a NOT NULL column with a DEFAULT is a metadata-only
--   operation in SQL Server (existing rows are not physically rewritten,
--   so the trigger does not fire), you should still follow the project
--   convention:
--     1. DISABLE TRIGGER [dbo].[trg_Device_UpdatedAt] ON [HC].[Device]
--     2. Run this script
--     3. ENABLE  TRIGGER [dbo].[trg_Device_UpdatedAt] ON [HC].[Device]
--
-- Existing rows (created before this migration) will default to 0
-- (browser). Mobile rows will be corrected to 1 the next time
-- hcapp_authorizeDevice runs for that device.
--
-- After executing, move this file to archive/.
-- =====================================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'Device' AND COLUMN_NAME = 'IsMobile'
)
BEGIN
    ALTER TABLE [HC].[Device]
    ADD [IsMobile] SMALLINT NOT NULL
        CONSTRAINT [DF_Device_IsMobile] DEFAULT 0;
    PRINT 'HC.Device.IsMobile added.';
END
ELSE
BEGIN
    PRINT 'HC.Device.IsMobile already exists — skipped.';
END
