

CREATE PROCEDURE [HC5].[hcapp_setEventMessagesRead]

	-- NOTE: This is the new proc for processing RSVPs
	-- NOTE: It's first use is in 1.1.6. The code in HC3.rsvpForEvent should be debugged if bugs are found in this code
	--       but HC3.rsvpForEvent should be tested against 1.1.5

	@deviceId uniqueidentifier, -- the one making the call to this SP
	@accessToken nvarchar(1000),
	@publicEventId uniqueidentifier = null,
	@resetBadgeCount int = 0,
	@resetAllBadgeCounts int = 0

AS

-- EXEC HC3.setEventRsvp @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', @accessToken = '', @eventId = '1D0EBCC8-264D-469C-ADE9-A6C0386E66B7', @hasherId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', @isHare = 0, @rsvpState = 3, @hasherEventMapUpdatedAfter = '2023-01-22 12:35:33.053778', @hasherKennelMapUpdatedAfter = '2023-01-22 06:00:09.584730', @hemId = '42502F23-5C42-4266-9F97-E8E7359E32F7'

BEGIN
	SET NOCOUNT ON

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindows int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindows = d.TimeWindow
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

	IF ((@resetAllBadgeCounts = 0) AND (@publicEventId IS NULL) OR (@publicEventId = '00000000-0000-0000-0000-000000000000'))
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

	DECLARE @paramString nvarchar(100)
	SET @paramString = @deviceSecret
	--IF (@publicEventId is not null)
	--BEGIN
	--	SET @paramString = @deviceSecret + cast(@publicEventId as nvarchar(50))
	--END

	
	IF (HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString,@timeWindows) = 0)
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


	IF (@resetAllBadgeCounts != 0)
	BEGIN

			UPDATE embc SET embc.LastSequenceCount = (SELECT max(em.MessageSequenceCount) FROM HC.EventMessage em where em.UserId = @userId AND em.EventId = embc.EventId)
			FROM HC.EventMessageBadgeCounts embc
			WHERE embc.UserId = @userId
			
			SELECT 0 as badgeCount

	END
	ELSE
	BEGIN

			DECLARE @messageSequenceCount int,
					@eventId uniqueidentifier

			SELECT 
				@messageSequenceCount = max(MessageSequenceCount), 
				@eventId = eventId 
			FROM HC.EventMessage 
			WHERE UserId = @userId AND PublicEventId = @publicEventId
			GROUP BY eventId

			IF (@resetBadgeCount != 0)
			BEGIN
				-- 1. Use the MERGE statement
				MERGE INTO HC.EventMessageBadgeCounts AS Target
				USING (VALUES (@userId, @eventId,@messageSequenceCount)) 
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
			END

			--SELECT (SELECT MAX(em.MessageSequenceCount) FROM HC.EventMessage em
			--where em.EventId = @eventId) - embc.LastSequenceCount as badgeCount
			--FROM HC.EventMessageBadgeCounts embc 
			--WHERE embc.EventId = @eventId AND embc.UserId = @userId
	
			SELECT @messageSequenceCount - embc.LastSequenceCount as badgeCount
			FROM HC.EventMessageBadgeCounts embc 
			WHERE embc.EventId = @eventId AND embc.UserId = @userId
    END

END





