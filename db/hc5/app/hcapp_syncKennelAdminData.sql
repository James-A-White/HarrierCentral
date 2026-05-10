

CREATE PROCEDURE [HC5].[hcapp_syncKennelAdminData]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @kennelsUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
 @paymentsUpdatedAfter nvarchar(50) = 'ignore',
 @targetHasherId uniqueidentifier = NULL,
 @usePaging int = 0,
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

-- NOTE: We could get into a situation where we are in an endless loop of loading by overlapping 
-- the times using "dateadd(second,-1,@ua)". This is a temporary fix that is there to ensure
-- we don't miss replicating records. I have to think of a workaround.

SET NOCOUNT ON

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	DECLARE @paging1000 int = 1000
	DECLARE @paging250 int = 250

	IF (@usePaging = 0)
	BEGIN
		SET @paging1000 = 1000000
		SET @paging250 = 1000000
	END

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
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty EventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),@accessToken,coalesce(@param, @deviceSecret),@timeWindow) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00')) SET @hashersUpdatedAfter = 'ignore'
	if ((@kennelsUpdatedAfter IS NULL) OR (@kennelsUpdatedAfter <= '2000-01-01 00:00:00')) SET @kennelsUpdatedAfter = 'ignore'
	if ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	if ((@hasherEventMapUpdatedAfter IS NULL) OR (@hasherEventMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherEventMapUpdatedAfter = 'ignore'
	if ((@paymentsUpdatedAfter IS NULL) OR (@paymentsUpdatedAfter <= '2000-01-01 00:00:00')) SET @paymentsUpdatedAfter = 'ignore'

	DECLARE @ua datetimeoffset(7)

	if (LOWER(@kennelsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelsUpdatedAfter as datetimeoffset(7))
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
			,[KennelPinColor] as kennelPinColor
			,[KennelCoverPhoto] as kennelCoverPhoto
			,[KennelWebsiteUrl] as kennelWebsiteUrl
			,coalesce([KennelMismanagementTeam],'') as kennelMismanagementTeam
			,[DefaultEventCurrencyType] as defaultEventCurrencyType
			,[IntegrationType] as integrationType
			,[KennelEventsUrl] as kennelEventsUrl

			-- Ints / Smallints
			,[KennelStatus] as kennelStatus
			,[AllowNegativeCredit] as allowNegativeCredit
			,[AllowSelfPayment] as allowSelfPayment
			,[MembershipDurationInMonths] as membershipDurationInMonths
			,[DistancePreference] as distancePreference
			,[CanEditRunAttendence] as canEditRunAttendence
			,[InboundIntegrationId] as kennelInboundIntegrationId

			-- Doubles
			,coalesce(k.[Latitude],c.[Latitude]) as kennelLatitude
			,coalesce(k.[Longitude],c.[Longitude]) as kennelLongitude
			,[DefaultEventPriceForMembers] as defaultPriceForMembers
			,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

			-- DateTimes
			,[DefaultRunStartTime] as defaultRunStartTime
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
			,CONVERT(nvarchar(50),cast(k.[updatedAt] as datetime2)) as updatedAt

	  FROM [HC].[Kennel] k WITH(INDEX(IX_AllSyncKennels))
	  INNER JOIN [HC].[City] c on c.id = k.CityId
	  WHERE k.updatedAt > @ua
	  ORDER BY k.updatedAt ASC, k.id ASC
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
		  ,CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt
		FROM HC.HasherKennelMap WITH(INDEX(IX_KennelSyncHasherKennelMap))
		WHERE KennelId = @kennelId AND updatedAt > @ua
		ORDER BY updatedAt ASC, id ASC
		OFFSET 0 ROWS  
		FETCH NEXT @paging250 ROWS ONLY

	END

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
		AND pmt.UserId = @targetHasherId
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
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS hemEventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. 
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetimeGmt) END AS hemEventStartDatetimeGmt -- This is a bit of a hack, force conversion into local time prior to sending over the wire. 
			,coalesce(evt.EventStartDatetimeGmt,evt.EventStartDatetime) as eventStartDatetimeGmt
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
		WHERE hem.UserId = @targetHasherId AND hem.updatedAt > @ua
		ORDER BY updatedAt ASC, hem.id ASC
	END
END

