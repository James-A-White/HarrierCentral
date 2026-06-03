-- =====================================================================
-- Run-once migration: add FcmTokenCreatedAt and FcmTokenDeleted to HC.Device
-- Move to archive/ after executing.
-- =====================================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'Device' AND COLUMN_NAME = 'FcmTokenCreatedAt'
)
BEGIN
    ALTER TABLE [HC].[Device] ADD [FcmTokenCreatedAt] DATETIMEOFFSET(7) NULL;
    PRINT 'HC.Device.FcmTokenCreatedAt added.';
END
ELSE
    PRINT 'HC.Device.FcmTokenCreatedAt already exists — skipped.';

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'Device' AND COLUMN_NAME = 'FcmTokenDeleted'
)
BEGIN
    ALTER TABLE [HC].[Device] ADD [FcmTokenDeleted] DATETIMEOFFSET(7) NULL;
    PRINT 'HC.Device.FcmTokenDeleted added.';
END
ELSE
    PRINT 'HC.Device.FcmTokenDeleted already exists — skipped.';
