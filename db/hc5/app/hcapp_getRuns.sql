CREATE PROCEDURE [HC5].[hcapp_getRuns]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000) = 'none',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000'

AS

--HC5.hcapp_getRuns @deviceId = '723BB72E-3737-4B53-A3A9-D5B812AD930C', @accessToken = '{accessToken_getMyRuns}',@kennelId = 'D1D51D20-5C09-458A-AD0F-D22A8B5BA019'

BEGIN

	DECLARE @errorId uniqueidentifier

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindows int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindows = d.TimeWindow
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
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	SET NOCOUNT ON

	IF (HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindows) = 0)
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

	IF (@kennelId IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty kennelId','A null or empty kennelId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty kennelId' as errorTitle
		,'A null or empty value was passed as the kennelId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF @kennelId IS NULL
	BEGIN		
		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Null or empty kennelId' as errorTitle
		,'A null or empty value was passed as the kennelId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		
		RETURN
	END
	
	--DECLARE @userId uniqueidentifier = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
	--DECLARE @kennelId uniqueidentifier = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'

	SELECT 
	   e.id as eventId  --0
       ,CASE WHEN (e.UseFbRunDetails = 1) THEN convert(datetime2,e.FbEventStartDatetime) ELSE convert(datetime2,e.EventStartDatetime) END AS eventStartDatetime -- 1 This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset --1
       ,e.eventEndDatetime as eventEndDatetime --2
	   ,CASE WHEN (e.UseFbRunDetails = 1) THEN e.FbEventName ELSE e.EventName END AS eventName --3
	   ,e.EventNumber as eventNumber --4
	   ,coalesce(CASE WHEN (e.UseFbLocation = 1) THEN e.FbLocationOneLineDesc ELSE e.LocationOneLineDesc END,e.LocationOneLineDesc,e.FbLocationOneLineDesc,'<unknown location>') AS locationOneLineDesc --5
       ,e.userEventCounterIncrement as userEventCounterIncrement --6
       ,e.EventFacebookId as eventFacebookId --7
       ,e.IsVisible as isVisible --8
       ,e.IsCountedRun as isCountedRun --9
       ,e.AbsoluteEventNumber as absoluteEventNumber --10
       ,hem.isHare as isHare --11
       --,rc.totalRunsThisKennel --12
       --,rc.totalRunsAllKennels --13
	   ,hem.TotalRunsThisKennel as totalRunsThisKennel -- 12
	   ,hem.TotalRuns as totalRunsAllKennels --13
       ,coalesce(hem.totalHaringThisKennel,0) as totalHaringThisKennel --14
       ,hem.userStartEvent as userStartEvent --15
       ,coalesce(hem.RsvpState, 0) as rsvpState --16
       ,coalesce(hem.AttendenceState, 0) as attendenceState --17
       FROM HC.Event e
	   INNER JOIN HC.HasherEventMap hem on hem.eventId = e.id AND hem.userId = @userId
	   WHERE e.KennelId = @kennelId and coalesce(hem.AttendenceState, 0) >= 20
	   AND e.eventStartDatetime < getdate() 
	   and e.IsVisible = 1 and e.IsCountedRun = 1
	   ORDER BY CASE WHEN (e.UseFbRunDetails = 1) THEN convert(datetime2,e.FbEventStartDatetime) ELSE convert(datetime2,e.EventStartDatetime) END desc

END
	

  
