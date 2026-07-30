-- =====================================================================
-- Procedure: HC6.nonApi_updateRunCountsForAllUsers
-- Description: Recalculates run-count statistics for all hashers whose
--              HasherEventMap records have been modified since
--              @updatedSince.  Applies the same logic as
--              nonApi_updateRunCountsByUser but in bulk:
--                1. Inserts HasherKennelMap rows for new kennel
--                   relationships discovered in the changed HEM rows.
--                2. Updates run-count columns on HasherEventMap.
--                3. Clears counts on non-attending HEM rows.
--                4. Updates HasherKennelMap summary counters.
--                5. Updates rolling-year counts on HasherKennelMap.
-- Parameters:
--   @updatedSince - Process HEM rows modified after this datetime.
--                   NULL processes all users (full recalculation).
--                   A 1-minute lookback is applied automatically to
--                   guard against sub-second race conditions.
-- Returns:    Nothing.  Internal helper called after bulk attendance
--             and payment operations.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_updateRunCountsForAllUsers
-- Breaking Changes vs HC5:
--   - HC5.fn_GetRunCounts and HC5.fn_GetRunCountsRolling inlined
--     directly; those legacy functions can now be retired.
--   - Affected users materialised into #affected once at the top and
--     JOINed in all stages, eliminating 3 repeated HEM scans and the
--     O(N²) correlated EXISTS in the HKM summary step.
--   - Asymmetric COALESCE sentinels (-999/999) replaced with
--     ISNULL(x, -1) pattern.
-- 2026-07-30 Fix: Stage 2/5 change-guards made symmetric with the values
--   actually written. The haring guards compared the RAW window value
--   against the stored CASE-adjusted value (non-hare rows store 0), so
--   every non-hare row fired on every recompute — re-stamping ~92k
--   HasherEventMap rows nightly (03:10 sweep) and a user's full history
--   on every RSVP/check-in. TotalHaring added to the guard (was absent,
--   so genuine TotalHaring staleness never self-healed).
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateRunCountsForAllUsers]
    @updatedSince DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1-minute lookback guards against sub-second race conditions
    SELECT @updatedSince = DATEADD(minute, -1, COALESCE(@updatedSince, '2000-01-01'));

    -- Materialise the set of affected non-anonymous users once.
    -- All 5 stages JOIN to this table; HEM is scanned for updatedAt only here.
    SELECT DISTINCT hem.UserId
    INTO   #affected
    FROM   HC.HasherEventMap hem
    JOIN   HC.Hasher h ON h.id = hem.UserId
    WHERE  hem.updatedAt > @updatedSince
      AND  h.isAnonymous  = 0;

    IF NOT EXISTS (SELECT 1 FROM #affected)
    BEGIN
        DROP TABLE #affected;
        RETURN;
    END

    -- ----------------------------------------------------------------
    -- Stage 1: Insert HasherKennelMap rows for any kennel an affected
    --          user has attended but has no existing HKM record.
    -- ----------------------------------------------------------------
    ;WITH attended AS (
        SELECT DISTINCT hem.UserId, evt.KennelId
        FROM   #affected af
        JOIN   HC.HasherEventMap hem ON hem.UserId = af.UserId
        JOIN   HC.Event evt          ON evt.id     = hem.EventId
        WHERE  hem.AttendenceState   >= 20
          AND  hem.VirginVisitorType  = 0
          AND  evt.IsCountedRun       = 1
          AND  evt.IsVisible          = 1
          AND  evt.removed            = 0
    )
    INSERT INTO HC.HasherKennelMap (
        id, UserId, KennelId,
        Following, IsMember, IsKennelFollowing, IsHomeKennel,
        KennelNotificationPreference, KennelEmailAlertPreference,
        MismanagementRoles, MismanagementRoleFlags, HcWebPermissionFlags,
        UserRoleFlags, AppAccessFlags,
        HistoricalTotalRunCount, HistoricalPackRunCount, HistoricalHaringCount,
        HistoricalCountIsEstimate,
        HcTotalRunCount, HcHaringCount, YtdTotalRunCount, YtdHaringCount,
        CurrentPackRunCount, CurrentHaringCount,
        KennelCredit, DiscountAmount, DiscountPercent, DiscountDescription,
        CanEditRunAttendence, removed, updatedAt
    )
    SELECT
        NEWID(), a.UserId, a.KennelId,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, N'',
        0, 0, SYSDATETIMEOFFSET()
    FROM   attended a
    WHERE  NOT EXISTS (
        SELECT 1 FROM HC.HasherKennelMap hkm
        WHERE  hkm.UserId   = a.UserId
          AND  hkm.KennelId = a.KennelId
    );

    -- ----------------------------------------------------------------
    -- Stage 2: Recompute HEM run-count columns for affected users.
    --          (Inline of HC5.fn_GetRunCounts)
    -- ----------------------------------------------------------------
    ;WITH counted AS (
        SELECT
            hem.id AS hemId,
            hem.isHare,
            ROW_NUMBER() OVER (PARTITION BY hem.userId
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS totalRuns,
            ROW_NUMBER() OVER (PARTITION BY hem.userId, hem.isHare
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS totalHaring,
            ROW_NUMBER() OVER (PARTITION BY hem.userId, evt.KennelId
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS totalRunsThisKennel,
            ROW_NUMBER() OVER (PARTITION BY hem.userId, evt.KennelId, hem.isHare
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS totalHaringThisKennel,
            ROW_NUMBER() OVER (PARTITION BY hem.userId, evt.KennelId, DATEPART(YEAR, evt.EventStartLocal)
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS ytdTotalRunsThisKennel,
            ROW_NUMBER() OVER (PARTITION BY hem.userId, evt.KennelId, hem.isHare, DATEPART(YEAR, evt.EventStartLocal)
                               ORDER BY evt.EventStartLocal, evt.KennelId, evt.EventNumber, evt.id)
                AS ytdHaringThisKennel
        FROM   #affected af
        JOIN   HC.HasherEventMap hem  WITH (INDEX = IX_HemRunCount) ON hem.UserId = af.UserId
        JOIN   HC.Event evt           WITH (INDEX = IX_EvtRunCount)  ON evt.id    = hem.EventId
        JOIN   HC.Kennel ken          ON ken.id  = evt.KennelId
        JOIN   HC.City c              ON c.id    = ken.CityId
        JOIN   DomainValues.Timezone tz ON tz.id = c.TimezoneId
        WHERE  hem.AttendenceState   >= 20
          AND  hem.VirginVisitorType  = 0
          AND  evt.IsCountedRun       = 1
          AND  evt.IsVisible          = 1
          AND  evt.removed            = 0
          AND  evt.EventStartDateTimeGmt < DATEADD(HOUR, 6, SYSUTCDATETIME()) -- count a run once it starts within 6h (covers pre-start check-in); still excludes far-future runs. UTC-safe vs the datetimeoffset column.
    )
    UPDATE hem
    SET    hem.TotalRuns              = c.totalRuns,
           hem.TotalHaring            = CASE WHEN c.isHare = 1 THEN c.totalHaring            ELSE 0 END,
           hem.TotalRunsThisKennel    = c.totalRunsThisKennel,
           hem.TotalHaringThisKennel  = CASE WHEN c.isHare = 1 THEN c.totalHaringThisKennel  ELSE 0 END,
           hem.YtdTotalRunsThisKennel = c.ytdTotalRunsThisKennel,
           hem.YtdHaringThisKennel    = CASE WHEN c.isHare = 1 THEN c.ytdHaringThisKennel    ELSE 0 END,
           hem.updatedAt              = SYSDATETIMEOFFSET()
    FROM   HC.HasherEventMap hem
    JOIN   counted c ON c.hemId = hem.id
    WHERE  hem.AttendenceState >= 20
      AND  (
               ISNULL(hem.TotalRuns,              -1) != ISNULL(c.totalRuns,              -1) OR
               ISNULL(hem.TotalHaring,            -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.totalHaring           ELSE 0 END, -1) OR
               ISNULL(hem.TotalRunsThisKennel,    -1) != ISNULL(c.totalRunsThisKennel,    -1) OR
               ISNULL(hem.TotalHaringThisKennel,  -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.totalHaringThisKennel ELSE 0 END, -1) OR
               ISNULL(hem.YtdTotalRunsThisKennel, -1) != ISNULL(c.ytdTotalRunsThisKennel, -1) OR
               ISNULL(hem.YtdHaringThisKennel,    -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.ytdHaringThisKennel   ELSE 0 END, -1)
           );

    -- ----------------------------------------------------------------
    -- Stage 3: Clear counts on HEM rows that no longer QUALIFY as a counted
    --          run (not just att<20): att>=20 rows whose event became
    --          hidden/uncounted/removed, virgin/visitor rows, or future runs
    --          checked into early. Otherwise their stale stored count columns
    --          get picked up by Stage 4's MAX() and over-count. Predicate
    --          mirrors Stage 2's `counted` filter. Scoped to #affected.
    -- ----------------------------------------------------------------
    UPDATE hem
    SET    hem.TotalRuns              = NULL,
           hem.TotalHaring            = NULL,
           hem.TotalRunsThisKennel    = NULL,
           hem.TotalHaringThisKennel  = NULL,
           hem.YtdTotalRunsThisKennel = NULL,
           hem.YtdHaringThisKennel    = NULL,
           hem.updatedAt              = SYSDATETIMEOFFSET()
    FROM   HC.HasherEventMap hem
    JOIN   #affected af ON af.UserId = hem.UserId
    LEFT   JOIN HC.Event evt ON evt.id = hem.EventId
    WHERE  (
               hem.AttendenceState < 20
            OR ISNULL(hem.VirginVisitorType, 0) <> 0
            OR evt.id IS NULL
            OR evt.IsCountedRun <> 1
            OR evt.IsVisible <> 1
            OR evt.removed <> 0
            OR evt.EventStartDateTimeGmt >= DATEADD(HOUR, 6, SYSUTCDATETIME())
           )
      AND  (
               hem.TotalRuns              IS NOT NULL OR
               hem.TotalHaring            IS NOT NULL OR
               hem.TotalRunsThisKennel    IS NOT NULL OR
               hem.TotalHaringThisKennel  IS NOT NULL OR
               hem.YtdTotalRunsThisKennel IS NOT NULL OR
               hem.YtdHaringThisKennel    IS NOT NULL
           );

    -- ----------------------------------------------------------------
    -- Stage 4: Update HasherKennelMap summary counters for all kennels
    --          associated with affected users.  JOIN to #affected avoids
    --          the correlated EXISTS anti-pattern against all HKM rows.
    -- ----------------------------------------------------------------
    DECLARE @thisYear INT = DATEPART(YEAR, GETDATE());

    ;WITH hkmSummary AS (
        SELECT
            hkm.UserId,
            hkm.KennelId,
            COALESCE(MAX(hem.TotalRunsThisKennel),  0) AS maxHcTotalRunCount,
            COALESCE(MAX(hem.TotalHaringThisKennel), 0) AS maxHcHaringCount,
            COALESCE(MAX(CASE WHEN DATEPART(YEAR, evt.EventStartLocal) = @thisYear
                              THEN hem.YtdTotalRunsThisKennel ELSE NULL END), 0) AS maxYtdTotalRunCount,
            COALESCE(MAX(CASE WHEN DATEPART(YEAR, evt.EventStartLocal) = @thisYear
                              THEN hem.YtdHaringThisKennel    ELSE NULL END), 0) AS maxYtdHaringCount,
            MAX(evt.EventStartLocal) AS dateOfLastRun
        FROM   #affected af
        JOIN   HC.HasherKennelMap hkm ON hkm.UserId = af.UserId
        LEFT   JOIN HC.HasherEventMap hem ON hem.KennelId = hkm.KennelId
                                         AND hem.UserId   = hkm.UserId
                                         AND hem.AttendenceState >= 20
        LEFT   JOIN HC.Event evt ON evt.id = hem.EventId
        GROUP  BY hkm.UserId, hkm.KennelId
    )
    UPDATE hkm
    SET    hkm.CurrentHaringCount    = 0,
           hkm.CurrentPackRunCount   = 0,
           hkm.HistoricalPackRunCount = 0,
           hkm.HcTotalRunCount       = s.maxHcTotalRunCount,
           hkm.HcHaringCount         = s.maxHcHaringCount,
           hkm.YtdTotalRunCount      = s.maxYtdTotalRunCount,
           hkm.YtdHaringCount        = s.maxYtdHaringCount,
           hkm.DateOfLastRun         = s.dateOfLastRun,
           hkm.updatedAt             = SYSDATETIMEOFFSET()
    FROM   HC.HasherKennelMap hkm
    JOIN   hkmSummary s ON s.UserId   = hkm.UserId
                       AND s.KennelId = hkm.KennelId
    WHERE  (
               ISNULL(hkm.HcTotalRunCount,  -1) != ISNULL(s.maxHcTotalRunCount,  -1) OR
               ISNULL(hkm.HcHaringCount,    -1) != ISNULL(s.maxHcHaringCount,    -1) OR
               ISNULL(hkm.YtdTotalRunCount, -1) != ISNULL(s.maxYtdTotalRunCount, -1) OR
               ISNULL(hkm.YtdHaringCount,   -1) != ISNULL(s.maxYtdHaringCount,   -1) OR
               ISNULL(hkm.DateOfLastRun,    '1900-01-01') != ISNULL(s.dateOfLastRun, '1900-01-01')
           );

    -- ----------------------------------------------------------------
    -- Stage 5: Update rolling-year (≈182-day) counts on HKM.
    --          (Inline of HC5.fn_GetRunCountsRolling)
    -- ----------------------------------------------------------------
    ;WITH rollingCounted AS (
        SELECT
            hem.UserId,
            evt.KennelId,
            hem.isHare,
            ((DATEDIFF(day, DATEADD(month, -6, GETDATE()), evt.EventStartLocal)) / 182) AS bucket,
            ROW_NUMBER() OVER (
                PARTITION BY hem.userId, evt.KennelId,
                             ((DATEDIFF(day, DATEADD(month, -6, GETDATE()), evt.EventStartLocal)) / 182)
                ORDER BY     evt.EventStartLocal, evt.KennelId
            ) AS rollingTotal,
            ROW_NUMBER() OVER (
                PARTITION BY hem.userId, evt.KennelId, hem.isHare,
                             ((DATEDIFF(day, DATEADD(month, -6, GETDATE()), evt.EventStartLocal)) / 182)
                ORDER BY     evt.EventStartLocal, evt.KennelId
            ) AS rollingHaring
        FROM   #affected af
        JOIN   HC.HasherEventMap hem  WITH (INDEX = IX_HemRunCount) ON hem.UserId = af.UserId
        JOIN   HC.Event evt           WITH (INDEX = IX_EvtRunCount)  ON evt.id    = hem.EventId
        JOIN   HC.Kennel ken          ON ken.id  = evt.KennelId
        JOIN   HC.City c              ON c.id    = ken.CityId
        JOIN   DomainValues.Timezone tz ON tz.id = c.TimezoneId
        WHERE  hem.AttendenceState   >= 20
          AND  hem.VirginVisitorType  = 0
          AND  evt.IsCountedRun       = 1
          AND  evt.IsVisible          = 1
          AND  evt.removed            = 0
          AND  evt.EventStartDateTimeGmt < DATEADD(HOUR, 6, SYSUTCDATETIME()) -- count a run once it starts within 6h (covers pre-start check-in); still excludes far-future runs. UTC-safe vs the datetimeoffset column.
    ),
    rollingAgg AS (
        SELECT
            UserId, KennelId,
            MAX(CASE WHEN bucket = 0                THEN rollingTotal  ELSE NULL END) AS rollingYearTotal,
            MAX(CASE WHEN bucket = 0 AND isHare = 1 THEN rollingHaring ELSE NULL END) AS rollingYearHaring
        FROM   rollingCounted
        GROUP  BY UserId, KennelId
    )
    UPDATE hkm
    SET    hkm.RollingYearTotalRunCount = ISNULL(ra.rollingYearTotal,  0),
           hkm.RollingYearHaringCount   = ISNULL(ra.rollingYearHaring, 0),
           hkm.updatedAt                = SYSDATETIMEOFFSET()
    FROM   HC.HasherKennelMap hkm
    JOIN   rollingAgg ra ON ra.UserId   = hkm.UserId
                        AND ra.KennelId = hkm.KennelId
    WHERE  (
               ISNULL(hkm.RollingYearTotalRunCount, -1) != ISNULL(ra.rollingYearTotal,  0) OR
               ISNULL(hkm.RollingYearHaringCount,   -1) != ISNULL(ra.rollingYearHaring, 0)
           );

    DROP TABLE #affected;

    INSERT INTO LOG.GeneralLog (LogSource, Message)
    VALUES ('RUN COUNTS', 'Updated all user run counts');

END
