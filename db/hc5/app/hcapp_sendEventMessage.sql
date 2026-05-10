CREATE PROCEDURE [HC5].[hcapp_sendEventMessage]

/* 

declare @messageId uniqueidentifier = newid()
EXEC [HC5].[hcapp_sendEventMessage] @deviceId = '6B1ED04F-44A3-4C00-A0C7-05EE1C3F73DD', @accessToken = 'xxx', @eventId = 'A509D3CB-7185-49B4-BD27-F14C4B901CBE', @messageTitle = 'Test message', @messageContent = 'Test message content', @messageReleasabilityFlags = 15, @messageId = @messageId

*/

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@eventId nvarchar(250) = NULL, -- NOTE: This is the true eventId, not the publicEventId
@messageId uniqueidentifier = NULL,
@messageTitle nvarchar(250) = NULL,
@messageContent nvarchar(500) = NULL,
@messageReleasabilityFlags int = NULL

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @hasherId uniqueidentifier,
			@publicHasherId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int,
			@publicEventId uniqueidentifier



	DECLARE @errorId uniqueidentifier
	DECLARE @isError int = 0
	DECLARE @errorTitle nvarchar(500) = ''

	IF (@deviceId IS NULL) OR (datalength(@deviceId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid deviceId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty hasherId','Null or empty hasherId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),NULL)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'Null or empty value was passed as the deviceId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END

	SELECT 
		@hasherId = d.UserId,
		@publicHasherId = h.publicHasherId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d
	INNER JOIN HC.Hasher h on h.id = d.UserId
	WHERE d.id = @deviceId


	IF (@messageId IS NULL) OR (datalength(@messageId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid messageId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty messageId','Null or empty messageId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),NULL)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'Null or empty value was passed as the messageId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END

    IF (@hasherId IS NULL) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'No record found with provided @hasherId'
		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','No record found with provided @hasherId','@hasherId was not found by ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'@hasherId was not found by'+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END



	IF ((@eventId IS NULL) OR (datalength(@eventId) != 72)) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid eventId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','Null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'Null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END

	DECLARE @timeLimitForNotificationsInHours smallint = 6
	
	DECLARE @kennelId uniqueidentifier,
			@eventStartDateTimeInUtc datetimeoffset(7),
			@isEventWithinTimeLimitForNotifications smallint = 0,
		    @roomId uniqueidentifier
	
	SELECT 
		@publicEventId = PublicEventId,
		@kennelId = evt.KennelId,
		@messageTitle = coalesce(@messageTitle,evt.EventName),
		@eventStartDateTimeInUtc = (cast(evt.EventStartDatetime as datetime) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC',
		@messageTitle = coalesce(@messageTitle,EventName)
	FROM HC.Event evt 
	INNER JOIN HC.Kennel k on k.id = evt.KennelId
	INNER JOIN HC.City c on k.CityId = c.id
	INNER JOIN DomainValues.Timezone tz on tz.id = c.TimezoneId
	WHERE evt.id = @eventId

	IF (abs(datediff(minute,getdate(),@eventStartDateTimeInUtc)) <= (@timeLimitForNotificationsInHours * 60))
	BEGIN
		SET @isEventWithinTimeLimitForNotifications = 1
	END

	--	IF ((@eventId IS NULL) OR (datalength(@eventId) != 16)) AND (@isError = 0)
	--BEGIN
	--	SET @errorId = newid()
	--	SET @isError = 1
	--	SET @errorTitle = 'Null or invalid eventId'

	--	INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','Null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId)
		
	--	SELECT 
	--	@errorId as errorId,
	--	cast (2 as int) as errorType 
	--	,@errorTitle as errorTitle
	--	,'Null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
	--	,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--END

	IF (HC.CHECK_ACCESS_TOKEN_V2(@hasherId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret + cast(@eventId as nvarchar(50)),@timeWindow) = 0) AND (@isError = 0) 
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Invalid access token'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,@errorTitle as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (
		@messageContent IS NULL 
		OR datalength(@messageContent) = 0 
		--OR @messageTitle IS NULL 
		--OR DATALENGTH(@messageTitle) = 0 
		OR @MessageReleasabilityFlags IS NULL 
		OR (@MessageReleasabilityFlags & 0x0000003f) = 0) 
	  AND (@isError = 0) 
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Missing or empty fields in call to stored procedure'

		declare @errorDetail nvarchar(1000)
		SET @errorDetail = ''
		IF (@messageContent IS NULL OR datalength(@messageContent) = 0) SET @errorDetail = 'Message Content '
		--IF (@messageTitle IS NULL OR datalength(@messageTitle) = 0) SET @errorDetail = @errorDetail + 'Message Title '
		IF (@MessageReleasabilityFlags IS NULL OR (@MessageReleasabilityFlags & 0x0000000f) = 0) SET @errorDetail = @errorDetail +  'Message Releasability Flags '

		SET @errorDetail = REPLACE(TRIM(@errorDetail),' ',', ')

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Missing or empty ' + @errorDetail + ' calling sendMessage procedure','Empty or missing fields were sent to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId,@errorDetail)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,@errorTitle as errorTitle
		,'Empty or missing fields sent to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END


	if (@isError = 1)
	BEGIN
		RETURN
	END

	INSERT INTO [HC].[EventMessage]
           (
		    [id]
           ,[EventId]
		   ,[PublicEventId]
           ,[UserId]
		   ,[PublicHasherId]
           ,[MessageTitle]
           ,[MessageContent]
           ,[MessageReleasabilityFlags]
           
		   )
     VALUES
           (
		    @messageId
           ,@eventId
		   ,@publicEventId
           ,@hasherId
		   ,@publicHasherId
           ,@messageTitle
           ,@messageContent
           ,@MessageReleasabilityFlags)

	DECLARE @messageSequenceCount int

	SELECT @messageSequenceCount = em.MessageSequenceCount FROM HC.EventMessage em where em.id = @messageId


	-- 1. Use the MERGE statement
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@hasherId, @eventId,@messageSequenceCount)) 
           AS Source (UserId, EventId, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.EventId = Source.EventId) -- This is the MATCH condition (the key)
    
    -- 2. WHEN MATCHED (The record EXISTS) - Perform an UPDATE
    WHEN MATCHED THEN 
        UPDATE SET 
            Target.UserId = Source.UserId,
            Target.EventId = Source.EventId,
			Target.LastSequenceCount = Source.LastSequenceCount
            
    -- 3. WHEN NOT MATCHED BY TARGET (The record DOES NOT exist) - Perform an INSERT
    WHEN NOT MATCHED BY TARGET THEN 
        INSERT (UserId, EventId, LastSequenceCount)
        VALUES (Source.UserId, Source.EventId, Source.LastSequenceCount);


	DECLARE @sendToHares smallint = @messageReleasabilityFlags & 0x0010,
			@sendToEveryone smallint = @messageReleasabilityFlags & 0x0020,
			@sendToMismanagement smallint  = @messageReleasabilityFlags & 0x0001,
			@sendToMembers smallint  = @messageReleasabilityFlags & 0x0002,
			@sendToFollowers smallint = @messageReleasabilityFlags & 0x0004,
			@sendToRsvps smallint = @messageReleasabilityFlags & 0x0008

	
	
	
	
	SELECT 
	   msg.[id] as MessageId
      ,[EventId] as EventId
	  ,[PublicEventId] as PublicEventId
      ,h.PublicHasherId as UserId
	  ,h.DisplayName as UserDisplayName
	  ,h.Photo as UserPhoto
      ,h.DisplayName + ' - ' + [MessageTitle] as MessageTitle
      --,[MessageTitle] as MessageTitle
      ,[MessageContent] as MessageContent
      ,[MessageReleasabilityFlags] as MessageRelesabilityFlags
	  ,0 as EventChatMessageCount -- this is now obsolete as of 2.1.3 and can eventually be removed.
	  ,msg.[MessageType] as MessageType
	FROM HC.EventMessage msg
	INNER JOIN HC.Hasher h on msg.UserId = h.id
	where msg.id = @messageId and msg.removed = 0 and h.Removed = 0
	

	SELECT 
		hkm.UserId as UserId,
		device.FcmToken as FcmToken
		--,h.HashName
		into #tempMessageOn
	FROM HC.HasherKennelMap hkm 
	INNER JOIN HC.Hasher h on hkm.UserId = h.id
	INNER JOIN HC.Event evt on evt.id = @eventId
	INNER JOIN HC.Device device on device.UserId = h.id
	LEFT OUTER JOIN HC.HasherEventMap hem on hem.EventId = evt.id and hem.UserId = h.id
	WHERE evt.id = @eventID
	AND 
	(
	  (coalesce(hem.EventNotificationPreference, hkm.KennelNotificationPreference) = 1) -- always send notifications
	  OR 
	  (
	    -- only send full notifications when within the time window
		(coalesce(hem.EventNotificationPreference, hkm.KennelNotificationPreference) = 4) AND (@isEventWithinTimeLimitForNotifications = 1)
	  )
	)
	AND hkm.KennelId = @kennelId 
	AND device.FcmToken IS NOT NULL
	  AND 
	   (@sendToEveryone != 0
		   OR (@sendToMismanagement != 0 AND hkm.MismanagementRoles != 0)
		   OR (@sendToMembers != 0 AND hkm.MembershipExpirationDate > getdate())
		   OR (@sendToFollowers != 0 AND hkm.Following = 1)
		   OR (@sendToRsvps != 0 AND hem.RsvpState >= 2 AND coalesce(hem.EventNotificationPreference,1) != 0)
		   OR (@sendToHares != 0 AND hem.IsHare != 0 AND coalesce(hem.EventNotificationPreference,1) != 0)
	   )

	-- This query covers cases where a visitor who is not following a Kennel has signed
	-- up for notofications for a run.
	--INSERT #tempMessageOn (UserId,FcmToken)
	--SELECT hem.UserId,device.FcmToken 
	--FROM HC.HasherEventMap hem
	--INNER JOIN HC.Device device on device.UserId = hem.UserId and hem.EventId = @eventId
	--LEFT OUTER JOIN #tempMessageOn t on t.UserId = hem.UserId
	--WHERE t.UserId IS NULL
	--AND coalesce(hem.EventNotificationPreference,1) != 0

	SELECT * FROM #tempMessageOn

	-- now, this is a list of everyone associated with a Kennel who 
	-- did not "qualify" for a full push notification. For these people
	-- we will send an in-app notification so they can see the chat 
	-- updating in realtime whe nthe app is open
	SELECT 
		hkm.UserId,
		device.FcmToken
		--,h.HashName 
	FROM HC.HasherKennelMap hkm
	INNER JOIN HC.Device device on hkm.UserId = device.UserId
	--INNER JOIN HC.Hasher h on h.id = hkm.UserId
	LEFT OUTER JOIN #tempMessageOn t on hkm.UserId = t.UserId
	WHERE hkm.KennelId = @kennelId AND (hkm.Following != 0 OR hkm.MembershipExpirationDate > getdate())
	AND device.FcmToken IS NOT NULL
	AND t.UserId IS NULL

	DROP TABLE #tempMessageOn

/* 

DECLARE @messageId uniqueidentifier = newid()
EXEC [HC5].[hcapp_sendEventMessage] @messageReleasabilityFlags = 63, @deviceId = '67090BB8-0706-4F20-AEFC-0442DCE6A6E5', @accessToken = 'xxx', @eventId = '39B17580-8D85-4677-9EC5-6244B4DDF2FB', @messageContent = 'Test message content',@messageId = @messageId

*/

END
	
	

