-- =====================================================================
-- Procedure: HC6.nonApi_pruneLogs
-- Description: Deletes aged rows from the two tables that dominate the
--              database: LOG.GeneralLog and HC.IntegrationJob. Runs
--              nightly from the HC_prune_logs Logic App, immediately
--              before HC_rebiuld_indexes so the rebuild reclaims the
--              freed pages the same night.
-- Parameters:  @RetentionDays - keep rows newer than this (default 90)
--              @BatchSize     - rows per DELETE (default 5000)
--              @MaxBatches    - upper bound for one run (default 200,
--                               i.e. 1,000,000 rows) so a single
--                               invocation can never run away
--              @BatchDelaySeconds - pause between batches (default 0.5).
--                               This is the throttle: the pause is dead time
--                               for the database, so raising it lowers the
--                               job's duty cycle and therefore its average
--                               DTU, leaving headroom for real users. A big
--                               catch-up should use a high value; there is
--                               never any hurry to delete old log rows.
-- Returns:     One summary rowset (GeneralLogDeleted, IntegrationJobDeleted,
--              ClientErrorLogDeleted)
-- Author:      Harrier Central
-- Created:     2026-08-31
-- HC5 Source:  None - new in HC6
-- Breaking Changes: None
--
-- Naming note: the six sibling maintenance jobs call [HC3].[extApi_daily_*]
-- SPs that exist only in the database and are not in source control. New
-- work goes in HC6 so it is versioned and picked up by tools/deploy_hc6.sh
-- (HC6.nonApi_* glob). The Logic App calls [HC6].[nonApi_pruneLogs].
--
-- Retention safety (verified 2026-08-31):
--   LOG.GeneralLog     - only hcportal_getCategoryDetail(2) category 8 reads
--                        it, and the portal offers at most "Last Month"
--                        (30 days), so 90 days leaves 3x headroom.
--   HC.IntegrationJob  - hcportal_getUsageData shows MAX(IntegrationJobId)
--                        per integration. The most recent job for every
--                        integration is therefore preserved regardless of
--                        age, or a dormant integration would vanish from
--                        the monitor.
--   Neither table has a foreign key or a trigger pointing at it.
--
-- Transaction note: deliberately NOT wrapped in one outer transaction.
-- Each batch autocommits, which is the entire point of batching - a single
-- transaction over millions of rows would hold locks and bloat the log,
-- the exact problem this SP exists to avoid.
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_pruneLogs]
    @RetentionDays INT = 90,
    @BatchSize     INT = 5000,
    @MaxBatches    INT = 200,
    @BatchDelaySeconds DECIMAL(5,1) = 0.5
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @procName    NVARCHAR(128) = OBJECT_NAME(@@PROCID);
    DECLARE @cutoff      DATETIMEOFFSET(7) = DATEADD(DAY, -@RetentionDays, SYSUTCDATETIME());
    DECLARE @glDeleted   BIGINT = 0;
    DECLARE @ijDeleted   BIGINT = 0;
