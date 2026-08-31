



CREATE PROCEDURE [HC5].[hcapp_syncEventAdminData]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @narrowEventsUpdatedAfter nvarchar(50) = 'ignore',
 @paymentsUpdatedAfter nvarchar(50) = 'ignore',
 @receiptsUpdatedAfter nvarchar(50) = 'ignore',
 @kennelCreditsUpdatedAfter nvarchar(50) = 'ignore',
 @usePaging int = 0,
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

SET NOCOUNT ON

-- NOTE: We could get into a situation where we are in an endless loop of loading by overlapping 
-- the times using "dateadd(second,-1,@ua)". This is a temporary fix that is there to ensure
-- we don't miss replicating records. I have to think of a workaround.

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty EventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),@accessToken,coalesce(@param,@deviceSecret),@timeWindow) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00')) SET @hashersUpdatedAfter = 'ignore'
	if ((@hasherEventMapUpdatedAfter IS NULL) OR (@hasherEventMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherEventMapUpdatedAfter = 'ignore'
	if ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	if ((@narrowEventsUpdatedAfter IS NULL) OR (@narrowEventsUpdatedAfter <= '2000-01-01 00:00:00')) SET @narrowEventsUpdatedAfter = 'ignore'
	if ((@paymentsUpdatedAfter IS NULL) OR (@paymentsUpdatedAfter <= '2000-01-01 00:00:00')) SET @paymentsUpdatedAfter = 'ignore'
	--if ((@kennelCreditsUpdatedAfter IS NULL) OR (@kennelCreditsUpdatedAfter <= '2000-01-01 00:00:00')) SET @kennelCreditsUpdatedAfter = 'ignore'


	DECLARE @paging1000 int = 1000
	DECLARE @paging250 int = 250

	IF (@usePaging = 0)
	BEGIN
		SET @paging1000 = 1000000
		SET @paging250 = 1000000
	END

	DECLARE @kennelId uniqueidentifier
	SELECT @kennelId = kennelId from HC.Event where id = @eventId

	DECLARE @ua datetimeoffset(7)

	if (LOWER(@hashersUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hashersUpdatedAfter as datetimeoffset(7))
		SELECT 
			h.id as hasherId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			CONVERT(nvarchar(50),cast(coalesce(h.updatedAt,getdate()) as datetime2)) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h WITH(INDEX(IX_AllSyncHashers))
		WHERE updatedAt > @ua
		ORDER BY h.updatedAt ASC, h.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging1000 ROWS ONLY
	END

	if (LOWER(@hasherEventMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherEventMapUpdatedAfter as datetimeoffset(7))
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
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS hemEventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS hemEventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,coalesce(evt.EventStartDatetimeGmt,evt.EventStartDatetime) as hemEventStartDatetimeGmt
			,evt.[CanEditRunAttendence] as hemCanEditRunAttendence
			,CASE WHEN ((evt.IsCountedRun != 0) AND (evt.IsVisible != 0)) THEN 1 ELSE 0 END AS hemEventIsCountedAndVisible
			,evt.KennelId as hemEventKennelId
			,hkm.KennelUserPhoto as hemKennelUserPhoto
			,hkm.KennelHashName as hemKennelHashName
			,hem.[removed] as removed
			,CONVERT(nvarchar(50),cast(hem.[updatedAt] as datetime2)) as updatedAt
		FROM HC.HasherEventMap hem WITH(INDEX(IX_EventSyncHasherEventMap))
		INNER JOIN HC.Event evt on evt.id = hem.EventId
		LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = hem.UserId AND hkm.KennelId = hem.KennelId
		WHERE hem.EventId = @eventId AND hem.updatedAt > @ua
		ORDER BY updatedAt ASC, hem.id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END


	if (LOWER(@hasherKennelMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherKennelMapUpdatedAfter as datetimeoffset(7))
		SELECT 
		   [id] as hkmId
		  ,[UserId] as userId
		  ,[KennelId] as kennelId

		  ,[Following] as following
		  ,CASE WHEN coalesce(MembershipExpirationDate,'1/1/2000') > getdate() THEN 1 ELSE 0 END as isMember
		  ,[IsHomeKennel] as isHomeKennel
		  ,[IsKennelFollowing] as isKennelFollowing
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoles] as mismanagementRoles
		  ,[UserRoleFlags] as userRoleFlags
		  ,[AppAccessFlags] as appAccessFlags
		  ,[HcTotalRunCount] as hcTotalRunCount
		  ,[HcHaringCount] as hcHaringCount
		  ,[HistoricalHaringCount] as historicalHaringCount
		  ,[HistoricalTotalRunCount] as historicalTotalRunCount
		  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
		  ,[KennelCredit] as kennelCredit
		  ,[DiscountAmount] as discountAmount
		  ,[DiscountPercent] as discountPercent
		  ,[DiscountDescription] as discountDescription
		  ,[MembershipExpirationDate] as membershipExpirationDate
		  ,'' as authorizedDeviceList
		  ,0 as authorizedDeviceCount
		  ,[MemberSince] as memberSince
		  ,[DateOfLastRun] as dateOfLastRun
		  ,[KennelUserPhoto] as kennelUserPhoto
		  ,[KennelHashName] as kennelHashName
		  ,[removed] as removed
		  ,CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt
		FROM HC.HasherKennelMap WITH(INDEX(IX_KennelSyncHasherKennelMap))
		WHERE KennelId = @kennelId AND updatedAt > @ua
		ORDER BY updatedAt ASC, id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY
	END

	--if (LOWER(@hasherKennelMapUpdatedAfter) != 'ignore')
	--BEGIN
	--	SET @ua = CAST(@hasherKennelMapUpdatedAfter as datetimeoffset(7))
	--	SELECT 
	--	   [id] as hkmId
	--	  ,[UserId] as userId
	--	  ,[KennelId] as kennelId
	--	  ,[Following] as following
	--	  ,[IsMember] as isMember
	--	  ,[IsHomeKennel] as isHomeKennel
	--	  ,[IsKennelFollowing] as isKennelFollowing
	--	  ,[KennelNotificationPreference] as kennelNotificationPreference
	--	  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
	--	  ,[MismanagementRoles] as mismanagementRoles
	--	  ,[UserRoleFlags] as userRoleFlags
	--	  ,[AppAccessFlags] as appAccessFlags
	--	  ,[KennelCredit] as kennelCredit
	--	  ,[DiscountAmount] as discountAmount
	--	  ,[DiscountPercent] as discountPercent
	--	  ,[DiscountDescription] as discountDescription
	--	  ,[HcTotalRunCount] as hcTotalRunCount
	--	  ,[HcHaringCount] as hcHaringCount
	--	  ,[HistoricalTotalRunCount] as historicalTotalRunCount
	--	  ,[HistoricalHaringCount] as historicalHaringCount
	--	  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
	--	  ,[MembershipExpirationDate] as membershipExpirationDate
	--	  ,[MemberSince] as memberSince
	--	  ,[DateOfLastRun] as dateOfLastRun
	--	  ,'' as authorizedDeviceList
	--	  ,0 as authorizedDeviceCount
	--	  ,[removed] as removed
	--	  ,CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt
	--	FROM HC.HasherKennelMap WITH(INDEX(IX_KennelSyncHasherKennelMap))
	--	WHERE KennelId = @kennelId AND updatedAt > @ua
	--	ORDER BY updatedAt ASC, id ASC
	--	OFFSET 0 ROWS  
	--	FETCH NEXT @paging250 ROWS ONLY

	--END

	if (LOWER(@narrowEventsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@narrowEventsUpdatedAfter as datetimeoffset(7))
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

			,evt.[Tags1] as tags1
			,evt.[Tags2] as tags2
			,evt.[Tags3] as tags3

			
			-- FB run details flag
			,CASE WHEN (evt.UseFbImage = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
			
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,coalesce(evt.EventStartDatetimeGmt,evt.EventStartDatetime) as eventStartDatetimeGmt
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventDescription ELSE evt.EventDescription END AS eventDescription
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			,evt.EventUrl AS eventUrl
			
			-- FB lat/lon flag
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL AND evt.FbLatitude >= -90.0 AND evt.FbLongitude >= -180.0) THEN evt.[fbLatitude] ELSE coalesce(evt.[Latitude],ken.Latitude) END AS narrowEventLatitude
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL AND evt.FbLatitude >= -90.0 AND evt.FbLongitude >= -180.0) THEN evt.[fbLongitude] ELSE coalesce(evt.[Longitude],ken.Longitude) END AS narrowEventLongitude

			-- FB location flag
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion


			,evt.[removed] as removed
			,CONVERT(nvarchar(50),cast(evt.[updatedAt] as datetime2)) as updatedAt

			,evt.UseFbLocation as useFbLocation
			,evt.UseFbLatLon as useFbLatLon
			,evt.UseFbRunDetails as useFbRunDetails
			,evt.UseFbImage as useFbImage

			,evt.Latitude as hcLatitude
			,evt.Longitude as hcLongitude
			,evt.CountryId as countryId -- this is the country where the event took place, which may be different than the country where the Kennel is currently located
			,coalesce(evt.w3wLatitude,evt.FbLatitude) as fbLatitude
			,coalesce(evt.w3wLongitude,evt.FbLongitude) as fbLongitude

		FROM HC.Event evt WITH(INDEX(PK_Event))
		INNER JOIN HC.Kennel ken on evt.KennelId = ken.id
		WHERE evt.id = @eventId AND evt.updatedAt > @ua
		
	END

	if (LOWER(@paymentsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@paymentsUpdatedAfter as datetimeoffset(7))
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
			,cast ([PaidDate] as datetime) as paidDate
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
			,CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt

		FROM HC.Payment pmt
		where pmt.updatedAt > @ua
		AND pmt.EventId = @eventId
	END

	if (LOWER(@receiptsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@receiptsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as receiptId
			,[EventId] as eventId
			,[UserId] as userId
			,[ReceiptAmount] as receiptAmount
			,[CostCategory] as costCategory
			,[DateUploaded] as dateUploaded
			,[ImageUrl] as imageUrl
			,[ReceiptShortDesc] as receiptShortDesc
			,[Notes] as notes
			,[ReimbursedBy] as reimbursedBy
			,[ReimbursedOn] as reimbursedOn
			,[ReimbursedAmount] as reimbursedAmount
			,[ReimbursedNotes] as reimbursedNotes
			,[removed] as removed
			,CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt

		FROM HC.Receipt rec
		where rec.updatedAt > @ua
		AND rec.EventId = @eventId
	END

	--if (LOWER(@kennelCreditsUpdatedAfter) != 'ignore')
	--BEGIN
	--	SET @ua = CAST(@kennelCreditsUpdatedAfter as datetimeoffset(7))
	--	SELECT 
	--		 kcred.[id] as kennelCreditId
	--		,[userId] as userId
	--		,kcred.[kennelId] as kennelId
	--		,kcred.[currentBalance] as currentBalance
	--		,kcred.[balanceAsOfEventId] as balanceAsOfEventId
	--		,CONVERT(nvarchar(50),cast(kcred.[updatedAt] as datetime2)) as updatedAt
	--		,kcred.[removed] as removed
	--	FROM HC.KennelCredit kcred 
	--	INNER JOIN HC.Event evt on kcred.kennelId = evt.KennelId
	--	where kcred.updatedAt > @ua
	--	AND evt.id = @eventId
	--END

END

