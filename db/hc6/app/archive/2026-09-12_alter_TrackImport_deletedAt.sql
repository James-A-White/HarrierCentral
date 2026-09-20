-- =====================================================================
-- Run-once: HC.TrackImport.DeletedAt (2026-09-12)
--   A hasher can clear an upload off the Import Tracks list. The row is
--   kept, not removed: it carries the BlobUrl, and the archives are being
--   kept deliberately for historic-run discovery — a hard DELETE would
--   orphan the blob with nothing left pointing at it.
--   HC.TrackImport is server-side only (no sync domain) and carries no
--   triggers, so this ALTER stamps nothing and forces no re-sync.
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

IF COL_LENGTH('HC.TrackImport', 'DeletedAt') IS NULL
BEGIN
    ALTER TABLE [HC].[TrackImport] ADD [DeletedAt] DATETIME2(3) NULL;
    PRINT 'HC.TrackImport.DeletedAt added';
END
ELSE PRINT 'HC.TrackImport.DeletedAt already exists';
GO
