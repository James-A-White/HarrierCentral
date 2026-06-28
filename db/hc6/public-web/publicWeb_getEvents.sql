CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getEvents]
    @PublicKennelId    NVARCHAR(50),
    @IsFuture          SMALLINT,
    @MaxEvents         INT           = NULL,
    @DateCutoff        NVARCHAR(50)  = NULL,
    @DaysOffset        INT           = NULL,
    @SummaryOnly       SMALLINT      = 0
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getEvents
-- Description: Returns upcoming or past events for a kennel, optionally
--              limited by count, absolute date cutoff, or relative days.
--              Returns two rowsets:
--                Rowset 0: { TotalMatchingEvents INT } — always 1 row
--                          when the kennel is found. Empty (0 rows) when
--                          the kennel does not exist → shim returns 404.
--                Rowset 1: event rows (may be empty when no events match).
--              This two-rowset design allows Rowset 1 to be empty without
--              the shim misreading it as a 404.
-- Parameters:  @PublicKennelId   NVARCHAR(50)  — HC.Kennel.PublicKennelId
--              @IsFuture         SMALLINT      — 1=upcoming, 0=past
--              @MaxEvents        INT  (opt)    — return up to N events
--              @DateCutoff       NVARCHAR(50) (opt) — absolute far boundary
--                                               (ISO 8601, e.g. 2027-01-01)
--              @DaysOffset       INT  (opt)    — relative boundary in days
--                                               from today (always positive;
--                                               direction from @IsFuture)
--              @SummaryOnly      SMALLINT (opt) — when 1, nulls out heavy text
--                                               fields (EventDescription,
--                                               EventUrl, w3wJson) for list views
--              Rules:
--                - At least one of @MaxEvents, @DateCutoff, @DaysOffset
--                  must be supplied.
--                - @DateCutoff and @DaysOffset are mutually exclusive.
--                - @MaxEvents and a date param may be combined (AND logic).
-- Returns:     Rowset 0: { TotalMatchingEvents INT }
--              Rowset 1: one row per event — see column list below.
--              On validation or runtime error: { Success=0, ErrorMessage }.
-- Author:      Harrier Central
-- Created:     2026-03-28
-- Updated:     2026-04-05 — Fee columns now COALESCE event-level override with
--                           kennel defaults (DefaultEventPriceForMembers/NonMembers/
--                           CurrencyType). Event fee fields are NULL when the event
--                           uses the kennel default; non-NULL only for per-event
--                           overrides. Column names and types are unchanged.
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None — column names unchanged; values now non-null when kennel
--                   has a default fee set.
-- Updated:     2026-05-03 — timezone-aware future/past boundary using
--                           EventStartDateTimeGmt; 8-hour grace window for
--                           future runs; overlap between lists allowed.
-- Updated:     2026-05-04 — return EventStartDatetimeGmt and KennelIANATimezone so
--                           the browser can display both kennel-local and viewer-local
--                           times; cast EventStartDatetime to datetime2(7) to strip
--                           the spurious +00:00 offset stored by SQL Server when no
--                           offset is supplied on insert. Also capture @WindowsTimezone
--                           alongside @IANATimezone so EventStartDatetimeGmt can be
--                           computed on-the-fly for runs where the trigger has not yet
--                           populated it (COALESCE fallback via AT TIME ZONE).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- ── Input validation ─────────────────────────────────────────────────────

    IF LEN(LTRIM(RTRIM(ISNULL(@PublicKennelId, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'PublicKennelId is required.' AS ErrorMessage;
        RETURN;
    END;

    IF @MaxEvents IS NULL AND @DateCutoff IS NULL AND @DaysOffset IS NULL
    BEGIN
        SELECT 0 AS Success,
               'At least one of MaxEvents, DateCutoff, or DaysOffset is required.'
               AS ErrorMessage;
        RETURN;
    END;

    IF @DateCutoff IS NOT NULL AND @DaysOffset IS NOT NULL
    BEGIN
        SELECT 0 AS Success,
               'DateCutoff and DaysOffset are mutually exclusive.' AS ErrorMessage;
        RETURN;
    END;

    IF @MaxEvents IS NOT NULL AND @MaxEvents <= 0
    BEGIN
        SELECT 0 AS Success, 'MaxEvents must be greater than zero.' AS ErrorMessage;
        RETURN;
    END;

    IF @DaysOffset IS NOT NULL AND @DaysOffset <= 0
    BEGIN
        SELECT 0 AS Success, 'DaysOffset must be greater than zero.' AS ErrorMessage;
        RETURN;
    END;

    -- ── Resolve kennel ───────────────────────────────────────────────────────

    DECLARE @KennelId UNIQUEIDENTIFIER;

    SELECT @KennelId = k.id
    FROM   HC.Kennel k
    WHERE  k.PublicKennelId = CONVERT(UNIQUEIDENTIFIER, @PublicKennelId)
      AND  k.deleted = 0
      AND  k.removed = 0;

    IF @KennelId IS NULL
    BEGIN
        -- Empty Rowset 0 → shim treats as 404 (kennel not found or inactive).
        SELECT TOP 0 CAST(NULL AS INT) AS TotalMatchingEvents;
        RETURN;
    END;

    -- ── Kennel IANA timezone ─────────────────────────────────────────────────────
    -- Passed through to the browser so it can format EventStartDatetimeGmt in
    -- the kennel's local timezone (e.g. "Asia/Tokyo"). territory = '001' is the
    -- primary/global CLDR mapping; fall back to any territory if absent.

    DECLARE @IANATimezone    NVARCHAR(MAX) = NULL;
    DECLARE @WindowsTimezone NVARCHAR(300) = NULL;

    SELECT TOP 1
        @IANATimezone    = tzm.IANATimeZone,
        @WindowsTimezone = tz.Timezone
    FROM   HC.City                  c
    JOIN   DomainValues.Timezone    tz  ON tz.id               = c.TimezoneId
    JOIN   DomainValues.TimeZoneMap tzm ON tzm.WindowsTimeZone = tz.Timezone COLLATE DATABASE_DEFAULT
    WHERE  c.id = (SELECT CityId FROM HC.Kennel WHERE id = @KennelId)
    ORDER  BY CASE WHEN tzm.territory = '001' THEN 0 ELSE 1 END, tzm.territory;

    -- ── Kennel-level fee defaults ────────────────────────────────────────────
    -- Event fee fields are NULL when the event uses the kennel's default fee.
    -- Resolved here so Rowset 1 can COALESCE without an extra join.

    DECLARE @DefaultPriceForMembers    DECIMAL(10,4);
    DECLARE @DefaultPriceForNonMembers DECIMAL(10,4);
    DECLARE @DefaultCurrencyType       NVARCHAR(10);

    SELECT @DefaultPriceForMembers    = k.DefaultEventPriceForMembers,
           @DefaultPriceForNonMembers = k.DefaultEventPriceForNonMembers,
           @DefaultCurrencyType       = k.DefaultEventCurrencyType
    FROM   HC.Kennel k
    WHERE  k.id = @KennelId;

    -- ── Compute boundary date ────────────────────────────────────────────────

    -- Current UTC time for timezone-aware future/past comparisons.
    -- EventStartDateTimeGmt holds the true UTC equivalent of the local run start
    -- (trigger: Kennel→City→Timezone). Falls back to EventStartDatetime when NULL.
    DECLARE @UtcNow         DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'UTC';
    DECLARE @FutureCutoff   DATETIMEOFFSET = DATEADD(HOUR, -8, @UtcNow);

    DECLARE @BoundaryDate DATETIMEOFFSET(7) = NULL;

    IF @DateCutoff IS NOT NULL
        SET @BoundaryDate = CONVERT(DATETIMEOFFSET(7), @DateCutoff);
    ELSE IF @DaysOffset IS NOT NULL
        SET @BoundaryDate = DATEADD(DAY,
                                CASE WHEN @IsFuture = 1
                                     THEN  @DaysOffset
                                     ELSE -@DaysOffset
                                END,
                                @UtcNow);

    -- ── TOP cap (INT max when no explicit limit) ─────────────────────────────

    DECLARE @TopN INT = COALESCE(@MaxEvents, 2147483647);

    -- ── Rowset 0: count of all matching events ───────────────────────────────
    -- Always exactly 1 row (COUNT never returns empty), preventing a false 404
    -- when there are simply no upcoming events for this kennel.

    SELECT COUNT(*) AS TotalMatchingEvents
    FROM   HC.Event e
    WHERE  e.KennelId  = @KennelId
      AND  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  (   (@IsFuture = 1
                    AND e.EventStartDateTimeGmt >= @FutureCutoff)
            OR (@IsFuture = 0
                    AND e.EventStartDateTimeGmt < @UtcNow))
      AND  (   @BoundaryDate IS NULL
            OR (@IsFuture = 1
                    AND e.EventStartDateTimeGmt <= @BoundaryDate)
            OR (@IsFuture = 0
                    AND e.EventStartDateTimeGmt >= @BoundaryDate));

    -- ── Rowset 1: events ─────────────────────────────────────────────────────

-- Split by direction so a plain ORDER BY can be served by an index
    -- (no Sort operator). Filter/order by EventStartDateTimeGmt — the true UTC instant,
    -- now guaranteed non-null by trigger — so no NULL-fallback is needed and the seek is sort-free. WHERE pruned per branch.
    IF @IsFuture = 1
    SELECT TOP (@TopN)

        -- Identity
        e.id            AS EventId,
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- Timing
        -- EventStartDatetime cast to datetime2(7): strips the spurious +00:00 stored
        -- by SQL Server when the portal inserts local time without an offset. The
        -- browser uses EventStartDatetimeGmt + KennelIANATimezone for display.
        CAST(e.EventStartDatetime AS datetime2(7)) AS EventStartDatetime,
        CAST(e.EventEndDatetime   AS datetime2(7)) AS EventEndDatetime,
        -- COALESCE: use stored GMT value when available (trigger-populated).
        -- Fall back to computing it on-the-fly via AT TIME ZONE for older runs
        -- where the trigger had not yet run (EventStartDatetimeGmt IS NULL).
        COALESCE(
            e.EventStartDatetimeGmt,
            CASE WHEN @WindowsTimezone IS NOT NULL
                 THEN CAST(
                          (CAST(e.EventStartDatetime AS datetime)
                               AT TIME ZONE @WindowsTimezone)
                          AT TIME ZONE 'UTC'
                      AS datetimeoffset(7))
                 ELSE NULL
            END
        )                                          AS EventStartDatetimeGmt,
        @IANATimezone                              AS KennelIANATimezone,

        -- Event type display name (NULL when ThemeRunType has no matching row)
        ett.EventEnumName        AS EventTypeName,

        -- Fees: event-level value overrides the kennel default; fall back to
        -- kennel default when the event has no explicit fee set (NULL).
        COALESCE(e.EventPriceForMembers,    @DefaultPriceForMembers)    AS EventPriceForMembers,
        COALESCE(e.EventPriceForNonMembers, @DefaultPriceForNonMembers) AS EventPriceForNonMembers,
        COALESCE(e.EventCurrencyType,       @DefaultCurrencyType)       AS EventCurrencyType,

        -- People
        e.Hares,

        -- Location — Sync* computed columns handle the Facebook data override
        e.LocationOneLineDesc,
        e.SyncLocationStreet     AS LocationStreet,
        e.SyncLocationCity       AS LocationCity,
        e.SyncLocationPostCode   AS LocationPostCode,
        e.SyncLocationRegion     AS LocationRegion,
        e.SyncLocationCountry    AS LocationCountry,
        e.SyncLatitude           AS Latitude,
        e.SyncLongitude          AS Longitude,
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.w3wJson           END AS w3wJson,

        -- Content (heavy fields nulled when @SummaryOnly = 1)
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.SyncDescription  END AS EventDescription,
        e.EventImage,
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.EventUrl          END AS EventUrl,

        -- Tags (raw bitflags — decoded on the client using the RunTag enum)
        e.Tags1,
        e.Tags2,
        e.Tags3,

        -- Metadata
        e.IsCountedRun,
        e.IsPromotedEvent,
        e.EventGeographicScope

    FROM  HC.Event e
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    WHERE  e.KennelId  = @KennelId
      AND  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND e.EventStartDateTimeGmt >= @FutureCutoff
      AND (@BoundaryDate IS NULL OR e.EventStartDateTimeGmt <= @BoundaryDate)
    ORDER BY e.EventStartDateTimeGmt ASC;
    ELSE
    SELECT TOP (@TopN)

        -- Identity
        e.id            AS EventId,
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- Timing
        -- EventStartDatetime cast to datetime2(7): strips the spurious +00:00 stored
        -- by SQL Server when the portal inserts local time without an offset. The
        -- browser uses EventStartDatetimeGmt + KennelIANATimezone for display.
        CAST(e.EventStartDatetime AS datetime2(7)) AS EventStartDatetime,
        CAST(e.EventEndDatetime   AS datetime2(7)) AS EventEndDatetime,
        -- COALESCE: use stored GMT value when available (trigger-populated).
        -- Fall back to computing it on-the-fly via AT TIME ZONE for older runs
        -- where the trigger had not yet run (EventStartDatetimeGmt IS NULL).
        COALESCE(
            e.EventStartDatetimeGmt,
            CASE WHEN @WindowsTimezone IS NOT NULL
                 THEN CAST(
                          (CAST(e.EventStartDatetime AS datetime)
                               AT TIME ZONE @WindowsTimezone)
                          AT TIME ZONE 'UTC'
                      AS datetimeoffset(7))
                 ELSE NULL
            END
        )                                          AS EventStartDatetimeGmt,
        @IANATimezone                              AS KennelIANATimezone,

        -- Event type display name (NULL when ThemeRunType has no matching row)
        ett.EventEnumName        AS EventTypeName,

        -- Fees: event-level value overrides the kennel default; fall back to
        -- kennel default when the event has no explicit fee set (NULL).
        COALESCE(e.EventPriceForMembers,    @DefaultPriceForMembers)    AS EventPriceForMembers,
        COALESCE(e.EventPriceForNonMembers, @DefaultPriceForNonMembers) AS EventPriceForNonMembers,
        COALESCE(e.EventCurrencyType,       @DefaultCurrencyType)       AS EventCurrencyType,

        -- People
        e.Hares,

        -- Location — Sync* computed columns handle the Facebook data override
        e.LocationOneLineDesc,
        e.SyncLocationStreet     AS LocationStreet,
        e.SyncLocationCity       AS LocationCity,
        e.SyncLocationPostCode   AS LocationPostCode,
        e.SyncLocationRegion     AS LocationRegion,
        e.SyncLocationCountry    AS LocationCountry,
        e.SyncLatitude           AS Latitude,
        e.SyncLongitude          AS Longitude,
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.w3wJson           END AS w3wJson,

        -- Content (heavy fields nulled when @SummaryOnly = 1)
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.SyncDescription  END AS EventDescription,
        e.EventImage,
        CASE WHEN @SummaryOnly = 1 THEN NULL ELSE e.EventUrl          END AS EventUrl,

        -- Tags (raw bitflags — decoded on the client using the RunTag enum)
        e.Tags1,
        e.Tags2,
        e.Tags3,

        -- Metadata
        e.IsCountedRun,
        e.IsPromotedEvent,
        e.EventGeographicScope

    FROM  HC.Event e
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    WHERE  e.KennelId  = @KennelId
      AND  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND e.EventStartDateTimeGmt < @UtcNow
      AND (@BoundaryDate IS NULL OR e.EventStartDateTimeGmt >= @BoundaryDate)
    ORDER BY e.EventStartDateTimeGmt DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
