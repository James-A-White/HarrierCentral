 CREATE PROCEDURE [HC5].[hcapp_copyEventRsvps]

  @deviceId uniqueidentifier,
  @accessToken nvarchar(1000),
  @fromEvent uniqueidentifier,
  @toEvent uniqueidentifier,
  @hasherEventMapUpdatedAfter nvarchar(50)

 AS

 BEGIN

 -- EXEC [HC5].[hcapp_copyEventRsvps]@deviceId = '86a228ed-30d9-40c5-9470-8bf2eeaec0e6', @accessToken = '5F548EA52469EF5FC59035FA458C7FCAD1C927B350F0F0CE6507EAC0A611AF0', @fromEvent = 'ed8bcbc6-b899-4bd3-ac0e-7c01e53ca2dd', @toEvent = '904971ce-beb8-4bfc-9592-96a611aad113', @hasherEventMapUpdatedAfter = '2022-09-11 03:17:16.662902'

 
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
 		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
 		,OBJECT_NAME(@@PROCID) as errorProc
 		RETURN
 	END

 	IF (@fromEvent IS NULL) OR (@fromEvent = '00000000-0000-0000-0000-000000000000')
 	BEGIN

 		SET @errorId = newid()

 		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty fromEvent','A null or empty fromEvent was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
 		SELECT 
 		@errorId as errorId,
 		cast (2 as int) as errorType 
 		,'Null or empty fromEvent' as errorTitle
 		,'A null or empty value was passed as the fromEvent to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
 		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
 		,OBJECT_NAME(@@PROCID) as errorProc
 		RETURN
 	END

	IF (@toEvent IS NULL) OR (@toEvent = '00000000-0000-0000-0000-000000000000')
 	BEGIN

 		SET @errorId = newid()

 		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty toEvent','A null or empty toEvent was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
 		SELECT 
 		@errorId as errorId,
 		cast (2 as int) as errorType 
 		,'Null or empty toEvent' as errorTitle
 		,'A null or empty value was passed as the toEvent to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
 		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
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
 		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
 		,OBJECT_NAME(@@PROCID) as errorProc
 		RETURN
 	END

	DECLARE @serverMessage nvarchar(500)
	SET @serverMessage = 'Error copying records'


	INSERT INTO [HC].[HasherEventMap]
				([id]
				,[EventId]
				,[KennelId]
				,[UserId]
				,[RsvpState]
				,[IsHare]
				,[VirginVisitorType]
				,[updatedAt]
				)
	SELECT 
	  newid()
	  ,@toEvent
	  ,hemFrom.KennelId
	  ,hemFrom.UserId
	  ,hemFrom.RsvpState
	  ,hemFrom.IsHare
	  ,hemFrom.VirginVisitorType
	  ,getdate()
	FROM HC.HasherEventMap hemFrom
	LEFT OUTER JOIN HC.HasherEventMap hemTo on hemTo.EventId = @toEvent AND hemTo.UserId = hemFrom.UserId
	WHERE hemFrom.EventId = @fromEvent 
	AND hemFrom.removed = 0
	AND hemTo.id IS NULL
	
	SET @serverMessage = 'Copied ' + cast(@@ROWCOUNT as nvarchar(50)) + ' RSVPs'
	
	SELECT
			1 as adHocDataId
			,coalesce(@serverMessage,'') as serverMessage

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)

	SET @hasherEventMapUpdatedAfter = coalesce(@hasherEventMapUpdatedAfter,'ignore')
 	
	EXEC HC5.hcapp_syncEventAdminData
	@deviceId = @deviceId,
	@accessToken = @accessToken,
	@eventId = @toEvent,
	@hashersUpdatedAfter = 'ignore',
	@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter, -- force all HEM records for this event to be sent to the app
	@hasherKennelMapUpdatedAfter = 'ignore',
	@narrowEventsUpdatedAfter = 'ignore',
	@paymentsUpdatedAfter = 'ignore',
	@kennelCreditsUpdatedAfter = 'ignore',
	@receiptsUpdatedAfter = 'ignore',
	@procName = @procName,
	@param = NULL

 END

