CREATE OR ALTER PROCEDURE [HC6].[hcapp_syncUserData]

    @deviceId                        UNIQUEIDENTIFIER,
    @accessToken                     NVARCHAR(1000),
    @hashersUpdatedAfter             NVARCHAR(50)      = 'ignore',
    @citiesUpdatedAfter              NVARCHAR(50)      = 'ignore',
    @regionsUpdatedAfter             NVARCHAR(50)      = 'ignore',
    @countriesUpdatedAfter           NVARCHAR(50)      = 'ignore',
    @kennelsUpdatedAfter             NVARCHAR(50)      = 'ignore',
    @hasherKennelMapUpdatedAfter     NVARCHAR(50)      = 'ignore',
    @hasherEventMapUpdatedAfter      NVARCHAR(50)      = 'ignore',
    @narrowEventsUpdatedAfter        NVARCHAR(50)      = 'ignore',
    @paymentsUpdatedAfter            NVARCHAR(50)      = 'ignore',
    @songsUpdatedAfter               NVARCHAR(50)      = 'ignore',
    @forceReplicateAllRunsForKennel  NVARCHAR(50)      = 'ignore',
    @usePaging                       INT               = 0,
    @initialLoad                     INT               = 0,
    @procName                        NVARCHAR(128)     = NULL,
    @param                           NVARCHAR(500)     = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_syncUserData
-- Description: Incremental sync of user-scoped data. Each entity type
--   is gated by a watermark parameter ('ignore' skips that table).
--   Called directly by the app on launch and periodically, and also
--   by write SPs after mutations to push the changed rows back in the
--   same response.
--
--   @procName and @param are delegation parameters: write SPs pass
--   their own procName and token param so the token can be validated
--   in the context of the calling operation. NULL means direct call.
--
--   Tables returned (when watermark != 'ignore'):
--     Hashers, Cities, Regions, Countries, Songs, Kennels,
--     HasherKennelMap, HasherEventMap, Events (narrow or force-replicate),
--     Payments.
--
--   isMember is computed dynamically from MembershipExpirationDate
--   rather than from the stored IsMember column (which can be stale).
-- Parameters:
--   @deviceId                       - Registered device UUID
--   @accessToken                    - Token (validated against delegating SP context or DeviceSecret)
--   @hashersUpdatedAfter            - Watermark for HC.Hasher
--   @citiesUpdatedAfter             - Watermark for HC.City
--   @regionsUpdatedAfter            - Watermark for HC.Region
--   @countriesUpdatedAfter          - Watermark for HC.Country
--   @kennelsUpdatedAfter            - Watermark for HC.Kennel
--   @hasherKennelMapUpdatedAfter    - Watermark for HC.HasherKennelMap (user-scoped)
--   @hasherEventMapUpdatedAfter     - Watermark for HC.HasherEventMap (user-scoped)
--   @narrowEventsUpdatedAfter       - Watermark for HC.Event (recent/followed/attended)
--   @paymentsUpdatedAfter           - Watermark for HC.Payment (user-scoped)
--   @songsUpdatedAfter              - Watermark for HC.Song
--   @forceReplicateAllRunsForKennel - UUID string to force full kennel event sync
--   @usePaging                      - 1 = enforce page limits; 0 = unlimited
--   @initialLoad                    - Reserved (not used, kept for caller compat)
--   @procName                       - Delegating SP name (NULL = direct call)
--   @param                          - Delegating SP token suffix (NULL = DeviceSecret only)
-- Returns:
--   Read SP (no success envelope).
--   On error (rowset 0): standard HC6 error detail
--   On success: one rowset per non-ignored watermark, in parameter order
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_syncUserData
-- Breaking Changes:
--   isMember in HasherKennelMap rowset computed dynamically (HC5 used
--     stored IsMember column which can be stale).
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @effectiveProcName NVARCHAR(128) = COALESCE(@procName, @procName_self);

DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @effectiveProcName,
    @spNumber     = 70,
    @param        = @param,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @effectiveProcName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Paging limits (0 = unlimited for write-SP delegation)
-- ---------------------------------------------------------------
DECLARE @paging2500 INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 2500 END;
DECLARE @paging250  INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 250  END;

-- ---------------------------------------------------------------
-- Normalise watermarks
-- ---------------------------------------------------------------
IF (@hashersUpdatedAfter            IS NULL OR @hashersUpdatedAfter            <= '2000-01-01') SET @hashersUpdatedAfter            = 'ignore';
IF (@citiesUpdatedAfter             IS NULL OR @citiesUpdatedAfter             <= '2000-01-01') SET @citiesUpdatedAfter             = 'ignore';
IF (@regionsUpdatedAfter            IS NULL OR @regionsUpdatedAfter            <= '2000-01-01') SET @regionsUpdatedAfter            = 'ignore';
IF (@countriesUpdatedAfter          IS NULL OR @countriesUpdatedAfter          <= '2000-01-01') SET @countriesUpdatedAfter          = 'ignore';
IF (@kennelsUpdatedAfter            IS NULL OR @kennelsUpdatedAfter            <= '2000-01-01') SET @kennelsUpdatedAfter            = 'ignore';
IF (@hasherKennelMapUpdatedAfter    IS NULL OR @hasherKennelMapUpdatedAfter    <= '2000-01-01') SET @hasherKennelMapUpdatedAfter    = 'ignore';
IF (@hasherEventMapUpdatedAfter     IS NULL OR @hasherEventMapUpdatedAfter     <= '2000-01-01') SET @hasherEventMapUpdatedAfter     = 'ignore';
IF (@narrowEventsUpdatedAfter       IS NULL OR @narrowEventsUpdatedAfter       <= '2000-01-01') SET @narrowEventsUpdatedAfter       = 'ignore';
IF (@paymentsUpdatedAfter           IS NULL OR @paymentsUpdatedAfter           <= '2000-01-01') SET @paymentsUpdatedAfter           = 'ignore';
IF (@songsUpdatedAfter              IS NULL OR @songsUpdatedAfter              <= '2000-01-01') SET @songsUpdatedAfter              = 'ignore';

DECLARE @DAYS_PAST  INT = 10;
DECLARE @forceKennelId UNIQUEIDENTIFIER = NULL;

IF (@forceReplicateAllRunsForKennel IS NOT NULL AND @forceReplicateAllRunsForKennel != 'ignore')
    SET @forceKennelId = CAST(@forceReplicateAllRunsForKennel AS UNIQUEIDENTIFIER);

DECLARE @ua DATETIMEOFFSET(7);

