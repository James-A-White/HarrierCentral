
CREATE PROCEDURE [HC5].[hcapp_addEditUser]

 @deviceId nvarchar(100),
 @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @hashersUpdatedAfter nvarchar(50),
 @hasherEventMapUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50),
 @targetUserId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @email nvarchar(250) = null,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @hashName nvarchar(100) = null,
 @photo nvarchar(500) = null,
 @includeInGlobalHashDirectory int = null,
 @preferences int = null,
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @historicalTotalRunCount int = null,
 @historicalPackRunCount int = null, -- Deprecated: Nov 2021
 @historicalHaringCount int = null,
 @historicalCountIsEstimate int = null,
 @followKennelOnAddNewUser int = null,
 @latitude decimal(18,15) = 0,
 @longitude decimal(19,15) = 0,
 @nameDisplayPreference int = null

AS

BEGIN

SET NOCOUNT ON

	DECLARE @deviceSecret nvarchar(150),
			@timeWindow int,
			@isAddingNewUser smallint = 1

	IF ((@deviceId IS NOT NULL) AND (@deviceId != ''))
	BEGIN

		SET @isAddingNewUser = 0

		SELECT 
			@userId = d.UserId,
			@deviceSecret = upper(d.DeviceSecret),
			@timeWindow = d.TimeWindow
		FROM HC.Device d where d.id = @deviceId
	END


