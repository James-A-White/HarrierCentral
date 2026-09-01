CREATE OR ALTER PROCEDURE [HC6].[nonApi_capturePerfBaseline]
    @label        NVARCHAR(50),
    @windowStart  DATETIMEOFFSET(7),
    @windowEnd    DATETIMEOFFSET(7)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_capturePerfBaseline
-- Description: Snapshots per-procedure runtime stats out of Query Store
--   into HC.PerfBaseline so they survive Query Store's retention window.
--   Query Store keeps only 7 days, so a before/after comparison across a
--   service-tier change MUST be captured before the old data ages out.
-- Parameters:
--   @label       - free text identifying the snapshot, e.g. 'S1-quiet'
--   @windowStart - only Query Store intervals fully inside this window
--   @windowEnd     are aggregated, so a noisy period can be excluded
-- Returns: the rows captured, for eyeballing
-- Author: Harrier Central
-- Created: 2026-09-01
-- HC5 Source: None - new in HC6
-- Breaking Changes: None
--
-- Comparison notes (read before drawing conclusions):
--   * Query Store's count_executions counts STATEMENT executions, not
--     procedure calls. A proc with a loop (nonApi_pruneLogs) registers its
--     inner DELETE once per iteration. So AvgStatementMs is the mean duration
--     of a statement inside the proc, NOT how long the proc takes to run.
--     That is fine for a before/after ratio as long as the same method is
--     applied to both sides - but never quote it as "the SP takes N ms".
--   * Compare PER-EXECUTION figures, never totals - workload volume varies.
--   * AvgPhysicalReads is the leading indicator. DTU scales the buffer pool,
--     so a smaller tier can turn cached logical reads into physical ones.
--     That is a cliff, not a slope, and it is the thing most likely to make
--     a lower tier hurt disproportionately.
--   * Exclude the hours right after a scale operation: it restarts/moves the
--     database, so the buffer pool is cold and everything looks slow.
--   * Exclude heavy maintenance windows (the 2026-08-31 catch-up prune sat at
--     100% data IO for hours and inflates anything measured alongside it).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY

    IF OBJECT_ID('HC.PerfBaseline') IS NULL
        CREATE TABLE HC.PerfBaseline (
            id               INT IDENTITY(1,1) PRIMARY KEY,
            Label            NVARCHAR(50)   NOT NULL,
            CapturedAt       DATETIME2(3)   NOT NULL,
            ServiceObjective NVARCHAR(50)   NULL,
            WindowStart      DATETIMEOFFSET(7) NULL,
            WindowEnd        DATETIMEOFFSET(7) NULL,
            ProcName         NVARCHAR(300)  NULL,
            StatementExecs   BIGINT         NULL,
            AvgStatementMs   DECIMAL(18,2)  NULL,
            MaxStatementMs   DECIMAL(18,2)  NULL,
            TotalMs          DECIMAL(18,2)  NULL,
            AvgCpuMs         DECIMAL(18,2)  NULL,
            AvgLogicalReads  BIGINT         NULL,
            AvgPhysicalReads BIGINT         NULL);

    DELETE FROM HC.PerfBaseline WHERE Label = @label;

    INSERT HC.PerfBaseline (Label, CapturedAt, ServiceObjective, WindowStart, WindowEnd,
                            ProcName, StatementExecs, AvgStatementMs, MaxStatementMs,
                            TotalMs, AvgCpuMs, AvgLogicalReads, AvgPhysicalReads)
    SELECT @label,
           SYSUTCDATETIME(),
           CAST(DATABASEPROPERTYEX(DB_NAME(),'ServiceObjective') AS NVARCHAR(50)),
           @windowStart,
           @windowEnd,
           OBJECT_NAME(q.object_id),
           SUM(rs.count_executions),
           CAST(SUM(rs.avg_duration      * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) / 1000.0 AS DECIMAL(18,2)),
           CAST(MAX(rs.max_duration) / 1000.0 AS DECIMAL(18,2)),
           CAST(SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS DECIMAL(18,2)),
           CAST(SUM(rs.avg_cpu_time      * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) / 1000.0 AS DECIMAL(18,2)),
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

    SELECT Label, ServiceObjective, ProcName, StatementExecs, AvgStatementMs,
           TotalMs, AvgCpuMs, AvgLogicalReads, AvgPhysicalReads
    FROM HC.PerfBaseline WHERE Label = @label ORDER BY TotalMs DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_capturePerfBaseline',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
