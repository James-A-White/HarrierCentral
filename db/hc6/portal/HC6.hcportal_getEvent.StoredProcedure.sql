CREATE OR ALTER PROCEDURE [HC6].[hcportal_getEvent]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@includePaymentInfo INT = 0,

	-- optional parameters
	@publicEventId UNIQUEIDENTIFIER = NULL,
	@kennelUniqueShortName NVARCHAR(50) = NULL,
	@runDesignator NVARCHAR(50) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getEvent
-- Description: Retrieves event details by publicEventId, kennel short
--              name + runDesignator, or special keywords 'nextrun'/
--              'lastrun'. Returns event details rowset and optionally
--              an attendee list (with or without payment info).
--              Used by both admin portal and public HashRuns.org site.
-- Parameters: @deviceId (auth), @accessToken (auth),
--             @includePaymentInfo (0=basic attendees, 1=full payment),
--             @publicEventId (direct lookup),
--             @kennelUniqueShortName + @runDesignator (indirect lookup)
-- Returns: Rowset 0: EventDetails (single row)
--          Rowset 1: AttendeeList (basic or with payment details)
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getEvent
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Token validation RE-ENABLED (was commented out in HC5)
--   - Removed eventChatMessageCount (obsolete, was hardcoded to 0)
--   - Removed @isAdmin variable (was set but never used in output)
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - @publicHasherId replaced by @deviceId (device-bound auth via HC.Device lookup)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicEventId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicEventId (re-enabled from HC5 where it was commented out)
	IF (@publicEventId IS NULL) AND (@kennelUniqueShortName IS NULL) AND (@runDesignator IS NULL)
	BEGIN
		SELECT 0 AS Success, 'No event identifier provided (publicEventId or kennelUniqueShortName+runDesignator required)' AS ErrorMessage;
		RETURN;
	END

	-- Resolve event ID from parameters
	DECLARE @eventId UNIQUEIDENTIFIER
	DECLARE @kennelId UNIQUEIDENTIFIER

	IF (@publicEventId IS NOT NULL)
	BEGIN
		SELECT @eventId = id FROM HC.Event WHERE PublicEventId = @publicEventId
	END
	ELSE IF (LOWER(@runDesignator) = 'nextrun')
	BEGIN
		;WITH cte AS (
			SELECT
				ken.id AS kennelId,
				evt.id AS evtId,
				ROW_NUMBER() OVER (PARTITION BY KennelID ORDER BY EventStartDatetime ASC) AS RowNumber
			FROM HC.Event evt
			INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
			INNER JOIN HC.City c ON ken.CityId = c.id
			INNER JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
			WHERE
				ken.KennelUniqueShortName = @kennelUniqueShortName AND
				evt.removed = 0 AND
				DATEADD(HOUR, 4, (CAST(evt.EventStartDatetime AS DATETIME) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC') > GETUTCDATE()
		)
		SELECT @kennelId = cte.kennelId, @eventId = cte.evtId FROM cte WHERE RowNumber = 1
	END
	ELSE IF (LOWER(@runDesignator) = 'lastrun')
	BEGIN
		;WITH cte AS (
			SELECT
				ken.id AS kennelId,
				evt.id AS evtId,
				ROW_NUMBER() OVER (PARTITION BY KennelID ORDER BY EventStartDatetime DESC) AS RowNumber
			FROM HC.Event evt
			INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
			INNER JOIN HC.City c ON ken.CityId = c.id
			INNER JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
			WHERE
				ken.KennelUniqueShortName = @kennelUniqueShortName AND
				evt.removed = 0 AND
				DATEADD(HOUR, 4, (CAST(evt.EventStartDatetime AS DATETIME) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC') > GETUTCDATE()
		)
		SELECT @kennelId = cte.kennelId, @eventId = cte.evtId FROM cte WHERE RowNumber = 1
	END
	ELSE
	BEGIN
		SELECT @kennelId = id FROM HC.Kennel WHERE KennelUniqueShortName = @kennelUniqueShortName
		SELECT @eventId = id FROM HC.Event evt WHERE CAST(evt.EventNumber AS NVARCHAR(50)) = @runDesignator AND evt.KennelId = @kennelId
	END

	IF @eventId IS NULL
	BEGIN
		SELECT 0 AS Success, 'No run record found with provided information' AS ErrorMessage;
		RETURN;
	END

	-- Rowset 0: Event Details
	SELECT
		  evt.PublicEventId AS publicEventId
		, ken.[PublicKennelId] AS publicKennelId
		, ken.[KennelName] AS kennelName
		, ken.[KennelLogo] AS kennelLogo
		, ken.[KennelWebsiteUrl] AS kennelWebUrl
		, ken.[KennelShortName] AS kennelShortName
		, ken.[KennelUniqueShortName] AS kennelUniqueShortName
		, evt.[IsVisible] AS isVisible
		, evt.[IsCountedRun] AS isCountedRun
		, evt.[EventGeographicScope] AS eventGeographicScope
		, evt.[IsPromotedEvent] AS isPromotedEvent
		, evt.[EventNumber] AS eventNumber
		, evt.[EventPriceForMembers] AS eventPriceForMembers
		, evt.[EventPriceForNonMembers] AS eventPriceForNonMembers
		, ken.[DefaultEventPriceForMembers] AS kennelDefaultEventPriceForMembers
		, ken.[DefaultEventPriceForNonMembers] AS kennelDefaultEventPriceForNonMembers

		, evt.[EventPriceForExtras] AS eventPriceForExtras
		, evt.[ExtrasDescription] AS extrasDescription
		, evt.[ExtrasRsvpRequired] AS extrasRsvpRequired
		, evt.[DoTrackHashCash] AS doTrackHashCash

		-- publishing and dissemination
		, ken.[DisseminateHashRunsDotOrg] AS kenDisseminateHashRunsDotOrg
		, ken.[DisseminateAllowWebLinks] AS kenDisseminateAllowWebLinks
		, ken.[DisseminationAudience] AS kenDisseminationAudience
		, evt.[EvtDisseminationAudience] AS evtDisseminationAudience
		, evt.[EvtDisseminateAllowWebLinks] AS evtDisseminateAllowWebLinks
		, evt.[EvtDisseminateHashRunsDotOrg] AS evtDisseminateHashRunsDotOrg
		, evt.PublishToGoogleCalendar AS evtPublishToGoogleCalendar
		, ken.PublishToGoogleCalendar AS kenPublishToGoogleCalendar
		, evt.PublishToGoogleCalendarAddresses AS evtPublishToGoogleCalendarAddresses
		, evt.DisseminateOnGlobalGoogleCalendar AS evtDisseminateOnGlobalGoogleCalendar
		, ken.DisseminateOnGlobalGoogleCalendar AS kenDisseminateOnGlobalGoogleCalendar

		, evt.[InboundIntegrationId] AS inboundIntegrationId
		, evt.[IntegrationEnabled] AS integrationEnabled
		, evt.[FacebookRecordLastUpdated] AS extDataLastUpdated

		, evt.[EventFacebookId] AS eventFacebookId
		, evt.[AbsoluteEventNumber] AS absoluteEventNumber
		, evt.[CanEditRunAttendence] AS canEditRunAttendence

		, evt.Hares AS hares
		, evt.EventPaymentScheme AS eventPaymentScheme
		, evt.EventPaymentUrl AS eventPaymentUrl
		, evt.EventPaymentUrlExpires AS eventPaymentUrlExpires
		, evt.UnconfirmedBankXferCount AS unconfirmedBankXferCount

		, evt.[Tags1] AS tags1
		, evt.[Tags2] AS tags2
		, evt.[Tags3] AS tags3

		-- FB run details flag
		, evt.FbEventImage AS extEventImage
		, evt.EventImage AS eventImage

		, evt.FbEventName AS extEventName
		, evt.EventName AS eventName

		-- TODO: Return DATETIMEOFFSET alongside DATETIME2 for timezone migration
		, CONVERT(datetime2, evt.FbEventStartDatetime) AS extEventStartDatetime
		, CONVERT(datetime2, evt.EventStartDatetime) AS eventStartDatetime
		, CONVERT(datetime2, evt.EventEndDatetime) AS eventEndDatetime

		, COALESCE(evt.FbEventDescription, '') AS extEventDescription
		, COALESCE(evt.EventDescription, '') AS eventDescription

		, evt.MaximumParticipantsAllowed AS maximumParticipantsAllowed
		, evt.MinimumParticipantsRequired AS minimumParticipantsRequired

		, evt.FbLocationOneLineDesc AS extLocationOneLineDesc
		, evt.LocationOneLineDesc AS locationOneLineDesc
		, evt.SyncResolvableLocation AS resolvableLocation

		, evt.FbLocationPostCode AS extLocationPostCode
		, evt.FbLocationCity AS extLocationCity
		, evt.FbLocationStreet AS extLocationStreet
		, evt.FbLocationCountry AS extLocationCountry
		, evt.FbLocationRegion AS extLocationRegion
		, evt.FbLocationSubRegion AS extLocationSubRegion

		, evt.LocationPostCode AS locationPostCode
		, evt.LocationCity AS locationCity
		, evt.LocationStreet AS locationStreet
		, evt.LocationCountry AS locationCountry
		, evt.LocationRegion AS locationRegion
		, evt.LocationSubRegion AS locationSubRegion

		, evt.[removed] AS removed
		, evt.[updatedAt] AS updatedAt

		, evt.UseFbLocation AS useFbLocation
		, evt.UseFbLatLon AS useFbLatLon
		, evt.UseFbRunDetails AS useFbRunDetails
		, evt.UseFbImage AS useFbImage

		, evt.Latitude AS hcLatitude
		, evt.Longitude AS hcLongitude
		, evt.FbLatitude AS fbLatitude
		, evt.FbLongitude AS fbLongitude
		, evt.CountryId AS countryId
		, c4s.CountryName AS countryName
		, ken.Latitude AS kenLatitude
		, ken.Longitude AS kenLongitude
		, city.Latitude AS cityLatitude
		, city.Longitude AS cityLongitude
		, cn.NeighboringCountries AS kennelCountryCodes
		, COALESCE(ken.DigitsAfterDecimal, cn.DigitsAfterDecimal) AS digitsAfterDecimal
		, COALESCE(ken.CurrencySymbol, cn.CurrencySymbol) AS currencySymbol
		, '' AS searchText

	FROM HC.Event evt
	INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
	INNER JOIN HC.City city ON ken.cityId = city.id
	INNER JOIN HC.Country cn ON cn.id = ken.CountryId
	INNER JOIN HC.Country c4s ON c4s.id = evt.CountryId
	WHERE evt.id = @eventId

	-- Rowset 1: Attendee List (only for non-service-account callers)
	IF (@callerType = 0)
	BEGIN
		IF (@includePaymentInfo = 0)
		BEGIN
			SELECT
				COALESCE(hem.DisplayName, hasher.DisplayName) AS displayName,
				hem.RsvpState AS rsvpState,
				hem.AttendenceState AS attendanceState,
				hem.IsHare AS isHare,
				COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS totalRunsThisKennel,
				COALESCE(hkm.HcHaringCount, 0) + COALESCE(hkm.HistoricalHaringCount, 0) AS totalHaringThisKennel,
				COALESCE(REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.CreditAmount, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))), '') AS amountPaidStr,
				COALESCE(REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.DebitAmount, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))), '') AS amountOwedStr,
				COALESCE(REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.CreditAvailable, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))), '') AS creditAvailableStr,
				hem.VirginVisitorType AS virginVisitorType
			FROM HC.Event evt
			INNER JOIN HC.HasherEventMap hem ON hem.EventId = evt.id
			INNER JOIN HC.Kennel ken ON ken.id = evt.KennelId
			INNER JOIN HC.Country n ON n.id = ken.CountryId
			LEFT OUTER JOIN HC.Hasher hasher ON hasher.id = hem.UserId
			LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = hasher.id AND hkm.kennelId = evt.KennelId
			LEFT OUTER JOIN HC.Payment pay ON pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
			WHERE evt.id = @eventId
		END
		ELSE
		BEGIN
			SELECT
				COALESCE(hem.DisplayName, hasher.DisplayName) AS displayName,
				hem.RsvpState AS rsvpState,
				hem.AttendenceState AS attendanceState,
				hem.IsHare AS isHare,
				COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS totalRunsThisKennel,
				COALESCE(hkm.HcHaringCount, 0) + COALESCE(hkm.HistoricalHaringCount, 0) AS totalHaringThisKennel,
				hem.VirginVisitorType AS virginVisitorType,
				pay.CancelledDate AS cancelledDate,
				canceledBy.DisplayName AS cancelledBy,
				pay.CreditAvailable AS creditAvailable,
				pay.CreditAmount AS amountPaid,
				pay.DebitAmount AS amountOwed,
				pay.NetPayment AS netPayment,
				REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.CreditAmount, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))) AS amountPaidStr,
				REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.DebitAmount, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))) AS amountOwedStr,
				REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.NetPayment, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))) AS netPaymentStr,
				REPLACE(COALESCE(ken.CurrencySymbol, n.CurrencySymbol), '^', FORMAT(pay.CreditAvailable, 'F' + CAST(COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS NVARCHAR))) AS creditAvailableStr,
				pay.DoPayForExtras AS doPayForExtras,
				pay.ConfirmedDate AS paymentConfirmedDate,
				confirmedBy.DisplayName AS paymentConfirmedBy,
				pay.PaidDate AS payedDate,
				pay.PaymentType AS paymentType,
				CASE
					WHEN pay.PaymentType = 0 THEN 'Unknown'
					WHEN pay.PaymentType = 1 THEN 'Not paid'
					WHEN pay.PaymentType = 2 THEN 'Free'
					WHEN pay.PaymentType = 3 THEN 'Cash'
					WHEN pay.PaymentType = 4 THEN 'Bank transfer'
					WHEN pay.PaymentType = 5 THEN 'Cash (other amount)'
					WHEN pay.PaymentType = 6 THEN 'Hash credit'
					WHEN pay.PaymentType = 7 THEN 'Bank transfer (other amount)'
				END AS paymentTypeString,
				pay.PaymentReference AS paymentReference
			FROM HC.Event evt
			INNER JOIN HC.HasherEventMap hem ON hem.EventId = evt.id
			INNER JOIN HC.Kennel ken ON ken.id = evt.KennelId
			INNER JOIN HC.Country n ON n.id = ken.CountryId
			LEFT OUTER JOIN HC.Hasher hasher ON hasher.id = hem.UserId
			LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = hasher.id AND hkm.kennelId = evt.KennelId
			LEFT OUTER JOIN HC.Payment pay ON pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
			LEFT OUTER JOIN HC.Hasher canceledBy ON canceledBy.id = pay.CancelledBy_UserId
			LEFT OUTER JOIN HC.Hasher confirmedBy ON confirmedBy.id = pay.ConfirmedBy_UserId
			WHERE evt.id = @eventId
		END
	END

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
