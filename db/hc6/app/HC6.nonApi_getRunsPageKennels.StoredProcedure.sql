CREATE OR ALTER PROCEDURE [HC6].[nonApi_getRunsPageKennels]
    @kennelId UNIQUEIDENTIFIER = NULL   -- one kennel (the API's "import now"); NULL = all
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getRunsPageKennels
-- Description: The kennels whose runs page the API's RunsPageImport reads
--   (2026-10-04): every live kennel set to Inbound Integration 6 with a
--   RunsPageUrl (2026-10-05), with what the
--   reader needs — the last page fingerprint (skip the model when it has not
--   changed), the kennel's local "today" (a page that leaves the year off is
--   read against it) and its latest run, default start time and time zone.
-- Returns: rowset 0 — { KennelId, KennelName, KennelShortName, RunsPageUrl,
--   RunsPageHash, LocalToday, TimeZoneName, LatestRunNumber, LatestRunDate,
--   DefaultStartTime, CityName, CountryName, AnchorLat, AnchorLon }
-- Changes: 2026-10-15 — kennels on Google Calendar (2) are read too (E3.F6.S5).
--   2026-10-14 — the anchor is the kennel's point only when both halves are
--   in range, else the city's (DH3's Latitude 999 failed every geocode).
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    SELECT  LOWER(CAST(k.id AS NVARCHAR(40)))             AS KennelId,
            k.KennelName,
            k.KennelShortName,
            k.RunsPageUrl,
            k.RunsPageHash,
            CONVERT(NVARCHAR(10),
                CAST(SYSDATETIMEOFFSET() AT TIME ZONE COALESCE(tz.Timezone, 'UTC') AS DATE), 23) AS LocalToday,
            tz.Timezone                                   AS TimeZoneName,
            last.EventNumber                              AS LatestRunNumber,
            CONVERT(NVARCHAR(10), last.EventStartLocal, 23) AS LatestRunDate,
            -- DefaultRunStartTime smuggles a day-of-week in its fractional
            -- seconds (reference_default_run_start_time_hack): hh:mm only.
            CONVERT(NVARCHAR(5), k.DefaultRunStartTime, 108) AS DefaultStartTime,
            -- Where the club is (2026-10-05): the AI writes each run's start
            -- as a full search address using the city and country when the
            -- page leaves them out, and a geocoded point is accepted only
            -- near the anchor (the kennel's own point, else its city's).
            c.CityName                                    AS CityName,
            co.CountryName                                AS CountryName,
            -- The kennel's point only when BOTH halves are real: DH3 had
            -- Latitude 999 (a "no position" sentinel) and no longitude, the
            -- two COALESCEs paired 999 with the city's longitude, and Azure
            -- Maps answered 400 to every lookup (2026-10-14).
            CAST(CASE WHEN ok.KennelPoint = 1 THEN k.Latitude  ELSE c.Latitude  END AS FLOAT) AS AnchorLat,
            CAST(CASE WHEN ok.KennelPoint = 1 THEN k.Longitude ELSE c.Longitude END AS FLOAT) AS AnchorLon
    FROM HC.Kennel k
    LEFT JOIN HC.City c ON c.id = k.CityId
    LEFT JOIN HC.Country co ON co.id = k.CountryId
    LEFT JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
    CROSS APPLY (SELECT CASE WHEN k.Latitude BETWEEN -90 AND 90 AND k.Longitude BETWEEN -180 AND 180
                              AND NOT (k.Latitude = 0 AND k.Longitude = 0)
                             THEN 1 ELSE 0 END AS KennelPoint) ok
    OUTER APPLY (
        SELECT TOP 1 e.EventNumber, e.EventStartLocal
        FROM HC.Event e
        WHERE e.KennelId = k.id AND e.deleted = 0 AND ISNULL(e.removed, 0) = 0
          AND e.EventStartDatetimeGmt <= SYSDATETIMEOFFSET()
        ORDER BY e.EventStartDatetimeGmt DESC) last
    -- One kennel by id (the portal's Test, an "import now") whether or not
    -- it has a runs page saved yet. Otherwise (the timer) every kennel whose
    -- Inbound Integration drop-down says "Runs page (AI)" and that has a
    -- runs page address. The drop-down is the switch; HC.Integration 6's
    -- Enabled flag is shown on the monitor tile only (James, 2026-10-05).
    WHERE k.deleted = 0 AND ISNULL(k.removed, 0) = 0
      AND ((@kennelId IS NOT NULL AND k.id = @kennelId)
           -- 6 Runs page (AI), and 2 Google Calendar: the same reader, which
           -- turns a Google Calendar link into its public iCal feed (2026-10-15).
           OR (@kennelId IS NULL AND k.InboundIntegrationId IN (2, 6)
               AND k.RunsPageUrl IS NOT NULL AND LEN(k.RunsPageUrl) > 10
               -- Due? The timer fires every 15 minutes (2026-10-05). On a run
               -- day (a run on the kennel's local today) every kennel is due
               -- each time, so a late change of start is caught within 15
               -- minutes; otherwise once every ~6 hours. Reading an unchanged
               -- page costs one small fetch — the model runs only when the
               -- text changed (James, 2026-10-05).
               AND (k.RunsPageCheckedAt IS NULL
                    OR k.RunsPageCheckedAt < DATEADD(MINUTE, -350, SYSUTCDATETIME())
                    OR (k.RunsPageCheckedAt < DATEADD(MINUTE, -13, SYSUTCDATETIME())
                        AND EXISTS (SELECT 1 FROM HC.Event t
                                    WHERE t.KennelId = k.id AND t.deleted = 0 AND ISNULL(t.removed, 0) = 0
                                      AND t.EventStartLocalDate =
                                          CAST(SYSDATETIMEOFFSET() AT TIME ZONE COALESCE(tz.Timezone, 'UTC') AS DATE))))));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in getRunsPageKennels', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
