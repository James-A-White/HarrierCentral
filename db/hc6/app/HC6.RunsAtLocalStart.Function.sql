CREATE OR ALTER FUNCTION [HC6].[RunsAtLocalStart]
(
    @kennelId       UNIQUEIDENTIFIER,
    @startLocal     DATETIME2(7),
    @excludeEventId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.RunsAtLocalStart
-- Description: The kennel's other runs that start at the same LOCAL date
--   and time, to the minute (E3.F1.S8). Before a run is saved with a new
--   start, both clients ask whether the kennel already has a run then and,
--   if so, confirm — a weekend event can have many runs at one time, so it
--   is a question, never a refusal. The ONE rule both
--   hcapp_getRunsAtStart and hcportal_getRunsAtStart read.
--   Local wall clock (EventStartLocal, /hc-event-datetimes): "the same
--   start" means what the hare typed, not an instant. Deleted and removed
--   runs are left out; hidden ones are not (a hidden run at that time is
--   still a second run at that time).
-- Parameters:
--   @kennelId       - the kennel (internal id)
--   @startLocal     - the start being saved, local wall clock; seconds
--                     and below are ignored
--   @excludeEventId - the run being saved (its own row never matches);
--                     NULL or an id not yet in HC.Event excludes nothing
-- Returns: { eventId, publicEventId, eventName, eventNumber, isVisible,
--   eventStartLocal } — one row per matching run.
-- Author: Harrier Central
-- Created: 2026-10-14
-- =====================================================================
RETURN
    SELECT e.id                  AS eventId,
           e.PublicEventId       AS publicEventId,
           CASE WHEN e.UseFbRunDetails = 1 AND e.FbEventName IS NOT NULL
                THEN e.FbEventName ELSE e.EventName END AS eventName,
           e.EventNumber         AS eventNumber,
           e.IsVisible           AS isVisible,
           e.EventStartLocal     AS eventStartLocal
    FROM (SELECT DATEADD(MINUTE,
                         DATEDIFF(MINUTE, CAST('2000-01-01' AS DATETIME2(7)), @startLocal),
                         CAST('2000-01-01' AS DATETIME2(7))) AS m) t
    JOIN HC.Event e
      ON  e.KennelId        =  @kennelId
      AND e.EventStartLocal >= t.m
      AND e.EventStartLocal <  DATEADD(MINUTE, 1, t.m)
    WHERE e.deleted = 0
      AND e.removed = 0
      AND (@excludeEventId IS NULL OR e.id <> @excludeEventId);
GO