-- NOTES: This proc edits an existing user... either the user who called it or an admin who is editing another user's record

	DECLARE @errorId uniqueidentifier

	DECLARE @useUsaMiles smallint = 0

	-- rough check to see if user is in continental US
	IF ((@latitude between 24.7433195 AND 49.3457868) AND (@longitude between -124.7844079 AND -66.9513812)) SET @useUsaMiles = 1

	-- rough check to see if user is in Alaska (East part)
	IF ((@latitude between 51.214183 AND 71.365162) AND (@longitude between -180 AND -179.148909)) SET @useUsaMiles = 1

	-- rough check to see if user is in Alaska (West part)
	IF ((@latitude between 51.214183 AND 71.365162) AND (@longitude between 179.77847 AND 180)) SET @useUsaMiles = 1

	-- rough check to see if user is in Hawaii 
	IF ((@latitude between 18.910361 AND 28.402123) AND (@longitude between -178.334698 AND -154.806773)) SET @useUsaMiles = 1

	IF (@userId IS NULL)
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

	DECLARE @paramString nvarchar(250)

	SET @paramString = upper(@deviceSecret + cast(coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as nvarchar(50))) 

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString,@timeWindow) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,cast(@targetUserId as nvarchar(40)))

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at harriercentral@gmail.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if (@targetUserId != '00000000-0000-0000-0000-000000000000')
	BEGIN
		if (SELECT count(*) from HC.Hasher h where h.id = @targetUserId) = 0
		BEGIN

			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'User not found','The userId provided to the edit user interface was not found. It is possible that this user has been deleted from Harrier Central.',OBJECT_NAME(@@PROCID),@userId,cast(@targetUserId as nvarchar(40)))

			select 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'User not found' as errorTitle
			,'The userId provided to the edit user interface was not found. It is possible that this user has been deleted from Harrier Central.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
	END

	if (@firstName = '') SET @firstName = null
	if (@lastName = '') SET @lastName = null
	if (@photo = '') SET @photo = null
	if (@email = '') SET @email = null
	if (@hashName = '') SET @hashName = null
	if (@historicalTotalRunCount = -1) SET @historicalTotalRunCount = NULL
	if (@historicalHaringCount = -1) SET @historicalHaringCount = NULL
	if (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL
	if (@preferences = -1) SET @preferences = NULL
	if (@nameDisplayPreference <= 0) SET @nameDisplayPreference = NULL


	IF (@email is not null)
	BEGIN
		IF (SELECT count(*) from HC.Hasher h where h.Email = trim(@email) and h.id <> @targetUserId) > 0
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Duplicate email','A user being edited is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@email)

			select 
			@errorId as errorId,
			cast (10005 as int) as errorType 
			,'Email address already exists' as errorTitle
			,'A user already exists with this e-mail address in the system. Please register with a different e-mail address.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
	END

	-- is it a new user?
	IF (@targetUserId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @targetUserId = newid()

		INSERT [HC].[Hasher]
			   ([id]
			   ,[FirstName]
			   ,[LastName]
			   ,[Email]
			   ,[HashName]
			   ,[Photo]
			   ,[NameDisplayPreference]
			   ,[IncludeInGlobalHashDirectory]
			   ,[Preferences]
			   ,[HomeLatitude]
			   ,[HomeLongitude]
			   ,[HomeKennelId]
			   ,[updatedAt])
		 VALUES
			   (@targetUserId,
				coalesce(@firstName,''),
				coalesce(@lastName,''),
				coalesce(@email, ''),
				coalesce(@hashName, ''),
				coalesce(@photo, ''),
				CASE WHEN @nameDisplayPreference IS NULL THEN
					CASE WHEN datalength(coalesce(@hashName,'')) != 0 
						THEN 1
					ELSE
						2
					END
				ELSE
					@nameDisplayPreference END,
				COALESCE(@includeInGlobalHashDirectory,0),
				COALESCE(@preferences,14 + @useUsaMiles),
				@latitude,
				@longitude,
				CASE WHEN @kennelId != '00000000-0000-0000-0000-000000000000' THEN
					@kennelId
				ELSE
					NULL 
				END,
				getdate())


		INSERT HC.LaunchAndLogin
			(
				HcVersion,
				UserId,
				UserName
			) 
			VALUES
			(
				@hcVersion,
				@targetUserId,
				'+' + coalesce(@hashName,@firstName + ' ' + @lastName,'<no name>') + '+'
			)
				

		IF ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000'))
		BEGIN
			DECLARE @kid uniqueidentifier
			SELECT @kid = KennelId FROM HC.Event where id = @eventId
			INSERT INTO HC.HasherEventMap(UserId,EventId,KennelId,RsvpState,AttendenceState,UserStartEvent,Rsvp,updatedAt) VALUES (@targetUserId,@eventId,@kid,3,0,GETDATE(),GETDATE(),GETDATE()) 
		END

		IF (
			(@kennelId IS NOT NULL) 
		AND (@targetUserId IS NOT NULL)
		AND (@kennelId != '00000000-0000-0000-0000-000000000000')
		AND (@targetUserId != '00000000-0000-0000-0000-000000000000')
		AND (coalesce(@followKennelOnAddNewUser,0) != 0)
		AND (NOT EXISTS(SELECT * FROM HC.HasherKennelMap WHERE KennelId = @kennelId AND UserId = @targetUserId))
		)
		BEGIN
			INSERT INTO [HC].[HasherKennelMap]
           (
           [UserId]
           ,[KennelId]
           ,[Following]
           ,[IsMember]
		   ,[IsHomeKennel]
           ,[MismanagementRoleFlags]
           ,[UserRoleFlags]
           ,[AppAccessFlags]
           ,[HistoricalTotalRunCount]
           ,[HistoricalHaringCount]
		   ,[HistoricalCountIsEstimate]
           ,[CurrentPackRunCount]
           ,[CurrentHaringCount]
           ,[MemberSince]
           ,[removed]
           ,[updatedAt])
			 VALUES (
				   @targetUserId,
				   @kennelId,
				   1, -- following (show up in the member list by setting following to 1)
				   0, -- IsMember (we want them to show up in the member list, but we don't want them to actually be a member yet because they might not have paid membership fees)
				   0, -- IsHomeKennel
				   0, -- MismanagementRoleFlags
				   0, -- UserRoleFlags
				   0, -- AppAccessFlags
				   coalesce(@historicalTotalRunCount,0), -- HistoricalRunCount
				   coalesce(@historicalHaringCount,0), -- HistoricalHaringCount
				   coalesce(@historicalCountIsEstimate,0),
				   CASE WHEN ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000')) THEN 1 ELSE 0 END, -- CurrentPackRunCount
				   0, -- CurrentHaringCount
				   getdate(), -- member since
				   0, -- removed
				   getdate() -- updated At
				  )

		END
	END
	ELSE
		BEGIN

		-- this stored proc is not used to add members to kennels or events
		-- when updating a Hasher, only when inserting one, so all we have to
		-- handle here is the update hasher case
		UPDATE HC.Hasher 
		SET
		FirstName = coalesce(@firstName,FirstName),
		LastName = coalesce(@lastName,LastName),
		Email = coalesce(@email, Email),
		HashName = coalesce(@hashName, HashName),
		Photo = coalesce(@photo, Photo),
		IncludeInGlobalHashDirectory = coalesce(@IncludeInGlobalHashDirectory,IncludeInGlobalHashDirectory),
		Preferences = coalesce(@preferences,Preferences),
		NameDisplayPreference = coalesce(@nameDisplayPreference,NameDisplayPreference),
		updatedAt = getdate()
		FROM HC.Hasher h where id = @targetUserId

		IF ((@kennelId IS NOT NULL) AND (@kennelId != '00000000-0000-0000-0000-000000000000') AND ((@historicalHaringCount is not null) OR (@historicalTotalRunCount is not null)))
		BEGIN
			UPDATE HC.HasherKennelMap 
				SET 
					HistoricalHaringCount = coalesce(@historicalHaringCount,HistoricalHaringCount),
					HistoricalTotalRunCount = coalesce(@historicalTotalRunCount,HistoricalTotalRunCount),
					HistoricalCountIsEstimate = coalesce(@historicalCountIsEstimate,HistoricalCountIsEstimate)
		FROM HC.HasherKennelMap 
		WHERE userId = @targetUserId AND KennelId = @kennelId
		END

	END

	DECLARE @RC int

	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)


	IF (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		-- this case is for when a new user is being created because someone
		-- is adding an account when installing an app for the first time
		SELECT 
			h.id as hasherId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.SupportCode,'') as supportCode,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.FacebookId,'') as facebookId,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.QR_secret_code,'') as qrSecretCode,
			cast(coalesce(h.Preferences,14 + coalesce(@useUsaMiles,0)) as nvarchar(20)) as preferences,
			--coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
			-- either sync the users, or in the case when a new user has been added (@targetUserId has been specified), return only that one record
		FROM HC.Hasher h where h.id = @targetUserId

	END
	ELSE
	BEGIN
		IF ( ((@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')) AND ((@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')))
		BEGIN
			-- this case is when a user is being edited but is not being added as a member of a Kennel or
			-- or added to an event
			EXECUTE @RC = [HC5].[hcapp_syncUserData] 
			@deviceId = @deviceId
			,@accessToken = @accessToken
			,@hashersUpdatedAfter = @hashersUpdatedAfter
			,@citiesUpdatedAfter = 'ignore'
			,@regionsUpdatedAfter = 'ignore'
			,@countriesUpdatedAfter = 'ignore'
			,@kennelsUpdatedAfter = 'ignore'
			,@hasherKennelMapUpdatedAfter ='ignore'
			,@hasherEventMapUpdatedAfter = 'ignore'
			,@narrowEventsUpdatedAfter = 'ignore'
			,@procName = @procName
			,@param = @paramString 
				
		END
		ELSE IF ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000'))
		BEGIN
			-- this case is when a user is being added and also needs to be added to an event
			-- the user can be added as just a Hasher or can also be added as a member of the
			-- Kennel
			EXECUTE @RC = [HC5].[hcapp_syncEventAdminData]
			@deviceId = @deviceId
			,@accessToken = @accessToken
			,@eventId = @eventId
			,@hashersUpdatedAfter = @hashersUpdatedAfter
			,@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter
			,@hasherKennelMapUpdatedAfter = 'ignore'
			,@narrowEventsUpdatedAfter = 'ignore'
			,@paymentsUpdatedAfter = 'ignore'
			,@receiptsUpdatedAfter = 'ignore'
			,@procName = @procName
			,@param = @paramString
		END
		ELSE IF ((@kennelId IS NOT NULL) AND (@kennelId != '00000000-0000-0000-0000-000000000000'))
		BEGIN
			-- this case is when a user is being added and also needs to be added as a 
			-- Kennel member
			EXECUTE @RC = [HC5].[hcapp_syncKennelAdminData] 
			 @deviceId = @deviceId
			,@accessToken = @accessToken
			,@kennelId = @kennelId
			,@kennelsUpdatedAfter = 'ignore'
			,@hashersUpdatedAfter =  @hashersUpdatedAfter
			,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
			,@procName = @procName
			,@param = @paramString	
		END
	END

END





