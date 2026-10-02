CREATE OR ALTER FUNCTION [HC6].[CoRunners] (@userId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.CoRunners
-- Description: Everyone @userId has run with, and how often (E10.F1.S5 By
--   Hasher, E9.F1.S26 search's "people I have run with"). The rule is
--   HC6.CoRunnerKennels' — both attended (AttendenceState >= 20, which
--   means ATTENDED, not ">= 3" any row) a visible, non-deleted,
--   non-removed run, neither attendance row removed; this only totals it
--   across kennels (2026-10-02), so the two can never disagree.
--   Inline (not scalar) so the search can join it without a per-row call.
-- Returns: { UserId, RunsTogether, FirstTogether, LastTogether } —
--   First/Last are EventStartDatetimeGmt (an instant; for ordering).
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
RETURN
    SELECT ck.UserId,
           SUM(ck.RunsTogether)  AS RunsTogether,
           MIN(ck.FirstTogether) AS FirstTogether,
           MAX(ck.LastTogether)  AS LastTogether
    FROM HC6.CoRunnerKennels(@userId) ck
    GROUP BY ck.UserId;
GO
