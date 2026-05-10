CREATE PROCEDURE [HC5].[hcapp_processThirdPartyLogin]

 @deviceId nvarchar(50),
 @accessToken nvarchar(1000),
 @hashersUpdatedAfter nvarchar(50),
 @firstName nvarchar(120),
 @lastName nvarchar(120),
 @hashName nvarchar(120),
 @email nvarchar(120),
 @photo nvarchar(2000),
 @thirdPartyLoginType nvarchar(120),
 @thirdPartyUserId nvarchar(1000),
 @thirdPartyAccessToken nvarchar(1000),
 @thirdPartyAuthorizationCode nvarchar(1000),
 @thirdPartyAccessTokenExpires nvarchar(150) = '1/1/2100',
 @includeInGlobalHashDirectory int = -1,
 @hcVersion nvarchar(100),
 @latitude decimal(18,15) = 0,
 @longitude decimal(19,15) = 0,
 @thirdPartyEmail nvarchar(120)

AS

BEGIN

SET NOCOUNT ON

	
	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	DECLARE @paramString nvarchar(250)
	SET @paramString = @deviceSecret + upper(cast(coalesce(@userId,'00000000-0000-0000-0000-000000000000') as nvarchar(50))) 

	DECLARE @useUsaMiles smallint = 0

	-- rough check to see if user is in continental US
	IF ((@latitude between 24.7433195 AND 49.3457868) AND (@longitude between -124.7844079 AND -66.9513812)) SET @useUsaMiles = 1

	-- rough check to see if user is in Alaska (East part)
	IF ((@latitude between 51.214183 AND 71.365162) AND (@longitude between -180 AND -179.148909)) SET @useUsaMiles = 1

	-- rough check to see if user is in Alaska (West part)
	IF ((@latitude between 51.214183 AND 71.365162) AND (@longitude between 179.77847 AND 180)) SET @useUsaMiles = 1

	-- rough check to see if user is in Hawaii 
	IF ((@latitude between 18.910361 AND 28.402123) AND (@longitude between -178.334698 AND -154.806773)) SET @useUsaMiles = 1

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),@paramString, @timeWindow) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

IF (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL
if (@hashName = '') SET @hashName = null
if (@photo = '') SET @photo = null

-- If this email address is already being used but not associated with this type of third party login, update it accordingly
IF (SELECT COUNT(*) FROM HC.Hasher h where (coalesce(h.ThirdPartyUserId,'<dummy data>') = @thirdPartyUserId) OR h.id = @userId OR (h.Email = @email OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail) OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @email) OR h.Email = @thirdPartyEmail)) > 0
BEGIN
	UPDATE h SET
		h.HashName = coalesce(@hashName,h.HashName),
		h.Email = coalesce(@email,h.Email),
		h.ThirdPartyLoginType = @thirdPartyLoginType,
		h.ThirdPartyUserId = @thirdPartyUserId,
		h.ThirdPartyAccessToken = @thirdPartyAccessToken,
		h.ThirdPartyAuthorizationCode = @thirdPartyAuthorizationCode,
		h.ThirdPartyTokenLastUpdated = GETDATE(),
		h.ThirdPartyEmail = @thirdPartyEmail,
		h.updatedAt = getdate(),
		h.FacebookId = case when @thirdPartyLoginType = 'facebook' then @thirdPartyUserId else null end,
		h.FacebookAccessToken = case when @thirdPartyLoginType = 'facebook' then @thirdPartyAccessToken else null end,
		h.FacebookAccessTokenLastUpdated = case when @thirdPartyLoginType = 'facebook' then getdate() else null end
	FROM HC.Hasher h
	WHERE (coalesce(h.ThirdPartyUserId,'<dummy data>') = @thirdPartyUserId) OR h.id = @userId OR (h.Email = @email OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail) OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @email) OR h.Email = @thirdPartyEmail)
END
ELSE
BEGIN
	SET @userId = NULL
END

DECLARE @errorId uniqueidentifier
DECLARE @isNewUser smallint

