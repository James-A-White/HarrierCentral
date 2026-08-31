
CREATE PROCEDURE [HC5].[hcapp_setEmailAndNotificationPrefs]

 @deviceId uniqueidentifier, 
 @accessToken nvarchar(1000),
 @hasherId uniqueidentifier, -- the hasher who is having their preferences changed
 @emailPreference int = -1,
 @notificationPreference int = -1,
 @kennelId uniqueidentifier = null,
 @eventId uniqueidentifier = null,
 @hasherEventMapUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50)

AS

BEGIN

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

	IF (
		((@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000'))
		AND
		((@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000'))
	   )
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty kennel and eventId' as errorTitle
		,'A null or empty values were passed for both the KennelId and EventId parameters in '+ OBJECT_NAME(@@PROCID) as errorUserMessage
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

	DECLARE  

		 @serverMessage nvarchar(250)
		,@hasherName nvarchar(120)
		,@hemId uniqueidentifier
		,@hkmId uniqueidentifier
		,@currentEmailPreference smallint
		,@currentNotificationPreference smallint
		,@eventDate datetime

	IF (@hasherId IS NULL) SET @hasherId = @userId

	SELECT @hasherName = DisplayName from HC.Hasher where id = @hasherId

	IF (@kennelId is null) SELECT @kennelId = evt.KennelId FROM HC.Event evt where evt.id = @eventId

	IF (@emailPreference = -1) SET @emailPreference = null
	IF (@notificationPreference = -1) SET @notificationPreference = null

	IF (@eventId IS NULL)
		BEGIN
			SELECT 
				@hkmId = id,
				@currentEmailPreference = hkm.KennelEmailAlertPreference,
				@currentNotificationPreference = hkm.KennelNotificationPreference
			FROM HC.HasherKennelMap hkm where hkm.KennelId = @kennelId and hkm.UserId = @hasherId

			IF (@hkmId IS NULL)
				BEGIN
					INSERT INTO [HC].[HasherKennelMap]
						([id]
						,[UserId]
						,[KennelId]
						,[KennelNotificationPreference]
						,[KennelEmailAlertPreference]
						,[updatedAt])
					VALUES
					(
						newid()
						,@hasherId
						,@kennelId
						,coalesce(@notificationPreference,0)
						,coalesce(@emailPreference,0)
						,getdate()
					)
				END
			ELSE
				BEGIN
					UPDATE HC.HasherKennelMap SET 
						KennelEmailAlertPreference = coalesce(@emailPreference,KennelEmailAlertPreference),
						KennelNotificationPreference = coalesce(@notificationPreference,KennelNotificationPreference),
						updatedAt = getdate()
					WHERE id = @hkmId
				END
		END
	ELSE
		BEGIN
		SELECT 
			@hemId = id,
			@currentEmailPreference = hem.EventEmailAlertPreference,
			@currentNotificationPreference = hem.EventNotificationPreference
		FROM HC.HasherEventMap hem where hem.EventId = @eventId and hem.UserId = @hasherId

		IF (@hemId IS NULL)
			BEGIN
				INSERT INTO [HC].[HasherEventMap]
				(
				    [id]
				   ,[EventId]
				   ,[KennelId]
				   ,[UserId]
				   ,[EventNotificationPreference]
				   ,[EventEmailAlertPreference]
				   ,[updatedAt]
				)
				VALUES
				(
					newid()
					,@eventId
					,@kennelId
					,@hasherId
					,case when @notificationPreference = 0 then null else @notificationPreference end
					,case when @emailPreference = 0 then null else @emailPreference end
					,getdate()
				)
			END
		ELSE
			BEGIN
				UPDATE HC.HasherEventMap SET 
					EventEmailAlertPreference = case when @emailPreference = 0 then null else coalesce(@emailPreference,EventEmailAlertPreference) end,
					EventNotificationPreference = case when @notificationPreference = 0 then null else coalesce(@notificationPreference,EventNotificationPreference) end,
					updatedAt = getdate()
				WHERE id = @hemId
			END
	END

	IF (@EventId IS NOT NULL)
		BEGIN
			SELECT 
				@notificationPreference = coalesce(hem.EventNotificationPreference,hkm.KennelNotificationPreference),
				@emailPreference = coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference)
			FROM HC.HasherEventMap hem
			INNER JOIN HC.HasherKennelMap hkm on hkm.KennelId = hem.KennelId AND hkm.UserId = hem.UserId
			WHERE hem.UserId = @hasherId AND hem.EventId = @eventId
		END
	ELSE
		BEGIN
			SELECT 
				@notificationPreference = hkm.KennelNotificationPreference,
				@emailPreference = hkm.KennelEmailAlertPreference
			FROM HC.HasherKennelMap hkm
			WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId
		END

	SELECT
		1 as adHocDataId,
		@notificationPreference as notificationPreference,
		@emailPreference as emailAlertPreference

	DECLARE @procName nvarchar(500)

	SET @procName = OBJECT_NAME(@@PROCID)
	SET @hasherKennelMapUpdatedAfter = coalesce(@hasherKennelMapUpdatedAfter,'ignore')
	SET @hasherEventMapUpdatedAfter = coalesce(@hasherEventMapUpdatedAfter,'ignore')

	EXEC HC5.hcapp_syncUserData
		@deviceId = @deviceId,
		@accessToken = @accessToken,
		@hashersUpdatedAfter = 'ignore',
		@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
		@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
		@narrowEventsUpdatedAfter = 'ignore',
		@usePaging = 0, -- if we are returning adHocData be sure to have paging off
		@procName = @procName,
		@param = NULL

END





