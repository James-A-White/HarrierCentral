

CREATE PROCEDURE [HC5].[hcapp_setEventRsvp]

	-- NOTE: This is the new proc for processing RSVPs
	-- NOTE: It's first use is in 1.1.6. The code in HC3.rsvpForEvent should be debugged if bugs are found in this code
	--       but HC3.rsvpForEvent should be tested against 1.1.5

	@deviceId uniqueidentifier, -- the one making the call to this SP
	@accessToken nvarchar(1000),
	@eventId uniqueidentifier,
	@hasherId uniqueidentifier, -- the hasher who is joining the event
 
	@isHare int = -1,
	@rsvpState int = -1,

	@hasherEventMapUpdatedAfter nvarchar(50),
	@hasherKennelMapUpdatedAfter nvarchar(50),
	@hemId uniqueidentifier = NULL,
	@autoSetNotifications smallint = 1

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

	IF (@hemId IS NOT NULL)
	BEGIN
		DECLARE @hemEventId uniqueidentifier

		SELECT 
			@hasherId = hem.userId,
			@hemEventId = hem.EventId
		FROM HC.HasherEventMap hem
		where hem.id = @hemId

		IF NOT (@eventId = @hemEventId)
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES 
			(@errorId,
				'<unknown>',
				'Mismatched eventIds',
				'The HEM ID EventId and EventId parameters passed to ' + OBJECT_NAME(@@PROCID) + ' do not match',OBJECT_NAME(@@PROCID),@userId
			)
		
			SELECT 
			@errorId as errorId,
			cast (2 as int) as errorType 
			,'Mismatched eventIds' as errorTitle
			,'The HEM ID EventId and EventId parameters passed to ' + OBJECT_NAME(@@PROCID) + ' do not match' as errorUserMessage
			,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
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

	DECLARE  

		 @kennelId uniqueidentifier
		,@serverMessage nvarchar(250)
		,@hasherName nvarchar(120)
		,@currentAttendenceState smallint
		,@currentRsvpState smallint
		,@currentIsHareState smallint
		,@eventDate datetime
		,@virginVisitorState smallint = 0

	IF (@hasherId IS NULL) SET @hasherId = @userId

	IF (@rsvpState = 1)
	BEGIN
		SET @isHare = 0
	END

	IF (@isHare = -1) SET @isHare = null
	IF (@rsvpState = -1) SET @rsvpState = null

	IF (@hemId IS NULL)
	BEGIN
		-- NOTE: This query may return no results if no HEM record exists yet
		SELECT 
			@hemId = id,
			@currentAttendenceState = hem.AttendenceState,
			@currentRsvpState = hem.RsvpState,
			@currentIsHareState = hem.IsHare,
			@virginVisitorState = hem.VirginVisitorType
		FROM HC.HasherEventMap hem where hem.EventId = @eventId and hem.UserId = @hasherId
	END
	ELSE
	BEGIN
		SELECT 
			@currentAttendenceState = hem.AttendenceState,
			@currentRsvpState = hem.RsvpState,
			@currentIsHareState = hem.IsHare,
			@virginVisitorState = hem.VirginVisitorType
		FROM HC.HasherEventMap hem where id = @hemId
	END

	IF (@virginVisitorState = 0) OR (@hemId IS NULL)
		SELECT @hasherName = coalesce(DisplayName,'Hasher') from HC.Hasher where id = @hasherId
	ELSE
		SELECT @hasherName = coalesce(DisplayName,'Hasher') from HC.HasherEventMap where id = @hemId


	SELECT 
		@kennelId = evt.KennelId
		,@eventDate = case when evt.UseFbRunDetails = 0 then evt.EventStartDatetime else evt.FbEventStartDatetime end
		FROM HC.Event evt where evt.id = @eventId


	DECLARE @kennelNotificationPreference int = NULL
	DECLARE @emailAlertPreference int = NULL

	IF (@autoSetNotifications = 1)
	BEGIN
		IF (@rsvpState = 1)
			BEGIN
				SET @kennelNotificationPreference = 2
				SET @emailAlertPreference = 2
			END
		ELSE
			BEGIN
				SELECT 
					@kennelNotificationPreference = hkm.KennelNotificationPreference
				   ,@emailAlertPreference = hkm.KennelEmailAlertPreference
				FROM HC.HasherKennelMap hkm
				WHERE hkm.KennelId = @kennelId AND hkm.UserId = @userId
			END
	END


	-- if @hemId is null, this is a new record
	--IF (@eventDate < dateadd(day,-1,getdate()))
	--	BEGIN
	--		SET @serverMessage = 'This event has already occurred and RSVPs cannot be updated'
	--	END
	--ELSE 
	IF ((@hemId IS NOT NULL) AND 
		(
			(@currentRsvpState != coalesce(@rsvpState,@currentRsvpState)) OR (@currentIsHareState != coalesce(@isHare,@currentIsHareState))) AND (@currentAttendenceState < 20)
			OR
			((@currentIsHareState != coalesce(@isHare,@currentIsHareState)) AND (@currentAttendenceState >= 20) AND ((@rsvpState = -1) OR (@rsvpState = @currentRsvpState)))
		)
		BEGIN
			UPDATE HC.HasherEventMap set 
				RsvpState = coalesce(@rsvpState,RsvpState), 
				IsHare = coalesce(@isHare,IsHare),
				EventNotificationPreference = coalesce(@kennelNotificationPreference,EventNotificationPreference),
				EventEmailAlertPreference = coalesce(@emailAlertPreference,EventEmailAlertPreference),
				updatedAt = getdate() 
			FROM HC.HasherEventMap where id = @hemId

			-- all is good, don't send a message back
			SET @serverMessage = ''
		END
	ELSE IF (@hemId IS NULL)
		BEGIN
			SELECT @hemId = newid()

			INSERT INTO [HC].[HasherEventMap]
				([id]
				,[EventId]
				,[KennelId]
				,[UserId]
				,[RsvpState]
				,[IsHare]
				,[VirginVisitorType]
				,[EventNotificationPreference]
				,[updatedAt])
			VALUES
				(
				@hemId
				,@eventId
				,@kennelId
				,@hasherId
				,@rsvpState
				,case when @isHare > 0 then 1 else 0 end
				,0
				,@kennelNotificationPreference -- it's OK for this to be null, as we'll just use the Kennel preference
				,getdate()
				)

			-- all is good, don't send a message back
			SET @serverMessage = ''
	
		END
	ELSE IF (@currentAttendenceState >= 20)
		BEGIN
			SET @serverMessage = coalesce(@hasherName,'User') + ' is already checked in at the Hash. The RSVP can no longer be changed.~~To change the RSVP, you must first mark ' + coalesce(@hasherName,'User') + ' as being not at the Hash.'
		END
	ELSE IF ((@currentRsvpState = @rsvpState) AND (@currentIsHareState = @isHare))
		BEGIN
			SET @serverMessage = 'The RSVP status has not changed for ' + coalesce(@hasherName,'User')
		END
	ELSE 
		BEGIN
			SET @serverMessage = 'The RSVP status has not changed for ' + coalesce(@hasherName,'User')
			--SET @serverMessage = 'Unknown status. Please contact us at connect@harriercentral.com'
		END

	DECLARE @newHareState smallint
	SELECT @newHareState = hem.IsHare
	FROM HC.HasherEventMap hem where hem.EventId = @eventId and hem.UserId = @hasherId

	if (@currentIsHareState != @newHareState)
	BEGIN
		DECLARE @hares NVARCHAR(2500)

		SELECT @hares = STRING_AGG(h.DisplayName,', ') WITHIN GROUP (ORDER BY h.displayName ASC) 
		FROM HC.HasherEventMap hem
		INNER JOIN HC.Hasher h ON hem.UserId = h.id
		WHERE eventId = @eventId AND isHare = 1 AND RsvpState = 3

		UPDATE HC.Event SET hares = @hares, updatedAt = getdate() WHERE id = @eventId AND coalesce(hares,'xxxxxxxxxxx') != @hares
		
	END

	EXEC HC.nonApi_updateRunCountsByUser @userId = @hasherId, @eventDateTime = @eventDate

	DECLARE @eventNotificationPreference int

	SELECT 
		@rsvpState = hem.RsvpState, 
		@isHare = hem.IsHare,
		@eventNotificationPreference = hem.EventNotificationPreference,
		@emailAlertPreference = hem.EventEmailAlertPreference
	FROM HC.HasherEventMap hem 
	WHERE 
		hem.UserId = @hasherId 
		AND hem.EventId = @eventId

	SELECT
			1 as adHocDataId
			,coalesce(@serverMessage,'') as serverMessage
			,@hemId as hasherEventMapId
			,@hasherId as hasherId
			,@rsvpState as rsvpState
			,@isHare as willHareState
			,@hares as hares
			,@eventNotificationPreference as eventNotificationPreference
			,@emailAlertPreference as emailAlertPreference

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





