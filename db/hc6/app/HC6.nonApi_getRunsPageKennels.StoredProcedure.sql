CREATE OR ALTER PROCEDURE [HC6].[nonApi_getRunsPageKennels]
    @kennelId UNIQUEIDENTIFIER = NULL   -- one kennel (the API's "import now"); NULL = all
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getRunsPageKennels
-- Description: The kennels whose runs page the API's RunsPageImport reads
--   (2026-10-04): every live kennel with a RunsPageUrl, with what the
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
    WHERE k.RunsPageUrl IS NOT NULL AND LEN(k.RunsPageUrl) > 10
      AND k.deleted = 0 AND ISNULL(k.removed, 0) = 0
      AND (@kennelId IS NULL OR k.id = @kennelId);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in getRunsPageKennels', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
