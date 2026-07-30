-- =====================================================================
-- Procedure: HC6.nonApi_updateRunCountsByUser
-- Description: Recalculates all run-count statistics for a single
--              hasher across all kennels:
--                1. Inserts HasherKennelMap rows for any kennel the user
--                   has attended but has no existing HKM record.
--                2. Updates run-count columns on HasherEventMap
--                   (TotalRuns, TotalHaring, TotalRunsThisKennel,
--                    YtdTotalRunsThisKennel, etc.).
--                3. Clears counts on HEM rows where the user is no
--                   longer attending (AttendenceState < 20).
--                4. Updates HasherKennelMap summary counters
--                   (HcTotalRunCount, HcHaringCount, YtdTotalRunCount,
--                    YtdHaringCount, DateOfLastRun).
--                5. Updates rolling-year counts on HasherKennelMap.
-- Parameters:
--   @userId - Hasher to recalculate.
-- Returns:    Nothing.  Internal helper; called inside and after
--             transactions by portal and app SPs.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_updateRunCountsByUser
-- Breaking Changes vs HC5:
--   - @eventDateTime parameter removed (was accepted but never used).
--   - Timezone-aware event filter applied to HEM update (was absent in
--     the HC5 version; already present in HC5.fn_GetRunCounts).
--   - HC4.vwRunCountsRolling (no timezone filter) replaced with the
--     HC5.fn_GetRunCountsRolling logic (timezone-aware, index hints).
--   - Asymmetric COALESCE sentinels (-999/999) replaced with
--     ISNULL(x, -1) pattern (cleaner; safe for non-negative counts).
-- 2026-07-30 Fix: Stage 2/5 change-guards made symmetric with the values
--   actually written. The haring guards compared the RAW window value
--   against the stored CASE-adjusted value (non-hare rows store 0), so
--   every non-hare row fired on every recompute — re-stamping ~92k
--   HasherEventMap rows nightly (03:10 sweep) and a user's full history
--   on every RSVP/check-in. TotalHaring added to the guard (was absent,
--   so genuine TotalHaring staleness never self-healed).
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateRunCountsByUser]
    @userId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Skip anonymous users
    IF NOT EXISTS (
        SELECT 1 FROM HC.Hasher WHERE id = @userId AND isAnonymous = 0
    ) RETURN;

    -- ----------------------------------------------------------------
    -- Stage 1: Insert HasherKennelMap rows for kennels the user has
    --          attended but has no HKM record.
    --          (Inline of HC5.fn_HkmRecordsToInsert)
    -- ----------------------------------------------------------------
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
        NEWID(), @userId, attended.KennelId,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, N'',
        0, 0, SYSDATETIMEOFFSET()
    FROM (
        SELECT DISTINCT evt.KennelId
        FROM   HC.HasherEventMap hem
        JOIN   HC.Event evt ON evt.id = hem.EventId
        WHERE  hem.UserId         = @userId
          AND  hem.AttendenceState >= 20
          AND  hem.VirginVisitorType = 0
          AND  evt.IsCountedRun    = 1
          AND  evt.IsVisible       = 1
          AND  evt.removed         = 0
    ) attended
    WHERE NOT EXISTS (
        SELECT 1 FROM HC.HasherKennelMap hkm
        WHERE  hkm.UserId   = @userId
          AND  hkm.KennelId = attended.KennelId
    );

    -- ----------------------------------------------------------------
    -- Stage 2: Recompute HEM run-count columns using window functions.
    --          The start-time gate counts a run once it starts within 6h (so a
    --          pre-start check-in tallies in real time) but still excludes runs
    --          further in the future — guarding against an accidental check-in
    --          to a distant run inflating counts.
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
        FROM   HC.HasherEventMap hem  WITH (INDEX = IX_HemRunCount)
        JOIN   HC.Event evt           WITH (INDEX = IX_EvtRunCount) ON evt.id = hem.EventId
        JOIN   HC.Kennel ken          ON ken.id  = evt.KennelId
        JOIN   HC.City c              ON c.id    = ken.CityId
        JOIN   DomainValues.Timezone tz ON tz.id = c.TimezoneId
        WHERE  hem.userId         = @userId
          AND  hem.AttendenceState >= 20
          AND  hem.VirginVisitorType = 0
          AND  evt.IsCountedRun   = 1
          AND  evt.IsVisible      = 1
          AND  evt.removed        = 0
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
    WHERE  hem.userId = @userId
      AND  hem.AttendenceState >= 20
      AND  (
               ISNULL(hem.TotalRuns,              -1) != ISNULL(c.totalRuns,              -1) OR
               ISNULL(hem.TotalHaring,            -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.totalHaring           ELSE 0 END, -1) OR
               ISNULL(hem.TotalRunsThisKennel,    -1) != ISNULL(c.totalRunsThisKennel,    -1) OR
               ISNULL(hem.TotalHaringThisKennel,  -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.totalHaringThisKennel ELSE 0 END, -1) OR
               ISNULL(hem.YtdTotalRunsThisKennel, -1) != ISNULL(c.ytdTotalRunsThisKennel, -1) OR
               ISNULL(hem.YtdHaringThisKennel,    -1) != ISNULL(CASE WHEN c.isHare = 1 THEN c.ytdHaringThisKennel   ELSE 0 END, -1)
           );

    -- ----------------------------------------------------------------
    -- Stage 3: Clear counts on HEM rows that no longer QUALIFY as a
    --          counted run — not just att<20. A row can be att>=20 yet
    --          non-qualifying (event hidden/uncounted/removed, virgin/visitor,
    --          or a future run checked into early). Its stored count columns
    --          must be cleared or Stage 4's MAX() picks up the stale value and
    --          over-counts. The predicate mirrors Stage 2's `counted` filter.
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
    LEFT   JOIN HC.Event evt ON evt.id = hem.EventId
    WHERE  hem.userId = @userId
      AND  (
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
    -- Stage 4: Update HasherKennelMap summary counters.
    -- ----------------------------------------------------------------
    DECLARE @thisYear INT = DATEPART(YEAR, GETDATE());

    ;WITH hkmSummary AS (
        SELECT
            COALESCE(MAX(hem.TotalRunsThisKennel),  0) AS maxHcTotalRunCount,
            COALESCE(MAX(hem.TotalHaringThisKennel), 0) AS maxHcHaringCount,
            COALESCE(MAX(CASE WHEN DATEPART(YEAR, evt.EventStartLocal) = @thisYear
                              THEN hem.YtdTotalRunsThisKennel ELSE NULL END), 0) AS maxYtdTotalRunCount,
            COALESCE(MAX(CASE WHEN DATEPART(YEAR, evt.EventStartLocal) = @thisYear
                              THEN hem.YtdHaringThisKennel    ELSE NULL END), 0) AS maxYtdHaringCount,
            MAX(evt.EventStartLocal) AS dateOfLastRun,
            hkm.UserId,
            hkm.KennelId
        FROM   HC.HasherKennelMap hkm
        LEFT   JOIN HC.HasherEventMap hem ON hem.KennelId = hkm.KennelId
                                         AND hem.UserId   = hkm.UserId
                                         AND hem.AttendenceState >= 20
        LEFT   JOIN HC.Event evt          ON evt.id = hem.EventId
        WHERE  hkm.UserId = @userId
        GROUP  BY hkm.UserId, hkm.KennelId
    )
    UPDATE hkm
    SET    hkm.CurrentHaringCount   = 0,
           hkm.CurrentPackRunCount  = 0,
           hkm.HistoricalPackRunCount = 0,
           hkm.HcTotalRunCount      = s.maxHcTotalRunCount,
           hkm.HcHaringCount        = s.maxHcHaringCount,
           hkm.YtdTotalRunCount     = s.maxYtdTotalRunCount,
           hkm.YtdHaringCount       = s.maxYtdHaringCount,
           hkm.DateOfLastRun        = s.dateOfLastRun,
           hkm.updatedAt            = SYSDATETIMEOFFSET()
    FROM   HC.HasherKennelMap hkm
    JOIN   hkmSummary s ON s.UserId   = hkm.UserId
                       AND s.KennelId = hkm.KennelId
    WHERE  hkm.UserId = @userId
      AND  (
               ISNULL(hkm.HcTotalRunCount,  -1) != ISNULL(s.maxHcTotalRunCount,  -1) OR
               ISNULL(hkm.HcHaringCount,    -1) != ISNULL(s.maxHcHaringCount,    -1) OR
               ISNULL(hkm.YtdTotalRunCount, -1) != ISNULL(s.maxYtdTotalRunCount, -1) OR
               ISNULL(hkm.YtdHaringCount,   -1) != ISNULL(s.maxYtdHaringCount,   -1) OR
               ISNULL(hkm.DateOfLastRun,    '1900-01-01') != ISNULL(s.dateOfLastRun, '1900-01-01')
           );

    -- ----------------------------------------------------------------
    -- Stage 5: Update rolling-year (≈182-day) counts on HKM.
    --          (Inline of HC5.fn_GetRunCountsRolling, scoped to @userId)
    --          Bucket 0 = the current 182-day window.
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
        FROM   HC.HasherEventMap hem  WITH (INDEX = IX_HemRunCount)
        JOIN   HC.Event evt           WITH (INDEX = IX_EvtRunCount) ON evt.id = hem.EventId
        JOIN   HC.Kennel ken          ON ken.id  = evt.KennelId
        JOIN   HC.City c              ON c.id    = ken.CityId
        JOIN   DomainValues.Timezone tz ON tz.id = c.TimezoneId
        WHERE  hem.UserId         = @userId
          AND  hem.AttendenceState >= 20
          AND  hem.VirginVisitorType = 0
          AND  evt.IsCountedRun   = 1
          AND  evt.IsVisible      = 1
          AND  evt.removed        = 0
          AND  evt.EventStartDateTimeGmt < DATEADD(HOUR, 6, SYSUTCDATETIME()) -- count a run once it starts within 6h (covers pre-start check-in); still excludes far-future runs. UTC-safe vs the datetimeoffset column.
    ),
    rollingAgg AS (
        SELECT
            UserId,
            KennelId,
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
    WHERE  hkm.UserId = @userId
      AND  (
               ISNULL(hkm.RollingYearTotalRunCount, -1) != ISNULL(ra.rollingYearTotal,  0) OR
               ISNULL(hkm.RollingYearHaringCount,   -1) != ISNULL(ra.rollingYearHaring, 0)
           );

END
