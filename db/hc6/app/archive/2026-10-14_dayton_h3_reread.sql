-- Run-once (2026-10-14): make DH3 due on the next RunsPageImport tick.
-- After SP build 70 fixed the geocode anchor (DH3's Latitude 999 made every
-- Azure Maps lookup 400), the calendar text is unchanged, so an ordinary read
-- would skip the model and the geocode. Clearing the fingerprint forces the
-- model and geocode; clearing the checked-at makes it due within 15 minutes.
-- Lesson: a script that switches a kennel's source must clear BOTH.
SET NOCOUNT ON;
UPDATE HC.Kennel
SET RunsPageHash = NULL, RunsPageCheckedAt = NULL
WHERE id = '332cc8ad-39e4-4151-b3d8-28eaa7717e1f';
SELECT @@ROWCOUNT AS rowsUpdated;
