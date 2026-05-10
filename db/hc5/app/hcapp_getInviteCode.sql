

CREATE PROCEDURE [HC5].[hcapp_getInviteCode]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @targetUserId uniqueidentifier

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

-- Only allow an invite code to be shared if the following conditions are met
-- 1) The target user can not have logged in using the app
-- 2) The target user has to have their home Kennel set
-- 3) The admin requesting the code has to either be a super admin or have the "manage members" permission on the same kennel that is the home kennel of the target user

-- the below query ensures all of these conditions are met

SELECT @result = h1.ResetCode FROM HC.Hasher h1
where h1.id = cast(@targetUserId as uniqueidentifier)
and h1.LastLoginDateTime is null
and h1.Removed = 0
and h1.HomeKennelId in (select hkm.KennelId from HC.Hasher h2 
inner join HC.HasherKennelMap hkm on hkm.UserId = h2.id
where h2.id = @userId 
AND hkm.AppAccessFlags & 1073741840 != 0
)

SELECT coalesce(@result,'No valid user') as result

END


