CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyHistory]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyHistory
-- Description: The app's History tab for a signed-in web member
--              (E9.F7.S5): totals per kennel, every run attended or
--              hared, and the number that run was for them at that
--              kennel (historical count carried in, then counted runs
--              in order) — the "My LH3 run #97" the app shows, and the
--              basis for the milestone nudge.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
-- Returns:     Rowset 0: envelope.
--              Rowset 1: grand totals — Runs, Haring, Kennels.
--              Rowset 2: per kennel — counts, home/following, since, last.
--              Rowset 3: runs attended, newest first, with MyRunNumber.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none (app: hcapp_getMyKennelRunTotals + local HEM history)
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
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    -- Rowset 1: grand totals
    SELECT
        SUM(COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0)) AS Runs,
        SUM(COALESCE(hkm.HcHaringCount, 0)   + COALESCE(hkm.HistoricalHaringCount, 0))   AS Haring,
        SUM(CASE WHEN COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) > 0 THEN 1 ELSE 0 END) AS Kennels,
        MAX(CASE WHEN COALESCE(hkm.HistoricalCountIsEstimate, 0) <> 0 THEN 1 ELSE 0 END) AS IsEstimate
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @userId AND hkm.removed = 0;

    -- Rowset 2: per kennel
    SELECT
        k.PublicKennelId,
        k.KennelUniqueShortName                                 AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        COALESCE(hkm.Following, 0)                              AS Following,
        COALESCE(hkm.IsHomeKennel, 0)                           AS IsHomeKennel,
        hkm.MemberSince,
        hkm.DateOfLastRun,
        COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS Runs,
        COALESCE(hkm.HcHaringCount, 0)   + COALESCE(hkm.HistoricalHaringCount, 0)   AS Haring,
        COALESCE(hkm.HistoricalCountIsEstimate, 0)              AS IsEstimate
    FROM HC.HasherKennelMap hkm
    JOIN HC.Kennel k ON k.id = hkm.KennelId AND k.deleted = 0 AND k.removed = 0
    WHERE hkm.UserId = @userId AND hkm.removed = 0
      AND COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) > 0
    ORDER BY COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) DESC, k.KennelShortName;

    -- Rowset 3: the runs. MyRunNumber = the kennel's historical count for me
    -- plus my position among its counted runs I attended, in date order —
    -- by the local wall-clock, which is how run numbers are assigned
    -- (/hc-event-datetimes).
    SELECT
        e.PublicEventId,
        e.EventNumber,
        e.EventName,
        CAST(e.EventStartDatetime AS datetime2(7))              AS EventStartDatetime,
        e.EventStartDatetimeGmt,
        e.IsCountedRun,
        e.LocationOneLineDesc,
        e.SyncLocationCity                                      AS LocationCity,
        e.Hares,
        e.TrackRunnerCount, e.PhotoCount,
        k.PublicKennelId,
        k.KennelUniqueShortName                                 AS KennelSlug,
        k.KennelShortName,
        k.KennelLogo,
        hem.IsHare,
        hem.AttendenceState,
        CASE WHEN e.IsCountedRun = 1 AND hem.AttendenceState >= 20
             THEN COALESCE(hkm.HistoricalTotalRunCount, 0)
                  + ROW_NUMBER() OVER (PARTITION BY k.id, CASE WHEN e.IsCountedRun = 1 AND hem.AttendenceState >= 20 THEN 1 ELSE 0 END
                                       ORDER BY e.EventStartLocal ASC, e.EventNumber ASC)
             ELSE NULL END                                      AS MyRunNumber
    FROM HC.HasherEventMap hem
    JOIN HC.Event  e ON e.id = hem.EventId AND e.deleted = 0 AND e.removed = 0
    JOIN HC.Kennel k ON k.id = e.KennelId
    LEFT JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = @userId AND hkm.removed = 0
    WHERE hem.UserId = @userId
      AND (hem.AttendenceState >= 20 OR hem.IsHare = 1)
    ORDER BY e.EventStartDateTimeGmt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyHistory', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
