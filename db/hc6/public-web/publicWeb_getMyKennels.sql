CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyKennels]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyKennels
-- Description: The app's Kennels tab for a signed-in web member
--              (E9.F7.S9): every kennel they follow, belong to, call
--              home, or have run with, with their counts there and the
--              kennel's next run. Counts are the app's own formula —
--              HcTotalRunCount + HistoricalTotalRunCount, '~' when the
--              historical part is an estimate.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
-- Returns:     Rowset 0: envelope. Rowset 1: kennels, home first, then by
--              runs there.
-- Author:      Harrier Central
-- Created:     2026-09-16
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
    @spNumber = 112, @param = NULL,
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
    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET() AT TIME ZONE 'UTC';

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        k.PublicKennelId,
        k.KennelUniqueShortName                                 AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        k.KennelStatus,
        c.CityName                                              AS City,
        rgn.RegionName                                          AS Region,
        ctr.CountryName                                         AS Country,
        kw.CustomDomain                                         AS KennelWebsiteDomain,
        COALESCE(hkm.Following, 0)                              AS Following,
        COALESCE(hkm.IsHomeKennel, 0)                           AS IsHomeKennel,
        COALESCE(hkm.IsMember, 0)                               AS IsMember,
        hkm.MembershipExpirationDate,
        hkm.MemberSince,
        hkm.DateOfLastRun,
        COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS Runs,
        COALESCE(hkm.HcHaringCount, 0)   + COALESCE(hkm.HistoricalHaringCount, 0)   AS Haring,
        COALESCE(hkm.HistoricalCountIsEstimate, 0)              AS IsEstimate,
        nxt.EventStartDatetimeGmt                               AS NextRunGmt,
        CAST(nxt.EventStartDatetime AS datetime2(7))            AS NextRunLocal,
        nxt.EventNumber                                         AS NextRunNumber,
        nxt.EventName                                           AS NextRunName,
        nxt.PublicEventId                                       AS NextRunPublicEventId
    FROM HC.HasherKennelMap hkm
    JOIN HC.Kennel k ON k.id = hkm.KennelId AND k.deleted = 0 AND k.removed = 0
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    LEFT JOIN HC.City    c   ON c.id   = k.CityId
    LEFT JOIN HC.Region  rgn ON rgn.id = k.ProvinceStateId
    LEFT JOIN HC.Country ctr ON ctr.id = k.CountryId
    OUTER APPLY (
        SELECT TOP 1 e.PublicEventId, e.EventNumber, e.EventName, e.EventStartDatetime, e.EventStartDatetimeGmt
        FROM HC.Event e
        WHERE e.KennelId = k.id AND e.IsVisible = 1 AND e.deleted = 0 AND e.removed = 0
          AND e.EventStartDateTimeGmt >= @now
        ORDER BY e.EventStartDateTimeGmt ASC
    ) nxt
    WHERE hkm.UserId = @userId AND hkm.removed = 0
      AND (hkm.Following = 1 OR hkm.IsHomeKennel = 1 OR hkm.IsMember = 1
           OR COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) > 0)
    ORDER BY COALESCE(hkm.IsHomeKennel, 0) DESC, COALESCE(hkm.Following, 0) DESC,
             COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) DESC,
             k.KennelShortName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyKennels', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
