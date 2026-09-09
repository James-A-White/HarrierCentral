-- Run-once migration: add soft-delete column to HC.KennelPhotos
-- Safe to run more than once (checks for column existence first).
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'HC.KennelPhotos')
      AND name = N'DeletedAt'
)
BEGIN
    ALTER TABLE [HC].[KennelPhotos]
        ADD [DeletedAt] DATETIME2 NULL;
END
