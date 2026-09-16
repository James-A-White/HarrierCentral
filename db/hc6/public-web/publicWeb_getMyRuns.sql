CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyRuns]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyRuns
-- Description: The app's Runs tab for a signed-in web member (E9.F7.S8),
--              mirroring what the phone holds after hcapp_syncUserData:
--              every run of the kennels they follow (a year each way),
--              every kennel's runs in the ten-day global window, and their
--              own RSVP'd / attended runs anywhere. The app's 6-hour rule
--              decides past vs future (query_runs.dart showAsPastEvent).
--              Rows are the publicWeb_getGlobalRuns shape plus the My*
--              columns the card needs: RSVP, attendance, hare, the bell
--              and envelope preferences, following, member, the activity
--              counts, the distance units, and the geographic scope.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
-- Returns:     Rowset 0: envelope. Rowset 1: runs, chronological, IsPast
--              by the 6-hour rule.
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
    -- The app's split: a run is "past" six hours after it started.
    DECLARE @split DATETIMEOFFSET(7) = DATEADD(HOUR, -6, @now);
    -- 120 days of past, not the phone's full history: the page carries every row.
    DECLARE @pastCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -120, @now);
    DECLARE @globalPast DATETIMEOFFSET(7) = DATEADD(DAY, -10, @now);
    DECLARE @globalFuture DATETIMEOFFSET(7) = DATEADD(DAY, 10, @now);
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
        COALESCE(hem.EventNotificationPreference, 0)                    AS MyNotificationPref,
        COALESCE(hem.EventEmailAlertPreference, 0)                      AS MyEmailAlertPref,
        COALESCE(hkm.Following, 0)                                      AS Following,
        CASE WHEN hkm.MembershipExpirationDate IS NOT NULL AND hkm.MembershipExpirationDate >= @now THEN 1 ELSE 0 END AS IsMember,
        CASE WHEN e.EventStartDateTimeGmt < @split THEN 1 ELSE 0 END    AS IsPast,
        (SELECT COUNT(*) FROM HC.HasherEventMap g
           WHERE g.EventId = e.id AND (g.RsvpState = 3 OR g.AttendenceState >= 20)) AS GoingCount,
        e.TrackRunnerCount, e.PhotoCount, e.MessageCount, e.DownDownCount,
        COALESCE(k.DistancePreference, ctr.DistancePreference, 0)      AS DistanceUnitsPref,
        e.EventGeographicScope,
        e.EventType
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
      AND e.EventStartDateTimeGmt >= @pastCutoff AND e.EventStartDateTimeGmt < @futureCutoff
      AND (
            -- the kennels I follow: a year each way
            hkm.Following = 1
            -- the ten-day global window every phone carries
         OR (e.EventStartDateTimeGmt >= @globalPast AND e.EventStartDateTimeGmt < @globalFuture)
            -- and anything I answered or attended, wherever it was
         OR hem.RsvpState >= 2 OR hem.AttendenceState >= 20 OR hem.IsHare = 1
          )
    ORDER BY e.EventStartDateTimeGmt ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyRuns', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
