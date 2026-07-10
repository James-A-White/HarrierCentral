-- =====================================================================
-- Run-once migration: KennelPhotos audience re-slice + Featured flag
-- Date: 2026-07-06 — design of record: project_kennel_standing_design
--
-- Old status ladder: 0=Private,1=Pending,2=Shared(all app users),
--   3=RunGallery(web),4=HomeGallery(web home),5=EventCover.
-- New audience model: 0=Private,1=Pending,2=MEMBERS,3=PUBLIC,5=Cover(public).
--   Featured (new SMALLINT flag) is ORTHOGONAL to audience — "showcase on the
--   kennel home page" — replacing the old status-4 rung.
-- Remap: Shared(2)->Public(3); RunGallery(3) stays 3; HomeGallery(4)->3+Featured;
--   Cover(5) unchanged. Status 4 is retired.
--
-- KennelPhotos is NOT a synced table (photos flow via SPs), so no trigger
-- dance. UpdatedAt is bumped on remapped rows so app photo caches re-pull.
-- Guarded: the remap only runs while pre-migration rows (Status=4) exist, so
-- re-running cannot demote new Members(2) photos.
-- Deploy order: run BEFORE deploying the photo SPs (they reference Featured).
-- =====================================================================
SET XACT_ABORT ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.KennelPhotos') AND name = 'Featured')
    ALTER TABLE [HC].[KennelPhotos] ADD [Featured] SMALLINT NOT NULL DEFAULT 0;
GO
IF EXISTS (SELECT 1 FROM HC.KennelPhotos WHERE Status = 4)
BEGIN
    BEGIN TRANSACTION;
    -- Old Shared (all-app-users) -> Public
    UPDATE HC.KennelPhotos SET Status = 3, UpdatedAt = GETUTCDATE() WHERE Status = 2;
    -- Old HomeGallery -> Public + Featured
    UPDATE HC.KennelPhotos SET Status = 3, Featured = 1, UpdatedAt = GETUTCDATE() WHERE Status = 4;
    COMMIT TRANSACTION;
END
GO
SELECT Status, COUNT(*) AS N, SUM(CAST(Featured AS INT)) AS FeaturedN
FROM HC.KennelPhotos GROUP BY Status ORDER BY Status;
GO
