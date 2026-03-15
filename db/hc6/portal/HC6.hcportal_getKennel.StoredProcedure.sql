CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennel]

	-- required parameters
	@publicHasherId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennel
-- Description: Retrieves comprehensive details for a single kennel by
--              its public ID. Returns kennel profile, location info,
--              website settings, payment configuration, default run
--              settings, and related geographic data. Used by both
--              admin portal and public HashRuns.org sites.
-- Parameters: @publicHasherId, @accessToken (auth)
--             @publicKennelId (routing)
-- Returns: Single rowset with 70+ columns of kennel detail, or error
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getKennel
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Removed dead variable @isAdmin (was only used for log prefix)
--   - Log prefix now always 'Admin Portal: hcportal_getKennel'
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, @publicKennelId, @authError OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: hasher exists (skip for magic service account GUIDs)
	-- 11111111-... = HashRuns.org public access
	-- 22222222-... = admin portal service account
	IF (@publicHasherId != '11111111-1111-1111-1111-111111111111') AND (@publicHasherId != '22222222-2222-2222-2222-222222222222')
	BEGIN
		DECLARE @hasherId UNIQUEIDENTIFIER
		SELECT @hasherId = id FROM HC.Hasher WHERE PublicHasherId = @publicHasherId

		IF @hasherId IS NULL
		BEGIN
			SELECT 0 AS Success, 'Hasher not found' AS ErrorMessage;
			RETURN;
		END
	END

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Resolve kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER
	SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId

	-- Validation: kennel exists
	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
		RETURN;
	END

	-- Main query (read-only, no transaction needed)
	SELECT
		  k.PublicKennelId as kennelPublicId
		, k.KennelName as kennelName
		, k.KennelShortName as kennelShortName
		, k.KennelUniqueShortName as kennelUniqueShortName
		, k.KennelLogo as kennelLogo
		, k.KennelDescription as kennelDescription
		, k.Latitude as latitude
		, k.Longitude as longitude
		, c.latitude as defaultLatitude
		, c.longitude as defaultLongitude
		, k.ExcludeFromLeaderboard as excludeFromLeaderboard
		, k.PublishToGoogleCalendar as publishToGoogleCalendar
		, k.PublishToGoogleCalendarAddresses as publishToGoogleCalendarAddresses
		, k.KennelMismanagementTeam as mismanagementTeam
		, k.KennelWebsiteUrl as kennelWebsiteUrl
		, k.KennelCoverPhoto as kennelCoverPhoto
		, c.CityName as cityName
		, r.RegionName as regionName
		, n.CountryName as countryName
		, n.ContinentName as continentName
		, n.FlagFile as countryFlag
		, r.FlagFile as regionFlag
		, c.FlagFile as cityFlag
		, k.[WebsiteBackgroundColor] as websiteBackgroundColor
		, k.[WebsiteBackgroundImage] as websiteBackgroundImage
		, k.[WebsiteTitleText] as websiteTitleText
		, k.[WebsiteMenuBackgroundColor] as websiteMenuBackgroundColor
		, k.[WebsiteMenuTextColor] as websiteMenuTextColor
		, k.[WebsiteWelcomeText] as websiteWelcomeText
		, k.[WebsiteBodyTextColor] as websiteBodyTextColor
		, k.[WebsiteTitleTextColor] as websiteTitleTextColor
		, k.[WebsiteMismanagementDescription] as websiteMismanagementDescription
		, k.[WebsiteMismanagementJson] as websiteMismanagementJson
		, k.[WebsiteExtraMenusJson] as websiteExtraMenusJson
		, k.[WebsiteControlFlags] as websiteControlFlags
		, k.[WebsiteContactDetailsJson] as websiteContactDetailsJson
		, k.[WebsiteBannerImage] as websiteBannerImage
		, k.[WebsiteUrlShortcode] as websiteUrlShortcode
		, k.[WebsiteTitleFont] as websiteTitleFont
		, k.[WebsiteBodyFont] as websiteBodyFont
		, k.[KennelStatus] as kennelStatus
		, k.[KennelAdminEmailList] as kennelAdminEmailList
		, k.[DisseminateHashRunsDotOrg] as disseminateHashRunsDotOrg
		, k.[DisseminateAllowWebLinks] as disseminateAllowWebLinks
		, k.[DisseminationAudience] as disseminationAudience
		, k.[DisseminateOnGlobalGoogleCalendar] as disseminateOnGlobalGoogleCalendar
		, k.[CanEditRunAttendence] as canEditRunAttendence
		, k.[KennelPinColor] as kennelPinColor
		, k.[KennelEventsUrl] as kennelEventsUrl
		, k.[KennelHcEventsUrl] as kennelHcEventsUrl
		, k.[DefaultEventPriceForMembers] as defaultEventPriceForMembers
		, k.[DefaultEventPriceForNonMembers] as defaultEventPriceForNonMembers
		, CAST(k.[DefaultRunStartTime] as DateTime) as defaultRunStartTime
		, k.[BankScheme] as bankScheme
		, k.[BankAccountNumber] as bankAccountNumber
		, k.[BankBic] as bankBic
		, k.[BankBeneficiary] as bankBeneficiary
		, k.[KennelPaymentScheme] as kennelPaymentScheme
		, k.[KennelPaymentUrl] as kennelPaymentUrl
		, k.[KennelPaymentUrlExpires] as kennelPaymentUrlExpires
		, k.[KennelPaymentMemberSurcharge] as kennelPaymentMemberSurcharge
		, k.[KennelPaymentNonMemberSurcharge] as kennelPaymentNonMemberSurcharge
		, k.[KennelPaymentScheme2] as kennelPaymentScheme2
		, k.[KennelPaymentUrl2] as kennelPaymentUrl2
		, k.[KennelPaymentUrlExpires2] as kennelPaymentUrlExpires2
		, k.[KennelPaymentMemberSurcharge2] as kennelPaymentMemberSurcharge2
		, k.[KennelPaymentNonMemberSurcharge2] as kennelPaymentNonMemberSurcharge2
		, k.[KennelPaymentScheme3] as kennelPaymentScheme3
		, k.[KennelPaymentUrl3] as kennelPaymentUrl3
		, k.[KennelPaymentUrlExpires3] as kennelPaymentUrlExpires3
		, k.[KennelPaymentMemberSurcharge3] as kennelPaymentMemberSurcharge3
		, k.[KennelPaymentNonMemberSurcharge3] as kennelPaymentNonMemberSurcharge3
		, k.[AllowSelfPayment] as allowSelfPayment
		, k.[AllowNegativeCredit] as allowNegativeCredit
		, k.[CityId] as cityId
		, k.[ProvinceStateId] as provinceStateId
		, k.[CountryId] as countryId
		, k.[DefaultRunTags1] as defaultRunTags1
		, k.[DefaultRunTags2] as defaultRunTags2
		, k.[DefaultRunTags3] as defaultRunTags3
		, k.[MembershipDurationInMonths] as membershipDurationInMonths
		, k.[RunCountStartDate] as runCountStartDate
		, k.[DistancePreference] as distancePreference
		, n.[DistancePreference] as defaultDistancePreference
		, k.[ExtApiKey] as extApiKey
		, k.[KennelSearchTags] as kennelSearchTags
		, k.[NotificationMinutesBeforeRunForChatPushNotifications] as notificationMinutesBeforeRunForChatPushNotifications
		, k.[NotificationMinutesBeforeRunForCheckinReminder] as notificationMinutesBeforeRunForCheckinReminder
	FROM HC.Kennel k
	INNER JOIN HC.City c on c.id = k.CityId
	INNER JOIN HC.Region r on r.id = c.RegionId
	INNER JOIN HC.Country n on n.id = r.CountryId
	WHERE k.PublicKennelId = @publicKennelId

END TRY
BEGIN CATCH
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
