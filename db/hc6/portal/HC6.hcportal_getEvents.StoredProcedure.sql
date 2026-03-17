CREATE OR ALTER PROCEDURE [HC6].[hcportal_getEvents]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,

	-- optional parameters
	@publicKennelIds NVARCHAR(4000) = NULL,
	@kennelUniqueShortName NVARCHAR(50) = NULL,
	@specialEventKennelIds NVARCHAR(4000) = NULL,
	@cityNames NVARCHAR(4000) = NULL,
	@specialEventCityNames NVARCHAR(4000) = NULL,
	@regionNames NVARCHAR(4000) = NULL,
	@regionCodes NVARCHAR(4000) = NULL,
	@cityIds NVARCHAR(4000) = NULL,
	@regionIds NVARCHAR(4000) = NULL,
	@countryIds NVARCHAR(4000) = NULL,
	@specialEventRegionNames NVARCHAR(4000) = NULL,
	@specialEventRegionCodes NVARCHAR(4000) = NULL,
	@countryCodes NVARCHAR(4000) = NULL,
	@countryNames NVARCHAR(4000) = NULL,
	@specialEventCountryCodes NVARCHAR(4000) = NULL,
	@specialEventCountryNames NVARCHAR(4000) = NULL,
	@continentNames NVARCHAR(4000) = NULL,
	@continentCodes NVARCHAR(4000) = NULL,
	@specialEventContinentNames NVARCHAR(4000) = NULL,
	@specialEventContinentCodes NVARCHAR(4000) = NULL,
	@fullDetails SMALLINT = NULL,
	@weeksToDisplay SMALLINT = 52,
	@pastOrFuture NVARCHAR(50) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getEvents
