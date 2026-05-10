



CREATE PROCEDURE [HC5].[hcapp_gdprDelete]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000)

AS

-- EXEC HC3.gdprDelete @userId = 'DCA00F27-5672-4435-B798-154E16ECD74B',@accessToken = 'aaaa'

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

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),@deviceSecret,@timeWindow) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @result nvarchar(100)
SET @result = 'success'

DECLARE @rowsUpdated int

UPDATE HC.Hasher SET
       [HomeKennelId] = null
      ,[MotherKennelId] = null
      ,[SupportCode] = '*' + SupportCode
      ,[ResetCode] = '*' + ResetCode
      ,[QR_code] = '*' + QR_code
      ,[HashName] = 'Deleted User'
      ,[FirstName] = 'Deleted'
      ,[LastName] = 'User'
      ,[Email] = ResetCode + '@harriercentral.com'
      ,[Photo] = 'bundle://avatar-0'
      ,[FacebookId] = null
      ,[FacebookAccessToken] = null
      ,[ThirdPartyUserId] = null
      ,[ThirdPartyAccessToken] = null
      ,[ThirdPartyEmail] = null
	  ,[ThirdPartyLoginType] = 'none'
      ,[Description] = null
      ,[HomeLatitude] = null
      ,[HomeLongitude] = null
      ,[HomeGeolocation] = null
      ,[Removed] = 1
      ,[updatedAt] = getdate()
      ,[SingleSignOnId] = null
      ,[SingleSignOnType] = null
      ,[IsBetaTester] = 0
FROM HC.Hasher
WHERE id = @userId AND Removed = 0

SET @rowsUpdated = @@ROWCOUNT

IF (@rowsUpdated = 1) 
	SET @result = 'success'
ELSE
	SET @result = 'failed'

SELECT @result as result

END