-- ---------------------------------------------------------------
-- HASHERS
-- ---------------------------------------------------------------
IF (@hashersUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hashersUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        h.id                                                                AS hasherId,
        h.HomeKennelId                                                      AS homeKennelId,
        COALESCE(h.FirstName, '')                                           AS firstName,
        COALESCE(h.LastName, '')                                            AS lastName,
        COALESCE(h.DisplayName, '')                                         AS dispName,
        COALESCE(h.HashName, '')                                            AS hashName,
        COALESCE(h.Photo, '')                                               AS photo,
        COALESCE(h.NameDisplayPreference, 0)                                AS dispPref,
        COALESCE(h.IncludeInGlobalHashDirectory, 0)                         AS includeInGlobalHashDirectory,
        CONVERT(NVARCHAR(50), CAST(COALESCE(h.updatedAt, GETDATE()) AS DATETIME2)) AS updatedAt,
        COALESCE(h.Removed, 0)                                              AS removed
    FROM HC.Hasher h
    WHERE h.updatedAt > @ua
    ORDER BY h.updatedAt ASC, h.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging2500 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- CITIES
-- ---------------------------------------------------------------
IF (@citiesUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@citiesUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        c.id                                                                AS cityId,
        c.CityName                                                          AS cityName,
        c.CitySearchTags                                                    AS citySearchTags,
        c.RegionId                                                          AS regionId,
        c.Latitude                                                          AS latitude,
        c.Longitude                                                         AS longitude,
        c.City_ASCII                                                        AS cityAscii,
        c.FlagFile                                                          AS flagFile,
        c.Removed                                                           AS removed,
        COALESCE(tz.IanaTimeZone, 'Europe/London')                          AS ianaTimeZone,
        CONVERT(NVARCHAR(50), CAST(c.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.City c
    LEFT OUTER JOIN DomainValues.Timezone tz ON c.TimezoneId = tz.id
    WHERE c.updatedAt > @ua
      AND EXISTS (SELECT 1 FROM HC.Kennel k WHERE k.CityId = c.id)
    ORDER BY c.updatedAt ASC, c.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- REGIONS
-- ---------------------------------------------------------------
IF (@regionsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@regionsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        r.id                                                                AS regionId,
        r.RegionName                                                        AS regionName,
        r.RegionAbbreviation                                                AS regionAbbreviation,
        r.CountryId                                                         AS countryId,
        r.FlagFile                                                          AS flagFile,
        r.RegionSearchTags                                                  AS regionSearchTags,
        r.Removed                                                           AS removed,
        CONVERT(NVARCHAR(50), CAST(r.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.Region r
    WHERE r.updatedAt > @ua
      AND EXISTS (SELECT 1 FROM HC.Kennel k WHERE k.ProvinceStateId = r.id)
    ORDER BY r.updatedAt ASC, r.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- COUNTRIES
-- ---------------------------------------------------------------
IF (@countriesUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@countriesUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        c.id                                                                AS countryId,
        c.CountryCode                                                       AS countryCode,
        c.Latitude                                                          AS latitude,
        c.Longitude                                                         AS longitude,
        c.CountryName                                                       AS countryName,
        c.ContinentCode                                                     AS continentCode,
        c.FlagFile                                                          AS flagFile,
        c.CurrencyCode                                                      AS currencyCode,
        c.PrimaryCultureCode                                                AS primaryCultureCode,
        c.ShowRegion                                                        AS showRegion,
        c.CurrencySymbol                                                    AS currencySymbol,
        c.DigitsAfterDecimal                                                AS digitsAfterDecimal,
        c.DistancePreference                                                AS distancePreference,
        c.CountrySearchTags                                                 AS countrySearchTags,
        c.Removed                                                           AS removed,
        CONVERT(NVARCHAR(50), CAST(c.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.Country c
    WHERE c.updatedAt > @ua
    ORDER BY c.updatedAt ASC, c.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- SONGS
-- ---------------------------------------------------------------
IF (@songsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@songsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        s.id                                                                AS songId,
        s.SongName                                                          AS songName,
        s.TuneOf                                                            AS tuneOf,
        s.BawdyRating                                                       AS bawdyRating,
        s.Notes                                                             AS notes,
        s.Actions                                                           AS actions,
        s.Variants                                                          AS variants,
        s.ImageUrl                                                          AS imageUrl,
        s.AudioUrl                                                          AS audioUrl,
        s.AutoAddToKennel                                                   AS autoAddToKennel,
        s.Rank                                                              AS rank,
        s.AddedBy_KennelId                                                  AS addedByKennelId,
        s.AddedBy_UserId                                                    AS addedByUserId,
        s.Lyrics                                                            AS lyrics,
        s.Tags                                                              AS tags,
        s.Removed                                                           AS removed,
        CONVERT(NVARCHAR(50), CAST(s.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.Song s
    WHERE s.updatedAt > @ua
    ORDER BY s.updatedAt ASC, s.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- KENNELS
-- ---------------------------------------------------------------
IF (@kennelsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@kennelsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        k.id                                                                AS kennelId,
        k.PublicKennelId                                                    AS publicKennelId,
        k.CityId                                                            AS cityId,
        k.ProvinceStateId                                                   AS regionId,
        k.CountryId                                                         AS countryId,
        k.KennelName                                                        AS kennelName,
        k.KennelShortName                                                   AS kennelShortName,
        k.KennelUniqueShortName                                             AS kennelUniqueShortName,
        k.KennelDescription                                                 AS kennelDescription,
        k.KennelSearchTags                                                  AS kennelSearchTags,
        k.KennelLogo                                                        AS kennelLogo,
        k.KennelCoverPhoto                                                  AS kennelCoverPhoto,
        k.KennelWebsiteUrl                                                  AS kennelWebsiteUrl,
        k.KennelMismanagementTeam                                           AS kennelMismanagementTeam,
        k.DefaultEventCurrencyType                                          AS defaultEventCurrencyType,
        k.IntegrationType                                                   AS integrationType,
        k.KennelEventsUrl                                                   AS kennelEventsUrl,
        k.KennelStatus                                                      AS kennelStatus,
        k.AllowNegativeCredit                                               AS allowNegativeCredit,
        k.AllowSelfPayment                                                  AS allowSelfPayment,
        k.MembershipDurationInMonths                                        AS membershipDurationInMonths,
        k.DistancePreference                                                AS distancePreference,
        k.KennelPinColor                                                    AS kennelPinColor,
        k.DisseminateAllowWebLinks                                          AS disseminateAllowWebLinks,
        k.CanEditRunAttendence                                               AS canEditRunAttendence,
        k.InboundIntegrationId                                              AS kennelInboundIntegrationId,
        COALESCE(k.Latitude,  c.Latitude)                                   AS kennelLatitude,
        COALESCE(k.Longitude, c.Longitude)                                  AS kennelLongitude,
        k.DefaultEventPriceForMembers                                       AS defaultPriceForMembers,
        k.DefaultEventPriceForNonMembers                                    AS defaultPriceForNonMembers,
        CONVERT(DATETIME, '1900-01-01') + CONVERT(DATETIME, k.DefaultRunStartTime) AS defaultRunStartTime,
        k.RunCountStartDate                                                 AS runCountStartDate,
        k.CurrencyCode                                                      AS currencyCode,
        k.PrimaryCultureCode                                                AS primaryCultureCode,
        k.CurrencySymbol                                                    AS currencySymbol,
        k.DigitsAfterDecimal                                                AS digitsAfterDecimal,
        k.BankScheme                                                        AS bankScheme,
        k.BankAccountNumber                                                 AS bankAccountNumber,
        k.BankBic                                                           AS bankBic,
        k.BankBeneficiary                                                   AS bankBeneficiary,
        k.KennelPaymentScheme                                               AS kennelPaymentScheme,
        k.KennelPaymentUrl                                                  AS kennelPaymentUrl,
        k.KennelPaymentUrlExpires                                           AS kennelPaymentUrlExpires,
        k.KennelPaymentMemberSurcharge                                      AS kennelPaymentMemberSurcharge,
        k.KennelPaymentNonMemberSurcharge                                   AS kennelPaymentNonMemberSurcharge,
        k.KennelPaymentScheme2                                              AS kennelPaymentScheme2,
        k.KennelPaymentUrl2                                                 AS kennelPaymentUrl2,
        k.KennelPaymentUrlExpires2                                          AS kennelPaymentUrlExpires2,
        k.KennelPaymentMemberSurcharge2                                     AS kennelPaymentMemberSurcharge2,
        k.KennelPaymentNonMemberSurcharge2                                  AS kennelPaymentNonMemberSurcharge2,
        k.KennelPaymentScheme3                                              AS kennelPaymentScheme3,
        k.KennelPaymentUrl3                                                 AS kennelPaymentUrl3,
        k.KennelPaymentUrlExpires3                                          AS kennelPaymentUrlExpires3,
        k.KennelPaymentMemberSurcharge3                                     AS kennelPaymentMemberSurcharge3,
        k.KennelPaymentNonMemberSurcharge3                                  AS kennelPaymentNonMemberSurcharge3,
        k.removed                                                           AS removed,
        CONVERT(NVARCHAR(50), CAST(k.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.Kennel k
    INNER JOIN HC.City c ON k.CityId = c.id
    WHERE k.updatedAt > @ua
    ORDER BY k.updatedAt ASC, k.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY
    OPTION (RECOMPILE);
END

-- ---------------------------------------------------------------
-- HASHER–KENNEL MAP (user-scoped)
-- ---------------------------------------------------------------
IF (@hasherKennelMapUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hasherKennelMapUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        hkm.id                                                              AS hkmId,
        hkm.UserId                                                          AS userId,
        hkm.KennelId                                                        AS kennelId,
        hkm.Following                                                       AS following,
        CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE() THEN 1 ELSE 0 END AS isMember,
        hkm.IsHomeKennel                                                    AS isHomeKennel,
        hkm.IsKennelFollowing                                               AS isKennelFollowing,
        hkm.KennelNotificationPreference                                    AS kennelNotificationPreference,
        hkm.KennelEmailAlertPreference                                      AS kennelEmailAlertPreference,
        hkm.MismanagementRoles                                              AS mismanagementRoles,
        hkm.UserRoleFlags                                                   AS userRoleFlags,
        hkm.AppAccessFlags                                                  AS appAccessFlags,
        hkm.KennelCredit                                                    AS kennelCredit,
        hkm.DiscountAmount                                                  AS discountAmount,
        hkm.DiscountPercent                                                 AS discountPercent,
        hkm.DiscountDescription                                             AS discountDescription,
        hkm.HcTotalRunCount                                                 AS hcTotalRunCount,
        hkm.HcHaringCount                                                   AS hcHaringCount,
        hkm.HistoricalTotalRunCount                                         AS historicalTotalRunCount,
        hkm.HistoricalHaringCount                                           AS historicalHaringCount,
        hkm.HistoricalCountIsEstimate                                       AS historicalCountIsEstimate,
        hkm.MembershipExpirationDate                                        AS membershipExpirationDate,
        hkm.MemberSince                                                     AS memberSince,
        hkm.DateOfLastRun                                                   AS dateOfLastRun,
        ''                                                                  AS authorizedDeviceList,
        0                                                                   AS authorizedDeviceCount,
        hkm.KennelUserPhoto                                                 AS kennelUserPhoto,
        hkm.KennelHashName                                                  AS kennelHashName,
        hkm.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(hkm.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @userId AND hkm.updatedAt > @ua
    ORDER BY hkm.UserId ASC, hkm.updatedAt ASC, hkm.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- HASHER–EVENT MAP (user-scoped)
-- ---------------------------------------------------------------
IF (@hasherEventMapUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hasherEventMapUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        hem.id                                                              AS hemId,
        hem.UserId                                                          AS userId,
        hem.EventId                                                         AS eventId,
        hem.HasherOwnEventId                                                AS hasherOwnEventId,
        hem.UserStartEvent                                                  AS userStartEvent,
        hem.UserEndEvent                                                    AS userEndEvent,
        hem.RsvpState                                                       AS rsvpState,
        hem.AttendenceState                                                 AS attendenceState,
        hem.IsHare                                                          AS isHare,
        hem.EventNotificationPreference                                     AS eventNotificationPreference,
        hem.EventEmailAlertPreference                                       AS eventEmailAlertPreference,
        hem.EventCountOverride                                              AS eventCountOverride,
        hem.VirginVisitorType                                               AS virginVisitorType,
        hem.TotalHaring                                                     AS totalHaring,
        hem.TotalHaringThisKennel                                           AS totalHaringThisKennel,
        hem.TotalRuns                                                       AS totalRuns,
        hem.TotalRunsThisKennel                                             AS totalRunsThisKennel,
        hem.DisplayName                                                     AS displayName,
        hem.Email                                                           AS email,
        hem.PhoneNumber                                                     AS phoneNumber,
        evt.EventNumber                                                     AS hemEventNumber,
        evt.CountryId                                                       AS hemCountryId,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName  ELSE evt.EventName  END AS hemEventName,
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetime) END AS hemEventStartDatetime,
        COALESCE(evt.EventStartDatetimeGmt, evt.EventStartDatetime)        AS hemEventStartDatetimeGmt,
        evt.CanEditRunAttendence                                            AS hemCanEditRunAttendence,
        CASE WHEN evt.IsCountedRun != 0 AND evt.IsVisible != 0 THEN 1 ELSE 0 END AS hemEventIsCountedAndVisible,
        evt.KennelId                                                        AS hemEventKennelId,
        hkm.KennelUserPhoto                                                 AS hemKennelUserPhoto,
        hkm.KennelHashName                                                  AS hemKennelHashName,
        hem.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(hem.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.HasherEventMap hem
    INNER JOIN HC.Event evt ON hem.EventId = evt.id
    LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = hem.UserId AND hkm.KennelId = hem.KennelId
    WHERE hem.UserId = @userId AND hem.updatedAt > @ua
    ORDER BY hem.UserId ASC, hem.updatedAt ASC, hem.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- EVENTS – narrow sync (recent/followed/attended; skipped when force-replicate)
-- ---------------------------------------------------------------
IF (@narrowEventsUpdatedAfter != 'ignore' AND @forceKennelId IS NULL)
BEGIN
    SET @ua = CAST(@narrowEventsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        evt.id                                                              AS eventId,
        evt.PublicEventId                                                   AS publicEventId,
        evt.KennelId                                                        AS kennelId,
        evt.IsVisible                                                       AS isVisible,
        evt.IsCountedRun                                                    AS isCountedRun,
        evt.EventGeographicScope                                            AS eventGeographicScope,
        evt.InboundIntegrationId                                            AS eventInboundIntegrationId,
        evt.IsPromotedEvent                                                 AS isPromotedEvent,
        evt.EventNumber                                                     AS eventNumber,
        evt.EventPriceForMembers                                            AS eventPriceForMembers,
        evt.EventPriceForNonMembers                                         AS eventPriceForNonMembers,
        evt.EventPriceForExtras                                             AS eventPriceForExtras,
        evt.ExtrasDescription                                               AS extrasDescription,
        evt.DoTrackHashCash                                                 AS doTrackHashCash,
        evt.EventFacebookId                                                 AS eventFacebookId,
        evt.AbsoluteEventNumber                                             AS absoluteEventNumber,
        evt.CanEditRunAttendence                                            AS canEditRunAttendence,
        evt.Hares                                                           AS hares,
        evt.EventPaymentScheme                                              AS eventPaymentScheme,
        evt.EventPaymentUrl                                                 AS eventPaymentUrl,
        evt.EventPaymentUrlExpires                                          AS eventPaymentUrlExpires,
        evt.UnconfirmedBankXferCount                                        AS unconfirmedBankXferCount,
        evt.EvtDisseminateAllowWebLinks                                     AS evtDisseminateAllowWebLinks,
        evt.Tags1                                                           AS tags1,
        evt.Tags2                                                           AS tags2,
        evt.Tags3                                                           AS tags3,
        CASE WHEN evt.UseFbImage      = 1 THEN evt.FbEventImage         ELSE evt.EventImage         END AS eventImage,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName          ELSE evt.EventName          END AS eventName,
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetime) END AS eventStartDatetime,
        COALESCE(evt.EventStartDatetimeGmt, evt.EventStartDatetime)        AS eventStartDatetimeGmt,
        evt.SyncDescription                                                AS eventDescription,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc,
        evt.EventUrl                                                        AS eventUrl,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationPostCode   ELSE evt.LocationPostCode   END AS locationPostCode,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCity       ELSE evt.LocationCity       END AS locationCity,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationStreet     ELSE evt.LocationStreet     END AS locationStreet,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCountry    ELSE evt.LocationCountry    END AS locationCountry,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationRegion     ELSE evt.LocationRegion     END AS locationRegion,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationSubRegion  ELSE evt.LocationSubRegion  END AS locationSubRegion,
        evt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(evt.updatedAt AS DATETIME2))             AS updatedAt,
        evt.UseFbLocation                                                   AS useFbLocation,
        evt.UseFbLatLon                                                     AS useFbLatLon,
        evt.UseFbRunDetails                                                 AS useFbRunDetails,
        evt.UseFbImage                                                      AS useFbImage,
        evt.Latitude                                                        AS hcLatitude,
        evt.Longitude                                                       AS hcLongitude,
        evt.CountryId                                                       AS countryId,
        COALESCE(evt.w3wLatitude,  evt.FbLatitude)                          AS fbLatitude,
        COALESCE(evt.w3wLongitude, evt.FbLongitude)                         AS fbLongitude
    FROM HC.Event evt
    WHERE evt.updatedAt > @ua
      AND (
          evt.EventStartDatetimeIndexed > DATEADD(DAY, -@DAYS_PAST, GETDATE())
          OR evt.KennelId IN (SELECT hkm2.KennelId FROM HC.HasherKennelMap hkm2 WHERE hkm2.UserId = @userId AND hkm2.Following = 1)
          OR evt.id IN (SELECT hem2.EventId FROM HC.HasherEventMap hem2 WHERE hem2.UserId = @userId AND hem2.AttendenceState >= 3)
      )
    ORDER BY evt.updatedAt ASC, evt.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY
    OPTION (RECOMPILE);
END

-- ---------------------------------------------------------------
-- PAYMENTS (user-scoped)
-- ---------------------------------------------------------------
IF (@paymentsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@paymentsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        pmt.id                                                              AS paymentId,
        pmt.KennelId                                                        AS kennelId,
        pmt.UserId                                                          AS paidBy,
        pmt.HasherEventMapId                                                AS hemId,
        pmt.EventId                                                         AS eventId,
        pmt.PaymentProcessedBy_userId                                       AS paidTo,
        pmt.CreditAmount                                                    AS creditAmount,
        pmt.DebitAmount                                                     AS debitAmount,
        pmt.CreditAvailable                                                 AS creditAvailable,
        CAST(pmt.PaidDate AS DATETIME)                                      AS paidDate,
        pmt.PaymentType                                                     AS paymentType,
        pmt.ProductType                                                     AS productType,
        CAST(pmt.CancelledDate AS DATETIME)                                 AS cancelledDate,
        pmt.CancelledBy_UserId                                              AS cancelledBy,
        CAST(pmt.ConfirmedDate AS DATETIME)                                 AS confirmedDate,
        pmt.ConfirmedBy_UserId                                              AS confirmedBy,
        pmt.PaymentReference                                                AS paymentReference,
        pmt.DiscountAmount                                                  AS discountAmount,
        pmt.DiscountPercent                                                 AS discountPercent,
        pmt.DiscountDescription                                             AS discountDescription,
        pmt.SpecialRunPriceReason                                           AS specialRunPriceReason,
        pmt.Notes                                                           AS notes,
        pmt.DoPayForExtras                                                  AS doPayForExtras,
        pmt.Surcharge                                                       AS surcharge,
        pmt.PaymentProvider                                                 AS paymentProvider,
        pmt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(pmt.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.Payment pmt
    WHERE pmt.UserId = @userId AND pmt.updatedAt > @ua
    ORDER BY pmt.updatedAt ASC, pmt.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- EVENTS – force replicate all for a specific kennel
-- ---------------------------------------------------------------
IF (@forceKennelId IS NOT NULL)
BEGIN
    SELECT
        evt.id                                                              AS eventId,
        evt.PublicEventId                                                   AS publicEventId,
        evt.KennelId                                                        AS kennelId,
        evt.IsVisible                                                       AS isVisible,
        evt.IsCountedRun                                                    AS isCountedRun,
        evt.EventGeographicScope                                            AS eventGeographicScope,
        evt.InboundIntegrationId                                            AS eventInboundIntegrationId,
        evt.IsPromotedEvent                                                 AS isPromotedEvent,
        evt.EventNumber                                                     AS eventNumber,
        evt.EventPriceForMembers                                            AS eventPriceForMembers,
        evt.EventPriceForNonMembers                                         AS eventPriceForNonMembers,
        evt.EventPriceForExtras                                             AS eventPriceForExtras,
        evt.ExtrasDescription                                               AS extrasDescription,
        evt.DoTrackHashCash                                                 AS doTrackHashCash,
        evt.EventFacebookId                                                 AS eventFacebookId,
        evt.AbsoluteEventNumber                                             AS absoluteEventNumber,
        evt.CanEditRunAttendence                                            AS canEditRunAttendence,
        evt.Hares                                                           AS hares,
        evt.EventPaymentScheme                                              AS eventPaymentScheme,
        evt.EventPaymentUrl                                                 AS eventPaymentUrl,
        evt.EventPaymentUrlExpires                                          AS eventPaymentUrlExpires,
        evt.UnconfirmedBankXferCount                                        AS unconfirmedBankXferCount,
        evt.EvtDisseminateAllowWebLinks                                     AS evtDisseminateAllowWebLinks,
        evt.Tags1                                                           AS tags1,
        evt.Tags2                                                           AS tags2,
        evt.Tags3                                                           AS tags3,
        CASE WHEN evt.UseFbImage      = 1 THEN evt.FbEventImage         ELSE evt.EventImage         END AS eventImage,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName          ELSE evt.EventName          END AS eventName,
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetime) END AS eventStartDatetime,
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetimeGmt) END AS eventStartDatetimeGmt,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventDescription   ELSE evt.EventDescription   END AS eventDescription,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc,
        evt.EventUrl                                                        AS eventUrl,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationPostCode   ELSE evt.LocationPostCode   END AS locationPostCode,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCity       ELSE evt.LocationCity       END AS locationCity,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationStreet     ELSE evt.LocationStreet     END AS locationStreet,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCountry    ELSE evt.LocationCountry    END AS locationCountry,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationRegion     ELSE evt.LocationRegion     END AS locationRegion,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationSubRegion  ELSE evt.LocationSubRegion  END AS locationSubRegion,
        evt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(evt.updatedAt AS DATETIME2))             AS updatedAt,
        evt.UseFbLocation                                                   AS useFbLocation,
        evt.UseFbLatLon                                                     AS useFbLatLon,
        evt.UseFbRunDetails                                                 AS useFbRunDetails,
        evt.UseFbImage                                                      AS useFbImage,
        evt.Latitude                                                        AS hcLatitude,
        evt.Longitude                                                       AS hcLongitude,
        evt.CountryId                                                       AS countryId,
        COALESCE(evt.w3wLatitude,  evt.FbLatitude)                          AS fbLatitude,
        COALESCE(evt.w3wLongitude, evt.FbLongitude)                         AS fbLongitude
    FROM HC.Event evt
    WHERE evt.KennelId = @forceKennelId
      AND (
          evt.EventStartDatetimeIndexed > DATEADD(DAY, -@DAYS_PAST, GETDATE())
          OR evt.KennelId IN (SELECT hkm2.KennelId FROM HC.HasherKennelMap hkm2 WHERE hkm2.UserId = @userId AND hkm2.Following = 1)
          OR evt.id IN (SELECT hem2.EventId FROM HC.HasherEventMap hem2 WHERE hem2.UserId = @userId AND hem2.AttendenceState >= 3)
      )
    ORDER BY evt.updatedAt ASC, evt.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY
    OPTION (RECOMPILE);
END
