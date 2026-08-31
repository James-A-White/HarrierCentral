 CREATE PROCEDURE [HC5].[hcapp_joinKennel]

  @deviceId uniqueidentifier,
  @accessToken nvarchar(1000),
  @kennelId uniqueidentifier,
  @targetUserId uniqueidentifier,
  @isFollowing smallint = null,
  @isHomeKennel smallint = null,
  @notificationState smallint = null,
  @emailAlertState smallint = null,
  @monthsToAddToMembership smallint = null,
  @appAccessFlags int = null,
  @mismanagementRoles int = null,
  @paymentAmount decimal(12,6) = NULL,
  @kennelsUpdatedAfter nvarchar(50),
  @hasherKennelMapUpdatedAfter nvarchar(50),
  @hashersUpdatedAfter nvarchar(50) = 'ignore'

 AS

 BEGIN

 	if (@isFollowing = -1) SET @isFollowing = null
 	if (@isHomeKennel = -1) SET @isHomeKennel = null
 	if (@monthsToAddToMembership = 0) SET @monthsToAddToMembership = null
 	if (@notificationState = -1) SET @notificationState = null
 	if (@emailAlertState = -1) SET @emailAlertState = null
 	if (@appAccessFlags = -1) SET @appAccessFlags = null
 	if (@mismanagementRoles = -1) SET @mismanagementRoles = null
 	if (@hashersUpdatedAfter is null) SET @hashersUpdatedAfter = 'ignore'

 -- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

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

 	IF (@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')
 	BEGIN

 		SET @errorId = newid()

 		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty KennelId','A null or empty kennelId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
 		SELECT 
 		@errorId as errorId,
 		cast (2 as int) as errorType 
 		,'Null or empty kennelId' as errorTitle
 		,'A null or empty value was passed as the kennelId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
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

 	IF @isHomeKennel = 1 SET @isFollowing = 1

 	-- remove the home kennel desgination if someone unfollows a kennel
 	if @isFollowing = 0 OR @isFollowing = 2 OR @isHomeKennel = 0
 	BEGIN
 		if ((SELECT count(*) from HC.Hasher where id = @targetUserId and HomeKennelId = @kennelId) > 0)
 		BEGIN
 			UPDATE HC.Hasher SET HomeKennelId = NULL, updatedAt = getdate() WHERE id = @targetUserId and HomeKennelId = @kennelId
			UPDATE HC.HasherKennelMap SET IsHomeKennel = 0, updatedAt = getdate() WHERE UserId = @targetUserId AND KennelId = @kennelId
 		END	
 	END

 	IF @isHomeKennel = 1
 	BEGIN
 		UPDATE HC.Hasher SET HomeKennelId = @kennelId, updatedAt = getdate() WHERE id = @targetUserId
		-- clear out any other home kennels
		UPDATE HC.HasherKennelMap SET IsHomeKennel = 0, updatedAt = getdate() WHERE UserId = @targetUserId AND IsHomeKennel != 0
	END

 	DECLARE @isMember smallint
 	DECLARE @newExpirationDate datetimeoffset(7)
 	DECLARE @memberSince datetimeoffset(7)
	
 	DECLARE @hkmId uniqueidentifier
 	SELECT @hkmId = id FROM HC.HasherKennelMap WHERE UserId = @targetUserId AND KennelId = @kennelId

 	IF (@hkmId is null)
 		BEGIN 
 			SET @isMember = 0

 			IF ((@monthsToAddToMembership IS NOT NULL) AND (@monthsToAddToMembership > 0))
 			BEGIN
 				SET @isMember = 1
 				SET @newExpirationDate = dateadd(month,@monthsToAddToMembership,getdate())
 				SET @memberSince = getdate()
 			END

 			SET @hkmId = newid()
 			INSERT INTO HC.HasherKennelMap(
 				id,
 				UserId,
 				KennelId,
 				[Following],
 				[IsMember],
 				[MembershipExpirationDate],
 				[MemberSince],
 				[IsHomeKennel],
 				[AppAccessFlags],
				[HcWebPermissionFlags],
 				[MismanagementRoles],
 				[KennelNotificationPreference],
 				[KennelEmailAlertPreference],
 				[updatedAt]) 
 			VALUES (
 				@hkmId,
 				@targetUserId,
 				@kennelId,
 				coalesce(@isFollowing,0),
 				coalesce(@isMember,0),
 				@newExpirationDate,
 				@memberSince,
 				coalesce(@isHomeKennel,0),
 				coalesce(@appAccessFlags,0), -- for the app
				coalesce(@appAccessFlags,0), -- for the web
 				coalesce(@mismanagementRoles, 0),
 				coalesce(@notificationState,0),
 				coalesce(@emailAlertState,0),
 				getdate()
 			) 
 		END
 	ELSE
 		BEGIN
 			UPDATE HC.HasherKennelMap SET 
 				[Following] = coalesce(@isFollowing,[Following]),
 				[IsMember] = 
 				CASE 
 					WHEN (@monthsToAddToMembership = -9999)
 						THEN 0
							 
 					WHEN dateadd(month,@monthsToAddToMembership,coalesce(MembershipExpirationDate,getdate())) > getdate()
 						THEN 1
 					ELSE
 						0
 					END,
 				[IsHomeKennel] = coalesce(@isHomeKennel,[isHomeKennel]),
 				[AppAccessFlags] = coalesce(@appAccessFlags,[AppAccessFlags]),
				[HcWebPermissionFlags] = coalesce(@appAccessFlags,[HcWebPermissionFlags]),
 				[MismanagementRoles] = coalesce(@mismanagementRoles,[MismanagementRoles]),
 				[KennelNotificationPreference] = coalesce(@notificationState,[KennelNotificationPreference],0),
 				[KennelEmailAlertPreference] = coalesce(@emailAlertState,[KennelEmailAlertPreference],0),
 				[MembershipExpirationDate] = 
 				CASE 
 					WHEN (@monthsToAddToMembership = 9999) THEN '1/1/2100'
 					WHEN ((@monthsToAddToMembership IS NULL) OR (@monthsToAddToMembership = -9999))
 						THEN
 							CASE WHEN (@monthsToAddToMembership = -9999) THEN NULL ELSE MembershipExpirationDate END
 					ELSE 
 						CASE 
 							WHEN ((MembershipExpirationDate < getdate()) OR (MembershipExpirationDate IS NULL)) 
 								THEN dateadd(month,@monthsToAddToMembership,getdate()) 
 							ELSE 
 								dateadd(month,@monthsToAddToMembership,MembershipExpirationDate) 
 							END
 					END,
 				[MemberSince] = 
 					CASE 
 					WHEN MemberSince IS NOT NULL THEN 
 						CASE WHEN (@monthsToAddToMembership = -9999) THEN NULL ELSE MemberSince END
					 
 					ELSE 
 						CASE 
 							WHEN ((@monthsToAddToMembership IS NULL) OR (@monthsToAddToMembership <= 0)) 
 								THEN NULL
 							ELSE 
 								getdate()
 							END
 					END,
 				[updatedAt] = getdate()
 				FROM HC.HasherKennelMap
 				WHERE id = @hkmId
 		END


 	IF (@mismanagementRoles is not null)
 	BEGIN
 		DECLARE @mmRoles nvarchar(4000)
 		SELECT @mmRoles = MmRoles FROM [HC3].[vwMmByKennel] where KennelId = @kennelId
 		UPDATE HC.Kennel 
 			SET KennelMismanagementTeam = @mmRoles, 
 			updatedAt = getdate()
 		where id = @kennelId
 	END

 	DECLARE @RC int

 	-- send back adHoc data to update the UI correctly
 	SELECT
 		1 as adHocDataId,
 		[Following] as following,
 		[KennelNotificationPreference] as kennelNotificationPreference,
 		[KennelEmailAlertPreference] as kennelEmailAlertPreference,
 		CASE WHEN hkm.kennelId = h.HomeKennelId then 1 else 0 end as isHomeKennel
 		FROM HC.HasherKennelMap hkm
 		INNER JOIN HC.Hasher h on h.id = hkm.UserId
 		WHERE hkm.id = @hkmId

 	DECLARE @procName nvarchar(100)
 	SET @procName = OBJECT_NAME(@@PROCID)

 	if ((@targetUserId IS NULL) OR (@targetUserId = @userId))
 		EXECUTE @RC = [HC5].[hcapp_syncUserData] 
 		   @deviceId = @deviceId
 		  ,@accessToken = @accesstoken
 		  ,@hashersUpdatedAfter = @hashersUpdatedAfter
 		  ,@citiesUpdatedAfter = 'ignore'
 		  ,@regionsUpdatedAfter = 'ignore'
 		  ,@countriesUpdatedAfter = 'ignore'
 		  ,@kennelsUpdatedAfter = @kennelsUpdatedAfter
 		  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
 		  ,@hasherEventMapUpdatedAfter = 'ignore'
 		  ,@narrowEventsUpdatedAfter = 'ignore'
 		  ,@procName = @procName
 		  ,@param = NULL
 	ELSE
 		EXECUTE @RC = [HC5].[hcapp_syncKennelAdminData] 
 		   @deviceId = @deviceId
 		  ,@accessToken = @accessToken
 		  ,@kennelId = @kennelId
 		  ,@hashersUpdatedAfter = @hashersUpdatedAfter
 		  ,@kennelsUpdatedAfter = @kennelsUpdatedAfter
 		  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
 		  ,@procName = @procName
 		  ,@param = NULL	

 END