DECLARE @celDeleted  BIGINT = 0;
    DECLARE @batches     INT = 0;
    DECLARE @rows        INT = 1;
    DECLARE @startedAt   DATETIME2(3) = SYSUTCDATETIME();

    -- Guard against a caller passing something absurd.
    IF (@RetentionDays < 30) SET @RetentionDays = 30;
    IF (@BatchSize < 100 OR @BatchSize > 50000) SET @BatchSize = 5000;
    IF (@MaxBatches < 1) SET @MaxBatches = 200;
    IF (@BatchDelaySeconds < 0 OR @BatchDelaySeconds > 600) SET @BatchDelaySeconds = 0.5;

    -- WAITFOR DELAY needs a time-typed value, not a number.
    DECLARE @delay CHAR(12) = CONVERT(CHAR(12),
        DATEADD(MILLISECOND, CAST(@BatchDelaySeconds * 1000 AS INT), CAST('00:00:00' AS TIME)), 114);

    BEGIN TRY

        -- -------------------------------------------------------------
        -- 1. LOG.GeneralLog
        --
        -- Resolve the id boundary ONCE, then delete by the clustered key.
        -- Deleting on [Timestamp] directly seeks the nonclustered index and
        -- then does a bookmark lookup per row - random IO that pegged DTU at
        -- ~90-100% and ran at only ~10k rows/min. idx is IDENTITY so it rises
        -- with insert time; ranging on it is a sequential clustered scan.
        -- The [Timestamp] predicate is KEPT as a second filter so a
        -- hypothetical backdated insert can never be deleted early.
        -- -------------------------------------------------------------
        DECLARE @maxIdx INT;
        SELECT @maxIdx = MAX(idx) FROM LOG.GeneralLog WHERE [Timestamp] < @cutoff;

        WHILE (@rows > 0 AND @batches < @MaxBatches AND @maxIdx IS NOT NULL)
        BEGIN
            DELETE TOP (@BatchSize) FROM LOG.GeneralLog
            WHERE idx <= @maxIdx AND [Timestamp] < @cutoff;

            SET @rows = @@ROWCOUNT;
            SET @glDeleted = @glDeleted + @rows;
            SET @batches = @batches + 1;

            IF (@rows > 0 AND @BatchDelaySeconds > 0) WAITFOR DELAY @delay;
        END

        -- -------------------------------------------------------------
        -- 2. HC.IntegrationJob - preserving the latest job per integration
        -- -------------------------------------------------------------
        CREATE TABLE #KeepJobs (IntegrationJobId INT PRIMARY KEY);

        INSERT INTO #KeepJobs (IntegrationJobId)
        SELECT MAX(IntegrationJobId)
        FROM HC.IntegrationJob
        GROUP BY IntegrationId;

        -- Also keep the latest COMPLETED job per integration, which is what
        -- the usage monitor actually joins on (endedAt IS NOT NULL).
        INSERT INTO #KeepJobs (IntegrationJobId)
        SELECT MAX(ij.IntegrationJobId)
        FROM HC.IntegrationJob ij
        WHERE ij.endedAt IS NOT NULL
        GROUP BY ij.IntegrationId
        HAVING MAX(ij.IntegrationJobId) NOT IN (SELECT IntegrationJobId FROM #KeepJobs);

        SET @rows = 1;
        SET @batches = 0;

        DECLARE @maxJobId INT;
        SELECT @maxJobId = MAX(IntegrationJobId) FROM HC.IntegrationJob WHERE startedAt < @cutoff;

        WHILE (@rows > 0 AND @batches < @MaxBatches AND @maxJobId IS NOT NULL)
        BEGIN
            DELETE TOP (@BatchSize) FROM HC.IntegrationJob
            WHERE IntegrationJobId <= @maxJobId
              AND startedAt < @cutoff
              AND IntegrationJobId NOT IN (SELECT IntegrationJobId FROM #KeepJobs);

            SET @rows = @@ROWCOUNT;
            SET @ijDeleted = @ijDeleted + @rows;
            SET @batches = @batches + 1;

            IF (@rows > 0 AND @BatchDelaySeconds > 0) WAITFOR DELAY @delay;
        END

        DROP TABLE #KeepJobs;

        -- -------------------------------------------------------------
        -- 3. HC.ClientErrorLog — the on-device diagnostics harvest.
        --
        -- Had NO retention at all until 2026-09-02: the only diagnostics
        -- table not covered here. Small (a few thousand rows), so a plain
        -- batched delete on LoggedAt is fine — no clustered-range trick
        -- needed, and its PK is a GUID so that trick would not apply anyway.
        -- -------------------------------------------------------------
        SET @rows = 1;
        SET @batches = 0;

        WHILE (@rows > 0 AND @batches < @MaxBatches)
        BEGIN
            DELETE TOP (@BatchSize) FROM HC.ClientErrorLog
            WHERE LoggedAt < @cutoff;

            SET @rows = @@ROWCOUNT;
            SET @celDeleted = @celDeleted + @rows;
            SET @batches = @batches + 1;

            IF (@rows > 0 AND @BatchDelaySeconds > 0) WAITFOR DELAY @delay;
        END

        -- -------------------------------------------------------------
        -- 3. Summary (one row per night - this is not self-defeating)
        -- -------------------------------------------------------------
        INSERT INTO LOG.GeneralLog (LogSource, Message, [Timestamp])
        VALUES ('nonApi_pruneLogs',
                CONCAT('Pruned to ', @RetentionDays, 'd: GeneralLog=', @glDeleted,
                       ' IntegrationJob=', @ijDeleted, ' ClientErrorLog=', @celDeleted,
                       ' delay=', @BatchDelaySeconds, 's',
                       ' in ', DATEDIFF(SECOND, @startedAt, SYSUTCDATETIME()), 's'),
                SYSUTCDATETIME());

        SELECT @glDeleted AS GeneralLogDeleted,
               @ijDeleted AS IntegrationJobDeleted,
               @celDeleted AS ClientErrorLogDeleted,
               DATEDIFF(SECOND, @startedAt, SYSUTCDATETIME()) AS ElapsedSeconds;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_pruneLogs',
                ERROR_MESSAGE(), @procName, NULL);

        THROW;
    END CATCH
END
