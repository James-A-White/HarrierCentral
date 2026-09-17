-- =====================================================================
-- Procedure: HC6.publicWeb_getMyKennels
-- Description: The app's Kennels tab for a web member (E9.F7.S9): every
--   eligible kennel (KennelStatus NOT IN (-1, 4) — the app's rule) with
--   the member's own HasherKennelMap row alongside where one exists, and
--   everything the app's kennel card and kennel page draw from the synced
--   tables: following / home / member state, notification and email
--   preferences, run and haring counts, date of last run, credit, the
--   location line as the app composes it (city, region when the country
--   says so, country), the city's coordinates for "N km from here" and the
--   kennel map, the kennel's last and next run, default prices (the app's
--   "Hash cash" rows), and a search text for the app's comma / plus / not
--   search. Sorting is the client's (the app's speed dial).
-- Parameters: @deviceId, @accessToken (the browser's device row + token)
-- Returns: rowset 0 envelope; rowset 1 one row per kennel
-- Author: Harrier Central
-- Created: 2026-09-16   v2 2026-09-17 (all eligible kennels, card fields)
-- HC5 Source: none — reads what hcapp_syncUserData syncs
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyKennels]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
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
        k.KennelCoverPhoto,
        k.KennelStatus,
        c.CityName                                              AS City,
        rgn.RegionName                                          AS Region,
        ctr.CountryName                                         AS Country,
        -- The app's location line (query_kennels.dart): city, region when
        -- the country shows regions, country.
        CASE WHEN c.CityName IS NULL THEN COALESCE(ctr.CountryName, '')
             ELSE c.CityName + ', '
                  + CASE WHEN COALESCE(ctr.ShowRegion, 0) = 1 AND rgn.RegionName IS NOT NULL THEN rgn.RegionName + ', ' ELSE '' END
                  + COALESCE(ctr.CountryName, '') END          AS Location,
        c.Latitude                                              AS CityLat,
        c.Longitude                                             AS CityLon,
        kw.CustomDomain                                         AS KennelWebsiteDomain,
        CASE WHEN hkm.id IS NULL THEN 0 ELSE 1 END              AS HasHkm,
        COALESCE(hkm.Following, 0)                              AS Following,
        COALESCE(hkm.IsHomeKennel, 0)                           AS IsHomeKennel,
        COALESCE(hkm.IsMember, 0)                               AS IsMember,
        COALESCE(hkm.KennelNotificationPreference, 0)           AS KennelNotificationPref,
        COALESCE(hkm.KennelEmailAlertPreference, 0)             AS KennelEmailAlertPref,
        hkm.MembershipExpirationDate,
        hkm.MemberSince,
        hkm.DateOfLastRun,
        COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS Runs,
        COALESCE(hkm.HcHaringCount, 0)   + COALESCE(hkm.HistoricalHaringCount, 0)   AS Haring,
        COALESCE(hkm.HistoricalCountIsEstimate, 0)              AS IsEstimate,
        k.KennelDescription,
        k.KennelWebsiteUrl,
        k.KennelMismanagementTeam,
        k.MessagingGroupInviteUrl,
        COALESCE(k.DefaultMessagingPlatform, 1)                 AS DefaultMessagingPlatform,
        COALESCE(k.AllowSelfPayment, 0)                         AS AllowSelfPayment,
        COALESCE(hkm.KennelCredit, 0)                           AS KennelCredit,
        COALESCE(k.CurrencySymbol, ctr.CurrencySymbol, '$^')     AS CurrencySymbol,
        COALESCE(k.DigitsAfterDecimal, ctr.DigitsAfterDecimal, 2) AS DigitsAfterDecimal,
        COALESCE(k.DistancePreference, ctr.DistancePreference, 0) AS DistanceUnitsPref,
        COALESCE(k.DefaultEventPriceForMembers, 0)              AS DefaultPriceMembers,
        COALESCE(k.DefaultEventPriceForNonMembers, 0)           AS DefaultPriceNonMembers,
        COALESCE(k.ExcludeFromLeaderboard, 0)                   AS ExcludeFromLeaderboard,
        lst.EventStartDatetimeGmt                               AS LastRunGmt,
        CAST(lst.EventStartDatetime AS datetime2(7))            AS LastRunLocal,
        lst.EventNumber                                         AS LastRunNumber,
        nxt.EventStartDatetimeGmt                               AS NextRunGmt,
        CAST(nxt.EventStartDatetime AS datetime2(7))            AS NextRunLocal,
        nxt.EventNumber                                         AS NextRunNumber,
        nxt.EventName                                           AS NextRunName,
        nxt.PublicEventId                                       AS NextRunPublicEventId,
        -- The app's searchKennelsText: a leading space before every word so
        -- a term matches at a word start; the four *SearchTags included
        -- ("Scotland" is neither a region nor a country).
        LOWER(' ' + k.KennelName + ' ' + k.KennelShortName + ' ' + k.KennelUniqueShortName
              + ' ' + COALESCE(c.CityName, '') + ' ' + COALESCE(rgn.RegionName, '') + ' ' + COALESCE(ctr.CountryName, '')
              + ' ' + REPLACE(COALESCE(k.KennelSearchTags, ''),    ',', ' ')
              + ' ' + REPLACE(COALESCE(c.CitySearchTags, ''),      ',', ' ')
              + ' ' + REPLACE(COALESCE(rgn.RegionSearchTags, ''),  ',', ' ')
              + ' ' + REPLACE(COALESCE(ctr.CountrySearchTags, ''), ',', ' '))
                                                                AS SearchText
    FROM HC.Kennel k
    LEFT JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = @userId AND hkm.removed = 0
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
    OUTER APPLY (
        SELECT TOP 1 e.EventNumber, e.EventStartDatetime, e.EventStartDatetimeGmt
        FROM HC.Event e
        WHERE e.KennelId = k.id AND e.IsVisible = 1 AND e.deleted = 0 AND e.removed = 0
          AND e.EventStartDateTimeGmt < @now
        ORDER BY e.EventStartDateTimeGmt DESC
    ) lst
    WHERE k.deleted = 0 AND k.removed = 0
      AND (COALESCE(k.KennelStatus, 2) NOT IN (-1, 4)
           OR COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) > 0
           OR hkm.IsHomeKennel = 1)
    ORDER BY k.KennelName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyKennels', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
GO
