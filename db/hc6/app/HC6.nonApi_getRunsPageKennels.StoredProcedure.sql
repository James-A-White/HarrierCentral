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
--   DefaultStartTime }
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
            CONVERT(NVARCHAR(5), k.DefaultRunStartTime, 108) AS DefaultStartTime
    FROM HC.Kennel k
    LEFT JOIN HC.City c ON c.id = k.CityId
    LEFT JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
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
           OR (@kennelId IS NULL AND k.InboundIntegrationId = 6
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
