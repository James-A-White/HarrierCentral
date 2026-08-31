
CREATE PROCEDURE [HC5].[hcapp_addEditEvent]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @narrowEventsUpdatedAfter datetimeoffset(7),
 @eventId uniqueidentifier = null,
 @kennelId uniqueidentifier = null,
 @startDatetime datetimeoffset(7) = null,
 @endDatetime datetimeoffset(7) = null,
 @isCountedRun smallint = null,
 @isVisible smallint = null,
 @usersCanEditRunAttendence smallint = null,
 @isPromotedEvent smallint = null,
 @eventGeographicScope smallint = null,
 @ThemeRunType smallint = null,
 @eventName nvarchar(120) = null,
 @eventDescription nvarchar(4000) = null,
 @locationCity nvarchar(250) = null,
 @locationStreet nvarchar(250) = null,
 @locationPostCode nvarchar(50) = null,
 @locationCountry nvarchar(250) = null,
 @locationRegion nvarchar(250) = null,
 @locationSubRegion nvarchar(250) = null,
 @locationOneLineDesc nvarchar(250) = null,
 @eventFacebookId nvarchar(250) = null,
 @coverPhotoUrl nvarchar(500) = null,
 @coverPhotoOffsetX int = null,
 @coverPhotoOffsetY int = null,
 @latitude decimal(18,15) = null,
 @longitude decimal(19,15) = null,
 @fbLatitude decimal(18,15) = null,
 @fbLongitude decimal(19,15) = null,
 @eventPriceForMembers float = null,
 @eventPriceForNonMembers float = null,
 @eventPriceForExtras float = null,
 @extrasDescription nvarchar(250) = null,
 @absoluteEventNumber smallint = null,
 @eventCurrencyType nvarchar(10) = null,
 @useFbLatLon smallint = null,
 @useFbRunDetails smallint = null,
 @useFbLocation smallint = null,
 @useFbImage smallint = null,
 @deleted smallint = null,
 @hasherEventMapUpdatedAfter datetimeoffset(7) = null,
 @hasherKennelMapUpdatedAfter datetimeoffset(7) = null,
 @hares nvarchar(2500) = null
 

AS

BEGIN

