CREATE OR ALTER PROCEDURE [HC6].[nonApi_refreshEventActivity]
    @eventId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.nonApi_refreshEventActivity
-- Description: Recomputes the four activity counts kept on HC.Event for
--   the run cards — TrackRunnerCount (attendance rows with a PackTrack
--   track), PhotoCount (approved, not deleted), MessageCount (trail chat,
--   not removed), DownDownCount (charges, not cancelled) — and writes them
--   ONLY when one differs. The write stamps updatedAt through the event
--   trigger, so the row syncs to every follower's phone; the guard keeps a
--   live run (a batch a minute per runner) from re-syncing the row for
--   nothing. Called by the triggers on HC.HasherEventMap, HC.KennelPhotos,
--   HC.EventMessage and HC.DownDowns, so every writer — SP or API — keeps
--   the counts right without knowing about them (James, 2026-09-12: what
--   the run card shows is synced to the phone, never fetched while
--   scrolling; see CLAUDE.md "Run-card data is synced").
--   The definitions match hcapp_getRunActivity 1.1.0, except photos: the
--   card's count is the approved photos everyone may see, not the viewer's
--   own pending ones (a synced number cannot depend on the viewer).
-- Parameters: @eventId — the run.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-09-12
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    UPDATE e
       SET TrackRunnerCount = x.runners,
           PhotoCount       = x.photos,
           MessageCount     = x.messages,
           DownDownCount    = x.downDowns
      FROM HC.Event e
     CROSS APPLY (
        SELECT
            (SELECT COUNT(*) FROM HC.HasherEventMap h
              WHERE h.EventId = e.id AND h.removed = 0 AND h.TrackPointCount > 0)      AS runners,
            (SELECT COUNT(*) FROM HC.KennelPhotos kp
              WHERE kp.EventId = e.id AND kp.DeletedAt IS NULL AND kp.Status >= 2)     AS photos,
            (SELECT COUNT(*) FROM HC.EventMessage m
              WHERE m.EventId = e.id AND m.Removed = 0)                                AS messages,
            (SELECT COUNT(*) FROM HC.DownDowns d
              WHERE d.EventId = e.id AND d.IsCancelled = 0)                            AS downDowns
     ) x
     WHERE e.id = @eventId
       AND (e.TrackRunnerCount <> x.runners OR e.PhotoCount <> x.photos
            OR e.MessageCount <> x.messages OR e.DownDownCount <> x.downDowns);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_refreshEventActivity',
            ERROR_MESSAGE(), @procName, NULL, @eventId);
    THROW;
END CATCH
GO
