



CREATE PROCEDURE [HC5].[hcapp_getResetCode]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @supportCode nvarchar(1000)

AS

BEGIN

-- EXEC HC2.updateAvatar @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @avatarUrl = 'bundle://Avatar-2'

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
SET @result = 'Support code not found'

IF EXISTS(SELECT * FROM HC.Hasher WHERE SupportCode = @supportCode)
BEGIN 
	SELECT @result = ResetCode FROM HC.Hasher h where h.SupportCode = @supportCode and removed = 0
END

SELECT @result as result

END


