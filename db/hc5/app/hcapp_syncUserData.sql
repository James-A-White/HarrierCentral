
CREATE PROCEDURE [HC5].[hcapp_syncUserData]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @citiesUpdatedAfter nvarchar(50) = 'ignore',
 @regionsUpdatedAfter nvarchar(50) = 'ignore',
 @countriesUpdatedAfter nvarchar(50) = 'ignore',
 @kennelsUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
 @narrowEventsUpdatedAfter nvarchar(50) = 'ignore',
 @paymentsUpdatedAfter nvarchar(50) = 'ignore',
 @songsUpdatedAfter nvarchar(50) = 'ignore',
 @forceReplicateAllRunsForKennel nvarchar(50) = 'ignore',
 @usePaging int = 0,
 @initialLoad int = 0,
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

SET NOCOUNT ON

	---------------------------------------------------------------------------
	-- 1. Resolve device → user, secret, time window
	---------------------------------------------------------------------------
	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d WHERE d.id = @deviceId

	---------------------------------------------------------------------------
	-- 2. Configure paging limits
	--    When paging is off, set limits high enough to effectively return all.
	---------------------------------------------------------------------------
	DECLARE @paging1000 int = 1000
	DECLARE @paging250 int = 250
	DECLARE @paging50 int = 50

	IF ((@usePaging IS NULL) OR (@usePaging = 0))
	BEGIN
		SET @paging1000 = 1000000
		SET @paging250 = 1000000
		SET @paging50 = 1000000
	END

	---------------------------------------------------------------------------
	-- 3. Validate userId
	---------------------------------------------------------------------------
	DECLARE @errorId uniqueidentifier

	IF ((@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000'))
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
		VALUES (@errorId, '<unknown>', 'Null or Empty UserID',
				'A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),
				OBJECT_NAME(@@PROCID), @userId)
		
		SELECT 
			 @errorId as errorId
			,cast(2 as int) as errorType 
			,'Null or empty userId' as errorTitle
			,'A null or empty value was passed as the userId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage
			,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	---------------------------------------------------------------------------
	-- 4. Validate access token
	---------------------------------------------------------------------------
	IF HC.CHECK_ACCESS_TOKEN_V2(@userId, coalesce(@procName, OBJECT_NAME(@@PROCID)),
								@accessToken, coalesce(@param, @deviceSecret), @timeWindow) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
		VALUES (@errorId, '<unknown>', 'Invalid access token',
				'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),
				OBJECT_NAME(@@PROCID), @userId, @accessToken)

		SELECT 
			 @errorId as errorId
			,cast(3 as int) as errorType 
			,'Invalid access token' as errorTitle
			,'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID) as errorUserMessage
			,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	---------------------------------------------------------------------------
	-- 5. Normalise watermark parameters
	--    Treat NULL or ancient dates as 'ignore' (skip that table).
	--    LOWER() removed — default SQL Server collation is case-insensitive.
	---------------------------------------------------------------------------
	IF ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00'))         SET @hashersUpdatedAfter = 'ignore'
	IF ((@citiesUpdatedAfter IS NULL) OR (@citiesUpdatedAfter <= '2000-01-01 00:00:00'))           SET @citiesUpdatedAfter = 'ignore'
	IF ((@regionsUpdatedAfter IS NULL) OR (@regionsUpdatedAfter <= '2000-01-01 00:00:00'))         SET @regionsUpdatedAfter = 'ignore'
	IF ((@countriesUpdatedAfter IS NULL) OR (@countriesUpdatedAfter <= '2000-01-01 00:00:00'))     SET @countriesUpdatedAfter = 'ignore'
	IF ((@kennelsUpdatedAfter IS NULL) OR (@kennelsUpdatedAfter <= '2000-01-01 00:00:00'))         SET @kennelsUpdatedAfter = 'ignore'
	IF ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	IF ((@paymentsUpdatedAfter IS NULL) OR (@paymentsUpdatedAfter <= '2000-01-01 00:00:00'))       SET @paymentsUpdatedAfter = 'ignore'
	IF ((@hasherEventMapUpdatedAfter IS NULL) OR (@hasherEventMapUpdatedAfter <= '2000-01-01 00:00:00'))   SET @hasherEventMapUpdatedAfter = 'ignore'
	IF ((@narrowEventsUpdatedAfter IS NULL) OR (@narrowEventsUpdatedAfter <= '2000-01-01 00:00:00'))       SET @narrowEventsUpdatedAfter = 'ignore'
	IF ((@songsUpdatedAfter IS NULL) OR (@songsUpdatedAfter <= '2000-01-01 00:00:00'))             SET @songsUpdatedAfter = 'ignore'

	---------------------------------------------------------------------------
	-- 6. Misc setup
	---------------------------------------------------------------------------
	DECLARE @DAYS_IN_THE_PAST_TO_SYNC_EVENTS int = 10
	DECLARE @forceReplicateKennelId uniqueidentifier = NULL
	
	IF ((@forceReplicateAllRunsForKennel IS NOT NULL) AND (@forceReplicateAllRunsForKennel != 'ignore'))
	BEGIN
		SET @forceReplicateKennelId = CAST(@forceReplicateAllRunsForKennel AS uniqueidentifier)
	END
	
	-- Reusable typed watermark variable (cast once per block)
	DECLARE @ua datetimeoffset(7)

	---------------------------------------------------------------------------
	-- 7. HASHERS  (page size: 1000)
	---------------------------------------------------------------------------
	IF (@hashersUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@hashersUpdatedAfter AS datetimeoffset(7))
		SELECT
			 h.id as hasherId
			,h.HomeKennelId as homeKennelId
			,coalesce(h.FirstName, '') as firstName
			,coalesce(h.LastName, '') as lastName
			,coalesce(h.DisplayName, '') as dispName
			,coalesce(h.HashName, '') as hashName
			,coalesce(h.Photo, '') as photo
			,coalesce(h.NameDisplayPreference, 0) as dispPref
			,coalesce(h.IncludeInGlobalHashDirectory, 0) as includeInGlobalHashDirectory
			,CONVERT(nvarchar(50), cast(coalesce(h.updatedAt, getdate()) as datetime2)) as updatedAt
			,coalesce(h.Removed, 0) as removed
		FROM HC.Hasher h
		WHERE h.updatedAt > @ua
		ORDER BY h.updatedAt ASC, h.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging1000 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 8. CITIES  (page size: 250)
	--    Optimisation: EXISTS replaces INNER JOIN + DISTINCT to avoid row
	--    multiplication when a city has multiple kennels.
	--    ORDER BY uses the raw updatedAt column so the index can provide order.
	---------------------------------------------------------------------------
	IF (@citiesUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@citiesUpdatedAfter AS datetimeoffset(7))
		SELECT
		   c.id as cityId
		  ,c.[CityName] as cityName
		  ,c.[CitySearchTags] as citySearchTags
		  ,c.[RegionId] as regionId
		  ,c.[Latitude] as latitude
		  ,c.[Longitude] as longitude
		  ,c.[City_ASCII] as cityAscii
		  ,c.[FlagFile] as flagFile
		  ,c.[Removed] as removed
		  ,coalesce(tz.IanaTimeZone, 'Europe/London') as ianaTimeZone
		  ,CONVERT(nvarchar(50), cast(c.[updatedAt] as datetime2)) as updatedAt
		FROM HC.City c
		LEFT OUTER JOIN DomainValues.Timezone tz ON c.TimezoneId = tz.id
		WHERE c.updatedAt > @ua
		  AND EXISTS (SELECT 1 FROM HC.Kennel k WHERE k.CityId = c.id)
		ORDER BY c.updatedAt ASC, c.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 9. REGIONS  (page size: 250)
	--    Same EXISTS optimisation as Cities.
	---------------------------------------------------------------------------
	IF (@regionsUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@regionsUpdatedAfter AS datetimeoffset(7))
		SELECT
		   r.[id] as regionId
		  ,r.[RegionName] as regionName
		  ,r.[RegionAbbreviation] as regionAbbreviation
		  ,r.[CountryId] as countryId
		  ,r.[FlagFile] as flagFile
		  ,r.[RegionSearchTags] as regionSearchTags
		  ,r.[Removed] as removed
		  ,CONVERT(nvarchar(50), cast(r.[updatedAt] as datetime2)) as updatedAt
		FROM HC.Region r
		WHERE r.updatedAt > @ua
		  AND EXISTS (SELECT 1 FROM HC.Kennel k WHERE k.ProvinceStateId = r.id)
		ORDER BY r.updatedAt ASC, r.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 10. COUNTRIES  (page size: 250)
	--     No JOIN needed; DISTINCT removed (PK guarantees uniqueness).
	---------------------------------------------------------------------------
	IF (@countriesUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@countriesUpdatedAfter AS datetimeoffset(7))
		SELECT
		   c.[id] as countryId
		  ,c.[CountryCode] as countryCode
		  ,c.[Latitude] as latitude
		  ,c.[Longitude] as longitude
		  ,c.[CountryName] as countryName
		  ,c.[ContinentCode] as continentCode
		  ,c.[FlagFile] as flagFile
		  ,c.[CurrencyCode] as currencyCode
		  ,c.[PrimaryCultureCode] as primaryCultureCode
		  ,c.[ShowRegion] as showRegion
		  ,c.[CurrencySymbol] as currencySymbol
		  ,c.[DigitsAfterDecimal] as digitsAfterDecimal
		  ,c.[DistancePreference] as distancePreference
		  ,c.[CountrySearchTags] as countrySearchTags
		  ,c.[Removed] as removed
		  ,CONVERT(nvarchar(50), cast(c.[updatedAt] as datetime2)) as updatedAt
		FROM HC.Country c
		WHERE c.updatedAt > @ua
		ORDER BY c.updatedAt ASC, c.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 11. SONGS  (page size: 250)
	--     Reference data — all songs are synced globally (no per-user filter).
	--     Ensure IX_Song_updatedAt index exists for efficient incremental sync.
	---------------------------------------------------------------------------
	IF (@songsUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@songsUpdatedAfter AS datetimeoffset(7))
		SELECT
		   s.[id] as songId
		  ,s.[SongName] as songName
		  ,s.[TuneOf] as tuneOf
		  ,s.[BawdyRating] as bawdyRating
		  ,s.[Notes] as notes
		  ,s.[Actions] as actions
		  ,s.[Variants] as variants
		  ,s.[ImageUrl] as imageUrl
		  ,s.[AudioUrl] as audioUrl
		  ,s.[AutoAddToKennel] as autoAddToKennel
		  ,s.[Rank] as rank
		  ,s.[AddedBy_KennelId] as addedByKennelId
		  ,s.[AddedBy_UserId] as addedByUserId
		  ,s.[Lyrics] as lyrics
		  ,s.[Tags] as tags
		  ,s.[Removed] as removed
		  ,CONVERT(nvarchar(50), cast(s.[updatedAt] as datetime2)) as updatedAt
		FROM HC.Song s
		WHERE s.updatedAt > @ua
		ORDER BY s.updatedAt ASC, s.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 12. KENNELS  (page size: 250)
	---------------------------------------------------------------------------
	IF (@kennelsUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelsUpdatedAfter AS datetimeoffset(7))
		SELECT
			-- GUIDs
			 k.[id] as kennelId
			,[PublicKennelId] as publicKennelId
			,[CityId] as cityId
			,[ProvinceStateId] as regionId
			,[CountryId] as countryId

			-- Strings
			,[KennelName] as kennelName
			,[KennelShortName] as kennelShortName
			,[KennelUniqueShortName] as kennelUniqueShortName
			,[KennelDescription] as kennelDescription
			,[KennelSearchTags] as kennelSearchTags
			,[KennelLogo] as kennelLogo
			,[KennelCoverPhoto] as kennelCoverPhoto
			,[KennelWebsiteUrl] as kennelWebsiteUrl
			,[KennelMismanagementTeam] as kennelMismanagementTeam
			,[DefaultEventCurrencyType] as defaultEventCurrencyType
			,[IntegrationType] as integrationType
			,[KennelEventsUrl] as kennelEventsUrl

			-- Ints / Smallints
			,[KennelStatus] as kennelStatus
			,[AllowNegativeCredit] as allowNegativeCredit
			,[AllowSelfPayment] as allowSelfPayment
			,[MembershipDurationInMonths] as membershipDurationInMonths
			,[DistancePreference] as distancePreference
			,[KennelPinColor] as kennelPinColor
			,[DisseminateAllowWebLinks] as disseminateAllowWebLinks
			,[CanEditRunAttendence] as canEditRunAttendence
			,[InboundIntegrationId] as kennelInboundIntegrationId

			-- Doubles
			,coalesce(k.[Latitude], c.[Latitude]) as kennelLatitude
			,coalesce(k.[Longitude], c.[Longitude]) as kennelLongitude
			,[DefaultEventPriceForMembers] as defaultPriceForMembers
			,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

			-- DateTimes
			,CONVERT(DATETIME, '1900-01-01') + CONVERT(DATETIME, DefaultRunStartTime) as defaultRunStartTime
			,[RunCountStartDate] as runCountStartDate

			-- Banking info
			,[CurrencyCode] as currencyCode
			,[PrimaryCultureCode] as primaryCultureCode
			,[CurrencySymbol] as currencySymbol
			,[DigitsAfterDecimal] as digitsAfterDecimal
			,[BankScheme] as bankScheme
			,[BankAccountNumber] as bankAccountNumber
			,[BankBic] as bankBic
			,[BankBeneficiary] as bankBeneficiary

			,[KennelPaymentScheme] as kennelPaymentScheme
			,[KennelPaymentUrl] as kennelPaymentUrl
			,[KennelPaymentUrlExpires] as kennelPaymentUrlExpires
			,[KennelPaymentMemberSurcharge] as kennelPaymentMemberSurcharge
			,[KennelPaymentNonMemberSurcharge] as kennelPaymentNonMemberSurcharge

			,[KennelPaymentScheme2] as kennelPaymentScheme2
			,[KennelPaymentUrl2] as kennelPaymentUrl2
			,[KennelPaymentUrlExpires2] as kennelPaymentUrlExpires2
			,[KennelPaymentMemberSurcharge2] as kennelPaymentMemberSurcharge2
			,[KennelPaymentNonMemberSurcharge2] as kennelPaymentNonMemberSurcharge2

			,[KennelPaymentScheme3] as kennelPaymentScheme3
			,[KennelPaymentUrl3] as kennelPaymentUrl3
			,[KennelPaymentUrlExpires3] as kennelPaymentUrlExpires3
			,[KennelPaymentMemberSurcharge3] as kennelPaymentMemberSurcharge3
			,[KennelPaymentNonMemberSurcharge3] as kennelPaymentNonMemberSurcharge3

			,k.[removed] as removed
			,CONVERT(nvarchar(50), cast(k.[updatedAt] as datetime2)) as updatedAt
		FROM [HC].[Kennel] k
		INNER JOIN [HC].[City] c ON k.CityId = c.id
		WHERE k.updatedAt > @ua
		ORDER BY k.[updatedAt] ASC, k.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
		OPTION (RECOMPILE);
	END

	---------------------------------------------------------------------------
	-- 13. HASHER–KENNEL MAP  (page size: 250, user-scoped)
	---------------------------------------------------------------------------
	IF (@hasherKennelMapUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherKennelMapUpdatedAfter AS datetimeoffset(7))
		SELECT
		   [id] as hkmId
		  ,[UserId] as userId
		  ,[KennelId] as kennelId
		  ,[Following] as following
		  ,[IsMember] as isMember
		  ,[IsHomeKennel] as isHomeKennel
		  ,[IsKennelFollowing] as isKennelFollowing
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoles] as mismanagementRoles
		  ,[UserRoleFlags] as userRoleFlags
		  ,[AppAccessFlags] as appAccessFlags
		  ,[KennelCredit] as kennelCredit
		  ,[DiscountAmount] as discountAmount
		  ,[DiscountPercent] as discountPercent
		  ,[DiscountDescription] as discountDescription
		  ,[HcTotalRunCount] as hcTotalRunCount
		  ,[HcHaringCount] as hcHaringCount
		  ,[HistoricalTotalRunCount] as historicalTotalRunCount
		  ,[HistoricalHaringCount] as historicalHaringCount
		  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
		  ,[MembershipExpirationDate] as membershipExpirationDate
		  ,[MemberSince] as memberSince
		  ,[DateOfLastRun] as dateOfLastRun
		  ,'' as authorizedDeviceList
		  ,0 as authorizedDeviceCount
		  ,[KennelUserPhoto] as kennelUserPhoto
		  ,[KennelHashName] as kennelHashName
		  ,[removed] as removed
		  ,CONVERT(nvarchar(50), cast([updatedAt] as datetime2)) as updatedAt
		FROM HC.HasherKennelMap
		WHERE UserId = @userId AND updatedAt > @ua
		ORDER BY UserId ASC, updatedAt ASC, id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 14. HASHER–EVENT MAP  (page size: 250, user-scoped)
	---------------------------------------------------------------------------
	IF (@hasherEventMapUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherEventMapUpdatedAfter AS datetimeoffset(7))
		SELECT 
			 hem.[id] as hemId
			,hem.[UserId] as userId
			,hem.[EventId] as eventId
			,hem.[HasherOwnEventId] as hasherOwnEventId
			,hem.[UserStartEvent] as userStartEvent
			,hem.[UserEndEvent] as userEndEvent
			,hem.[RsvpState] as rsvpState
			,hem.[AttendenceState] as attendenceState
			,hem.[IsHare] as isHare
			,hem.[EventNotificationPreference] as eventNotificationPreference
			,hem.[EventEmailAlertPreference] as eventEmailAlertPreference
			,hem.[EventCountOverride] as eventCountOverride
			,hem.[VirginVisitorType] as virginVisitorType
			,hem.[TotalHaring] as totalHaring
			,hem.[TotalHaringThisKennel] as totalHaringThisKennel
			,hem.[TotalRuns] as totalRuns
			,hem.[TotalRunsThisKennel] as totalRunsThisKennel
			,hem.[DisplayName] as displayName
			,hem.[Email] as email
			,hem.[PhoneNumber] as phoneNumber
			,evt.[EventNumber] as hemEventNumber
			,evt.[CountryId] as hemCountryId
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS hemEventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2, evt.FbEventStartDatetime) ELSE convert(datetime2, evt.EventStartDatetime) END AS hemEventStartDatetime
			,coalesce(evt.EventStartDatetimeGmt, evt.EventStartDatetime) as hemEventStartDatetimeGmt
			,evt.[CanEditRunAttendence] as hemCanEditRunAttendence
			,CASE WHEN ((evt.IsCountedRun != 0) AND (evt.IsVisible != 0)) THEN 1 ELSE 0 END AS hemEventIsCountedAndVisible
			,evt.KennelId as hemEventKennelId
			,hkm.KennelUserPhoto as hemKennelUserPhoto
			,hkm.KennelHashName as hemKennelHashName
			,hem.[removed] as removed
			,CONVERT(nvarchar(50), cast(hem.[updatedAt] as datetime2)) as updatedAt
		FROM HC.HasherEventMap hem
		INNER JOIN HC.Event evt ON hem.EventId = evt.id
		LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = hem.UserId AND hkm.KennelId = hem.KennelId
		WHERE hem.UserId = @userId AND hem.[updatedAt] > @ua
		ORDER BY hem.UserId ASC, hem.[updatedAt] ASC, hem.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	---------------------------------------------------------------------------
	-- 15. EVENTS – narrow sync  (page size: 50)
	--     Returns recent/followed/attended events. Only runs when NOT doing a
	--     force-replicate for a specific kennel.
	---------------------------------------------------------------------------
	IF ((@narrowEventsUpdatedAfter != 'ignore') AND (@forceReplicateKennelId IS NULL))
	BEGIN
		SET @ua = CAST(@narrowEventsUpdatedAfter AS datetimeoffset(7))
		SELECT
			 evt.[id] as eventId
			,evt.[PublicEventId] as publicEventId
			,evt.[KennelId] as kennelId
			,evt.[IsVisible] as isVisible
			,evt.[IsCountedRun] as isCountedRun
			,evt.[EventGeographicScope] as eventGeographicScope
			,evt.[InboundIntegrationId] as eventInboundIntegrationId
			,evt.[IsPromotedEvent] as isPromotedEvent
			,evt.[EventNumber] as eventNumber
			,evt.[EventPriceForMembers] as eventPriceForMembers
			,evt.[EventPriceForNonMembers] as eventPriceForNonMembers

			,evt.[EventPriceForExtras] as eventPriceForExtras
			,evt.[ExtrasDescription] as extrasDescription
			,evt.[DoTrackHashCash] as doTrackHashCash

			,evt.[EventFacebookId] as eventFacebookId
			,evt.[AbsoluteEventNumber] as absoluteEventNumber
			,evt.[CanEditRunAttendence] as canEditRunAttendence

			,evt.Hares as hares
			,evt.EventPaymentScheme as eventPaymentScheme
			,evt.EventPaymentUrl as eventPaymentUrl
			,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
			,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount
			,evt.EvtDisseminateAllowWebLinks as evtDisseminateAllowWebLinks

			,evt.[Tags1] as tags1
			,evt.[Tags2] as tags2
			,evt.[Tags3] as tags3

			,CASE WHEN (evt.UseFbImage = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2, evt.FbEventStartDatetime) ELSE convert(datetime2, evt.EventStartDatetime) END AS eventStartDatetime
			,coalesce(evt.EventStartDatetimeGmt, evt.EventStartDatetime) as eventStartDatetimeGmt

			,evt.SyncDescription as eventDescription
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			,evt.EventUrl AS eventUrl

			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion

			,evt.[removed] as removed
			,CONVERT(nvarchar(50), cast(evt.[updatedAt] as datetime2)) as updatedAt

			,evt.UseFbLocation as useFbLocation
			,evt.UseFbLatLon as useFbLatLon
			,evt.UseFbRunDetails as useFbRunDetails
			,evt.UseFbImage as useFbImage

			,evt.Latitude as hcLatitude
			,evt.Longitude as hcLongitude
			,evt.CountryId as countryId
			,coalesce(evt.w3wLatitude, evt.FbLatitude) as fbLatitude
			,coalesce(evt.w3wLongitude, evt.FbLongitude) as fbLongitude

		FROM HC.Event evt
		WHERE 
			evt.updatedAt > @ua
			AND 
			(
				evt.EventStartDatetimeIndexed > dateadd(day, -@DAYS_IN_THE_PAST_TO_SYNC_EVENTS, getdate())
				OR
				evt.KennelId IN (SELECT KennelId FROM HC.HasherKennelMap WHERE UserId = @userId AND Following = 1)
				OR
				evt.id IN (SELECT hem.eventId FROM HC.HasherEventMap hem WHERE hem.userId = @userId AND hem.attendenceState >= 3)
			)
		ORDER BY evt.updatedAt ASC, evt.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging50 ROWS ONLY
		OPTION (RECOMPILE);
	END

	---------------------------------------------------------------------------
	-- 16. PAYMENTS  (page size: 250, user-scoped)
	--     Added ORDER BY + OFFSET/FETCH for deterministic paging.
	---------------------------------------------------------------------------
	IF (@paymentsUpdatedAfter != 'ignore')
	BEGIN
		SET @ua = CAST(@paymentsUpdatedAfter AS datetimeoffset(7))
		SELECT 
			 [id] as paymentId
			,[KennelId] as kennelId
			,[UserId] as paidBy
			,[HasherEventMapId] as hemId
			,[EventId] as eventId
			,[PaymentProcessedBy_userId] as paidTo
			,[CreditAmount] as creditAmount
			,[DebitAmount] as debitAmount
			,[CreditAvailable] as creditAvailable
			,cast([PaidDate] as datetime) as paidDate
			,[PaymentType] as paymentType
			,[ProductType] as productType
			,cast([CancelledDate] as datetime) as cancelledDate
			,[CancelledBy_UserId] as cancelledBy
			,cast([ConfirmedDate] as datetime) as confirmedDate
			,[ConfirmedBy_UserId] as confirmedBy
			,[PaymentReference] as paymentReference
			,[DiscountAmount] as discountAmount
			,[DiscountPercent] as discountPercent
			,[DiscountDescription] as discountDescription
			,[SpecialRunPriceReason] as specialRunPriceReason
			,[Notes] as notes
			,[DoPayForExtras] as doPayForExtras
			,[Surcharge] as surcharge
			,[PaymentProvider] as paymentProvider

			,[removed] as removed
			,CONVERT(nvarchar(50), cast([updatedAt] as datetime2)) as updatedAt

		FROM HC.Payment pmt
		WHERE pmt.UserId = @userId AND pmt.updatedAt > @ua
		ORDER BY pmt.updatedAt ASC, pmt.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END
	
	---------------------------------------------------------------------------
	-- 17. EVENTS – force replicate all for a specific kennel  (page size: 250)
	--     Optimisation: removed unused INNER JOIN HC.Kennel (never referenced).
	--     Added ORDER BY + OFFSET/FETCH + OPTION (RECOMPILE) for paging and
	--     plan quality. Removed redundant @forceReplicateKennelId IS NOT NULL
	--     check (already guaranteed by outer IF).
	---------------------------------------------------------------------------
	IF (@forceReplicateKennelId IS NOT NULL)
	BEGIN
		SELECT
		 evt.[id] as eventId
		,evt.[PublicEventId] as publicEventId
		,evt.[KennelId] as kennelId
		,evt.[IsVisible] as isVisible
		,evt.[IsCountedRun] as isCountedRun
		,evt.[EventGeographicScope] as eventGeographicScope
		,evt.[InboundIntegrationId] as eventInboundIntegrationId
		,evt.[IsPromotedEvent] as isPromotedEvent
		,evt.[EventNumber] as eventNumber
		,evt.[EventPriceForMembers] as eventPriceForMembers
		,evt.[EventPriceForNonMembers] as eventPriceForNonMembers

		,evt.[EventPriceForExtras] as eventPriceForExtras
		,evt.[ExtrasDescription] as extrasDescription
		,evt.[DoTrackHashCash] as doTrackHashCash

		,evt.[EventFacebookId] as eventFacebookId
		,evt.[AbsoluteEventNumber] as absoluteEventNumber
		,evt.[CanEditRunAttendence] as canEditRunAttendence

		,evt.Hares as hares
		,evt.EventPaymentScheme as eventPaymentScheme
		,evt.EventPaymentUrl as eventPaymentUrl
		,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
		,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount
		,evt.EvtDisseminateAllowWebLinks as evtDisseminateAllowWebLinks

		,evt.[Tags1] as tags1
		,evt.[Tags2] as tags2
		,evt.[Tags3] as tags3

		,CASE WHEN (evt.UseFbImage = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
		,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
		,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2, evt.FbEventStartDatetime) ELSE convert(datetime2, evt.EventStartDatetime) END AS eventStartDatetime 
		,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2, evt.FbEventStartDatetime) ELSE convert(datetime2, evt.EventStartDatetimeGmt) END AS eventStartDatetimeGmt 
		,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventDescription ELSE evt.EventDescription END AS eventDescription
		,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
		,evt.EventUrl AS eventUrl
			
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
		,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion

		,evt.[removed] as removed
		,CONVERT(nvarchar(50), cast(evt.[updatedAt] as datetime2)) as updatedAt

		,evt.UseFbLocation as useFbLocation
		,evt.UseFbLatLon as useFbLatLon
		,evt.UseFbRunDetails as useFbRunDetails
		,evt.UseFbImage as useFbImage

		,evt.Latitude as hcLatitude
		,evt.Longitude as hcLongitude
		,evt.CountryId as countryId
		,coalesce(evt.w3wLatitude, evt.FbLatitude) as fbLatitude
		,coalesce(evt.w3wLongitude, evt.FbLongitude) as fbLongitude

		FROM HC.Event evt
		WHERE 
			evt.KennelId = @forceReplicateKennelId
			AND 
			(
				evt.EventStartDatetimeIndexed > dateadd(day, -@DAYS_IN_THE_PAST_TO_SYNC_EVENTS, getdate())
				OR
				evt.KennelId IN (SELECT KennelId FROM HC.HasherKennelMap WHERE UserId = @userId AND Following = 1)
				OR
				evt.id IN (SELECT hem.eventId FROM HC.HasherEventMap hem WHERE hem.userId = @userId AND hem.attendenceState >= 3)
			)
		ORDER BY evt.updatedAt ASC, evt.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
		OPTION (RECOMPILE);
	END
END
