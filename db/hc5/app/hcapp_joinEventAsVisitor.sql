CREATE PROCEDURE [HC5].[hcapp_joinEventAsVisitor]  

@deviceId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier, 
@displayName nvarchar(250), 
@virginVisitorType smallint,
@attendenceState smallint,
@email nvarchar(250),
@phoneNumber nvarchar(250),
@hasherEventMapUpdatedAfter nvarchar(50),
@paymentsUpdatedAfter nvarchar(50)

AS

-- exec HC.joinEventAsVisitor @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @displayName = 'Stacy', @virginVisitorType = '0'
BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

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

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

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

DECLARE @isGenericUserPresent smallint  
		,@kennelId uniqueidentifier   
		,@hasherEventMapId uniqueidentifier

-- only two types of Virgin/Visitors at the moment... check to make sure it's one of these
IF ((@VirginVisitorType = 1) OR (@VirginVisitorType = 2))  
BEGIN  
		-- The generic user is a record in HC.Hasher that is available to be mapped to for visitors, virgins and anyone else who 
		-- is not in the system. This allows us to account for people on runs without having to add a new HC.Hasher record
		-- for each one of them.
		SELECT  @isGenericUserPresent = count(*) from HC.Hasher h inner join HC.Event e on h.id = e.KennelId WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0  

		-- if the "generic user" is not present for this Kennel, go ahead and add one in HC.Hasher
		if (@isGenericUserPresent = 0)  
		BEGIN   
			SELECT 
				@kennelId = e.KennelId 
			FROM HC.Event e 
			WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0
	
			INSERT INTO [HC].[Hasher]             
			(
				[id] 
				,[FirstName]
				,[LastName]
				,[HashName] 
				,[NameDisplayPreference]
				,[Description]       
				,[HomeLatitude]       
				,[HomeLongitude]
				,[Email])   
				SELECT     
					k.id    
					,'Placeholder'
					,'User'
					,'Placeholder user for visitors / virgins for ' + k.KennelName 
					,1
					,'Placeholder user for visitors / virgins for ' + k.KennelName    
					,coalesce(k.Latitude,0)
					,coalesce(k.Longitude,0)
					,cast(k.id as nvarchar(50)) + '@harriercentral.com'
				FROM HC.Event e 
				INNER JOIN HC.Kennel k 
				ON e.KennelId = k.id   
				WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0   
		
		END 

		SELECT @hasherEventMapId = hem.id from HC.HasherEventMap hem where hem.EventId = @eventId AND hem.DisplayName is not null and hem.DisplayName = @displayName
		
		IF (@hasherEventMapId is null)
		BEGIN

			SET @hasherEventMapId = NEWID()


			INSERT INTO [HC].[HasherEventMap]
					   ([id]
					   ,[EventId]
					   ,[KennelId]
					   ,[UserId]
					   ,[UserStartEvent]
					   ,[EventCost]
					   ,[Rsvp]
					   ,[RsvpState]
					   ,[AttendenceState]
					   ,[VirginVisitorType] -- 0 = HasherInSystem, 1 = Virgin, 2 = Visitor
					   ,[DisplayName]
					   ,[Email]
					   ,[PhoneNumber]
					   ,[updatedAt])

					SELECT @hasherEventMapId
						,@eventId
						,e.KennelId
						,e.KennelId  -- Virgins and Visitors don't have their own UserId, so we put in the KennelId instead as a flag
						,getdate()
						,e.EventPriceForNonMembers
						,getdate()
						,3 -- RSVP state as 'coming'
						,@attendenceState
						,@virginVisitorType
						,@displayName
						,@email
						,@phoneNumber
						,getdate()
						from HC.Event e where e.id = @eventId and e.deleted = 0 and e.IsVisible <> 0

			END

	-- send back adHoc data to support cases when the user was scanned in at a Hash

	SELECT
		1 as adHocDataId,
		@hasherEventMapId as hasherEventMapId


		DECLARE @procName nvarchar(500)
		SET @procName = OBJECT_NAME(@@PROCID)

		EXEC HC5.hcapp_syncEventAdminData 
		 @deviceId = @deviceId,
		 @accessToken = @accessToken,
		 @eventId = @eventId,
		 @hashersUpdatedAfter = 'ignore',
		 @hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
		 @hasherKennelMapUpdatedAfter = 'ignore',
		 @narrowEventsUpdatedAfter = 'ignore',
		 @paymentsUpdatedAfter = @paymentsUpdatedAfter,
		 @receiptsUpdatedAfter = 'ignore',
		 @procName = @procName,
		 @param = NULL

END

END


