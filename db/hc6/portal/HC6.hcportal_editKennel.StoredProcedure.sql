CREATE OR ALTER PROCEDURE [HC6].[hcportal_editKennel]

	-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL,

	-- optional parameters
	@kennelStatus SMALLINT = NULL,
	@kennelName NVARCHAR(250) = NULL,
	@kennelAdminEmailList NVARCHAR(2000) = NULL,
	@disseminateHashRunsDotOrg SMALLINT = NULL,
	@disseminateAllowWebLinks SMALLINT = NULL,
	@disseminationAudience INT = NULL,
	@disseminateOnGlobalGoogleCalendar SMALLINT = NULL,
	@googleCalendarId NVARCHAR(250) = NULL,
	@publishToGoogleCalendar SMALLINT = NULL,
	@publishToGoogleCalendarAddresses NVARCHAR(1000) = NULL,
	@canEditRunAttendence SMALLINT = NULL,
	@kennelShortName NVARCHAR(25) = NULL,
	@kennelUniqueShortName NVARCHAR(50) = NULL,
	@kennelDescription NVARCHAR(4000) = NULL,
	@kennelLogo NVARCHAR(500) = NULL,
	@kennelPinColor SMALLINT = NULL,
	@kennelCoverPhoto NVARCHAR(500) = NULL,
	@kennelWebsiteUrl NVARCHAR(500) = NULL,
	@kennelEventsUrl NVARCHAR(500) = NULL,
	@kennelHcEventsUrl NVARCHAR(500) = NULL,
	@kennelMismanagementTeam NVARCHAR(4000) = NULL,
	@defaultEventPriceForMembers DECIMAL(10, 4) = NULL,
	@defaultEventPriceForNonMembers DECIMAL(10, 4) = NULL,
	@defaultEventCurrencyType NVARCHAR(10) = NULL,
	@defaultRunStartTime TIME(7) = NULL,
	@currencyCode NVARCHAR(5) = NULL,
	@primaryCultureCode NVARCHAR(10) = NULL,
	@currencySymbol NVARCHAR(5) = NULL,
	@digitsAfterDecimal SMALLINT = NULL,
	@bankScheme NVARCHAR(10) = NULL,
	@bankAccountNumber NVARCHAR(50) = NULL,
	@bankBic NVARCHAR(50) = NULL,
	@bankBeneficiary NVARCHAR(150) = NULL,
	@kennelPaymentScheme NVARCHAR(50) = NULL,
	@kennelPaymentUrl NVARCHAR(2000) = NULL,
	@kennelPaymentUrlExpires DATETIMEOFFSET(7) = NULL,
	@kennelPaymentMemberSurcharge DECIMAL(10, 4) = NULL,
	@kennelPaymentNonMemberSurcharge DECIMAL(10, 4) = NULL,
	@kennelPaymentScheme2 NVARCHAR(50) = NULL,
	@kennelPaymentUrl2 NVARCHAR(2000) = NULL,
	@kennelPaymentUrlExpires2 DATETIMEOFFSET(7) = NULL,
	@kennelPaymentMemberSurcharge2 DECIMAL(10, 4) = NULL,
	@kennelPaymentNonMemberSurcharge2 DECIMAL(10, 4) = NULL,
	@kennelPaymentScheme3 NVARCHAR(50) = NULL,
	@kennelPaymentUrl3 NVARCHAR(2000) = NULL,
	@kennelPaymentUrlExpires3 DATETIMEOFFSET(7) = NULL,
	@kennelPaymentMemberSurcharge3 DECIMAL(10, 4) = NULL,
	@kennelPaymentNonMemberSurcharge3 DECIMAL(10, 4) = NULL,
	@kennelFeaturesTier SMALLINT = NULL,
	@kennelFeaturesExpire DATETIMEOFFSET(7) = NULL,
	@kennelGoogleSheetApiKey NVARCHAR(250) = NULL,
	@allowSelfPayment SMALLINT = NULL,
	@allowNegativeCredit SMALLINT = NULL,
	@cityId UNIQUEIDENTIFIER = NULL,
	@provinceStateId UNIQUEIDENTIFIER = NULL,
	@countryId UNIQUEIDENTIFIER = NULL,
	@latitude DECIMAL(18, 14) = NULL,
	@longitude DECIMAL(19, 15) = NULL,
	@defaultRunTags1 INT = NULL,
	@defaultRunTags2 INT = NULL,
	@defaultRunTags3 INT = NULL,
	@kennelGeolocation GEOGRAPHY = NULL,
	@membershipDurationInMonths INT = NULL,
	@runCountStartDate DATETIMEOFFSET(7) = NULL,
	@distancePreference SMALLINT = NULL,
	@extApiKey NVARCHAR(120) = NULL,
	@kennelSearchTags NVARCHAR(4000) = NULL,
	@excludeFromLeaderboard SMALLINT = NULL,
	@notificationMinutesBeforeRunForChatPushNotifications SMALLINT = NULL,
	@notificationMinutesBeforeRunForCheckinReminder SMALLINT = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_editKennel
