-- =====================================================================
-- Procedure: HC6.nonApi_rptKennelRunStats
-- Description: Generates a pivoted run-stats report for a kennel.
--              Each hasher becomes a column; each run a row.  The
--              "paid" value encodes payment amount and type into a
--              single integer so a single pivot covers both.
--              Also inserts summary rows for run totals and hare counts.
-- Parameters:
--   @kennelId - The kennel to report on.
-- Returns:
--   Rowset 0 — Pivoted attendance/payment matrix ordered by event date.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_rptKennelRunStats
-- Notes: Dynamic SQL is required for the PIVOT because the column list
--        (one per hasher) is not known at compile time.  Display names
--        are bracket-delimited; a name containing ']' will produce a
--        SQL error rather than injection, but callers should sanitise
--        display names upstream to avoid unexpected failures.
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_rptKennelRunStats]
    @kennelId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Build per-run, per-hasher attendance and payment rows
    SELECT
        h.DisplayName                                                                      AS Display_name,
        CASE WHEN e.UseFbRunDetails = 1 THEN e.FbEventName    ELSE e.EventName    END     AS Event_name,
        CASE WHEN e.UseFbRunDetails = 1
             THEN CONVERT(datetime2, e.FbEventStartDatetime)
             ELSE CONVERT(datetime2, e.EventStartDatetime)    END                         AS Event_date,
        e.EventNumber                                                                      AS Run_number,
        h.id                                                                               AS hid,
        e.id                                                                               AS eid,
        (COALESCE(CAST((CAST(p.DebitAmount AS money) * 10000) AS int) + p.PaymentType, 99990000) + 100000000)
            * CASE WHEN hem.isHare = 1 THEN -1 ELSE 1 END                                AS paid,
        COUNT(*) OVER (PARTITION BY h.id ORDER BY e.EventStartDatetime)
            + COALESCE(hkm.HistoricalTotalRunCount, 0)                                   AS runcount,
        SUM(hem.isHare) OVER (PARTITION BY h.id ORDER BY e.EventStartDatetime)
            + COALESCE(hkm.HistoricalHaringCount, 0)                                     AS hareCount,
        a.Total_hashers
    INTO #rpt
    FROM HC.HasherEventMap hem
    JOIN HC.Event e           ON e.id          = hem.EventId
    JOIN HC.Hasher h          ON h.id          = hem.UserId
    LEFT JOIN HC.HasherKennelMap hkm
                              ON hkm.KennelId  = e.KennelId AND hkm.UserId = h.id
    LEFT JOIN HC.Payment p    ON p.HasherEventMapId = hem.id AND p.CancelledBy_UserId IS NULL,
    (
        SELECT COUNT(*)    AS Total_hashers, hem2.EventId
        FROM   HC.HasherEventMap hem2
        JOIN   HC.Event e2 ON e2.id = hem2.EventId
        WHERE  e2.KennelId = @kennelId AND hem2.AttendenceState >= 20
        GROUP  BY hem2.EventId
    ) AS a
    WHERE e.KennelId         = @kennelId
      AND hem.TotalRunsThisKennel IS NOT NULL
      AND hem.AttendenceState >= 20
      AND a.EventId           = hem.EventId
      AND e.IsVisible         = 1
      AND e.KennelId         != h.id
      AND e.removed           = 0;

    -- Visitors and virgins (hasher id = kennel id rows)
    INSERT INTO #rpt (Display_name, Event_name, Event_date, Run_number, hid, eid, paid, runcount, hareCount, Total_hashers)
    SELECT
        'Visitors & Virgins',
        CASE WHEN e.UseFbRunDetails = 1 THEN e.FbEventName ELSE e.EventName END,
        CASE WHEN e.UseFbRunDetails = 1
             THEN CONVERT(datetime2, e.FbEventStartDatetime)
             ELSE CONVERT(datetime2, e.EventStartDatetime) END,
        e.EventNumber,
        h.id,
        e.id,
        (COALESCE(CAST((CAST(SUM(p.DebitAmount) AS money) * 10000) AS int), 99990000) + (COUNT(*) * 100000000)),
        99999,
        0,
        (SELECT TOP 1 Total_hashers FROM #rpt t
         WHERE t.Event_date = CASE WHEN e.UseFbRunDetails = 1
                                   THEN CONVERT(datetime2, e.FbEventStartDatetime)
                                   ELSE CONVERT(datetime2, e.EventStartDatetime) END)
    FROM HC.HasherEventMap hem
    JOIN HC.Event e  ON e.id = hem.EventId
    JOIN HC.Hasher h ON h.id = hem.UserId
    LEFT JOIN HC.Payment p ON p.HasherEventMapId = hem.id AND p.CancelledBy_UserId IS NULL
    WHERE e.KennelId          = @kennelId
      AND hem.TotalRunsThisKennel IS NOT NULL
      AND hem.AttendenceState >= 20
      AND e.KennelId           = h.id
    GROUP BY
        CASE WHEN e.UseFbRunDetails = 1 THEN e.FbEventName    ELSE e.EventName    END,
        CASE WHEN e.UseFbRunDetails = 1 THEN CONVERT(datetime2, e.FbEventStartDatetime)
                                         ELSE CONVERT(datetime2, e.EventStartDatetime) END,
        e.EventNumber, h.id, e.id;

    -- Summary sentinel rows (sorted to bottom via future dates)
    INSERT INTO #rpt (paid, hid, Display_name, eid, Event_name, Run_number, Event_date)
        SELECT MAX(runcount),  hid, Display_name, '00000000-0000-0000-0000-000000000000', 'Run totals',  0, '1/1/2200' FROM #rpt GROUP BY hid, Display_name;
    INSERT INTO #rpt (paid, hid, Display_name, eid, Event_name, Run_number, Event_date)
        SELECT MAX(hareCount), hid, Display_name, '00000000-0000-0000-0000-000000000000', 'Times hared', 0, '1/1/2100' FROM #rpt GROUP BY hid, Display_name;

    -- Build dynamic column list ordered by run count descending
    DECLARE @cols  NVARCHAR(MAX),
            @stmt  NVARCHAR(MAX),
            @dname NVARCHAR(500),
            @rc    INT;

    DECLARE xCrsr CURSOR FOR
        SELECT Display_name, MAX(runcount)
        FROM   #rpt
        WHERE  TRIM(Display_name) != ''
        GROUP  BY Display_name
        ORDER  BY MAX(runcount) DESC;

    OPEN xCrsr;
    FETCH NEXT FROM xCrsr INTO @dname, @rc;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cols = ISNULL(@cols + ', ', '') + '[' + REPLACE(TRIM(@dname), ']', ']]') + ']';
        FETCH NEXT FROM xCrsr INTO @dname, @rc;
    END;
    CLOSE xCrsr;
    DEALLOCATE xCrsr;

    SET @stmt = N'
SELECT * FROM (
    SELECT Event_name, Run_number, Total_hashers, Event_date, Display_name, paid
    FROM   #rpt
) s
PIVOT (SUM(paid) FOR Display_name IN (' + @cols + N')) AS pvt
ORDER BY Event_date DESC';

    EXEC sp_executesql @stmt = @stmt;

    DROP TABLE #rpt;

END
