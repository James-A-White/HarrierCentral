CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyRuns]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyRuns
-- Description: The app's Runs tab for a signed-in web member (E9.F7.S8):
--              the next year of runs for the kennels they follow, plus
--              the runs they attended in the last ten days (the app puts
--              attended-past above next), each with their own RSVP and
--              attendance state and a going count. Rows are the
--              publicWeb_getGlobalRuns shape so the web renders them with
--              the same cards, plus My* columns.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
-- Returns:     Rowset 0: envelope. Rowset 1: runs, chronological.
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
    @spNumber = 111, @param = NULL,
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
    DECLARE @pastCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -10, @now);
    DECLARE @futureCutoff DATETIMEOFFSET(7) = DATEADD(DAY, 365, @now);

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        e.PublicEventId,
        e.EventNumber,
        e.EventName,
        CAST(e.EventStartDatetime AS datetime2(7))                      AS EventStartDatetime,
        CAST(e.EventEndDatetime   AS datetime2(7))                      AS EventEndDatetime,
        e.EventStartDatetimeGmt,
        COALESCE(tzmap.IANATimeZone_001, tzmap.IANATimeZone_any)        AS KennelIANATimezone,
        ett.EventEnumName                                               AS EventTypeName,
        COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers)    AS EventPriceForMembers,
        COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers) AS EventPriceForNonMembers,
        COALESCE(e.EventCurrencyType,       k.DefaultEventCurrencyType)       AS EventCurrencyType,
        e.Hares,
        e.LocationOneLineDesc,
        e.SyncLocationStreet                                            AS LocationStreet,
        e.SyncLocationCity                                              AS LocationCity,
        e.SyncLocationPostCode                                          AS LocationPostCode,
        e.SyncLocationRegion                                            AS LocationRegion,
        e.SyncLocationCountry                                           AS LocationCountry,
        e.SyncLatitude                                                  AS Latitude,
        e.SyncLongitude                                                 AS Longitude,
        e.w3wJson,
        e.SyncDescription                                               AS EventDescription,
        e.EventImage,
        e.EventUrl,
        e.Tags1, e.Tags2, e.Tags3,
        e.IsCountedRun,
        k.KennelUniqueShortName                                         AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        kw.PrimaryColor,
        kw.AccentColor,
        k.PublicKennelId,
        kw.CustomDomain                                                 AS KennelWebsiteDomain,
        ctr.ContinentName                                               AS KennelContinent,
        -- ── Mine ────────────────────────────────────────────────────────────
        COALESCE(hem.RsvpState, 0)                                      AS MyRsvpState,
        COALESCE(hem.AttendenceState, 0)                                AS MyAttendenceState,
        COALESCE(hem.IsHare, 0)                                         AS MyIsHare,
        CASE WHEN e.EventStartDateTimeGmt < @now THEN 1 ELSE 0 END      AS IsPast,
        (SELECT COUNT(*) FROM HC.HasherEventMap g
           WHERE g.EventId = e.id AND (g.RsvpState = 3 OR g.AttendenceState >= 20)) AS GoingCount,
        e.TrackRunnerCount, e.PhotoCount, e.MessageCount
    FROM   HC.Event e
    JOIN   HC.Kennel k ON k.id = e.KennelId AND k.deleted = 0 AND k.removed = 0
    LEFT JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = @userId AND hkm.removed = 0
    LEFT JOIN HC.HasherEventMap  hem ON hem.EventId = e.id AND hem.UserId = @userId
    LEFT JOIN HC.KennelWebsite   kw  ON kw.KennelId = k.id
    LEFT JOIN HC.Country         ctr ON ctr.id = k.CountryId
    LEFT JOIN DomainValues.EventThemeType ett ON ett.EventEnumId = e.ThemeRunType
    LEFT JOIN HC.City c ON c.id = k.CityId
    LEFT JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
    LEFT JOIN (
        SELECT WindowsTimeZone,
               MAX(CASE WHEN territory = '001' THEN IANATimeZone END) AS IANATimeZone_001,
               MIN(IANATimeZone)                                       AS IANATimeZone_any
        FROM DomainValues.TimeZoneMap GROUP BY WindowsTimeZone
    ) tzmap ON tzmap.WindowsTimeZone = tz.Timezone COLLATE DATABASE_DEFAULT
    WHERE e.IsVisible = 1 AND e.deleted = 0 AND e.removed = 0
      AND (
            -- next year for the kennels I follow
            (hkm.Following = 1 AND e.EventStartDateTimeGmt >= @now AND e.EventStartDateTimeGmt < @futureCutoff)
            -- and what I attended in the last ten days, wherever it was
         OR (hem.AttendenceState >= 20 AND e.EventStartDateTimeGmt >= @pastCutoff AND e.EventStartDateTimeGmt < @now)
          )
    ORDER BY e.EventStartDateTimeGmt ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyRuns', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
