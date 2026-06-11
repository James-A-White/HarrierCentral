CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMultiKennelRuns]
    @SlugList    NVARCHAR(MAX),
    @IsFuture    SMALLINT,
    @MaxEvents   INT = NULL,
    @DaysOffset  INT = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMultiKennelRuns
-- Description: Returns upcoming or past events for a comma-separated
--              list of kennel slugs (KennelUniqueShortName). Each event
--              row includes kennel name, logo, and theme colours so
--              mixed-kennel lists can render kennel badges without a
--              second API call. Invalid/unknown/deleted slugs are
--              silently ignored.
--              Returns two rowsets:
--                Rowset 0: { TotalMatchingEvents INT } — always 1 row
--                Rowset 1: event rows with kennel context columns
-- Parameters:  @SlugList   NVARCHAR(MAX) — comma-separated KennelUniqueShortName values
--              @IsFuture   SMALLINT      — 1=upcoming, 0=past
--              @MaxEvents  INT  (opt)    — cap total events returned
--              @DaysOffset INT  (opt)    — relative boundary in days from
--                                         today (always positive; direction
--                                         from @IsFuture)
-- Returns:     Rowset 0: { TotalMatchingEvents INT }
--              Rowset 1: one row per event — see column list below
-- Author:      Harrier Central
-- Created:     2026-05-10
-- HC5 Source:  None — new for HC6 RunListBlock multi-kennel support
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- ── Input validation ─────────────────────────────────────────────────────

    IF LEN(LTRIM(RTRIM(ISNULL(@SlugList, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'SlugList is required.' AS ErrorMessage;
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

    -- ── Resolve valid kennels from slug list ─────────────────────────────────
    -- Kennels are resolved here so each event row can carry its kennel's
    -- name, logo, colours, and IANA timezone without per-row joins.
    -- Invalid/deleted slugs produce no rows and are silently skipped.

    CREATE TABLE #ValidKennels (
        KennelId                  UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        KennelSlug                NVARCHAR(50)     NOT NULL,
        KennelName                NVARCHAR(250)    NOT NULL,
        KennelShortName           NVARCHAR(25)     NOT NULL,
        KennelLogo                NVARCHAR(500)    NULL,
        PrimaryColor              NVARCHAR(25)     NULL,
        AccentColor               NVARCHAR(25)     NULL,
        DefaultPriceForMembers    DECIMAL(10,4)    NULL,
        DefaultPriceForNonMembers DECIMAL(10,4)    NULL,
        DefaultCurrencyType       NVARCHAR(10)     NULL,
        IANATimezone              NVARCHAR(MAX)    NULL
    );

    INSERT INTO #ValidKennels (
        KennelId, KennelSlug, KennelName, KennelShortName, KennelLogo,
        PrimaryColor, AccentColor,
        DefaultPriceForMembers, DefaultPriceForNonMembers, DefaultCurrencyType,
        IANATimezone
    )
    SELECT
        k.id,
        k.KennelUniqueShortName,
        k.KennelName,
        k.KennelShortName,
        NULLIF(k.KennelLogo, N'bundle://defaultKennelLogo'),
        kw.PrimaryColor,
        kw.AccentColor,
        k.DefaultEventPriceForMembers,
        k.DefaultEventPriceForNonMembers,
        k.DefaultEventCurrencyType,
        (
            SELECT TOP 1 tzm.IANATimeZone
            FROM   HC.City                  c
            JOIN   DomainValues.Timezone    tz  ON tz.id               = c.TimezoneId
            JOIN   DomainValues.TimeZoneMap tzm ON tzm.WindowsTimeZone = tz.Timezone COLLATE DATABASE_DEFAULT
            WHERE  c.id = k.CityId
            ORDER BY CASE WHEN tzm.territory = '001' THEN 0 ELSE 1 END, tzm.territory
        )
    FROM HC.Kennel k
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE k.KennelUniqueShortName IN (
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@SlugList, ',')
    )
    AND k.deleted = 0
    AND k.removed = 0;

    -- ── Boundary calculation ─────────────────────────────────────────────────

    DECLARE @UtcNow       DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'UTC';
    DECLARE @FutureCutoff DATETIMEOFFSET = DATEADD(HOUR, -8, @UtcNow);

    DECLARE @BoundaryDate DATETIMEOFFSET(7) = NULL;
    IF @DaysOffset IS NOT NULL
        SET @BoundaryDate = DATEADD(DAY,
                                CASE WHEN @IsFuture = 1 THEN @DaysOffset ELSE -@DaysOffset END,
                                @UtcNow);

    DECLARE @TopN INT = COALESCE(@MaxEvents, 2147483647);

    -- ── Rowset 0: total count ────────────────────────────────────────────────
    -- Always exactly 1 row so the shim never misreads an empty result as 404.

    SELECT COUNT(*) AS TotalMatchingEvents
    FROM   HC.Event e
    JOIN   #ValidKennels vk ON vk.KennelId = e.KennelId
    WHERE  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  (   (@IsFuture = 1
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @FutureCutoff)
            OR (@IsFuture = 0
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) < @UtcNow))
      AND  (   @BoundaryDate IS NULL
            OR (@IsFuture = 1
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) <= @BoundaryDate)
            OR (@IsFuture = 0
                    AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @BoundaryDate));

    -- ── Rowset 1: events with kennel context ─────────────────────────────────

    SELECT TOP (@TopN)

        -- Kennel context (for badges in mixed-kennel lists)
        vk.KennelSlug,
        vk.KennelName,
        vk.KennelShortName,
        vk.KennelLogo,
        vk.PrimaryColor  AS KennelPrimaryColor,
        vk.AccentColor   AS KennelAccentColor,

        -- Identity
        e.id            AS EventId,
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- Timing
        CAST(e.EventStartDatetime AS datetime2(7)) AS EventStartDatetime,
        CAST(e.EventEndDatetime   AS datetime2(7)) AS EventEndDatetime,
        e.EventStartDatetimeGmt,
        vk.IANATimezone                            AS KennelIANATimezone,

        -- Event type
        ett.EventEnumName AS EventTypeName,

        -- Fees (event-level overrides kennel default)
        COALESCE(e.EventPriceForMembers,    vk.DefaultPriceForMembers)    AS EventPriceForMembers,
        COALESCE(e.EventPriceForNonMembers, vk.DefaultPriceForNonMembers) AS EventPriceForNonMembers,
        COALESCE(e.EventCurrencyType,       vk.DefaultCurrencyType)       AS EventCurrencyType,

        -- People
        e.Hares,

        -- Location
        e.LocationOneLineDesc,
        e.SyncLocationStreet   AS LocationStreet,
        e.SyncLocationCity     AS LocationCity,
        e.SyncLocationPostCode AS LocationPostCode,
        e.SyncLocationRegion   AS LocationRegion,
        e.SyncLocationCountry  AS LocationCountry,
        e.SyncLatitude         AS Latitude,
        e.SyncLongitude        AS Longitude,
        NULL                   AS w3wJson,
        NULL                   AS EventDescription,
        e.EventImage,
        NULL                   AS EventUrl,

        -- Tags (raw bitflags — decoded client-side)
        e.Tags1,
        e.Tags2,
        e.Tags3,

        -- Metadata
        e.IsCountedRun,
        e.IsPromotedEvent,
        e.EventGeographicScope

    FROM  HC.Event e
    JOIN  #ValidKennels vk ON vk.KennelId = e.KennelId
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    WHERE e.IsVisible = 1
      AND e.deleted   = 0
      AND e.removed   = 0
      AND (   (@IsFuture = 1
                   AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @FutureCutoff)
           OR (@IsFuture = 0
                   AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) < @UtcNow))
      AND (   @BoundaryDate IS NULL
           OR (@IsFuture = 1
                   AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) <= @BoundaryDate)
           OR (@IsFuture = 0
                   AND COALESCE(e.EventStartDateTimeGmt, e.EventStartDatetime) >= @BoundaryDate))
    ORDER BY
        CASE WHEN @IsFuture = 1 THEN e.EventStartDatetime END ASC,
        CASE WHEN @IsFuture = 0 THEN e.EventStartDatetime END DESC;

    DROP TABLE #ValidKennels;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID('tempdb..#ValidKennels') IS NOT NULL DROP TABLE #ValidKennels;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
