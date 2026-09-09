CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getRunPhotoPins]
    @publicEventId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.publicWeb_getRunPhotoPins
-- Description: Where and when each Hash-Flash-approved PUBLIC photo of a
--   run was taken, for the public PackTrack map and Trail TV pins. Photos
--   are their own thing — a location, a time and a photographer — and are
--   no longer written into anybody's GPS track, so the maps read pins from
--   the photo rows instead of from PHO:: track marks.
--   Exposure is unchanged from before: these are the same public photos
--   whose PHO:: coordinates the track payload already carried. The gallery
--   endpoint (publicWeb_getRunPhotos) still carries no coordinates.
-- Parameters: @publicEventId - HC.Event.PublicEventId
-- Returns:
--   Rowset 0: EventFound (1/0)
--   Rowset 1: photoId, Latitude, Longitude, TakenAtUtc, CreatedAt for
--             Status >= 3, not deleted, with a real coordinate.
-- Author: Harrier Central
-- Created: 2026-09-09
-- HC5 Source: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    IF @publicEventId IS NULL
    BEGIN
        SELECT 0 AS EventFound;
        RETURN;
    END

    SELECT CASE WHEN EXISTS (SELECT 1 FROM HC.Event WHERE PublicEventId = @publicEventId) THEN 1 ELSE 0 END AS EventFound;

    SELECT
        kp.id          AS photoId,
        kp.Latitude,
        kp.Longitude,
        kp.TakenAtUtc,
        kp.CreatedAt
    FROM HC.KennelPhotos kp
    INNER JOIN HC.Event e ON e.id = kp.EventId AND e.PublicEventId = @publicEventId
    WHERE kp.Status    >= 3          -- audience model: Public(3) and Cover(5) only
      AND kp.DeletedAt IS NULL
      AND kp.Latitude  IS NOT NULL AND kp.Longitude IS NOT NULL
      AND NOT (kp.Latitude = 0 AND kp.Longitude = 0)   -- no fix known: no pin rather than a wrong one
    ORDER BY COALESCE(kp.TakenAtUtc, kp.CreatedAt) ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getRunPhotoPins', ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