SET @isNewUser = 1

	IF ((SELECT COUNT(*) FROM HC.Hasher h 
		where h.ThirdPartyUserId = @thirdPartyUserId OR ((h.Email = @email OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail) OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @email) OR h.Email = @thirdPartyEmail)))
		> 0)
	BEGIN
		SET @isNewUser = 0
		-- this was commented out, but I don't know why!!!!
		UPDATE HC.Hasher
			SET 
				FirstName = coalesce(@firstName,FirstName),
				LastName = coalesce(@lastName,LastName),
				Photo = coalesce(Photo,@photo,'bundle://avatar-'+cast(cast (rand() * 50 as int) as nvarchar(2))),
				IncludeInGlobalHashDirectory = 0,
				FacebookId = case when @thirdPartyLoginType = 'facebook' then @thirdPartyUserId else null end,
				FacebookAccessToken = case when @thirdPartyLoginType = 'facebook' then @thirdPartyAccessToken else null end,
				FacebookAccessTokenLastUpdated = case when @thirdPartyLoginType = 'facebook' then getdate() else null end,
				ThirdPartyLoginType = @thirdPartyLoginType,
				ThirdPartyAccessToken = @thirdPartyAccessToken,
				ThirdPartyUserId = @thirdPartyUserId,
				ThirdPartyAuthorizationCode = @thirdPartyAuthorizationCode,
				ThirdPartyTokenLastUpdated = getdate(),
				ThirdPartyAccessTokenExpires = cast(@thirdPartyAccessTokenExpires as datetimeoffset(7)),
				HashName = coalesce(@hashName,HashName),
				removed = 0,
				updatedAt = getdate()
			FROM HC.Hasher ha
			WHERE (ha.ThirdPartyUserId = @thirdPartyUserId) OR (ha.Email = @email OR (ha.ThirdPartyEmail IS NOT NULL AND ha.ThirdPartyEmail = @thirdPartyEmail) OR (ha.ThirdPartyEmail IS NOT NULL AND ha.ThirdPartyEmail = @email) OR ha.Email = @thirdPartyEmail)

	END
	ELSE
	BEGIN
		
		SET @userId = newid()

		INSERT [HC].[Hasher]
			   ([id]
			   ,[FirstName]
			   ,[LastName]
			   ,[Email]
			   ,[HashName]
			   ,[Photo]
			   ,[NameDisplayPreference]
			   ,[IncludeInGlobalHashDirectory]
			   ,[FacebookId]
			   ,[FacebookAccessToken]
			   ,[FacebookAccessTokenLastUpdated]
			   ,[ThirdPartyLoginType]
			   ,[ThirdPartyUserId]
			   ,[ThirdPartyAccessToken]
			   ,[ThirdPartyAuthorizationCode]
			   ,[ThirdPartyTokenLastUpdated]
			   ,[ThirdPartyAccessTokenExpires]
			   ,[ThirdPartyEmail]
			   ,[Preferences]
			   ,[HomeLatitude]
			   ,[HomeLongitude]
			   ,[updatedAt])
		 VALUES
			   (@userId,
				coalesce(@firstName,''),
				coalesce(@lastName,''),
				coalesce(@email, @thirdPartyEmail, ''),
				coalesce(@hashName, ''),
				coalesce(@photo, 'bundle://avatar-'+cast(cast (rand() * 50 as int) as nvarchar(2))),
				CASE WHEN datalength(coalesce(@hashName,'')) != 0 
					THEN 1
				ELSE
					2
				END,
				COALESCE(@includeInGlobalHashDirectory,0),
				case when @thirdPartyLoginType = 'facebook' then @thirdPartyUserId else null end,
				case when @thirdPartyLoginType = 'facebook' then @thirdPartyAccessToken else null end,
				case when @thirdPartyLoginType = 'facebook' then getdate() else null end,
				@thirdPartyLoginType,
				@thirdPartyUserId,
				@thirdPartyAccessToken,
				@thirdPartyAuthorizationCode,
				getdate(),
				cast(@thirdPartyAccessTokenExpires as datetimeoffset(7)),
				@thirdPartyEmail,
				14 + @useUsaMiles,
				@latitude,
				@longitude,
				getdate())


	
	-- for new users, set them up to follow a kennel so some runs will show
			DECLARE @filthKennelId uniqueidentifier

			SELECT TOP 1 @filthKennelId = k.id from HC.Kennel k inner join HC.City c on k.CityId = c.id where KennelName like '%FILTH%' and c.CityName like '%Leiden%'

			

			IF (@filthKennelId is not null)
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
			   ,[HistoricalPackRunCount]
			   ,[HistoricalHaringCount]
			   ,[HistoricalCountIsEstimate]
			   ,[CurrentPackRunCount]
			   ,[CurrentHaringCount]
			   ,[MemberSince]
			   ,[removed]
			   ,[updatedAt])
				 VALUES (
					   @userId,
					   @filthKennelId,
					   1, -- following (show up in the member list by setting following to 1)
					   0, -- IsMember (we want them to show up in the member list, but we don't want them to actually be a member yet because they might not have paid membership fees)
					   0, -- IsHomeKennel
					   0, -- MismanagementRoleFlags
					   0, -- UserRoleFlags
					   0, -- AppAccessFlags
					   0, -- HistoricalRunCount
					   0, -- HistoricalHaringCount
					   0, -- historicalCountIsEstimate
					   0, -- CurrentPackRunCount
					   0, -- CurrentHaringCount
					   getdate(), -- member since
					   0, -- removed
					   getdate() -- updated At
					  )
			END

	END

	if (@thirdPartyLoginType = 'facebook')
	BEGIN
		-- Now update the Kennels that have this user as a FB admin
		UPDATE HC.Kennel set KennelFacebookToken = @thirdPartyAccessToken, KennelFacebookTokenLastUpdated = getdate() FROM HC.Kennel 
			where KennelFacebookTokenUsername = @email OR KennelFacebookTokenUsername = @thirdPartyEmail
	END

	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where (h.ThirdPartyUserId = @thirdPartyUserId) OR (h.Email = @email OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail) OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @email) OR h.Email = @thirdPartyEmail)

	IF (@userId is not null)
		BEGIN

			SELECT
				h.id as hasherId,
				h.Photo as photo,
				h.DisplayName as displayName,
				h.Email as email,
				h.ThirdPartyUserId as thirdPartyUserId,
				h.ThirdPartyLoginType as thirdPartyLoginType,
				h.ThirdPartyAccessToken as thirdPartyAccessToken,
				h.ThirdPartyAuthorizationCode as thirdPartyAuthorizationCode,
				h.ThirdPartyTokenLastUpdated as thirdPartyTokenLastUpdated,
				h.ThirdPartyAccessTokenExpires as thirdPartyAccessTokenExpires,
				h.ThirdPartyEmail as thirdPartyEmail,
				h.FirstName as firstName,
				h.HashName as hashName,
				h.LastName as lastName,
				coalesce(h.NameDisplayPreference,0) as dispPref,
				coalesce(h.DisplayName,'') as dispName,
				h.QR_code as qrCode,
				h.SupportCode as supportCode,
				h.QR_secret_code as qrSecretCode,
				h.ResetCode as resetCode,
				h.IncludeInGlobalHashDirectory as includeInGlobalHashDirectory,
			    h.Preferences as preferences,
				--h.updatedAt as updatedAt
				CONVERT(nvarchar(50),cast([updatedAt] as datetime2)) as updatedAt,
				h.removed as removed
			FROM HC.Hasher h where h.id = @userId
		END
	ELSE
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'User account not created','There was a problem creating a user account using the third party login API.',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000',coalesce(@thirdPartyEmail,''),@email)

			SELECT 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'Reset code not found' as errorTitle
			,'The reset code provided was not found in the Harrier Central system' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END

END

