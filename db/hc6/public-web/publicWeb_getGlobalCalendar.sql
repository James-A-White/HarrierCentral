CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getGlobalCalendar]
    @fromDate  DATE    = NULL,
    @daysLimit INT     = 30
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getGlobalCalendar
-- Description: Returns one row per (event date, kennel) for all kennels
--              with publicly visible events in the given date window.
--              Used by the harriercentral.com global run calendar page
--              to show upcoming hash runs across all kennels.
-- Parameters:  @fromDate   DATE — start date (inclusive); defaults to
--                                 today (UTC) if NULL
--              @daysLimit  INT  — number of days to include (default 30,
--                                 clamped to 1–365 if out of range)
-- Returns:     Rowset 0: sentinel (CalendarAvailable = 1) — always one
--                        row so the shim never returns HTTP 404 for an
--                        empty date window.
--              Rowset 1: one row per (EventDate, Kennel) combination,
--                        ordered by EventDate ASC, KennelName ASC.
--                        Empty = no events in the given window (not an error).
-- Author:      Harrier Central
-- Created:     2026-04-04
-- HC5 Source:  None — new for HC6 global calendar
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Default and clamp inputs
    IF @fromDate IS NULL
        SET @fromDate = CAST(GETUTCDATE() AS DATE);

    IF @daysLimit IS NULL OR @daysLimit < 1 OR @daysLimit > 365
        SET @daysLimit = 30;

    -- Sentinel: always one row so the shim does not emit HTTP 404 on an
    -- empty calendar window (empty = no events, not a missing resource).
    SELECT 1 AS CalendarAvailable;

    -- One row per (event date, kennel). DISTINCT collapses multiple events
    -- on the same day for the same kennel into a single calendar entry.
    --
    -- LEFT JOIN on HC.KennelWebsite so kennels without a configured HC6
    -- website row are still included — logo and colour will be NULL and the
    -- frontend falls back to an initial-letter placeholder.
    --
    -- Date filtering uses CAST on EventStartDatetime so the local event date
    -- (as stored in the datetimeoffset value) is used for grouping, which is
    -- consistent with what the SELECT returns in EventDate.
    -- GROUP BY instead of DISTINCT so we can expose EventNumber.
    -- When a kennel has multiple events on the same day, MIN(EventNumber)
    -- picks the first counted run for the link target.
    SELECT
        CAST(e.EventStartDatetime AS DATE)  AS EventDate,
        k.KennelUniqueShortName             AS KennelSlug,
        k.KennelName,
        kw.LogoUrl                          AS KennelLogo,
        kw.PrimaryColor,
        k.PublicKennelId,
        MIN(e.EventNumber)                  AS EventNumber
    FROM  HC.Event         e
    JOIN  HC.Kennel        k  ON k.id        = e.KennelId
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE CAST(e.EventStartDatetime AS DATE) >= @fromDate
      AND CAST(e.EventStartDatetime AS DATE)  < DATEADD(DAY, @daysLimit, @fromDate)
      AND e.deleted   = 0
      AND e.removed   = 0
      AND e.IsVisible = 1
      AND k.deleted   = 0
      AND k.removed   = 0
    GROUP BY
        CAST(e.EventStartDatetime AS DATE),
        k.KennelUniqueShortName,
        k.KennelName,
        kw.LogoUrl,
        kw.PrimaryColor,
        k.PublicKennelId
    ORDER BY EventDate, KennelName;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
