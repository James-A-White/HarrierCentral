CREATE OR ALTER PROCEDURE [HC6].[nonApi_importRunsPageRuns]
    @kennelId UNIQUEIDENTIFIER = NULL,
    @runsJson NVARCHAR(MAX)    = NULL,
    @dryRun   SMALLINT         = 0      -- 1 = work it all out, report, write nothing (the portal's Test)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_importRunsPageRuns
-- Description: Writes the runs the API read off a kennel's runs page
--   (RunsPageImport, 2026-10-04) into HC.Event, the way every inbound
--   integration does: the source's values go into the Fb* mirror columns
--   with the UseFb* flags on, so the app shows them until a kennel admin
--   chooses their own (switching a flag off), and a later import refreshes
--   only the mirror. InboundIntegrationId = 6 ("Import from kennel runs
--   page"); EventFacebookId = 'runspage:<run number>' identifies the run on
--   that page.
--
--   Rules:
--     * a new run number becomes a run (AbsoluteEventNumber anchors the
--       numbering; nonApi_updateRunNumbers is run for each);
--     * a run number the kennel already has in Harrier Central from any
--       other source is LEFT ALONE (counted as alreadyInHc) — the kennel's
--       own run wins;
--     * an imported run gets its mirror refreshed; its start time and hares
--       only while they still hold what was last imported / the run still
--       shows the source's details (UseFbRunDetails = 1);
--     * nothing is deleted: a run that drops off the page stays.
--   EventStartDatetime is local wall-clock time (+00:00, the house
--   convention); trgUpdateModifiedOnDateForEvent turns it into GMT with the
--   kennel's time zone.
-- Parameters:
--   @runsJson  {"runs":[{"number":3095,"date":"2026-10-06","time":"18:30",
--               "title":"Joint run","hares":"…","start":"Corunna Rd, Eastwood",
--               "lat":-33.78,"lon":151.09,"mapUrl":"https://…",
--               "description":"…","special":1}]}
-- Returns: rowset 0 — { inserted, updated, unchanged, alreadyInHc, rejected }
--          rowset 1 — { EventNumber, Outcome } per run: new | update |
--          unchanged | already in Harrier Central | unreadable
--   @dryRun = 1 (the portal's Test button, 2026-10-04) does everything
--   inside the transaction, reports, and rolls it back.
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
-- A table variable: its rows survive the dry run's ROLLBACK.
DECLARE @out TABLE (EventNumber INT NULL, Outcome NVARCHAR(40));

BEGIN TRY
    IF (@kennelId IS NULL OR ISJSON(@runsJson) <> 1)
    BEGIN
        SELECT 0 AS inserted, 0 AS updated, 0 AS unchanged, 0 AS alreadyInHc, 0 AS rejected;
        SELECT EventNumber, Outcome FROM @out;
        RETURN;
    END

    DECLARE @countryId UNIQUEIDENTIFIER, @defaultTime NVARCHAR(5),
            @priceM DECIMAL(10, 4), @priceNM DECIMAL(10, 4), @currency NVARCHAR(10);
    SELECT @countryId   = k.CountryId,
           @defaultTime = CONVERT(NVARCHAR(5), k.DefaultRunStartTime, 108),
           @priceM      = k.DefaultEventPriceForMembers,
           @priceNM     = k.DefaultEventPriceForNonMembers,
           @currency    = k.DefaultEventCurrencyType
    FROM HC.Kennel k WHERE k.id = @kennelId;

    CREATE TABLE #runs (
        EventNumber INT, ExtId NVARCHAR(250), StartDt DATETIMEOFFSET,
        Name NVARCHAR(250), Hares NVARCHAR(2500), Place NVARCHAR(250),
        Lat DECIMAL(18, 15), Lon DECIMAL(19, 15), MapUrl NVARCHAR(500),
        Descr NVARCHAR(4000), Special SMALLINT, NewId UNIQUEIDENTIFIER);

    INSERT #runs (EventNumber, ExtId, StartDt, Name, Hares, Place, Lat, Lon, MapUrl, Descr, Special)
    SELECT j.number,
           CONCAT(N'runspage:', j.number),
           TRY_CAST(CONCAT(j.runDate, N' ',
                COALESCE(CASE WHEN j.runTime LIKE N'[0-2][0-9]:[0-5][0-9]' THEN j.runTime END,
                         @defaultTime, N'19:00'), N':00 +00:00') AS DATETIMEOFFSET),
           -- No title = "Run N", never the start: a start is often a full
           -- address ("The Red Lion, 92-94 Linkfield Road, Isleworth…") and
           -- it shows on its own line anyway (James, 2026-10-05).
           LEFT(COALESCE(NULLIF(LTRIM(j.title), N''), CONCAT(N'Run ', j.number)), 250),
           -- A placeholder is not a hare: "Hare needed - contact the
           -- Hareraiser", "TBA", "TBC" become no hares (2026-10-05).
           CASE WHEN j.hares LIKE N'%hare%needed%' OR j.hares LIKE N'%hare%wanted%'
                  OR j.hares LIKE N'%hares%required%' OR j.hares LIKE N'%volunteer%'
                  OR LTRIM(RTRIM(j.hares)) IN (N'TBA', N'TBC', N'TBD', N'?', N'-')
                THEN NULL ELSE LEFT(NULLIF(LTRIM(j.hares), N''), 2500) END,
           LEFT(NULLIF(LTRIM(j.start), N''), 250),
           CASE WHEN ABS(j.lat) <= 90 AND ABS(j.lon) <= 180 AND NOT (j.lat = 0 AND j.lon = 0) THEN j.lat END,
           CASE WHEN ABS(j.lat) <= 90 AND ABS(j.lon) <= 180 AND NOT (j.lat = 0 AND j.lon = 0) THEN j.lon END,
           LEFT(NULLIF(j.mapUrl, N''), 500),
           LEFT(NULLIF(j.description, N''), 4000),
           CASE WHEN j.special = 1 THEN 1 ELSE 0 END
    FROM OPENJSON(@runsJson, '$.runs') WITH (
        number INT '$.number', runDate NVARCHAR(10) '$.date', runTime NVARCHAR(5) '$.time',
        title NVARCHAR(500) '$.title', hares NVARCHAR(4000) '$.hares', start NVARCHAR(500) '$.start',
        lat DECIMAL(18, 15) '$.lat', lon DECIMAL(19, 15) '$.lon', mapUrl NVARCHAR(1000) '$.mapUrl',
        description NVARCHAR(MAX) '$.description', special INT '$.special') j;

    -- A run needs a number and a date that is real and not absurdly far off.
    INSERT @out (EventNumber, Outcome) SELECT EventNumber, N'unreadable' FROM #runs
        WHERE EventNumber IS NULL OR EventNumber <= 0 OR StartDt IS NULL
           OR StartDt < DATEADD(YEAR, -1, SYSDATETIMEOFFSET()) OR StartDt > DATEADD(YEAR, 2, SYSDATETIMEOFFSET());
    DECLARE @rejected INT = (SELECT COUNT(*) FROM #runs
        WHERE EventNumber IS NULL OR EventNumber <= 0 OR StartDt IS NULL
           OR StartDt < DATEADD(YEAR, -1, SYSDATETIMEOFFSET()) OR StartDt > DATEADD(YEAR, 2, SYSDATETIMEOFFSET()));
    DELETE #runs
        WHERE EventNumber IS NULL OR EventNumber <= 0 OR StartDt IS NULL
           OR StartDt < DATEADD(YEAR, -1, SYSDATETIMEOFFSET()) OR StartDt > DATEADD(YEAR, 2, SYSDATETIMEOFFSET());
    -- One row per run number (a page that repeats a run keeps its first).
    ;WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY EventNumber ORDER BY StartDt) AS rn FROM #runs)
    DELETE FROM d WHERE rn > 1;

    -- The kennel's own runs win: a number it already has from any other
    -- source is not touched.
    INSERT @out (EventNumber, Outcome) SELECT r.EventNumber, N'already in Harrier Central' FROM #runs r WHERE EXISTS (
        SELECT 1 FROM HC.Event e
        WHERE e.KennelId = @kennelId AND e.deleted = 0 AND e.EventNumber = r.EventNumber
          AND NOT (ISNULL(e.InboundIntegrationId, 0) = 6 AND e.EventFacebookId = r.ExtId));
    DECLARE @alreadyInHc INT = (SELECT COUNT(*) FROM #runs r WHERE EXISTS (
        SELECT 1 FROM HC.Event e
        WHERE e.KennelId = @kennelId AND e.deleted = 0 AND e.EventNumber = r.EventNumber
          AND NOT (ISNULL(e.InboundIntegrationId, 0) = 6 AND e.EventFacebookId = r.ExtId)));
    DELETE r FROM #runs r WHERE EXISTS (
        SELECT 1 FROM HC.Event e
        WHERE e.KennelId = @kennelId AND e.deleted = 0 AND e.EventNumber = r.EventNumber
          AND NOT (ISNULL(e.InboundIntegrationId, 0) = 6 AND e.EventFacebookId = r.ExtId));

    BEGIN TRANSACTION;
    -- A savepoint, so a dry run undoes only its own work even when called
    -- inside someone else's transaction.
    SAVE TRANSACTION runsPageImport;

    -- Refresh the runs this page already brought in.
    DECLARE @updated INT, @matched INT;
    SELECT @matched = COUNT(*) FROM #runs r JOIN HC.Event e
        ON e.KennelId = @kennelId AND e.InboundIntegrationId = 6 AND e.EventFacebookId = r.ExtId AND e.deleted = 0;

    UPDATE e SET
        EventStartDatetime    = CASE WHEN e.EventStartDatetime = e.FbEventStartDatetime THEN r.StartDt ELSE e.EventStartDatetime END,
        FbEventStartDatetime  = r.StartDt,
        FbEventName           = r.Name,
        FbEventDescription    = r.Descr,
        FbLocationOneLineDesc = r.Place,
        FbLatitude            = r.Lat,
        FbLongitude           = r.Lon,
        FbEventMapUrl         = r.MapUrl,
        Hares                 = CASE WHEN e.UseFbRunDetails = 1 THEN r.Hares ELSE e.Hares END,
        EventGeolocation      = CASE WHEN e.UseFbLatLon = 1
                                     THEN CASE WHEN r.Lat IS NOT NULL THEN geography::Point(r.Lat, r.Lon, 4326) END
                                     ELSE e.EventGeolocation END
    OUTPUT r.EventNumber, N'update' INTO @out (EventNumber, Outcome)
    FROM HC.Event e
    JOIN #runs r ON e.KennelId = @kennelId AND e.InboundIntegrationId = 6 AND e.EventFacebookId = r.ExtId AND e.deleted = 0
    WHERE ISNULL(e.FbEventStartDatetime, '2000-01-01') <> r.StartDt
       OR ISNULL(e.FbEventName, N'') <> ISNULL(r.Name, N'')
       OR ISNULL(e.FbEventDescription, N'') <> ISNULL(r.Descr, N'')
       OR ISNULL(e.FbLocationOneLineDesc, N'') <> ISNULL(r.Place, N'')
       OR ISNULL(e.FbLatitude, -999) <> ISNULL(r.Lat, -999)
       OR ISNULL(e.FbLongitude, -999) <> ISNULL(r.Lon, -999)
       OR ISNULL(e.FbEventMapUrl, N'') <> ISNULL(r.MapUrl, N'')
       OR (e.UseFbRunDetails = 1 AND ISNULL(e.Hares, N'') <> ISNULL(r.Hares, N''));
    SET @updated = @@ROWCOUNT;

    -- New runs.
    UPDATE r SET NewId = NEWID() FROM #runs r
    WHERE NOT EXISTS (SELECT 1 FROM HC.Event e
        WHERE e.KennelId = @kennelId AND e.InboundIntegrationId = 6 AND e.EventFacebookId = r.ExtId AND e.deleted = 0);

    INSERT HC.Event (
        id, KennelId, CountryId, EventStartDatetime, FbEventStartDatetime,
        IsCountedRun, IsVisible, IsPromotedEvent, EventGeographicScope, InboundIntegrationId, ThemeRunType,
        EventName, FbEventName, EventDescription, FbEventDescription,
        LocationOneLineDesc, FbLocationOneLineDesc, FbEventMapUrl, EventFacebookId,
        Latitude, Longitude, FbLatitude, FbLongitude, EventGeolocation,
        UseFbRunDetails, UseFbLocation, UseFbLatLon, UseFbImage,
        EventPriceForMembers, EventPriceForNonMembers, EventCurrencyType,
        AbsoluteEventNumber, Hares, EventSource, deleted, updatedAt)
    SELECT r.NewId, @kennelId, @countryId, r.StartDt, r.StartDt,
           1, 1, 0, CASE WHEN r.Special = 1 THEN 2 ELSE 1 END, 6, 0,
           r.Name, r.Name, r.Descr, r.Descr,
           r.Place, r.Place, r.MapUrl, r.ExtId,
           r.Lat, r.Lon, r.Lat, r.Lon,
           CASE WHEN r.Lat IS NOT NULL THEN geography::Point(r.Lat, r.Lon, 4326) END,
           1, 1, 1, 0,
           @priceM, @priceNM, @currency,
           r.EventNumber, r.Hares, N'Runs page', 0, SYSDATETIMEOFFSET()
    FROM #runs r WHERE r.NewId IS NOT NULL;
    DECLARE @inserted INT = @@ROWCOUNT;
    INSERT @out (EventNumber, Outcome) SELECT EventNumber, N'new' FROM #runs WHERE NewId IS NOT NULL;
    INSERT @out (EventNumber, Outcome) SELECT r.EventNumber, N'unchanged' FROM #runs r
        WHERE r.NewId IS NULL AND NOT EXISTS (SELECT 1 FROM @out o WHERE o.EventNumber = r.EventNumber);

    DECLARE @newId UNIQUEIDENTIFIER;
    DECLARE newRuns CURSOR LOCAL FAST_FORWARD FOR SELECT NewId FROM #runs WHERE NewId IS NOT NULL;
    OPEN newRuns;
    FETCH NEXT FROM newRuns INTO @newId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_updateRunNumbers @eventId = @newId;
        FETCH NEXT FROM newRuns INTO @newId;
    END
    CLOSE newRuns;
    DEALLOCATE newRuns;

    IF (@dryRun = 0 AND @inserted + @updated > 0)
        INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
        VALUES ('runsPageImport', CONCAT('runs page import: ', @inserted, ' new, ', @updated, ' updated'),
                CAST(@kennelId AS NVARCHAR(40)),
                (SELECT STRING_AGG(CAST(EventNumber AS NVARCHAR(10)), N',') FROM #runs), SYSDATETIMEOFFSET());

    IF (@dryRun = 1) ROLLBACK TRANSACTION runsPageImport;
    COMMIT TRANSACTION;

    SELECT @inserted AS inserted, @updated AS updated, @matched - @updated AS unchanged,
           @alreadyInHc AS alreadyInHc, @rejected AS rejected;
    SELECT EventNumber, Outcome FROM @out ORDER BY EventNumber;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in importRunsPageRuns',
            CONCAT(ERROR_MESSAGE(), ' (kennel ', @kennelId, ')'), @procName, NULL);
    THROW;
END CATCH
GO
