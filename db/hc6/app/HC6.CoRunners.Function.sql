CREATE OR ALTER FUNCTION [HC6].[CoRunners] (@userId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.CoRunners
-- Description: Everyone @userId has run with, and how often. THE one
--   definition of "run together" (E10.F1.S5 By Hasher, E9.F1.S26 search's
--   "people I have run with"): both attended the same run —
--   AttendenceState >= 20, which means ATTENDED, not ">= 3" (any row,
--   RSVP included) — on a run that is visible and not deleted or removed,
--   with neither attendance row removed.
--   Inline (not scalar) so the search can join it without a per-row call.
-- Returns: { UserId, RunsTogether, FirstTogether, LastTogether } —
--   First/Last are EventStartDatetimeGmt (an instant; for ordering).
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
RETURN
    SELECT o.UserId,
           COUNT(*)                      AS RunsTogether,
           MIN(e.EventStartDatetimeGmt)  AS FirstTogether,
           MAX(e.EventStartDatetimeGmt)  AS LastTogether
    FROM HC.HasherEventMap m
    JOIN HC.HasherEventMap o
      ON o.EventId = m.EventId
     AND o.UserId <> m.UserId
     AND o.AttendenceState >= 20
     AND ISNULL(o.removed, 0) = 0
    JOIN HC.Event e
      ON e.id = m.EventId
     AND e.deleted = 0
     AND ISNULL(e.removed, 0) = 0
     AND e.IsVisible = 1
    WHERE m.UserId = @userId
      AND m.AttendenceState >= 20
      AND ISNULL(m.removed, 0) = 0
    GROUP BY o.UserId;
GO
