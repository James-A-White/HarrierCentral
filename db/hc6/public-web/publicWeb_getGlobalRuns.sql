CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getGlobalRuns]
    @IsFuture     SMALLINT,
    @PageSize     INT            = 50,
    @Offset       INT            = 0,
    @MinEventDate DATETIMEOFFSET = NULL,
    @MaxEventDate DATETIMEOFFSET = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getGlobalRuns
-- Description: Returns one row per event across all kennels for the
--              hashruns.org global [Runs] discovery tab. Unlike
--              publicWeb_getGlobalCalendar (which collapses multiple
--              events per day per kennel into one row), this SP returns
--              individual events with full kennel and event detail so
--              the client detail panel needs no second API call.
-- Parameters:  @IsFuture     SMALLINT — 1 = upcoming events (>= now, ASC);
--                                   0 = past events (< now, DESC)
--              @PageSize     INT  — events per page (default 50,
--                                  clamped to 1–5000). Use a large value
--                                  (e.g. 5000) to load all future runs in
--                                  a single SSR request.
--              @Offset       INT  — zero-based row offset for pagination
--                                  (default 0)
--              @MinEventDate DATETIMEOFFSET (optional) — lower bound
--                                  (inclusive) for past events. When NULL,
--                                  no lower bound is applied (all history).
--              @MaxEventDate DATETIMEOFFSET (optional) — upper bound
--                                  (exclusive) for past events. When NULL,
--                                  defaults to @UtcNow (current UTC time).
-- Future/past boundary (timezone-aware):
--              Uses EventStartDateTimeGmt (true UTC equivalent of the local
--              run start, maintained by trigger via Kennel→City→Timezone).
--              Falls back to EventStartDatetime when EventStartDateTimeGmt
--              is NULL (kennel has no city/timezone configured).
--              Future: run stays in upcoming list until 8 hours after local
--                      start (so a morning run is still visible that evening).
--              Past:   run appears in past list as soon as local start passes.
--              A run therefore appears in both lists for up to 8 hours.
-- Returns:     Rowset 0: { TotalMatchingEvents INT } — total count before
--                        the @PageSize cap; always one row so the client
--                        can determine whether more pages exist without
--                        a separate count call.
--              Rowset 1: one row per event, ordered by EventStartDatetime
--                        ASC (future) or DESC (past), with KennelName /
--                        PublicEventId as deterministic tiebreakers for
--                        stable pagination when concurrent events exist.
--              On runtime error: { Success = 0, ErrorMessage } from CATCH.
-- Author:      Harrier Central
-- Created:     2026-04-14
-- Updated:     2026-05-04 — return EventStartDatetimeGmt and KennelIANATimezone per
--                           row; cast EventStartDatetime to datetime2(7) to strip the
--                           spurious +00:00 offset. OUTER APPLY replaced with a
--                           pre-aggregated LEFT JOIN on TimeZoneMap to avoid row
--                           multiplication. COALESCE fallback computes
--                           EventStartDatetimeGmt on-the-fly via AT TIME ZONE for
--                           older runs where the trigger column is NULL.
-- Updated:     2026-05-03 — timezone-aware future/past boundary using
--                           EventStartDateTimeGmt; 8-hour grace window for
--                           future runs; overlap allowed between the two lists.
-- HC5 Source:  None — new for HC6 public web (hashruns.org)
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Clamp inputs
    IF @PageSize IS NULL OR @PageSize < 1 OR @PageSize > 5000
        SET @PageSize = 50;
    IF @Offset IS NULL OR @Offset < 0
        SET @Offset = 0;

    -- Current UTC time used for all future/past boundary comparisons.
    -- EventStartDateTimeGmt is the true UTC equivalent of the local run start
    -- (trigger: Kennel→City→Timezone). Falls back to EventStartDatetime when NULL.
    DECLARE @UtcNow         DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'UTC';
    DECLARE @FutureCutoff   DATETIMEOFFSET = DATEADD(HOUR, -8, @UtcNow);

    -- ── Rowset 0: total count ────────────────────────────────────────────────
    -- Always one row — lets the client compute hasMore without a separate query.

    SELECT COUNT(*) AS TotalMatchingEvents
    FROM   HC.Event  e
    JOIN   HC.Kennel k ON k.id = e.KennelId
    WHERE  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  k.deleted   = 0
      AND  k.removed   = 0
      AND  (   (@IsFuture = 1
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @FutureCutoff)
            OR (@IsFuture = 0
                    AND (@MinEventDate IS NULL OR e.EventStartDatetime >= @MinEventDate)
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) < ISNULL(@MaxEventDate, @UtcNow)));

    -- ── Rowset 1: events with kennel context ─────────────────────────────────

    SELECT
        -- ── Event identity ───────────────────────────────────────────────────
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- ── Timing ──────────────────────────────────────────────────────────
        CAST(e.EventStartDatetime AS datetime2(7)) AS EventStartDatetime,
        CAST(e.EventEndDatetime   AS datetime2(7)) AS EventEndDatetime,
        -- COALESCE: use stored GMT value when available; fall back to computing
        -- it via AT TIME ZONE for older runs where the trigger column is NULL.
        COALESCE(
            e.EventStartDatetimeGmt,
            CASE WHEN tz.Timezone IS NOT NULL
                 THEN CAST(
                          (CAST(e.EventStartDatetime AS datetime)
                               AT TIME ZONE tz.Timezone)
                          AT TIME ZONE 'UTC'
                      AS datetimeoffset(7))
                 ELSE NULL
            END
        )                                          AS EventStartDatetimeGmt,
        COALESCE(tzmap.IANATimeZone_001, tzmap.IANATimeZone_any) AS KennelIANATimezone,

        -- ── Event type ──────────────────────────────────────────────────────
        ett.EventEnumName                                               AS EventTypeName,

        -- ── Fees: event-level value overrides the kennel default ─────────────
        COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers)    AS EventPriceForMembers,
        COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers) AS EventPriceForNonMembers,
        COALESCE(e.EventCurrencyType,       k.DefaultEventCurrencyType)       AS EventCurrencyType,

        -- ── People ──────────────────────────────────────────────────────────
        e.Hares,

        -- ── Location — Sync* computed columns handle the Facebook override ──
        e.LocationOneLineDesc,
        e.SyncLocationStreet                                            AS LocationStreet,
        e.SyncLocationCity                                              AS LocationCity,
        e.SyncLocationPostCode                                          AS LocationPostCode,
        e.SyncLocationRegion                                            AS LocationRegion,
        e.SyncLocationCountry                                           AS LocationCountry,
        e.SyncLatitude                                                  AS Latitude,
        e.SyncLongitude                                                 AS Longitude,
        e.w3wJson,

        -- ── Content ─────────────────────────────────────────────────────────
        e.SyncDescription                                               AS EventDescription,
        e.EventImage,
        e.EventUrl,

        -- ── Tags (raw bitflags — decoded client-side using RunTag enum) ──────
        e.Tags1,
        e.Tags2,
        e.Tags3,

        -- ── Metadata ────────────────────────────────────────────────────────
        e.IsCountedRun,

        -- ── Kennel context (needed for list card and detail panel) ───────────
        k.KennelUniqueShortName                                         AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        kw.PrimaryColor,
        kw.AccentColor,
        k.PublicKennelId,

        -- KennelWebsiteDomain: the kennel's custom domain (e.g. www.cityhash.org).
        -- NULL for kennels without a custom domain. Used for the "Open Kennel
        -- website" QR code — omit that QR entry when NULL.
        kw.CustomDomain                                                 AS KennelWebsiteDomain,

        -- Continent derived from the kennel's country — used for search/filter.
        ctr.ContinentName                                               AS KennelContinent

    FROM   HC.Event             e
    JOIN   HC.Kennel            k   ON k.id          = e.KennelId
    LEFT JOIN HC.KennelWebsite  kw  ON kw.KennelId   = k.id
    LEFT JOIN HC.Country        ctr ON ctr.id         = k.CountryId
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    LEFT JOIN HC.City                  c   ON c.id    = k.CityId
    LEFT JOIN DomainValues.Timezone    tz  ON tz.id   = c.TimezoneId
    -- Pre-aggregated join avoids row multiplication when multiple territory rows
    -- exist in TimeZoneMap for the same Windows timezone name.
    LEFT JOIN (
        SELECT
            WindowsTimeZone,
            MAX(CASE WHEN territory = '001' THEN IANATimeZone ELSE NULL END) AS IANATimeZone_001,
            MIN(IANATimeZone)                                                 AS IANATimeZone_any
        FROM   DomainValues.TimeZoneMap
        GROUP  BY WindowsTimeZone
    ) tzmap ON tzmap.WindowsTimeZone = tz.Timezone COLLATE DATABASE_DEFAULT
    WHERE  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  k.deleted   = 0
      AND  k.removed   = 0
      AND  (   (@IsFuture = 1
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @FutureCutoff)
            OR (@IsFuture = 0
                    AND (@MinEventDate IS NULL OR e.EventStartDatetime >= @MinEventDate)
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) < ISNULL(@MaxEventDate, @UtcNow)))
    ORDER BY
        -- Conditional sort: only one branch is active per call.
        -- The inactive branch evaluates to NULL for every row and
        -- contributes nothing to the sort (SQL Server treats NULL as lowest
        -- in ASC — no effect on the active branch's ordering).
        CASE WHEN @IsFuture = 1 THEN e.EventStartDatetime END ASC,
        CASE WHEN @IsFuture = 0 THEN e.EventStartDatetime END DESC,
        k.KennelName    ASC,    -- stable tiebreaker when concurrent events exist
        e.PublicEventId ASC     -- final tiebreaker for consistent pagination
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
