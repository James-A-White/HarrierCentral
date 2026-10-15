CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getKennelRunsFeed]
    @kennelUniqueShortName NVARCHAR(50) = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getKennelRunsFeed
-- Description: Everything a kennel's iCal feed (/<slug>/runs.ics, E3.F6.S8)
--              needs, in ONE call: the kennel's header row and its runs from
--              30 days ago onwards. A procedure of its own, not a reuse of
--              publicWeb_getEvents (James, 2026-10-15): the feed is read by
--              every subscriber's calendar app, so it is kept small, and a
--              change made for the site's run lists must not change it by
--              accident. Only the columns the calendar writes are returned.
-- Parameters:  @kennelUniqueShortName NVARCHAR(50) — the URL slug
--              (HC.Kennel.KennelUniqueShortName, unique index).
-- Returns:     Rowset 0: KennelFeedHeader — one row, or EMPTY when there is
--                        no such live kennel (the shim answers 404).
--              Rowset 1: FeedRuns — visible, live runs whose start
--                        (EventStartDateTimeGmt) is no more than 30 days
--                        ago, oldest first, at most 500. Empty when the
--                        kennel is Defunct (-1) or Inactive-Hidden (4): the
--                        feed stays valid and its runs leave subscribers'
--                        calendars. A kennel with its website switched off
--                        still has a feed — its run pages still render.
--              On a runtime error: logged to HC.ErrorLog and re-thrown.
-- Cost:        a unique-index seek on the slug, then a seek on
--              IX_Event_Kennel_GmtStart_Visible (KennelId, EventStartDatetimeGmt)
--              plus key lookups for the few dozen rows returned. No COUNT, no
--              per-row subquery. The web caches the answer 15 minutes per
--              kennel, so this runs at most four times an hour per kennel.
-- Idempotency: read-only — no writes.
-- Author:      Harrier Central
-- Created:     2026-10-15
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None — new procedure.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE @kennelId         UNIQUEIDENTIFIER,
            @kennelStatus     INT,
            @kennelPackOff    SMALLINT,
            @cityId           UNIQUEIDENTIFIER;

    SELECT @kennelId      = k.id,
           @kennelStatus  = k.KennelStatus,
           @kennelPackOff = k.PackOffMinutes,
           @cityId        = k.CityId
    FROM   HC.Kennel k
    WHERE  k.KennelUniqueShortName = @kennelUniqueShortName
      AND  k.deleted = 0
      AND  k.removed = 0;

    IF @kennelId IS NULL
    BEGIN
        -- Empty rowset 0 → the shim answers 404.
        SELECT TOP 0 CAST(NULL AS NVARCHAR(200)) AS KennelName;
        RETURN;
    END;

    -- The kennel's IANA zone, for the gather / pack-off times written into
    -- each run's description (the instants themselves are UTC).
    DECLARE @ianaTimezone NVARCHAR(100);
    SELECT TOP 1 @ianaTimezone = tzm.IANATimeZone
    FROM   HC.City c
    JOIN   DomainValues.Timezone    tz  ON tz.id               = c.TimezoneId
    JOIN   DomainValues.TimeZoneMap tzm ON tzm.WindowsTimeZone = tz.Timezone COLLATE DATABASE_DEFAULT
    WHERE  c.id = @cityId
    ORDER  BY CASE WHEN tzm.territory = '001' THEN 0 ELSE 1 END, tzm.territory;

    DECLARE @feedActive SMALLINT = CASE WHEN ISNULL(@kennelStatus, 2) IN (-1, 4) THEN 0 ELSE 1 END;
    DECLARE @since DATETIMEOFFSET = DATEADD(DAY, -30, SYSDATETIMEOFFSET() AT TIME ZONE 'UTC');

    -- ── Rowset 0: KennelFeedHeader ──────────────────────────────────────
    SELECT k.KennelName,
           k.KennelShortName,
           kw.CustomDomain,
           @ianaTimezone AS KennelIANATimezone,
           @feedActive   AS FeedActive
    FROM   HC.Kennel k
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE  k.id = @kennelId;

    -- ── Rowset 1: FeedRuns ──────────────────────────────────────────────
    SELECT TOP (500)
           LOWER(CAST(e.PublicEventId AS NVARCHAR(40)))   AS PublicEventId,
           e.EventNumber,
           e.EventName,
           -- The instant (/hc-event-datetimes): never the raw EventStartDatetime.
           e.EventStartDatetimeGmt,
           -- Wall clock, for the run's length only (end − start).
           e.EventStartLocal,
           CAST(e.EventEndDatetime AS DATETIME2(7))        AS EventEndLocal,
           COALESCE(e.PackOffMinutes, @kennelPackOff)      AS PackOffMinutes,
           e.Hares,
           e.LocationOneLineDesc,
           e.SyncLocationStreet                            AS LocationStreet,
           e.SyncLocationCity                              AS LocationCity,
           e.SyncLocationPostCode                          AS LocationPostCode,
           e.SyncLocationCountry                           AS LocationCountry,
           e.SyncLatitude                                  AS Latitude,
           e.SyncLongitude                                 AS Longitude,
           e.SyncDescription                               AS EventDescription,
           e.updatedAt                                     AS UpdatedAt
    FROM   HC.Event e
    WHERE  @feedActive = 1
      AND  e.KennelId  = @kennelId
      AND  e.IsVisible = 1
      AND  e.deleted   = 0
      AND  e.removed   = 0
      AND  e.EventStartDatetimeGmt >= @since
    ORDER  BY e.EventStartDatetimeGmt ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in getKennelRunsFeed', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
