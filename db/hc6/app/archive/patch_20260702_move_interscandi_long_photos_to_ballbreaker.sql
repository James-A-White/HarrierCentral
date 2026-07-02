-- =====================================================================
-- Run-once data patch (2026-07-02)
-- Move the 6 "Interscandi2026 Long" photos to "Interscandi2026 Ballbreaker".
--
-- The 6 photos on the Long event (evt 16) were actually taken on the
-- Ballbreaker run (evt 15) — the user briefly opened the Long run's live map,
-- and the photos were stamped with Long's eventId (photos are attributed to the
-- open live-run page's event). Timestamps 08:27–08:39 and GPS both match the
-- Ballbreaker photo stream. Reattribute all 6 to Ballbreaker.
--
-- NOT a stored procedure — run once, then archive (deploy globs skip it anyway).
-- Author: Harrier Central
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @long        UNIQUEIDENTIFIER = '2D9C8009-6F9E-4F95-BB09-D76E01B82558';
DECLARE @ballbreaker UNIQUEIDENTIFIER = '630D7042-E514-4BA8-B8DC-06F2D2CC4A3C';

SELECT 'before' AS phase,
  (SELECT COUNT(*) FROM HC.KennelPhotos WHERE EventId = @long)        AS LongPhotos,
  (SELECT COUNT(*) FROM HC.KennelPhotos WHERE EventId = @ballbreaker) AS BallbreakerPhotos;

BEGIN TRANSACTION;

UPDATE HC.KennelPhotos
SET EventId = @ballbreaker
WHERE EventId = @long;

DECLARE @moved INT = @@ROWCOUNT;

-- Safety: we expect exactly the 6 known misplaced photos.
IF (@moved <> 6)
BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Expected to move 6 photos but matched %d — rolled back.', 16, 1, @moved);
    RETURN;
END

COMMIT TRANSACTION;
PRINT CONCAT('Rows moved: ', @moved);

SELECT 'after' AS phase,
  (SELECT COUNT(*) FROM HC.KennelPhotos WHERE EventId = @long)        AS LongPhotos,
  (SELECT COUNT(*) FROM HC.KennelPhotos WHERE EventId = @ballbreaker) AS BallbreakerPhotos;
