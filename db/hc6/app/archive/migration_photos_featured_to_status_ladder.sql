-- =====================================================================
-- RUN-ONCE MIGRATION — collapse the orthogonal Featured flag into the Status ladder.
-- =====================================================================
-- Photo tags are a single-tag ladder: 0=Private, 1=Pending, 2=Members, 3=Public,
-- 4=Featured, 5=Cover. "Featured" used to be an orthogonal SMALLINT flag; it is now
-- the Status=4 rung (matches hcportal_batchUpdatePhotoStatus, which already did this).
--
-- Data today (non-deleted): 42 photos are Public(3)+Featured=1 (genuinely featured);
-- 4 are conflicts — 3 Members(2)+Featured, 1 Pending(1)+Featured. Per James: keep the
-- 4 conflicts at their RESTRICTIVE audience (don't publicize), just drop the flag.
--
-- Featured column is left in place (still SELECTed by some read SPs) but goes all-zero
-- and unused — drop it in a later cleanup once those projections are trimmed.
-- KennelPhotos is fetched on-demand (not in the delta-sync domains), so touching
-- UpdatedAt here does not trigger re-replication.
-- ⚠️  RUN MANUALLY, ONCE. Archived after running.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- 1. Promote genuinely-featured (already Public) photos to the Featured rung.
UPDATE HC.KennelPhotos
SET Status = 4, UpdatedAt = GETUTCDATE()
WHERE DeletedAt IS NULL AND Status = 3 AND Featured = 1;

-- 2. Clear the now-vestigial Featured flag everywhere. The 4 conflict photos
--    (Members/Pending + Featured) keep their restrictive Status — only the flag drops.
UPDATE HC.KennelPhotos
SET Featured = 0, UpdatedAt = GETUTCDATE()
WHERE Featured = 1;

COMMIT TRANSACTION;
GO

-- Verify: Status distribution + no Featured flags remain.
SELECT Status,
       CASE Status WHEN 0 THEN 'Private' WHEN 1 THEN 'Pending' WHEN 2 THEN 'Members'
                   WHEN 3 THEN 'Public' WHEN 4 THEN 'Featured' WHEN 5 THEN 'Cover' ELSE '?' END AS Meaning,
       COUNT(*) AS Photos
FROM HC.KennelPhotos WHERE DeletedAt IS NULL GROUP BY Status ORDER BY Status;

SELECT SUM(CASE WHEN Featured = 1 THEN 1 ELSE 0 END) AS FeaturedRemaining
FROM HC.KennelPhotos;
GO
