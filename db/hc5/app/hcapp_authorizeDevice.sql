CREATE PROCEDURE [HC5].[hcapp_authorizeDevice]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @scanText nvarchar(250) = NULL,
 @userId uniqueidentifier = NULL,
 @deviceData nvarchar(MAX),
 @apnsToken nvarchar(500) = NULL, -- Apple notificatoin system token, will be null for Android devices
 @fcmToken nvarchar(500) = NULL   -- Firebase notificatoin system token
 
AS

BEGIN

	SET NOCOUNT ON
-- EXEC HC5.hcapp_authorizeDevice @scanText = 'URC:NCCARY', @deviceId = '0C2852D4-A60E-4BA9-8628-4B0F246034C4', @userId = '00000000-0000-0000-0000-000000000000', @accessToken = 'asdfasdfasfdasdfasdfaf', @hcVersion = 'test'

	IF HC.CHECK_ACCESS_TOKEN_V2('00000000-0000-0000-0000-000000000000',OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),null,30) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	DECLARE 
		@errorId uniqueidentifier,
		@hasherName nvarchar(250),
		@removed int


	if (@userId IS NOT NULL)
	BEGIN
   		SELECT top 1 
			@scanText = h.ResetCode,
			@hasherName = coalesce(h.DisplayName,h.firstName + ' ' + h.lastName,'<no name>'),
			@removed = h.Removed
		FROM HC.Hasher h where h.id = @userId
	END

	if ((@scanText like 'URC:%') AND (@userId IS NULL))
	BEGIN
		SELECT top 1 
			@userId = h.id,
			@hasherName = coalesce(h.DisplayName,h.firstName + ' ' + h.lastName,'<no name>'),
			@removed = h.Removed
		FROM HC.Hasher h where h.ResetCode = @scanText
	END



	DECLARE @include smallint

	IF ((@userId is not null) AND (@removed = 0))
		BEGIN

			UPDATE HC.Hasher set 
				LastLoginDateTime = getdate(),
				HcVersion = coalesce(@hcVersion,'<unknown version>'),
				updatedAt = getdate() 
				where id = @userId
			
			INSERT HC.LaunchAndLogin(HcVersion,UserId,UserName) VALUES(@hcVersion,@userId,'~'+@hasherName+'~')
			
			DECLARE	@BinaryData varbinary(max) = crypt_gen_random (150) 
			DECLARE @deviceSecret nvarchar(150), @timeWindow int
			SELECT @deviceSecret = LEFT(REPLACE(REPLACE(cast('' as xml).value('xs:base64Binary(sql:variable("@BinaryData"))', 'varchar(max)'),'+',''),'/',''),75)
			SELECT @timeWindow = cast((rand()*15)+30 as int)

			--SELECT @timeWindow = 30
			
			DELETE FROM [HC].[Device]
			WHERE ApnsToken = @apnsToken AND FcmToken = @fcmToken
			
			INSERT INTO [HC].[Device]
			([id]
           ,[DeviceSecret]
		   ,[TimeWindow]
           ,[DeviceData]
           ,[UserId]
		   ,[ApnsToken]
		   ,[FcmToken])
			VALUES
			   (@deviceId
			   ,@deviceSecret
			   ,@timeWindow
			   ,@deviceData
			   ,@userId
			   ,@apnsToken
			   ,@fcmToken
			   )
			
			SELECT
				h.id as hasherId,
				h.PublicHasherId as publicHasherId,
				h.Photo as photo,
				h.DisplayName as displayName,
				h.Email as email,
				h.FacebookId as facebookId,
				h.FirstName as firstName,
				h.HashName as hashName,
				h.LastName as lastName,
				h.QR_code as qrCode,
				h.SupportCode as supportCode,
				h.QR_secret_code as qrSecretCode,
				h.ResetCode as resetCode,
				h.IncludeInGlobalHashDirectory as includeInGlobalHashDirectory,
				h.Preferences as preferences,
				h.IsBetaTester as isBetaTester,
				h.HomeKennelId as homeKennelId,

				h.ThirdPartyAccessToken as thirdPartyAccessToken,
				h.ThirdPartyAuthorizationCode as thirdPartyAuthorizationCode,
				h.ThirdPartyEmail as thirdPartyEmail,
				h.ThirdPartyForceTokenRefresh as thirdPartyForceTokenRefresh,
				h.ThirdPartyLoginType as thirdPartyLoginType,
				h.ThirdPartyUserId  as thirdPartyUserId,

				h.ThirdPartyTokenLastUpdated as thirdPartyTokenLastUpdated,
				h.ThirdPartyAccessTokenExpires as thirdPartyAccessTokenExpires,
				d.DeviceSecret as iconDataBase64, -- a bit of security by obscurity here
				d.TimeWindow as colorPaletteIndex -- more security through obscurity (yes I know it's bad)
			FROM HC.Hasher h INNER JOIN
			HC.Device d on d.userId = h.id AND d.id = @deviceId
			where h.id = @userId
		END
	ELSE IF ((@userId is not null) AND (@removed = 1))
		BEGIN
			SET @errorId = newid()
			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'Attempt to load a removed user ('+@hasherName+')',@hasherName + ' is attempting to be loaded even though the account has been removed',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000',@deviceId,@scanText)

			SELECT 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'This user has been removed' as errorTitle
			,'The user account associated with ('+REPLACE(@scanText,'URC:','')+') for "'+@hasherName+'" has been removed from our servers.~~Please attempt to have a new invite code emailed to you by pressing the ''Email me a new invite code'' text on this screen.~~You can also contact your Kennel''s Harrier Central admin for a new invite code or contact us at connect@harriercentral.com for assistance.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN

		END
	ELSE
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'User invite code not found','User invite code "'+ @scanText +'" not found',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000',@deviceId,@scanText)

			SELECT 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'Invite code not found' as errorTitle
			,'The invite code provided was not found in the Harrier Central system' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END

END

