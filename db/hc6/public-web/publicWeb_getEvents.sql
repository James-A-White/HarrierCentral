CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getEvents]
    @PublicKennelId    NVARCHAR(50),
    @IsFuture          BIT,
    @MaxEvents         INT           = NULL,
    @DateCutoff        NVARCHAR(50)  = NULL,
    @DaysOffset        INT           = NULL
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
--              @IsFuture         BIT           — 1=upcoming, 0=past
--              @MaxEvents        INT  (opt)    — return up to N events
--              @DateCutoff       NVARCHAR(50) (opt) — absolute far boundary
--                                               (ISO 8601, e.g. 2027-01-01)
--              @DaysOffset       INT  (opt)    — relative boundary in days
--                                               from today (always positive;
--                                               direction from @IsFuture)
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
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None
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

    -- ── Compute boundary date ────────────────────────────────────────────────

    DECLARE @BoundaryDate DATETIMEOFFSET(7) = NULL;

    IF @DateCutoff IS NOT NULL
        SET @BoundaryDate = CONVERT(DATETIMEOFFSET(7), @DateCutoff);
    ELSE IF @DaysOffset IS NOT NULL
        SET @BoundaryDate = DATEADD(DAY,
                                CASE WHEN @IsFuture = 1
                                     THEN  @DaysOffset
                                     ELSE -@DaysOffset
                                END,
                                SYSDATETIMEOFFSET());

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
      AND  (   (@IsFuture = 1 AND e.EventStartDatetime >= SYSDATETIMEOFFSET())
            OR (@IsFuture = 0 AND e.EventStartDatetime <  SYSDATETIMEOFFSET()))
      AND  (   @BoundaryDate IS NULL
            OR (@IsFuture = 1 AND e.EventStartDatetime <= @BoundaryDate)
            OR (@IsFuture = 0 AND e.EventStartDatetime >= @BoundaryDate));

    -- ── Rowset 1: events ─────────────────────────────────────────────────────

    SELECT TOP (@TopN)

        -- Identity
        e.PublicEventId,
        e.EventNumber,
        e.EventName,

        -- Timing
        e.EventStartDatetime,
        e.EventEndDatetime,

        -- Event type display name (NULL when ThemeRunType has no matching row)
        ett.EventEnumName        AS EventTypeName,

        -- Fees
        e.EventPriceForMembers,
        e.EventPriceForNonMembers,
        e.EventCurrencyType,

        -- People
        e.Hares,

        -- Location — Sync* computed columns handle the Facebook data override
        e.LocationOneLineDesc,
        e.SyncLocationStreet     AS LocationStreet,
        e.SyncLocationCity       AS LocationCity,
        e.SyncLocationPostCode   AS LocationPostCode,
        e.SyncLatitude           AS Latitude,
        e.SyncLongitude          AS Longitude,
        e.w3wJson,

        -- Content
        e.SyncDescription        AS EventDescription,
        e.EventImage,
        e.EventUrl,

        -- Tags (raw bitflags — decoded on the client using the RunTag enum)
        e.Tags1,
        e.Tags2,
        e.Tags3,

        -- Metadata
        e.IsCountedRun

    FROM  HC.Event e
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    WHERE  e.KennelId  = @KennelId
      AND  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  (   (@IsFuture = 1 AND e.EventStartDatetime >= SYSDATETIMEOFFSET())
            OR (@IsFuture = 0 AND e.EventStartDatetime <  SYSDATETIMEOFFSET()))
      AND  (   @BoundaryDate IS NULL
            OR (@IsFuture = 1 AND e.EventStartDatetime <= @BoundaryDate)
            OR (@IsFuture = 0 AND e.EventStartDatetime >= @BoundaryDate))
    ORDER BY
        -- Upcoming: earliest first; past: most recent first.
        -- Only one branch is active per call; the other evaluates to NULL
        -- for every row and contributes nothing to the sort.
        CASE WHEN @IsFuture = 1 THEN e.EventStartDatetime END ASC,
        CASE WHEN @IsFuture = 0 THEN e.EventStartDatetime END DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
