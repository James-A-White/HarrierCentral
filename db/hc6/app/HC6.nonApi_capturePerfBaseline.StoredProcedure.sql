CREATE OR ALTER PROCEDURE [HC6].[nonApi_capturePerfBaseline]
    @label        NVARCHAR(50),
    @windowStart  DATETIMEOFFSET(7),
    @windowEnd    DATETIMEOFFSET(7)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_capturePerfBaseline
-- Description: Snapshots per-procedure Query Store aggregates into
--   HC.PerfBaseline so a performance comparison survives Query Store's
--   retention window, and stamps each snapshot with the DTU tier that was
--   ACTUALLY IN EFFECT during the measured window.
-- Parameters:
--   @label       - identifies the snapshot, e.g. 'S0-run1'
--   @windowStart - only Query Store intervals fully inside this window are
--   @windowEnd     aggregated, so noisy periods can be excluded
-- Returns: the rows captured
-- Author: Harrier Central
-- Created: 2026-09-01
-- HC5 Source: None - new in HC6
-- Breaking Changes: None
--
-- WHY THE TIER IS DERIVED, NOT ASSUMED:
--   The first version stamped DATABASEPROPERTYEX('ServiceObjective') at
--   CAPTURE time, which is not the tier the window ran under. That silently
--   mislabelled three snapshots — a window believed to be S0 turned out to be
--   99% S1, because the scale happened ten hours later than assumed. The tier
--   now comes from HC.TierLog, maintained from the observed dtu_limit.
--
--   TierChangedDuringWindow = 1 means the window SPANS a scale operation and
--   the numbers are meaningless. Always check it before comparing anything.
--
-- OTHER COMPARISON NOTES:
--   * Query Store's count_executions counts STATEMENT executions, not proc
--     calls — a proc with a loop registers its inner statement once per
--     iteration. AvgStatementMs is a mean statement duration, NOT "how long
--     the SP takes". Fine for a like-for-like ratio; never quote it alone.
--   * Compare AvgLogicalReads FIRST. If it differs between two windows the
--     workload differed, and the duration ratio means nothing.
--   * AvgPhysicalReads is the leading indicator of a tier being too small:
--     DTU scales the buffer pool, so a smaller tier can turn cached logical
--     reads into physical ones. That is a cliff, not a slope.
--   * Match the TIME OF DAY between windows. Night vs day load differences
--     swamp the tier effect.
--   * Skip the first hour after any scale: it restarts/moves the database, so
--     the buffer pool is cold and everything looks slow.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY

    IF OBJECT_ID('HC.TierLog') IS NULL
        CREATE TABLE HC.TierLog (
            id         INT IDENTITY(1,1) PRIMARY KEY,
            DtuLimit   INT               NOT NULL,
            Tier       NVARCHAR(50)      NULL,
            ValidFrom  DATETIMEOFFSET(7) NOT NULL,
            ValidTo    DATETIMEOFFSET(7) NULL);   -- NULL = still in effect

    IF OBJECT_ID('HC.PerfBaseline') IS NULL
        CREATE TABLE HC.PerfBaseline (
            id                      INT IDENTITY(1,1) PRIMARY KEY,
            Label                   NVARCHAR(50)      NOT NULL,
            CapturedAt              DATETIME2(3)      NOT NULL,
            WindowStart             DATETIMEOFFSET(7) NULL,
            WindowEnd               DATETIMEOFFSET(7) NULL,
            DtuLimitDuringWindow    INT               NULL,
            TierDuringWindow        NVARCHAR(50)      NULL,
            TierChangedDuringWindow SMALLINT          NOT NULL DEFAULT 0,
            TierAtCapture           NVARCHAR(50)      NULL,
            ProcName                NVARCHAR(300)     NULL,
            StatementExecs          BIGINT            NULL,
            AvgStatementMs          DECIMAL(18,2)     NULL,
            MaxStatementMs          DECIMAL(18,2)     NULL,
            TotalMs                 DECIMAL(18,2)     NULL,
            AvgCpuMs                DECIMAL(18,2)     NULL,
            AvgLogicalReads         BIGINT            NULL,
            AvgPhysicalReads        BIGINT            NULL);

    -- ---------------------------------------------------------------
    -- Keep HC.TierLog current. Every capture observes the live dtu_limit
    -- and opens a new range when it has changed, so repeated scale
    -- up/down cycles are recorded without anyone having to remember.
    -- ---------------------------------------------------------------
    DECLARE @nowDtu INT, @nowTier NVARCHAR(50), @openDtu INT;
    SELECT TOP 1 @nowDtu = dtu_limit FROM sys.dm_db_resource_stats ORDER BY end_time DESC;
    SET @nowTier = CAST(DATABASEPROPERTYEX(DB_NAME(),'ServiceObjective') AS NVARCHAR(50));

    SELECT TOP 1 @openDtu = DtuLimit FROM HC.TierLog WHERE ValidTo IS NULL ORDER BY ValidFrom DESC;

    IF (@nowDtu IS NOT NULL AND (@openDtu IS NULL OR @openDtu <> @nowDtu))
    BEGIN
        UPDATE HC.TierLog SET ValidTo = SYSUTCDATETIME() WHERE ValidTo IS NULL;
        INSERT HC.TierLog (DtuLimit, Tier, ValidFrom) VALUES (@nowDtu, @nowTier, SYSUTCDATETIME());
    END

    -- ---------------------------------------------------------------
    -- Which tier(s) were in effect across the measured window?
    -- ---------------------------------------------------------------
    DECLARE @distinctTiers INT, @windowDtu INT, @windowTier NVARCHAR(50);

    SELECT @distinctTiers = COUNT(DISTINCT DtuLimit)
    FROM HC.TierLog
    WHERE ValidFrom < @windowEnd AND COALESCE(ValidTo, '9999-12-31 00:00:00 +00:00') > @windowStart;

    SELECT TOP 1 @windowDtu = DtuLimit, @windowTier = Tier
    FROM HC.TierLog
    WHERE ValidFrom < @windowEnd AND COALESCE(ValidTo, '9999-12-31 00:00:00 +00:00') > @windowStart
    ORDER BY ValidFrom;

    DELETE FROM HC.PerfBaseline WHERE Label = @label;

    INSERT HC.PerfBaseline (Label, CapturedAt, WindowStart, WindowEnd,
                            DtuLimitDuringWindow, TierDuringWindow,
                            TierChangedDuringWindow, TierAtCapture,
                            ProcName, StatementExecs, AvgStatementMs, MaxStatementMs,
                            TotalMs, AvgCpuMs, AvgLogicalReads, AvgPhysicalReads)
    SELECT @label, SYSUTCDATETIME(), @windowStart, @windowEnd,
           @windowDtu, @windowTier,
           CASE WHEN @distinctTiers > 1 THEN 1 ELSE 0 END, @nowTier,
           OBJECT_NAME(q.object_id),
           SUM(rs.count_executions),
           CAST(SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) / 1000.0 AS DECIMAL(18,2)),
           CAST(MAX(rs.max_duration) / 1000.0 AS DECIMAL(18,2)),
           CAST(SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS DECIMAL(18,2)),
           CAST(SUM(rs.avg_cpu_time * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) / 1000.0 AS DECIMAL(18,2)),
           CAST(SUM(rs.avg_logical_io_reads  * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) AS BIGINT),
           CAST(SUM(rs.avg_physical_io_reads * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) AS BIGINT)
    FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p  ON p.plan_id  = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_runtime_stats_interval i
         ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
    WHERE q.object_id <> 0
      AND i.start_time >= @windowStart
      AND i.end_time   <= @windowEnd
    GROUP BY OBJECT_NAME(q.object_id);

    IF (@distinctTiers > 1)
        RAISERROR('WARNING: the window spans a tier change - these numbers are not comparable.', 10, 1) WITH NOWAIT;

    SELECT Label, TierDuringWindow, DtuLimitDuringWindow, TierChangedDuringWindow,
           ProcName, StatementExecs, AvgStatementMs, TotalMs,
           AvgLogicalReads, AvgPhysicalReads
    FROM HC.PerfBaseline WHERE Label = @label ORDER BY TotalMs DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_capturePerfBaseline',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
