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
    -- Date filtering uses EventStartLocalDate, a PERSISTED computed column
    -- holding CAST(EventStartDatetime AS DATE) — the LOCAL event date as
    -- stored in the datetimeoffset value. Filtering/grouping on the stored
    -- column (rather than CAST() inline) is sargable, so the filtered index
    -- IX_Event_LocalDate_Visible serves this query as a seek instead of a
    -- full scan of HC.Event. Day-boundary semantics are identical to the
    -- previous CAST(EventStartDatetime AS DATE).
    -- GROUP BY instead of DISTINCT so we can expose EventNumber.
    -- When a kennel has multiple events on the same day, MIN(EventNumber)
    -- picks the first counted run for the link target.
    SELECT
        e.EventStartLocalDate               AS EventDate,
        k.KennelUniqueShortName             AS KennelSlug,
        k.KennelName,
        k.KennelLogo                        AS KennelLogo,
        kw.PrimaryColor,
        k.PublicKennelId,
        MIN(e.EventNumber)                  AS EventNumber
    FROM  HC.Event         e
    JOIN  HC.Kennel        k  ON k.id        = e.KennelId
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE e.EventStartLocalDate >= @fromDate
      AND e.EventStartLocalDate  < DATEADD(DAY, @daysLimit, @fromDate)
      AND e.deleted   = 0
      AND e.removed   = 0
      AND e.IsVisible = 1
      AND k.deleted   = 0
      AND k.removed   = 0
    GROUP BY
        e.EventStartLocalDate,
        k.KennelUniqueShortName,
        k.KennelName,
        k.KennelLogo,
        kw.PrimaryColor,
        k.PublicKennelId
    ORDER BY EventDate, KennelName;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
