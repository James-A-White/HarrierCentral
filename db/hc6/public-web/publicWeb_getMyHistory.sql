CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyHistory]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyHistory
-- Description: The app's Run Counts tab for a signed-in web member
--              (E9.F7.S5) — the app's own three queries
--              (history_list_page.dart), moved server-side:
--                By Kennel  = HasherKennelMap Historical* + Hc* per kennel
--                By Country = HC runs grouped by the RUN's country
--                             (Event.CountryId — a travelling kennel is
--                             in several) merged with the historical
--                             counts grouped by the KENNEL's country
--                Totals     = the By Kennel rows summed
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
-- Returns:     Rowset 0: envelope.
--              Rowset 1: totals — Runs, Haring, Kennels, IsEstimate.
--              Rowset 2: by kennel, runs desc.
--              Rowset 3: by country, runs desc.
-- Author:      Harrier Central
-- Created:     2026-09-16 (rewritten the same day to mirror the app)
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 113, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    -- ── By kennel (queryKennelStats) ─────────────────────────────────────
    SELECT
        k.PublicKennelId,
        k.KennelUniqueShortName                                          AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        COALESCE(hkm.HistoricalTotalRunCount, 0) + COALESCE(hkm.HcTotalRunCount, 0) AS TotalRuns,
        COALESCE(hkm.HistoricalHaringCount, 0)   + COALESCE(hkm.HcHaringCount, 0)   AS TotalHaring,
        COALESCE(hkm.HcTotalRunCount, 0)                                 AS HcRuns,
        COALESCE(hkm.HcHaringCount, 0)                                   AS HcHaring,
        COALESCE(hkm.HistoricalTotalRunCount, 0)                         AS HistoricalRuns,
        COALESCE(hkm.HistoricalHaringCount, 0)                           AS HistoricalHaring,
        COALESCE(hkm.HistoricalCountIsEstimate, 0)                       AS IsEstimate,
        COALESCE(hkm.Following, 0)                                       AS Following,
        COALESCE(hkm.KennelCredit, 0)                                    AS KennelCredit,
        COALESCE(k.DigitsAfterDecimal, c.DigitsAfterDecimal, 2)          AS DigitsAfterDecimal,
        COALESCE(k.CurrencySymbol, c.CurrencySymbol, '$^')               AS CurrencySymbol
    INTO #byKennel
    FROM HC.HasherKennelMap hkm
    JOIN HC.Kennel k ON k.id = hkm.KennelId AND k.deleted = 0 AND k.removed = 0
    LEFT JOIN HC.Country c ON c.id = k.CountryId
    WHERE hkm.UserId = @userId AND hkm.removed = 0
      AND COALESCE(hkm.HistoricalTotalRunCount, 0) + COALESCE(hkm.HcTotalRunCount, 0) > 0;

    -- Rowset 1: totals = the by-kennel rows summed, as the app does
    SELECT
        COALESCE(SUM(TotalRuns), 0)   AS Runs,
        COALESCE(SUM(TotalHaring), 0) AS Haring,
        COUNT(*)                      AS Kennels,
        COALESCE(MAX(IsEstimate), 0)  AS IsEstimate
    FROM #byKennel;

    -- Rowset 2
    SELECT * FROM #byKennel ORDER BY TotalRuns DESC, KennelShortName;

    -- ── By country (queryCountryStats) ───────────────────────────────────
    -- HC runs by the run's country…
    SELECT
        n.id AS CountryId,
        COUNT(CASE WHEN hem.AttendenceState >= 20 THEN 1 END)                     AS RunCount,
        COUNT(CASE WHEN hem.IsHare <> 0 AND hem.AttendenceState >= 20 THEN 1 END) AS HareCount
    INTO #hc
    FROM HC.HasherEventMap hem
    JOIN HC.Event evt ON evt.id = hem.EventId
    JOIN HC.Country n ON n.id = evt.CountryId
    WHERE hem.UserId = @userId
      AND evt.removed = 0  -- no deleted filter: the app's local query has none, and the counts must match it
      AND evt.IsCountedRun <> 0 AND evt.IsVisible <> 0
      AND evt.EventStartDateTimeGmt <= @now
    GROUP BY n.id;

    -- …plus the historical counts by the kennel's country, merged by country.
    SELECT
        n.id AS CountryId,
        SUM(COALESCE(hkm.HistoricalTotalRunCount, 0)) AS RunCount,
        SUM(COALESCE(hkm.HistoricalHaringCount, 0))   AS HareCount
    INTO #hist
    FROM HC.HasherKennelMap hkm
    JOIN HC.Kennel k ON k.id = hkm.KennelId
    JOIN HC.Country n ON n.id = k.CountryId
    WHERE hkm.UserId = @userId AND hkm.removed = 0
    GROUP BY n.id;

    -- Rowset 3
    SELECT
        n.id                                                    AS CountryId,
        n.CountryName,
        n.CountryCode,
        n.FlagFile,
        COALESCE(h.RunCount, 0)  + COALESCE(x.RunCount, 0)      AS RunCount,
        COALESCE(h.HareCount, 0) + COALESCE(x.HareCount, 0)     AS HareCount
    FROM HC.Country n
    LEFT JOIN #hc   h ON h.CountryId = n.id
    LEFT JOIN #hist x ON x.CountryId = n.id
    WHERE COALESCE(h.RunCount, 0) + COALESCE(x.RunCount, 0) > 0
    ORDER BY RunCount DESC, n.CountryName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyHistory', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
