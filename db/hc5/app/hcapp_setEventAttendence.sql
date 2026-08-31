

CREATE PROCEDURE [HC5].[hcapp_setEventAttendence]

	@deviceId uniqueidentifier, -- the one making the call to this SP
	@accessToken nvarchar(1000),
	@eventId uniqueidentifier,
	@hasherId uniqueidentifier, -- the hasher who is joining the event
 
	@attendenceState smallint,
	@isHare smallint = null,

	@hasherEventMapUpdatedAfter nvarchar(50),
	@hasherKennelMapUpdatedAfter nvarchar(50),
	@returnUserRecords smallint = 0,
	@qrScanText nvarchar(50),
	@hemId uniqueidentifier = NULL

AS

BEGIN

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindows int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindows = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	DECLARE @errorId uniqueidentifier

	IF (@isHare = -1) SET @isHare = NULL

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
			,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
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
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	
	IF ((@attendenceState IS NULL) OR (@attendenceState < 0) OR (@attendenceState > 40))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Invalid attendence state','An invalid attendence state was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Invalid attendence state' as errorTitle
		,'An invalid attendence state was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
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
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE  
		 @kennelId uniqueidentifier
		,@serverMessage nvarchar(250)
		,@hasherNameText nvarchar(120)
		,@hasherName nvarchar(120)
		,@currentAttendenceState smallint
		,@eventDate datetime
		,@recalculateRunNumbers smallint = 0
		,@currentHareStatus smallint = 0
		,@eventPrice smallmoney
		,@alreadyText nvarchar(20) = ''
		,@eventName nvarchar(250)
		,@payCount int
		,@isMember smallint
		,@virginVisitorState smallint = 0


	IF (@qrScanText IS NOT NULL)
		BEGIN
		-- The Event ID from a scan can either be the public event ID or the internal event ID
		-- use this to set the eventId to the internal eventId in all cases
		SELECT @eventId = coalesce(evt.id,@eventId) FROM HC.Event evt where evt.PublicEventId = @eventId
	END



	IF ((@hasherId IS NULL) AND (@qrScanText IS NULL)) 
	BEGIN
		SET @hasherId = @userId
	END
	ELSE IF (@qrScanText IS NOT NULL)
	BEGIN
		SELECT @hasherId = id FROM HC.Hasher h WHERE h.QR_code = @qrScanText
	END

	IF (@hasherId IS NULL)
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
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END
		 

	-- TODO: add check to see if Hasher is already checked in to another run


	IF (@hemId IS NULL)
	BEGIN
		SELECT 
			@hemId = id,
			@currentAttendenceState = hem.AttendenceState,
			@currentHareStatus = hem.IsHare,
			@virginVisitorState = hem.VirginVisitorType
		FROM HC.HasherEventMap hem where hem.EventId = @eventId and hem.UserId = @hasherId
	END
	ELSE
	BEGIN
		SELECT 
			@currentAttendenceState = hem.AttendenceState,
			@currentHareStatus = hem.IsHare,
			@virginVisitorState = hem.VirginVisitorType
		FROM HC.HasherEventMap hem where hem.id = @hemId
	END


	IF (@virginVisitorState = 0) OR (@hemId IS NULL)
		SELECT @hasherName = coalesce(DisplayName,'Hasher') from HC.Hasher where id = @hasherId
	ELSE
		SELECT @hasherName = coalesce(DisplayName,'Hasher') from HC.HasherEventMap where id = @hemId

	IF (@hasherId = @userId)
		BEGIN
			SELECT @hasherNameText = 'You are '
		END
	ELSE
		BEGIN
			SELECT @hasherNameText = @hasherName + ' is ' 
		END



	SELECT @payCount = COUNT(*) from HC.Payment pay WHERE pay.HasherEventMapId = @hemId and pay.CancelledBy_UserId is NULL

	IF (@currentAttendenceState >= 20 AND @attendenceState < 20 AND @payCount > 0)
	BEGIN
		SELECT 
		newid() as errorId,
		cast (2 as int) as errorType 
		,'Payment registered' as errorTitle
		-- NOTE: Tildes "~" are replaced in the app with Carriage Returns.
		,'You tried to mark ' + @hasherName + ' as not at the Hash, but the system indicates that ' + @hasherName + ' has paid for the run.~~Please cancel the payment first before marking ' + @hasherName + ' as not at the run.' as errorUserMessage
		,'' as debugMessage
		,'Register Hasher' as errorProc
		RETURN
	END


	IF ((@attendenceState >= 20) AND (@attendenceState <= @currentAttendenceState))
	BEGIN
		SET @alreadyText = 'already '
	END

	SELECT 
		 @kennelId = evt.KennelId
		,@eventDate = case when evt.UseFbRunDetails = 0 then evt.EventStartDatetime else evt.FbEventStartDatetime end
		,@eventName = case when evt.UseFbRunDetails = 0 then evt.EventName else evt.FbEventName end
	FROM HC.Event evt where evt.id = @eventId

	SET @serverMessage = @hasherNameText + coalesce(@alreadyText,'') + 'recorded as ' + case when ((@attendenceState >= 20) AND (@attendenceState < 30)) then 'on the Hash trail at "' + coalesce(@eventName +'"','the Hash') when @attendenceState >= 30 then 'On Inn' end

	IF ((@hemId IS NOT NULL) AND (@attendenceState < 20))
		BEGIN
			UPDATE HC.HasherEventMap set 
				AttendenceState = @attendenceState, 
				--IsHare = 0,
				updatedAt = getdate() 
			FROM HC.HasherEventMap where id = @hemId

			-- They were at the run and now they are not at the run, so recalculate run counts
			IF (@currentAttendenceState >= 20) SET @recalculateRunNumbers = 1
		END
	ELSE IF ((@hemId IS NOT NULL) AND (@attendenceState >= 20))
		BEGIN
			UPDATE HC.HasherEventMap set 
				AttendenceState = @attendenceState, 
				RsvpState = 3,
				IsHare = coalesce(@isHare,IsHare),
				updatedAt = getdate() 
			FROM HC.HasherEventMap where id = @hemId

			-- They were not at the run and now they are at the run, so recalculate run counts
			IF (@currentAttendenceState < 20) SET @recalculateRunNumbers = 1
		END
	ELSE IF (@hemId IS NULL)
		BEGIN
			SELECT @hemId = newid()

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
			VALUES
				(
				 @hemId
				,@eventId
				,@kennelId
				,@hasherId
				,@attendenceState
				,3
				,0
				,0
				,getdate()
				)

			SET @recalculateRunNumbers = 1
		END
	ELSE 
		BEGIN
			SET @serverMessage = 'Unknown status. Please contact us at harriercentral@gmail.com'
		END


	IF (@isHare IS NOT NULL)
	BEGIN
		DECLARE @hares NVARCHAR(2500)

		SELECT @hares = STRING_AGG(h.DisplayName,', ') WITHIN GROUP (ORDER BY h.displayName ASC) 
		FROM HC.HasherEventMap hem
		INNER JOIN HC.Hasher h ON hem.UserId = h.id
		WHERE eventId = @eventId AND isHare = 1 AND RsvpState = 3

		UPDATE HC.Event SET hares = @hares, updatedAt = getdate() WHERE id = @eventId AND coalesce(hares,'xxxxxxxxxxx') != @hares
	END

	EXEC HC.nonApi_updateRunCountsByUser @userId = @hasherId

	SELECT 
		@isMember = case when coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() then 1 else 0 end,
		@eventPrice = case when coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() 
			then coalesce(e.eventPriceForMembers,k.defaultEventPriceForMembers,0) 
			else coalesce(e.eventPriceForNonMembers,k.defaultEventPriceForNonMembers,0) 
		end
	from HC.Event e
	INNER JOIN HC.Kennel k on k.id = e.KennelId
	LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.KennelId = e.KennelId AND hkm.UserId = @hasherId
	WHERE e.id = @eventId

	if ((@attendenceState >= 20) AND (@eventPrice != 0))
	BEGIN
		-- determine if the Hasher has paid or not, this is needed when scanning is dnne to determine if the payment popup should be displayed
		
		-- set the message appropriately
		IF @payCount = 0 
			SET @serverMessage = @serverMessage + '. Don''t forget to pay for the Hash' 
		ELSE 
			IF @attendenceState = 20
				SET @serverMessage = @serverMessage + ' and paid. Enjoy your run!' 
			ELSE IF @attendenceState = 30
				SET @serverMessage = @serverMessage + ' and paid. Enjoy your beer!' 
	END

	SELECT @attendenceState = hem.AttendenceState
	FROM HC.HasherEventMap hem 
	WHERE hem.UserId = @hasherId AND hem.EventId = @eventId

	IF (@qrScanText IS NULL)
		BEGIN
			SELECT
			1 as adHocDataId
			,coalesce(@serverMessage,'') as serverMessage
			,@hemId as hasherEventMapId
			,@hasherId as hasherId
			,@attendenceState as attendenceState
		END
	ELSE
		BEGIN
			SELECT
			1 as adHocDataId
			,coalesce(@serverMessage,'') as userMessage
			,coalesce(@payCount,0) as isPaid
			,@isMember as isMember
			,@hemId as hasherEventMapId
			,@hasherId as hasherId
			,coalesce(hem.EventNotificationPreference,hkm.KennelNotificationPreference) as notificationPreference
			,coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference) as emailAlertPreference
			,coalesce(hkm.CurrentHaringCount,-1) as currentHaringCount
			,coalesce(hkm.CurrentPackRunCount,-1) as currentPackRunCount
			,coalesce(hem.rsvpState,-1) as rsvpState
			,coalesce(hem.isHare,0) as willHareState
			,coalesce(evt.Hares, '') as hares
			,coalesce(hkm.DiscountAmount,0) as discountAmount
			,coalesce(hkm.DiscountPercent,0) as discountPercent
			,coalesce(hkm.DiscountDescription,'') as discountDescription
			FROM HC.HasherEventMap hem
			INNER JOIN HC.Event evt on hem.eventId = evt.id
			LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.kennelId = @kennelId AND hkm.userId = hem.userId
			WHERE hem.id = @hemId
		END

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)
	SET @hasherKennelMapUpdatedAfter = coalesce(@hasherKennelMapUpdatedAfter,'ignore')
	SET @hasherEventMapUpdatedAfter = coalesce(@hasherEventMapUpdatedAfter,'ignore')

	IF @returnUserRecords = 0
		BEGIN
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
	ELSE
		BEGIN
			EXEC HC5.hcapp_syncUserData
				@deviceId = @deviceId,
				@accessToken = @accessToken,
				@hashersUpdatedAfter = 'ignore',
				@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
				@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
				@narrowEventsUpdatedAfter = 'ignore',
				@paymentsUpdatedAfter = 'ignore',
				@procName = @procName,
				@param = NULL
		END

END





