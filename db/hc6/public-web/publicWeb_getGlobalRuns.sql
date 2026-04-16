CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getGlobalRuns]
    @IsFuture   BIT,
    @PageSize   INT  = 50,
    @Offset     INT  = 0
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getGlobalRuns
-- Description: Returns one row per event across all kennels for the
--              hashruns.org global [Runs] discovery tab. Unlike
--              publicWeb_getGlobalCalendar (which collapses multiple
--              events per day per kennel into one row), this SP returns
--              individual events with full kennel and event detail so
--              the client detail panel needs no second API call.
-- Parameters:  @IsFuture   BIT  — 1 = upcoming events (>= now, ASC);
--                                 0 = past events (< now, DESC)
--              @PageSize   INT  — events per page (default 50,
--                                clamped to 1–200)
--              @Offset     INT  — zero-based row offset for pagination
--                                (default 0)
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
-- HC5 Source:  None — new for HC6 public web (hashruns.org)
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Clamp inputs
    IF @PageSize IS NULL OR @PageSize < 1 OR @PageSize > 200
        SET @PageSize = 50;
    IF @Offset IS NULL OR @Offset < 0
        SET @Offset = 0;

    -- Past events: rolling 1-year window.
    -- Declared once and reused in both the count and data queries so the
    -- optimizer sees the same predicate and the plan is consistent.
    DECLARE @PastWindowStart DATETIMEOFFSET = DATEADD(DAY, -365, SYSDATETIMEOFFSET());

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
      AND  (   (@IsFuture = 1 AND e.EventStartDatetime >= SYSDATETIMEOFFSET())
            OR (@IsFuture = 0 AND e.EventStartDatetime >= @PastWindowStart
                              AND e.EventStartDatetime <  SYSDATETIMEOFFSET()));

    -- ── Rowset 1: events with kennel context ─────────────────────────────────

    SELECT
        -- ── Event identity ───────────────────────────────────────────────────
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- ── Timing ──────────────────────────────────────────────────────────
        e.EventStartDatetime,
        e.EventEndDatetime,

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
    WHERE  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  k.deleted   = 0
      AND  k.removed   = 0
      AND  (   (@IsFuture = 1 AND e.EventStartDatetime >= SYSDATETIMEOFFSET())
            OR (@IsFuture = 0 AND e.EventStartDatetime >= @PastWindowStart
                              AND e.EventStartDatetime <  SYSDATETIMEOFFSET()))
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