SET NOCOUNT ON

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

	--IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	--BEGIN

	--	SET @errorId = newid()

	--	INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
	--	SELECT 
	--	@errorId as errorId,
	--	cast (2 as int) as errorType 
	--	,'Null or empty eventId' as errorTitle
	--	,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
	--	,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--	RETURN
	--END


	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindow) = 0 
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

	DECLARE @resultStr nvarchar(250)
	DECLARE @resultInt int

	if (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL
	if (@kennelId = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL
	if ((@startDatetime IS NOT NULL) AND (@startDatetime <= '1/1/1901')) SET @startDatetime = NULL
	if ((@endDatetime IS NOT NULL) AND (@endDatetime <= '1/1/1901')) SET @endDatetime = NULL
	if (@isCountedRun = -1) SET @isCountedRun = NULL
	if (@isVisible = -1) SET @isVisible = NULL
	if (@isPromotedEvent = -1) SET @isPromotedEvent = NULL
	if (@eventGeographicScope = -1) SET @eventGeographicScope = NULL
	if (@ThemeRunType = -1) SET @ThemeRunType = NULL
	if (DATALENGTH(@eventName) < 2) SET @eventName = NULL
	if (DATALENGTH(@eventDescription) < 2) SET @eventDescription = NULL
	if (DATALENGTH(@locationCity) < 2) SET @locationCity = NULL
	if (DATALENGTH(@locationStreet) < 2) SET @locationStreet = NULL
	if (DATALENGTH(@locationPostCode) < 2) SET @locationPostCode = NULL
	if (DATALENGTH(@locationCountry) < 2) SET @locationCountry = NULL
	if (DATALENGTH(@locationRegion) < 2) SET @locationRegion = NULL
	if (DATALENGTH(@locationSubRegion) < 2) SET @locationSubRegion = NULL
	if (DATALENGTH(@locationOneLineDesc) < 2) SET @locationOneLineDesc = NULL
	if (DATALENGTH(@eventFacebookId) < 5) SET @eventFacebookId = NULL
	if (DATALENGTH(@coverPhotoUrl) < 5) SET @coverPhotoUrl = NULL
	if (DATALENGTH(@hares) < 4) SET @hares = NULL
	if (@coverPhotoOffsetX = -1) SET @coverPhotoOffsetX = NULL
	if (@coverPhotoOffsetY = -1) SET @coverPhotoOffsetY = NULL
	if (@latitude = -1) SET @latitude = NULL
	if (@longitude = -1) SET @longitude = NULL
	if (@fbLatitude = -1) SET @fbLatitude = NULL
	if (@fbLongitude = -1) SET @fbLongitude = NULL
	if (@useFbLatLon = -1) SET @useFbLatLon = NULL
	if (@useFbRunDetails = -1) SET @useFbRunDetails = NULL
	if (@useFbLocation = -1) SET @useFbLocation = NULL
	if (@useFbImage = -1) SET @useFbImage = NULL
	if (@eventPriceForMembers = -1) SET @eventPriceForMembers = NULL
	if (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL
	if (@eventPriceForExtras = -1) SET @eventPriceForExtras = NULL
	if (DATALENGTH(@extrasDescription) < 2) SET @extrasDescription = NULL
	if (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL -- if AbsoluteEventNumber is zero, that will cause the record to null out the value currently in AbsoluteEventNumber
	if (DATALENGTH(@eventCurrencyType) < 4) SET @eventCurrencyType = NULL
	if (@deleted = -1) SET @deleted = NULL

	if (@eventFacebookId like '%break%') SET @eventFacebookId = ''


	-- This is a unicode paragraph separator that screws up the ability to parse JSON in the app
	if (@eventDescription like '%'+NCHaR(8233)+'%') SET @eventDescription = REPLACE(@eventDescription,NCHaR(8233),'')
	if (@eventName like '%'+NCHaR(8233)+'%') SET @eventName = REPLACE(@eventName,NCHaR(8233),'')
	if (@locationOneLineDesc like '%'+NCHaR(8233)+'%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc,NCHaR(8233),'')
	if (@hares like '%'+NCHaR(8233)+'%') SET @hares = REPLACE(@hares,NCHaR(8233),'')

	-- This is a unicode paragraph separator that screws up the ability to parse JSON in the app
	if (@eventDescription like '%'+NCHaR(8232)+'%') SET @eventDescription = REPLACE(@eventDescription,NCHaR(8232),'')
	if (@eventName like '%'+NCHaR(8232)+'%') SET @eventName = REPLACE(@eventName,NCHaR(8232),'')
	if (@locationOneLineDesc like '%'+NCHaR(8232)+'%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc,NCHaR(8232),'')
	if (@hares like '%'+NCHaR(8232)+'%') SET @hares = REPLACE(@hares,NCHaR(8232),'')
	
	
	--DECLARE @lat DECIMAL(18,15)
	--DECLARE @lon DECIMAL(19,15)
	--DECLARE @geo GEOGRAPHY

	--SELECT @lat = coalesce(@latitude,@fbLatitude)
	--SELECT @lon = coalesce(@longitude,@fbLongitude)

	--IF ((@lat IS NOT NULL) AND (@lon IS NOT NULL))
	--BEGIN
	--	SET @geo = geography::Point(@lat, @lon, 4326)
	--END

    if ((@deleted IS NOT NULL) AND (@deleted = 1))
	BEGIN
		SET NOCOUNT ON
		-- use the kennel id and date if we don't have an eventId
		--if ((@eventId = '00000000-0000-0000-0000-000000000000') OR (@eventId is null))
		--BEGIN
		--	select top 1 @eventId = id from HC.Event WHERE KennelId = @kennelId AND cast(EventStartDatetime as Date) = cast(@startDatetime as Date)
		--END

		--if ((@eventId is not null) AND (@eventId <> '00000000-0000-0000-0000-000000000000'))
		--BEGIN
		--	UPDATE HC.Event SET 
		--	deleted = 1
		--	FROM HC.Event e where e.id = @eventId
		--END
			
	END
	ELSE
	BEGIN
	-- does a record exist? If so, we are in "edit" mode
	if ((@eventId is not null) AND ((SELECT count(*) from HC.Event e where e.id = @eventId AND e.KennelId = @kennelId) > 0))
		BEGIN
			declare @runCountsNeedToBeUpdated int = 0

			-- start by determining if we need to adjust run counts because this run has been updated
			-- have any of the items that would cause changes to hasher run counts changed?
			SELECT @runCountsNeedToBeUpdated = count(*) FROM HC.Event evt
				where id = @eventId
					AND (
							   ((@isCountedRun is not null) AND (@isCountedRun != evt.IsCountedRun))
							OR ((@isVisible is not null) AND (@isVisible != evt.IsVisible))
							OR ((@useFbRunDetails is not null) AND (@useFbRunDetails != evt.UseFbRunDetails))
							OR ((@startDatetime is not null) AND (@startDatetime != evt.EventStartDatetime))
						)

			UPDATE HC.Event SET 
			--KennelId = coalesce(@kennelId,KennelId),
			EventStartDatetime = coalesce(@startDatetime,EventStartDatetime,getdate()), -- at this point @startDatetime should never be null
			EventEndDatetime = coalesce(@endDatetime,EventEndDatetime),
			IsCountedRun = coalesce(@isCountedRun,IsCountedRun,0),
			IsVisible = coalesce(@isVisible,IsVisible),
			CanEditRunAttendence = case when @usersCanEditRunAttendence = -1 then null else coalesce(@usersCanEditRunAttendence,CanEditRunAttendence) end,
			IsPromotedEvent = coalesce(@isPromotedEvent,IsPromotedEvent),
			EventGeographicScope = coalesce(@eventGeographicScope,EventGeographicScope),
			ThemeRunType = coalesce(@ThemeRunType,ThemeRunType,0),
			EventName = coalesce(@eventName, EventName),
			EventDescription = case when @eventDescription = '<remove>' then null else coalesce(@eventDescription, EventDescription) end,
			LocationCity = case when @locationCity = '<remove>' then null else coalesce(@locationCity, LocationCity) end,
			LocationStreet = case when @locationStreet = '<remove>' then null else coalesce(@locationStreet, LocationStreet) end,
			LocationPostCode = case when @locationPostCode = '<remove>' then null else coalesce(@locationPostCode,LocationPostCode) end,
			LocationCountry = case when @locationCountry = '<remove>' then null else coalesce(@locationCountry,LocationCountry) end,
			LocationRegion = case when @locationRegion = '<remove>' then null else coalesce(@locationRegion,LocationRegion) end,
			LocationSubRegion = case when @locationSubRegion = '<remove>' then null else coalesce(@locationSubRegion,LocationSubRegion) end,
			LocationOneLineDesc = case when @locationOneLineDesc = '<remove>' then null else coalesce(@locationOneLineDesc, LocationOneLineDesc) end,
			EventFacebookId = coalesce(@eventFacebookId, EventFacebookId),
			EventImage = coalesce(@coverPhotoUrl, EventImage),
			EventImageOffsetX = coalesce(@coverPhotoOffsetX,EventImageOffsetX),
			EventImageOffsetY = coalesce(@coverPhotoOffsetY,EventImageOffsetY),
			Latitude = case when @latitude = -2.0 then null else coalesce(cast(@latitude as decimal(18,15)),Latitude) end,
			Longitude = case when @longitude = -2.0 then null else coalesce(cast(@longitude as decimal(19,15)),Longitude) end,
			FbLatitude = coalesce(cast(@fbLatitude as decimal(18,15)),FbLatitude),
			FbLongitude = coalesce(cast(@fbLongitude as decimal(19,15)),FbLongitude),
			EventGeolocation = 
			case when coalesce(@useFbLatLon,UseFbLatLon) = 1 then 
				case when coalesce(cast(@fbLatitude as decimal(18,15)),FbLatitude) is not null then
					geography::Point(coalesce(cast(@fbLatitude as decimal(18,15)),FbLatitude), coalesce(cast(@fbLongitude as decimal(18,15)),FbLongitude), 4326)
				else
					null
				end
			else
			  	case when case when @latitude = -2.0 then null else coalesce(cast(@latitude as decimal(18,15)),Latitude) end is not null then
					geography::Point(case when @latitude = -2.0 then null else coalesce(cast(@latitude as decimal(18,15)),Latitude) end, case when @longitude = 2.0 then null else coalesce(cast(@longitude as decimal(19,15)),Longitude) end, 4326)
				else
					null
				end
			end,
			EventPriceForMembers = case when @eventPriceForMembers = -2 then null else coalesce(@eventPriceForMembers,EventPriceForMembers) end,
			EventPriceForNonMembers = case when @eventPriceForNonMembers = -2 then null else coalesce(@eventPriceForNonMembers,EventPriceForNonMembers) end,
			EventPriceForExtras = case when @eventPriceForExtras = -2 then null else coalesce(@eventPriceForExtras,EventPriceForExtras) end,
			ExtrasDescription = case when @extrasDescription = '<none>' then null else coalesce(@extrasDescription,ExtrasDescription) end,
			AbsoluteEventNumber = case when @absoluteEventNumber = 0 then null else coalesce(@absoluteEventNumber, AbsoluteEventNumber) end,
			EventCurrencyType = coalesce(@eventCurrencyType, EventCurrencyType),
			deleted = coalesce(@deleted, deleted),
			EventSource = 'HC app',
			UseFbLatLon = coalesce(@useFbLatLon,UseFbLatLon),
			UseFbRunDetails = coalesce(@useFbRunDetails,UseFbRunDetails),
			UseFbLocation = coalesce(@useFbLocation,UseFbLocation),
			UseFbImage = coalesce(@useFbImage,UseFbImage),
			Hares = case when @hares = '<remove>' then null else coalesce(@hares,Hares) end,
			updatedAt = getdate()
			FROM HC.Event e where e.id = @eventId AND e.KennelId = @kennelId

			--IF (@runCountsNeedToBeUpdated != 0)
			--BEGIN
			--	EXEC HC.nonApi_updateRunCountsForEventUsers @eventId = @eventId
			--END

			set @resultStr = 'Updated record x ' + cast (@eventId as nvarchar(50)) + ' set name to: ' + coalesce(@eventName,'oops, it is null!')
			set @resultInt = 1
		END
	ELSE
		BEGIN

			if (coalesce(datalength(@eventName),0) < 1) 
			BEGIN
				DECLARE @kennelShortName nvarchar(50)
				SELECT @kennelShortName = k.KennelShortName from HC.Kennel k where k.id = @kennelId
				SET @eventName = 'Placeholder event for ' + coalesce(@kennelShortName,'<no kennel found>')
			END

			-- record does not exist, we're in insert mode
			if ((datalength(Trim(@eventName)) > 0) AND (@startDatetime is not null) AND (@kennelId is not null) AND (@kennelId <> '00000000-0000-0000-0000-000000000000'))
			BEGIN

				if (cast(@startDatetime as time) = '00:00:00.0000000')
				BEGIN
					DECLARE	 @time time(7),
							 @diffSeconds int

					SELECT @time = DefaultRunStartTime from HC.Kennel where id = @kennelId

					if (@time is not null) 
					BEGIN
						SELECT @diffSeconds = datediff(second,'00:00:00',@time)
						SET @startDateTime = dateadd(second,@diffSeconds,@startDateTime)
					END
				END

				if (@eventId is null) SET @eventId = newid()

				DECLARE @countryId uniqueidentifier

				if ((@kennelId is not null) AND (@kennelId != '00000000-0000-0000-0000-000000000000'))
				BEGIN
					SELECT 
						@eventPriceForMembers = coalesce(@eventPriceForMembers,k.DefaultEventPriceForMembers),
						@eventPriceForNonMembers = coalesce(@eventPriceForNonMembers,k.DefaultEventPriceForNonMembers),
						@countryId = k.CountryId
					 from HC.Kennel k WHERE k.id = @kennelId
				END

				INSERT HC.Event 
					(
						id
						,KennelId
						,EventStartDatetime
						,EventEndDatetime
						,IsCountedRun
						,IsVisible
						,IsPromotedEvent
						,CanEditRunAttendence
						,EventGeographicScope
						,InboundIntegrationId
						,ThemeRunType
						,EventName
						,EventDescription
						,LocationCity
						,LocationStreet
						,LocationPostCode
						,LocationCountry
						,LocationRegion
						,LocationSubRegion
						,LocationOneLineDesc
						,EventFacebookId
						,EventImage
						,EventImageOffsetX
						,EventImageOffsetY

						,Latitude
						,Longitude
						,FbLatitude
						,FbLongitude
						,EventGeolocation
						,EventPriceForMembers
						,EventPriceForNonMembers
						,EventPriceForExtras
						,ExtrasDescription
						,AbsoluteEventNumber
						,EventCurrencyType
						,Hares
						,EventSource
						,deleted
						,updatedAt
						,countryId
					) VALUES 
					(
						@eventId
						,@KennelId
						,coalesce(@startDatetime,getdate()) -- at this point @startDatetime should never be null
						,@endDatetime
						,coalesce(@isCountedRun,0)
						,coalesce(@isVisible,1)
						,coalesce(@isPromotedEvent,0)
						,case when @usersCanEditRunAttendence = -1 then null else @usersCanEditRunAttendence end
						,coalesce(@eventGeographicScope,0)
						,0 -- InboundIntegrationId set for Harrier Central as the source
						,coalesce(@ThemeRunType,0)
						,@eventName
						,case when @eventDescription = '<remove>' then null else @eventDescription end
						,case when @locationCity = '<remove>' then null else @locationCity end
						,case when @locationStreet = '<remove>' then null else @locationStreet end
						,case when @locationPostCode = '<remove>' then null else @locationPostCode end
						,case when @locationCountry = '<remove>' then null else @locationCountry end
						,case when @locationRegion = '<remove>' then null else @locationRegion end
						,case when @locationSubRegion = '<remove>' then null else @locationSubRegion end
						,case when @locationOneLineDesc = '<remove>' then null else @locationOneLineDesc end
						,@eventFacebookId
						,@coverPhotoUrl
						,coalesce(@coverPhotoOffsetX,0)
						,coalesce(@coverPhotoOffsetY,0)
						,case when @latitude = -2.0 then null else cast(@latitude as decimal(18,15)) end
						,case when @longitude = -2.0 then null else cast(@longitude as decimal(19,15)) end
						,cast(@fbLatitude as decimal(18,15))
						,cast(@fbLongitude as decimal(19,15))
						,case when @useFbLatLon = 1 then 
							case when cast(@fbLatitude as decimal(18,15)) is not null then
								geography::Point(cast(@fbLatitude as decimal(18,15)), cast(@fbLongitude as decimal(18,15)), 4326)
							else
								null
							end
						else
			  				case when case when @latitude = -2.0 then null else cast(@latitude as decimal(18,15)) end is not null then
								geography::Point(case when @latitude = -2.0 then null else cast(@latitude as decimal(18,15)) end, case when @longitude = 2.0 then null else cast(@longitude as decimal(19,15)) end, 4326)
							else
								null
							end
						end
						,case when @eventPriceForMembers = -2 then null else @eventPriceForMembers end
						,case when @eventPriceForNonMembers = -2 then null else @eventPriceForNonMembers end
						,case when @eventPriceForExtras = -2 then null else @eventPriceForExtras end
						,case when @extrasDescription = '<none>' then null else @extrasDescription end
						,@absoluteEventNumber
						,@eventCurrencyType
						,case when @locationOneLineDesc = '<remove>' then null else @locationOneLineDesc end
						,'HC app'
						,coalesce(@deleted,0)
						,getdate()
						,@countryId
					)

				SET @resultStr = 'Insert succeeded'
				SET @resultInt = 1
			END
		END
	END

	EXEC HC.nonApi_updateRunNumbers @eventId = @eventId

	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)

	-- added this capability to sync user run counts
	-- when event parameters have been changed. Older
	-- versions of the HC App will not pass these values in, so they may be null
	DECLARE @hasherEventMapUpdatedAfterStr nvarchar(50) = coalesce(cast(@hasherEventMapUpdatedAfter as nvarchar(50)),'ignore'),
			@hasherKennelMapUpdatedAfterStr nvarchar(50) = coalesce(cast(@hasherKennelMapUpdatedAfter as nvarchar(50)),'ignore')

	EXECUTE [HC5].[hcapp_syncUserData] 
	   @deviceId
	  ,@accessToken
	  ,@hashersUpdatedAfter = 'ignore'
	  ,@citiesUpdatedAfter = 'ignore'
	  ,@regionsUpdatedAfter = 'ignore'
	  ,@countriesUpdatedAfter = 'ignore'
	  ,@kennelsUpdatedAfter = 'ignore'
	  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfterStr
	  ,@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfterStr
	  ,@narrowEventsUpdatedAfter = @narrowEventsUpdatedAfter
	  ,@procName = @procName
	  ,@param = NULL
	  

END






