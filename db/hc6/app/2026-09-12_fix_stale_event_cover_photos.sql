-- =====================================================================
-- Run-once: covers left on the uncropped original (2026-09-12)
--
--   HC.Event.EventCoverPhotoUrl is a COPY of the chosen photo's URL, made
--   when the photo is approved. hcapp_updateRunPhotoEditedBlob wrote the
--   crop to HC.KennelPhotos and never followed that copy, so a photo
--   approved BEFORE it was cropped left the run card showing the original
--   for ever. The SP now re-points the cover; these are the rows that were
--   already wrong when it was fixed.
--
--   HC.Event IS SYNCED. Each row updated here stamps updatedAt through the
--   event trigger and re-syncs to followers — which is exactly what we
--   want (their phones are holding the stale URL), and it is a handful of
--   rows, not a table. Do NOT disable the trigger for this one.
--
--   Only covers that still match the photo's own original are touched, so
--   a cover deliberately pointing at a different photo is left alone.
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

SELECT e.id AS EventId, e.EventName, e.EventCoverPhotoUrl AS [before], kp.EditedBlobUrl AS [after]
  FROM HC.Event e
  JOIN HC.KennelPhotos kp ON kp.EventId = e.id
 WHERE kp.EditedBlobUrl IS NOT NULL
   AND LEN(kp.EditedBlobUrl) > 0
   AND e.EventCoverPhotoUrl = kp.BlobUrl;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE e
       SET e.EventCoverPhotoUrl = kp.EditedBlobUrl
      FROM HC.Event e
      JOIN HC.KennelPhotos kp ON kp.EventId = e.id
     WHERE kp.EditedBlobUrl IS NOT NULL
       AND LEN(kp.EditedBlobUrl) > 0
       AND e.EventCoverPhotoUrl = kp.BlobUrl;

    PRINT CONCAT('Covers re-pointed at the edited photo: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT CONCAT('FAILED: ', ERROR_MESSAGE());
    THROW;
END CATCH
GO
