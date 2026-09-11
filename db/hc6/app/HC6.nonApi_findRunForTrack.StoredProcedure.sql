CREATE OR ALTER PROCEDURE [HC6].[nonApi_findRunForTrack]
    @userId         UNIQUEIDENTIFIER,
    @firstPointUtc  DATETIME2(3),
    @lastPointUtc   DATETIME2(3),
    @latitude       DECIMAL(18, 15),
    @longitude      DECIMAL(19, 15)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_findRunForTrack
-- Description: The matching behind a track import (E5.F5.S6/S7), without
--   auth, so the same rule serves the app (hcapp_findRunForTrack) and the
--   server-side import processor. Given a track's first/last point times
--   (UTC) and first position, returns the runs that started between three
--   hours before the first point and the last point, nearest start first,
--   with the distance from each run's recorded start, whether @userId
--   already has a trail on it, and their attendance state. Callers apply:
--   a recorded start must be within a mile; no recorded start ⇒ needs a
--   human; several ⇒ needs a choice. Instant ⇒ EventStartDateTimeGmt.
-- Returns: rowset 0 — up to 10 candidate runs.
-- Author: Harrier Central
-- Created: 2026-09-11 (split out of hcapp_findRunForTrack)
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    DECLARE @windowStart DATETIMEOFFSET = TODATETIMEOFFSET(DATEADD(HOUR, -3, @firstPointUtc), 0);
    DECLARE @windowEnd   DATETIMEOFFSET = TODATETIMEOFFSET(@lastPointUtc, 0);
    DECLARE @firstAt     DATETIMEOFFSET = TODATETIMEOFFSET(@firstPointUtc, 0);
    DECLARE @here        GEOGRAPHY      = geography::Point(@latitude, @longitude, 4326);

    SELECT TOP (10)
        e.id                                   AS eventId,
        e.EventName                            AS eventName,
        k.KennelName                           AS kennelName,
        e.KennelId                             AS kennelId,
        e.EventStartDateTimeGmt                AS eventStartGmt,
        CAST(e.EventStartDatetime AS DATETIME2(0)) AS eventStartLocal,
        CASE WHEN e.Latitude IS NOT NULL AND e.Longitude IS NOT NULL
              AND NOT (e.Latitude = 0 AND e.Longitude = 0) THEN 1 ELSE 0 END AS hasLocation,
        CASE WHEN e.Latitude IS NOT NULL AND e.Longitude IS NOT NULL
              AND NOT (e.Latitude = 0 AND e.Longitude = 0)
             THEN CAST(geography::Point(e.Latitude, e.Longitude, 4326).STDistance(@here) AS INT)
        END                                    AS distanceMeters,
        ISNULL(hem.TrackPointCount, 0)         AS existingTrackPoints,
        ISNULL(hem.AttendenceState, 0)         AS attendenceState
    FROM HC.Event e
    INNER JOIN HC.Kennel k ON k.id = e.KennelId
    OUTER APPLY (
        SELECT TOP (1) h.TrackPointCount, h.AttendenceState
        FROM HC.HasherEventMap h
        WHERE h.EventId = e.id AND h.UserId = @userId AND h.removed = 0
        ORDER BY h.TrackPointCount DESC
    ) hem
    WHERE e.deleted = 0 AND e.removed = 0 AND e.IsVisible = 1
      AND e.EventStartDateTimeGmt >= @windowStart
      AND e.EventStartDateTimeGmt <= @windowEnd
    ORDER BY ABS(DATEDIFF(SECOND, e.EventStartDateTimeGmt, @firstAt)) ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_findRunForTrack',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