-- Description: Retrieves hash running events filtered by geographic
--              constraints (kennels, cities, regions, countries,
--              continents) for display in the admin portal or on
--              public HashRuns.org pages. Returns either a summary
--              list or full event details depending on @fullDetails.
--              Supports past/future/all time windows.
-- Parameters: @deviceId, @accessToken (auth),
--             @publicKennelIds..@specialEventContinentCodes (geo filters),
--             @fullDetails (0/NULL=summary, 1=full details),
--             @weeksToDisplay (time window), @pastOrFuture (direction)
-- Returns: Rowset 0: EventSummaryList (when @fullDetails IS NULL or 0)
--                  OR EventFullDetails (when @fullDetails = 1)
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getEvents
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error with RETURN
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Removed eventChatMessageCount from BOTH EventSummaryList and
--     EventFullDetails rowsets (obsolete, was hardcoded to 0)
--   - Removed commented-out debug code
--   - Fixed DATALENGTH location string check to use LEN
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
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: at least one geographic constraint required
	IF COALESCE(
		@publicKennelIds,
		@kennelUniqueShortName,
		@specialEventKennelIds,
		@cityNames,
		@cityIds,
		@regionIds,
		@countryIds,
		@specialEventCityNames,
		@regionNames,
		@regionCodes,
		@specialEventRegionNames,
		@specialEventRegionCodes,
		@countryCodes,
		@countryNames,
		@specialEventCountryCodes,
		@specialEventCountryNames,
		@continentNames,
		@continentCodes,
		@specialEventContinentNames,
		@specialEventContinentCodes
	) IS NULL
	BEGIN
		SELECT 0 AS Success, 'No query constraints were supplied. Please provide kennel IDs or geographic region filters.' AS ErrorMessage;
		RETURN;
	END

	-- Default parameter handling
	IF (@weeksToDisplay IS NULL) SET @weeksToDisplay = 999
	IF (@pastOrFuture IS NULL) SET @pastOrFuture = 'future'
	IF (@weeksToDisplay > 999) SET @weeksToDisplay = 999

	-- Determine isAdmin for dissemination WHERE clause
	DECLARE @isAdmin SMALLINT = 1
	IF (@callerType = 1)
	BEGIN
		SET @isAdmin = 0
	END

	-- Resolve kennelUniqueShortName to geographic IDs if not found as kennel
	DECLARE @kennelId UNIQUEIDENTIFIER
	DECLARE @cityId UNIQUEIDENTIFIER
	DECLARE @regionId UNIQUEIDENTIFIER
	DECLARE @countryId UNIQUEIDENTIFIER

	SELECT @kennelId = ken.id FROM HC.Kennel ken WHERE ken.KennelUniqueShortName = @kennelUniqueShortName
	IF (@kennelId IS NULL)
	BEGIN
		SELECT TOP 1
			@cityId = CASE WHEN c.CityName = @kennelUniqueShortName THEN c.id ELSE NULL END,
			@regionId = CASE WHEN r.RegionName = @kennelUniqueShortName THEN r.id ELSE NULL END,
			@countryId = CASE WHEN n.CountryName = @kennelUniqueShortName THEN n.id ELSE NULL END
		FROM
			HC.City c
			INNER JOIN HC.Region r ON c.RegionId = r.id
			INNER JOIN HC.Country n ON r.CountryId = n.id
			INNER JOIN HC.Kennel ken ON ken.CityId = c.id
			INNER JOIN HC.Event evt ON evt.KennelId = ken.id
		WHERE c.CityName = @kennelUniqueShortName OR r.RegionName = @kennelUniqueShortName OR n.CountryName = @kennelUniqueShortName
			AND evt.EventStartDatetime > DATEADD(DAY, -30, GETDATE())
		GROUP BY
			CASE WHEN c.CityName = @kennelUniqueShortName THEN c.id ELSE NULL END,
			CASE WHEN r.RegionName = @kennelUniqueShortName THEN r.id ELSE NULL END,
			CASE WHEN n.CountryName = @kennelUniqueShortName THEN n.id ELSE NULL END
		ORDER BY COUNT(evt.id) DESC
	END

	-- EventSummaryList: returned when @fullDetails IS NULL or 0
	IF ((@fullDetails IS NULL) OR (@fullDetails = 0))
	BEGIN

		SELECT
			  evt.PublicEventId AS publicEventId
			, ken.PublicKennelId AS publicKennelId
			, ken.[KennelName] AS kennelName
			, ken.[KennelShortName] AS kennelShortName
			, ken.[KennelUniqueShortName] AS kennelUniqueShortName
			, ken.[KennelLogo] AS kennelLogo
			, evt.[IsVisible] AS isVisible
			, evt.[IsCountedRun] AS isCountedRun
			, evt.[EventNumber] AS eventNumber
			, evt.[EventGeographicScope] AS eventGeographicScope
			-- FB lat/lon flag
			, CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL AND evt.FbLatitude != 0 AND evt.FbLongitude != 0) THEN evt.[fbLatitude] ELSE CASE WHEN COALESCE(evt.[Latitude], ken.Latitude, c.Latitude, 0.0) != 0 THEN COALESCE(evt.[Latitude], ken.Latitude, c.Latitude) ELSE c.Latitude END END AS syncLat
			, CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL AND evt.FbLatitude != 0 AND evt.FbLongitude != 0) THEN evt.[fbLongitude] ELSE CASE WHEN COALESCE(evt.[Longitude], ken.Longitude, c.Longitude, 0.0) != 0 THEN COALESCE(evt.[Longitude], ken.Longitude, c.Longitude) ELSE c.Longitude END END AS syncLong

			, ken.PublishToGoogleCalendar AS kenPublishToGoogleCalendar
			, ken.DisseminateOnGlobalGoogleCalendar AS kenDisseminateOnGlobalGoogleCalendar
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			, evt.SyncResolvableLocation AS resolvableLocation
			, evt.Hares AS hares
			, CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			-- TODO: Return DATETIMEOFFSET alongside DATETIME2 for timezone migration
			, CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END AS eventStartDatetime
			, DATEDIFF(DAY, GETDATE(), CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END) AS daysUntilEvent

			, '~'
			+ ' ' + COALESCE(evt.EventName, '')
			+ ' ' + COALESCE(ken.KennelShortName, '')
			+ ' ' + COALESCE(ken.KennelUniqueShortName, '')
			+ ' ' + COALESCE(ken.KennelName, '')
			+ ' ' + COALESCE(evt.Hares, '')
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationCity, '') ELSE COALESCE(evt.LocationCity, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationCountry, '') ELSE COALESCE(evt.LocationCountry, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationOneLineDesc, '') ELSE COALESCE(evt.LocationOneLineDesc, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationPostCode, '') ELSE COALESCE(evt.LocationPostCode, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationRegion, '') ELSE COALESCE(evt.LocationRegion, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationStreet, '') ELSE COALESCE(evt.LocationStreet, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationSubRegion, '') ELSE COALESCE(evt.LocationSubRegion, '') END
			+ ' ' + CASE WHEN evt.EventNumber IS NOT NULL THEN CAST(evt.EventNumber AS NVARCHAR(30)) ELSE '' END
			+ ' ' + c.CityName
			+ ' ' + r.RegionName
			+ ' ' + n.CountryName
			+ ' ' + COALESCE(r.RegionAbbreviation, '')
			+ ' ' + n.CountryCode
			+ ' ' + REPLACE(COALESCE(c.CitySearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(r.RegionSearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(n.CountrySearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(ken.KennelSearchTags, ''), ',', ' ')
			+ CASE
				WHEN evt.EventGeographicScope = 1 THEN 'not event is local'
				WHEN evt.EventGeographicScope = 2 THEN 'is event is local'
				WHEN evt.EventGeographicScope = 3 THEN 'is event is regional is state'
				WHEN evt.EventGeographicScope = 4 THEN 'is event is national is nash hash is nashhash'
				WHEN evt.EventGeographicScope = 5 THEN 'is event is continental is interhash'
				WHEN evt.EventGeographicScope = 6 THEN 'is event is global is world interhash'
				WHEN evt.EventGeographicScope = 7 THEN 'is event is other'
				ELSE ''
			END
			+ CASE
				WHEN n.ContinentCode = 'EU' THEN 'europe'
				WHEN n.ContinentCode = 'AF' THEN 'africa'
				WHEN n.ContinentCode = 'AS' THEN 'asia'
				WHEN n.ContinentCode = 'NA' THEN 'north america'
				WHEN n.ContinentCode = 'SA' THEN 'south america'
				WHEN n.ContinentCode = 'OC' THEN 'oceania'
				WHEN n.ContinentCode = 'AN' THEN 'antarctica'
				ELSE ''
			END
			+ ' ~'
			AS searchText,

			CASE WHEN evt.UseFbLocation = 1 THEN
				CASE WHEN LEN(COALESCE(evt.fbLocationCity, '') + ', ' + CASE WHEN n.ShowRegion = 1 THEN COALESCE(evt.fbLocationRegion + ', ', '') ELSE '' END + COALESCE(evt.fbLocationCountry, '')) < 3 THEN
					c.CityName + ', ' + CASE WHEN n.ShowRegion = 1 THEN r.RegionName + ', ' ELSE '' END + n.CountryName
				ELSE
					COALESCE(evt.fbLocationCity + ', ' + CASE WHEN n.ShowRegion = 1 THEN COALESCE(evt.fbLocationRegion + ', ', '') ELSE '' END + evt.fbLocationCountry, c.CityName + ', ' + CASE WHEN n.ShowRegion = 1 THEN r.RegionName + ', ' ELSE '' END + n.CountryName)
				END
			ELSE
				COALESCE(evt.LocationCity + ', ' + CASE WHEN n.ShowRegion = 1 THEN COALESCE(evt.LocationRegion + ', ', '') ELSE '' END + evt.LocationCountry, c.CityName + ', ' + CASE WHEN n.ShowRegion = 1 THEN r.RegionName + ', ' ELSE '' END + n.CountryName)
			END
			AS eventCityAndCountry

			FROM HC.Event evt
			INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
			INNER JOIN HC.City c ON ken.CityId = c.id
			INNER JOIN HC.Region r ON c.RegionId = r.id
			INNER JOIN HC.Country n ON r.CountryId = n.id
			WHERE evt.removed = 0 AND
			evt.IsVisible = 1 AND
			(
				(@pastOrFuture = 'future' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(DAY, -1, GETDATE()) AND DATEADD(WEEK, @weeksToDisplay, GETDATE())))
				OR
				(@pastOrFuture = 'past' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(WEEK, -@weeksToDisplay, GETDATE()) AND DATEADD(DAY, 1, GETDATE())))
				OR
				(@pastOrFuture = 'all' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(WEEK, -@weeksToDisplay, GETDATE()) AND DATEADD(WEEK, @weeksToDisplay, GETDATE())))
			)
			AND
			(((@publicKennelIds IS NOT NULL) AND (ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@publicKennelIds, ','))))
			  OR ((@cityId IS NOT NULL) AND (c.id = @cityId))
			  OR ((@regionId IS NOT NULL) AND (r.id = @regionId))
			  OR ((@countryId IS NOT NULL) AND (n.id = @countryId))
			  OR ((@kennelUniqueShortName IS NOT NULL) AND (ken.KennelUniqueShortName = @kennelUniqueShortName))
			  OR ((@specialEventKennelIds IS NOT NULL) AND (ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@specialEventKennelIds, ','))) AND (evt.EventGeographicScope >= 2))
			  OR ((@cityIds IS NOT NULL) AND (c.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@cityIds, ','))))
			  OR ((@regionIds IS NOT NULL) AND (r.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@regionIds, ','))))
			  OR ((@countryIds IS NOT NULL) AND (n.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@countryIds, ','))))
			  OR ((@cityNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(c.CityName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@cityNames, ',')))))
			  OR ((@specialEventCityNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(c.CityName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventCityNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@regionNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(r.RegionName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@regionNames, ',')))))
			  OR ((@regionCodes IS NOT NULL) AND ((TRIM(LOWER(r.RegionAbbreviation)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@regionCodes, ',')))))
			  OR ((@specialEventRegionNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(r.RegionName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventRegionNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventRegionCodes IS NOT NULL) AND ((TRIM(LOWER(r.RegionAbbreviation)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventRegionCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@countryNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.CountryName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@countryNames, ',')))))
			  OR ((@countryCodes IS NOT NULL) AND ((TRIM(LOWER(n.CountryCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@countryCodes, ',')))))
			  OR ((@specialEventCountryNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.CountryName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventCountryNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventCountryCodes IS NOT NULL) AND ((TRIM(LOWER(n.CountryCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventCountryCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@continentNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.ContinentName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@continentNames, ',')))))
			  OR ((@continentCodes IS NOT NULL) AND ((TRIM(LOWER(n.ContinentCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@continentCodes, ',')))))
			  OR ((@specialEventContinentNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.ContinentName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventContinentNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventContinentCodes IS NOT NULL) AND ((TRIM(LOWER(n.ContinentCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventContinentCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			)
			AND
			(
			(@isAdmin = 1)
			-- This event or Kennel is marked to display runs in public
			OR (COALESCE(evt.[EvtDisseminateHashRunsDotOrg], ken.[DisseminateHashRunsDotOrg], 0) = 5)
			-- This event or Kennel is marked to display runs only on the Kennel's webpage
			OR ((COALESCE(evt.[EvtDisseminateHashRunsDotOrg], ken.[DisseminateHashRunsDotOrg], 0) = 1) AND ((ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@publicKennelIds, ',')))))
			)

	END

	-- EventFullDetails: returned when @fullDetails = 1
	IF (@fullDetails = 1)
	BEGIN
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

			, evt.[IntegrationEnabled] AS integrationEnabled
			, evt.[EventFacebookId] AS eventFacebookId
			, evt.[AbsoluteEventNumber] AS absoluteEventNumber
			, evt.[CanEditRunAttendence] AS canEditRunAttendence

			, evt.Hares AS hares
			, evt.EventPaymentScheme AS eventPaymentScheme
			, evt.EventPaymentUrl AS eventPaymentUrl
			, evt.EventPaymentUrlExpires AS eventPaymentUrlExpires
			, COALESCE(evt.ExtrasRsvpRequired, 0) AS extrasRsvpRequired
			, evt.UnconfirmedBankXferCount AS unconfirmedBankXferCount

			, evt.[Tags1] AS tags1
			, evt.[Tags2] AS tags2
			, evt.[Tags3] AS tags3

			-- FB run details flag
			, CASE WHEN (evt.UseFbImage = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage

			, CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			-- TODO: Return DATETIMEOFFSET alongside DATETIME2 for timezone migration
			, CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END AS eventStartDatetime
			, COALESCE(CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventDescription ELSE evt.EventDescription END, '') AS eventDescription
			, CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc

			-- FB lat/lon flag
			, CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL AND evt.FbLatitude != 0 AND evt.FbLongitude != 0) THEN evt.[fbLatitude] ELSE CASE WHEN COALESCE(evt.[Latitude], ken.Latitude, city.Latitude, 0.0) != 0 THEN COALESCE(evt.[Latitude], ken.Latitude, city.Latitude) ELSE city.Latitude END END AS narrowEventLatitude
			, CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL AND evt.FbLatitude != 0 AND evt.FbLongitude != 0) THEN evt.[fbLongitude] ELSE CASE WHEN COALESCE(evt.[Longitude], ken.Longitude, city.Longitude, 0.0) != 0 THEN COALESCE(evt.[Longitude], ken.Longitude, city.Longitude) ELSE city.Longitude END END AS narrowEventLongitude

			-- FB location flag
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			, CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion

			, evt.[removed] AS removed
			, evt.[updatedAt] AS updatedAt

			, evt.UseFbLocation AS useFbLocation
			, evt.UseFbLatLon AS useFbLatLon
			, evt.UseFbRunDetails AS useFbRunDetails
			, evt.UseFbImage AS useFbImage

			, evt.FbEventImage AS extEventImage
			, COALESCE(evt.FbEventDescription, '') AS extEventDescription

			, evt.Latitude AS hcLatitude
			, evt.Longitude AS hcLongitude
			, evt.FbLatitude AS fbLatitude
			, evt.FbLongitude AS fbLongitude
			, ken.Latitude AS kenLatitude
			, ken.Longitude AS kenLongitude
			, evt.CountryId AS countryId
			, c4s.CountryName AS countryName
			, city.Latitude AS cityLatitude
			, city.Longitude AS cityLongitude
			, COALESCE(ken.DigitsAfterDecimal, n.DigitsAfterDecimal) AS digitsAfterDecimal
			, COALESCE(ken.CurrencySymbol, n.CurrencySymbol) AS currencySymbol
			, DATEDIFF(DAY, GETDATE(), CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END) AS daysUntilEvent

			, '~'
			+ ' ' + COALESCE(evt.EventName, '')
			+ ' ' + COALESCE(ken.KennelShortName, '')
			+ ' ' + COALESCE(ken.KennelUniqueShortName, '')
			+ ' ' + COALESCE(ken.KennelName, '')
			+ ' ' + COALESCE(evt.Hares, '')
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationCity, '') ELSE COALESCE(evt.LocationCity, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationCountry, '') ELSE COALESCE(evt.LocationCountry, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationOneLineDesc, '') ELSE COALESCE(evt.LocationOneLineDesc, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationPostCode, '') ELSE COALESCE(evt.LocationPostCode, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationRegion, '') ELSE COALESCE(evt.LocationRegion, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationStreet, '') ELSE COALESCE(evt.LocationStreet, '') END
			+ ' ' + CASE WHEN (evt.UseFbLocation = 1) THEN COALESCE(evt.FbLocationSubRegion, '') ELSE COALESCE(evt.LocationSubRegion, '') END
			+ ' ' + CASE WHEN evt.EventNumber IS NOT NULL THEN CAST(evt.EventNumber AS NVARCHAR(30)) ELSE '' END
			+ ' ' + city.CityName
			+ ' ' + r.RegionName
			+ ' ' + n.CountryName
			+ ' ' + COALESCE(r.RegionAbbreviation, '')
			+ ' ' + n.CountryCode
			+ ' ' + REPLACE(COALESCE(city.CitySearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(r.RegionSearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(n.CountrySearchTags, ''), ',', ' ')
			+ ' ' + REPLACE(COALESCE(ken.KennelSearchTags, ''), ',', ' ')
			+ CASE
				WHEN evt.EventGeographicScope = 1 THEN 'not event is local'
				WHEN evt.EventGeographicScope = 2 THEN 'is event is local'
				WHEN evt.EventGeographicScope = 3 THEN 'is event is regional is state'
				WHEN evt.EventGeographicScope = 4 THEN 'is event is national is nash hash is nashhash'
				WHEN evt.EventGeographicScope = 5 THEN 'is event is continental is interhash'
				WHEN evt.EventGeographicScope = 6 THEN 'is event is global is world interhash'
				WHEN evt.EventGeographicScope = 7 THEN 'is event is other'
				ELSE ''
			END
			+ CASE
				WHEN n.ContinentCode = 'EU' THEN 'europe'
				WHEN n.ContinentCode = 'AF' THEN 'africa'
				WHEN n.ContinentCode = 'AS' THEN 'asia'
				WHEN n.ContinentCode = 'NA' THEN 'north america'
				WHEN n.ContinentCode = 'SA' THEN 'south america'
				WHEN n.ContinentCode = 'OC' THEN 'oceania'
				WHEN n.ContinentCode = 'AN' THEN 'antarctica'
				ELSE ''
			END
			+ ' ~'
			AS searchText
			FROM HC.Event evt
			INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
			INNER JOIN HC.City city ON ken.CityId = city.id
			INNER JOIN HC.Region r ON city.RegionId = r.id
			INNER JOIN HC.Country n ON r.CountryId = n.id
			INNER JOIN HC.Country c4s ON c4s.id = evt.CountryId
			WHERE evt.removed = 0 AND
			evt.IsVisible = 1 AND
			(
				(@pastOrFuture = 'future' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(DAY, -1, GETDATE()) AND DATEADD(WEEK, @weeksToDisplay, GETDATE())))
				OR
				(@pastOrFuture = 'past' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(WEEK, -@weeksToDisplay, GETDATE()) AND DATEADD(DAY, 1, GETDATE())))
				OR
				(@pastOrFuture = 'all' AND (CASE WHEN (evt.UseFbRunDetails = 1) THEN CONVERT(datetime2, evt.FbEventStartDatetime) ELSE CONVERT(datetime2, evt.EventStartDatetime) END BETWEEN DATEADD(WEEK, -@weeksToDisplay, GETDATE()) AND DATEADD(WEEK, @weeksToDisplay, GETDATE())))
			)
			AND
			(((@publicKennelIds IS NOT NULL) AND (ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@publicKennelIds, ','))))
			  OR ((@kennelUniqueShortName IS NOT NULL) AND (ken.KennelUniqueShortName = @kennelUniqueShortName))
			  OR ((@specialEventKennelIds IS NOT NULL) AND (ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@specialEventKennelIds, ','))) AND (evt.EventGeographicScope >= 2))
			  OR ((@cityIds IS NOT NULL) AND (city.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@cityIds, ','))))
			  OR ((@regionIds IS NOT NULL) AND (r.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@regionIds, ','))))
			  OR ((@countryIds IS NOT NULL) AND (n.id IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@countryIds, ','))))
			  OR ((@cityNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(city.CityName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@cityNames, ',')))))
			  OR ((@specialEventCityNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(city.CityName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventCityNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@regionNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(r.RegionName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@regionNames, ',')))))
			  OR ((@regionCodes IS NOT NULL) AND ((TRIM(LOWER(r.RegionAbbreviation)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@regionCodes, ',')))))
			  OR ((@specialEventRegionNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(r.RegionName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventRegionNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventRegionCodes IS NOT NULL) AND ((TRIM(LOWER(r.RegionAbbreviation)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventRegionCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@countryNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.CountryName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@countryNames, ',')))))
			  OR ((@countryCodes IS NOT NULL) AND ((TRIM(LOWER(n.CountryCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@countryCodes, ',')))))
			  OR ((@specialEventCountryNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.CountryName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventCountryNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventCountryCodes IS NOT NULL) AND ((TRIM(LOWER(n.CountryCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventCountryCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@continentNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.ContinentName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@continentNames, ',')))))
			  OR ((@continentCodes IS NOT NULL) AND ((TRIM(LOWER(n.ContinentCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@continentCodes, ',')))))
			  OR ((@specialEventContinentNames IS NOT NULL) AND ((TRIM(LOWER(REPLACE(n.ContinentName, ' ', ''))) IN (SELECT TRIM(LOWER(REPLACE(value, ' ', ''))) FROM STRING_SPLIT(@specialEventContinentNames, ',')))) AND (evt.EventGeographicScope >= 2))
			  OR ((@specialEventContinentCodes IS NOT NULL) AND ((TRIM(LOWER(n.ContinentCode)) IN (SELECT TRIM(LOWER(value)) FROM STRING_SPLIT(@specialEventContinentCodes, ',')))) AND (evt.EventGeographicScope >= 2))
			)

			AND
			(
			(@isAdmin = 1)
			-- This event or Kennel is marked to display runs in public
			OR (COALESCE(evt.[EvtDisseminateHashRunsDotOrg], ken.[DisseminateHashRunsDotOrg], 0) = 5)
			-- This event or Kennel is marked to display runs only on the Kennel's webpage
			OR ((COALESCE(evt.[EvtDisseminateHashRunsDotOrg], ken.[DisseminateHashRunsDotOrg], 0) = 1) AND ((ken.PublicKennelId IN (SELECT CAST(value AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@publicKennelIds, ',')))))
			)
	END

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
