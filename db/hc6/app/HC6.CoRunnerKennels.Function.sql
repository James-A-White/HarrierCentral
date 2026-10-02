CREATE OR ALTER FUNCTION [HC6].[CoRunnerKennels] (@userId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.CoRunnerKennels
-- Description: THE definition of "run together" (E10.F1.S5, E9.F1.S26),
--   per co-runner AND kennel: both attended the same run —
--   AttendenceState >= 20 (ATTENDED, not ">= 3" any row) — on a visible,
--   non-deleted, non-removed run, neither attendance row removed.
--   HC6.CoRunners totals this, so the two can never disagree; By Hasher
--   uses the per-kennel split for "mostly <kennel>" (James, 2026-10-02).
-- Returns: { UserId, KennelId, RunsTogether, FirstTogether, LastTogether }
--   (First/Last = EventStartDatetimeGmt, instants)
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
RETURN
    SELECT o.UserId,
           e.KennelId,
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
    GROUP BY o.UserId, e.KennelId;
GO
