

CREATE PROCEDURE [HC5].[hcapp_setBulkEventAttendence]

	@deviceId uniqueidentifier, -- the one making the call to this SP
	@accessToken nvarchar(1000),
	@eventId uniqueidentifier,
	@hasherIds varchar(8000), -- the hasher who is joining the event
 
	@attendenceState smallint,
	@hasherEventMapUpdatedAfter nvarchar(50),
	@hasherKennelMapUpdatedAfter nvarchar(50)

AS

BEGIN

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindows int,
			@queryStart datetime

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindows = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	SELECT @queryStart = dateadd(second,-1,getdate())

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


	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	
	IF ((@attendenceState IS NULL) OR (@attendenceState < 20) OR (@attendenceState > 40))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Invalid attendence state','An invalid attendence state was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Invalid attendence state' as errorTitle
		,'An invalid attendence state was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindows) = 0 
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

	DECLARE  
		 @kennelId uniqueidentifier
		,@eventDate datetime
		,@eventName nvarchar(250)

	IF (@hasherIds IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (
			id, 
			HcVersion, 
			ErrorName,
			ErrorDescription,
			ProcName,userId
		) VALUES 
		(
			@errorId,
			'<unknown>',
			'Unknown user',
			'An unknown user was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),
			@userId
		)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Unknown user' as errorTitle
		,'An unknown user was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	SELECT 
		 @kennelId = evt.KennelId
		,@eventDate = evt.EventStartDatetime
		,@eventName = evt.EventName
	FROM HC.Event evt where evt.id = @eventId

	DECLARE @updatedRowCount int,
			@insertedRowCount int

	;WITH ParsedGuids AS (
    SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
    FROM STRING_SPLIT(@hasherIds, ',')
    WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
)
	UPDATE hem SET 
			hem.AttendenceState = @attendenceState,
			hem.RsvpState = 3,
			hem.updatedAt = getdate()
		FROM HC.HasherEventMap hem inner join ParsedGuids pg on pg.UserId = hem.UserId
		WHERE hem.EventId = @eventId
		
	SET @updatedRowCount = @@ROWCOUNT
	

	;WITH ParsedGuids AS (
    SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
    FROM STRING_SPLIT(@hasherIds, ',')
    WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
	)

	INSERT INTO [HC].[HasherEventMap]
				([id]
				,[EventId]
				,[KennelId]
				,[UserId]
				,[AttendenceState]
				,[RsvpState]
				,[IsHare]
				,[VirginVisitorType]
				,[updatedAt])

	SELECT 
		newid(),
		@eventId,
		@kennelId,
		pg.UserId,
		@attendenceState,
		3, -- RSVP state is always 3 with a bulk update
		0, -- IsHare is always 0 with a bulk import
		0, -- VirginVisitorType is always 0 with a bulk import
		getdate()
	FROM ParsedGuids pg left outer join HC.HasherEventMap hem on hem.UserId = pg.UserId AND hem.EventId = @eventId
	WHERE hem.id IS NULL

		
	SET @insertedRowCount = @@ROWCOUNT

	EXEC HC.nonApi_updateRunCountsForAllUsers @updatedSince = @queryStart

	SELECT
	1 as adHocDataId
	,cast(@updatedRowCount as nvarchar(10)) + ' records updated, ' + cast(@insertedRowCount as nvarchar(10)) + ' records inserted, '  as serverMessage
	

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)
	SET @hasherKennelMapUpdatedAfter = coalesce(@hasherKennelMapUpdatedAfter,'ignore')
	SET @hasherEventMapUpdatedAfter = coalesce(@hasherEventMapUpdatedAfter,'ignore')


	EXEC HC5.hcapp_syncEventAdminData 
		@deviceId = @deviceId,
		@accessToken = @accessToken,
		@eventId = @eventId,
		@hashersUpdatedAfter = 'ignore',
		@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
		@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
		@narrowEventsUpdatedAfter = 'ignore',
		@paymentsUpdatedAfter = 'ignore',
		@kennelCreditsUpdatedAfter = 'ignore',
		@receiptsUpdatedAfter = 'ignore',
		@procName = @procName,
		@param = NULL
	

END