-- Description: Updates an existing kennel's settings. Update-only (no
--              insert path). Covers kennel identity, dissemination,
--              Google Calendar, payment config (3 slots), pricing,
--              currency, location, tags, membership, notifications,
--              and feature tier. Includes duplicate-name detection with
--              auto-suggested alternatives for KennelUniqueShortName.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing)
--             ~60 optional kennel settings via COALESCE pattern
-- Returns: SuccessResult rowset (result, resultCode) or error envelope
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_editKennel
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - @kennelUniqueShortName widened from NVARCHAR(25) to NVARCHAR(50)
--   - @disseminateOnGlobalGoogleCalendar narrowed from INT to SMALLINT
--     (matches table column)
--   - Lat/lon sentinel changed from 999 to -999.0 (consistent with
--     addEditEvent2 conventions)
--   - Removed dead variable @isAdmin
--   - Fixed wrong SP name in LOG.GeneralLog (was hcportal_addEditEvent)
--   - UPDATE wrapped in transaction
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
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, OBJECT_NAME(@@PROCID), @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Validation: kennelUniqueShortName uniqueness
	IF @kennelUniqueShortName IS NOT NULL
	BEGIN
		IF (SELECT COUNT(*) FROM HC.Kennel WHERE KennelUniqueShortName = @kennelUniqueShortName AND PublicKennelId != @publicKennelId) != 0
		BEGIN
			DECLARE @shortName AS NVARCHAR(50),
					@shortNameWithCountry AS NVARCHAR(50)

			SELECT @shortName = KennelShortName FROM HC.Kennel WHERE KennelUniqueShortName = @kennelUniqueShortName AND PublicKennelId != @publicKennelId

			SELECT @shortNameWithCountry = @shortName + '-' + c.CountryCode FROM HC.Kennel ken
			INNER JOIN HC.Country c on ken.CountryId = c.id
			WHERE ken.PublicKennelId = @publicKennelId

			IF (SELECT COUNT(*) FROM HC.Kennel ken WHERE ken.KennelUniqueShortName = @shortNameWithCountry AND PublicKennelId != @publicKennelId) != 0
			BEGIN
				SET @shortNameWithCountry = NULL
			END

			DECLARE @counter INT = 2
			DECLARE @validName NVARCHAR(500)

			WHILE @counter <= 100
			BEGIN
				SET @validName = @shortName + '-' + CAST(@counter AS NVARCHAR(50))
				IF (SELECT COUNT(*) FROM HC.Kennel WHERE KennelUniqueShortName = @validName AND PublicKennelId != @publicKennelId) = 0
				BEGIN
					BREAK;
				END

				SET @counter = @counter + 1;
			END;

			IF @shortNameWithCountry IS NOT NULL
			BEGIN
				SET @validName = @validName + ' and ' + @shortNameWithCountry + ' are not yet taken. Please use one of these or try another unique name.'
			END
			ELSE
			BEGIN
				SET @validName = @validName + ' is not yet taken. Please use this one or try another unique name.'
			END

			SELECT 0 AS Success,
				@kennelUniqueShortName + ' already exists in Harrier Central. ' + @validName AS ErrorMessage;
			RETURN;
		END
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

	-- Main update (wrapped in transaction)
	BEGIN TRANSACTION;

	UPDATE HC.Kennel
	SET
		KennelStatus = COALESCE(@kennelStatus, KennelStatus),
		KennelName = COALESCE(@kennelName, KennelName),
		KennelAdminEmailList = COALESCE(@kennelAdminEmailList, KennelAdminEmailList),
		DisseminateHashRunsDotOrg = COALESCE(@disseminateHashRunsDotOrg, DisseminateHashRunsDotOrg),
		DisseminateAllowWebLinks = COALESCE(@disseminateAllowWebLinks, DisseminateAllowWebLinks),
		DisseminationAudience = COALESCE(@disseminationAudience, DisseminationAudience),
		DisseminateOnGlobalGoogleCalendar = COALESCE(@disseminateOnGlobalGoogleCalendar, DisseminateOnGlobalGoogleCalendar),
		GoogleCalendarId = COALESCE(@googleCalendarId, GoogleCalendarId),
		PublishToGoogleCalendar = COALESCE(@publishToGoogleCalendar, PublishToGoogleCalendar),
		PublishToGoogleCalendarAddresses = COALESCE(@publishToGoogleCalendarAddresses, PublishToGoogleCalendarAddresses),
		CanEditRunAttendence = COALESCE(@canEditRunAttendence, CanEditRunAttendence),
		KennelShortName = COALESCE(@kennelShortName, KennelShortName),
		KennelUniqueShortName = COALESCE(@kennelUniqueShortName, KennelUniqueShortName),
		KennelDescription = COALESCE(@kennelDescription, KennelDescription),
		KennelLogo = COALESCE(@kennelLogo, KennelLogo),
		KennelPinColor = COALESCE(@kennelPinColor, KennelPinColor),
		KennelCoverPhoto = COALESCE(@kennelCoverPhoto, KennelCoverPhoto),
		KennelWebsiteUrl = COALESCE(@kennelWebsiteUrl, KennelWebsiteUrl),
		KennelEventsUrl = COALESCE(@kennelEventsUrl, KennelEventsUrl),
		KennelHcEventsUrl = COALESCE(@kennelHcEventsUrl, KennelHcEventsUrl),
		KennelMismanagementTeam = COALESCE(@kennelMismanagementTeam, KennelMismanagementTeam),
		DefaultEventPriceForMembers = COALESCE(@defaultEventPriceForMembers, DefaultEventPriceForMembers),
		DefaultEventPriceForNonMembers = COALESCE(@defaultEventPriceForNonMembers, DefaultEventPriceForNonMembers),
		DefaultEventCurrencyType = COALESCE(@defaultEventCurrencyType, DefaultEventCurrencyType),
		DefaultRunStartTime = COALESCE(@defaultRunStartTime, DefaultRunStartTime),
		CurrencyCode = COALESCE(@currencyCode, CurrencyCode),
		PrimaryCultureCode = COALESCE(@primaryCultureCode, PrimaryCultureCode),
		CurrencySymbol = COALESCE(@currencySymbol, CurrencySymbol),
		DigitsAfterDecimal = COALESCE(@digitsAfterDecimal, DigitsAfterDecimal),
		BankScheme = COALESCE(@bankScheme, BankScheme),
		BankAccountNumber = COALESCE(@bankAccountNumber, BankAccountNumber),
		BankBic = COALESCE(@bankBic, BankBic),
		BankBeneficiary = COALESCE(@bankBeneficiary, BankBeneficiary),
		KennelPaymentScheme = COALESCE(@kennelPaymentScheme, KennelPaymentScheme),
		KennelPaymentUrl = COALESCE(@kennelPaymentUrl, KennelPaymentUrl),
		KennelPaymentUrlExpires = COALESCE(@kennelPaymentUrlExpires, KennelPaymentUrlExpires),
		KennelPaymentMemberSurcharge = COALESCE(@kennelPaymentMemberSurcharge, KennelPaymentMemberSurcharge),
		KennelPaymentNonMemberSurcharge = COALESCE(@kennelPaymentNonMemberSurcharge, KennelPaymentNonMemberSurcharge),
		KennelPaymentScheme2 = COALESCE(@kennelPaymentScheme2, KennelPaymentScheme2),
		KennelPaymentUrl2 = COALESCE(@kennelPaymentUrl2, KennelPaymentUrl2),
		KennelPaymentUrlExpires2 = COALESCE(@kennelPaymentUrlExpires2, KennelPaymentUrlExpires2),
		KennelPaymentMemberSurcharge2 = COALESCE(@kennelPaymentMemberSurcharge2, KennelPaymentMemberSurcharge2),
		KennelPaymentNonMemberSurcharge2 = COALESCE(@kennelPaymentNonMemberSurcharge2, KennelPaymentNonMemberSurcharge2),
		KennelPaymentScheme3 = COALESCE(@kennelPaymentScheme3, KennelPaymentScheme3),
		KennelPaymentUrl3 = COALESCE(@kennelPaymentUrl3, KennelPaymentUrl3),
		KennelPaymentUrlExpires3 = COALESCE(@kennelPaymentUrlExpires3, KennelPaymentUrlExpires3),
		KennelPaymentMemberSurcharge3 = COALESCE(@kennelPaymentMemberSurcharge3, KennelPaymentMemberSurcharge3),
		KennelPaymentNonMemberSurcharge3 = COALESCE(@kennelPaymentNonMemberSurcharge3, KennelPaymentNonMemberSurcharge3),
		KennelFeaturesTier = COALESCE(@kennelFeaturesTier, KennelFeaturesTier),
		KennelFeaturesExpire = COALESCE(@kennelFeaturesExpire, KennelFeaturesExpire),
		KennelGoogleSheetApiKey = COALESCE(@kennelGoogleSheetApiKey, KennelGoogleSheetApiKey),
		AllowSelfPayment = COALESCE(@allowSelfPayment, AllowSelfPayment),
		AllowNegativeCredit = COALESCE(@allowNegativeCredit, AllowNegativeCredit),
		CityId = COALESCE(@cityId, CityId),
		ProvinceStateId = COALESCE(@provinceStateId, ProvinceStateId),
		CountryId = COALESCE(@countryId, CountryId),
		Latitude = CASE WHEN ((@latitude = -999.0) OR (@longitude = -999.0)) THEN NULL ELSE COALESCE(@latitude, Latitude) END,
		Longitude = CASE WHEN ((@latitude = -999.0) OR (@longitude = -999.0)) THEN NULL ELSE COALESCE(@longitude, Longitude) END,
		DefaultRunTags1 = COALESCE(@defaultRunTags1, DefaultRunTags1),
		DefaultRunTags2 = COALESCE(@defaultRunTags2, DefaultRunTags2),
		DefaultRunTags3 = COALESCE(@defaultRunTags3, DefaultRunTags3),
		KennelGeolocation = COALESCE(@kennelGeolocation, KennelGeolocation),
		MembershipDurationInMonths = COALESCE(@membershipDurationInMonths, MembershipDurationInMonths),
		RunCountStartDate = COALESCE(@runCountStartDate, RunCountStartDate),
		DistancePreference = COALESCE(@distancePreference, DistancePreference),
		ExtApiKey = COALESCE(@extApiKey, ExtApiKey),
		KennelSearchTags = COALESCE(@kennelSearchTags, KennelSearchTags),
		ExcludeFromLeaderboard = COALESCE(@excludeFromLeaderboard, ExcludeFromLeaderboard),
		NotificationMinutesBeforeRunForChatPushNotifications = COALESCE(@notificationMinutesBeforeRunForChatPushNotifications, NotificationMinutesBeforeRunForChatPushNotifications),
		NotificationMinutesBeforeRunForCheckinReminder = COALESCE(@notificationMinutesBeforeRunForCheckinReminder, NotificationMinutesBeforeRunForCheckinReminder),
		updatedAt = SYSUTCDATETIME()
	WHERE id = @kennelId;

	COMMIT TRANSACTION;

	SELECT 'Kennel updated successfully' AS result, 1 AS resultCode

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
