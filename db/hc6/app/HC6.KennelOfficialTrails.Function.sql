CREATE OR ALTER FUNCTION [HC6].[KennelOfficialTrails] (@kennelId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.KennelOfficialTrails
-- Description: Every official (hare's) trail of a kennel's runs, for the
--   kennel's trail map (E5.F6.S6, James 2026-10-03: "show all the runs for
--   the kennel that are saved with the event... the official trails, not
--   the pack trails"). Only runs that have ENDED (start + 4 hours, the same
--   rule as publicWeb_getOfficialTrail): during a run its trail is for a
--   lost runner only.
-- Returns: { EventId, PublicEventId, EventNumber, EventName, EventStartLocal,
--   OfficialTrail (the lanes JSON), OfficialTrailInfo }
-- Author: Harrier Central
-- Created: 2026-10-03
-- =====================================================================
RETURN
    SELECT e.id                  AS EventId,
           e.PublicEventId,
           e.EventNumber,
           e.EventName,
           e.EventStartLocal,
           e.EventStartDatetimeGmt,
           CAST(DECOMPRESS(e.OfficialTrailGzip) AS NVARCHAR(MAX)) AS OfficialTrail,
           e.OfficialTrailInfo
    FROM HC.Event e
    WHERE e.KennelId = @kennelId
      AND e.OfficialTrailGzip IS NOT NULL
      AND e.deleted = 0
      AND ISNULL(e.removed, 0) = 0
      AND e.IsVisible = 1
      AND DATEADD(HOUR, 4, e.EventStartDatetimeGmt) <= SYSDATETIMEOFFSET();
GO
