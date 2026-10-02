CREATE OR ALTER FUNCTION [HC6].[CoRunners] (@userId UNIQUEIDENTIFIER)
RETURN
    -- The rule itself lives in HC6.CoRunnerKennels (2026-10-02); this only
    -- totals it across kennels.
    SELECT ck.UserId,
           SUM(ck.RunsTogether)  AS RunsTogether,
           MIN(ck.FirstTogether) AS FirstTogether,
           MAX(ck.LastTogether)  AS LastTogether
    FROM HC6.CoRunnerKennels(@userId) ck
    GROUP BY ck.UserId;
GO
