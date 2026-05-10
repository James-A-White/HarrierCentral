

CREATE PROCEDURE [HC5].[hcapp_approveLogin]

@deviceId nvarchar(100),
@accessToken nvarchar(1000),
@deviceType nvarchar(100),
@deviceName nvarchar(100),
@systemName nvarchar(100),
@systemVersion nvarchar(100),
@manufacturer nvarchar(100),
@latitude decimal(18,15),
@longitude decimal (19,15),
@hcVersion nvarchar(200) = 'pre 0.6.4',
@buildNumber nvarchar(50) = '?',
@fbToken nvarchar(1000) = null,
@usesLocSvcs smallint = -1,
@screenWidth smallint = 0,
@screenHeight smallint = 0,
@ipInfo nvarchar(4000),
@splashSequenceViewed datetimeoffset = null,
@splashSequenceRootName nvarchar(100) = null,
@locale nvarchar(50) = ''

AS

BEGIN

	SET NOCOUNT ON

-- EXEC HC3.approveLoginV2 @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', @accessToken = '', @deviceId = 'TestDevice', @deviceType = 'iPhone 6s / iOS 11.4', @latitude = 52.4, @longitude = 4.4, @ipInfo = '',@deviceName ='jsHot',@systemName = 'iOS', @systemVersion = '17.2', @manufacturer = 'Apple'



	DECLARE @errorId uniqueidentifier

	DECLARE @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
			@deviceSecret nvarchar(150) = '<none>',
			@timeWindow int = 30


	IF (@deviceId != '')
		BEGIN
			SELECT 
				@userId = d.UserId,
				@deviceSecret = upper(d.DeviceSecret),
				@timeWindow = d.TimeWindow
			FROM HC.Device d where d.id = @deviceId
		END
	ELSE
		BEGIN
			SET @deviceId = '00000000-0000-0000-0000-000000000000'
		END

	DECLARE @userName nvarchar(250),
			@email nvarchar(250),
			@isBetaTester smallint,
			@homeKennelId nvarchar(100),
			@ThirdPartyForceTokenRefresh datetimeoffset(7),
			@invalidAccessToken smallint = 0,
			@removed int,
			@integrationCount int,
			@lastIntegrationExecuted datetime,
			@integrationStopped int,
			@betaFeaturesEnabled nvarchar(1000)

			;with cte as (
				select count(case when datediff(hour,ken.IntegrationLastExecuted,getdate()) > 2 then 1 else null end) as integrationCount,
				min(ken.IntegrationLastExecuted) as lastIntegrationExecuted,
				h.id as hid
				from HC.Kennel ken inner join HC.Hasher h on ken.KennelFacebookTokenUsername = h.ThirdPartyEmail and h.id = @userId
				where ken.IntegrationAutoImportEvents != 0 and ken.InboundIntegrationId = 1
				group by h.id)
			SELECT  @userName = coalesce(h.displayName, h.firstName + ' ' + h.lastName, '<no name>')
				   ,@email = h.Email
				   ,@fbToken = coalesce(@fbToken,h.FacebookAccessToken)
				   ,@isBetaTester = h.IsBetaTester
				   ,@homeKennelId = h.HomeKennelId
				   ,@ThirdPartyForceTokenRefresh = h.ThirdPartyForceTokenRefresh
				   ,@removed = h.removed
				   ,@integrationCount = cte.integrationCount
				   ,@lastIntegrationExecuted = cte.lastIntegrationExecuted
				   ,@integrationStopped = case when datediff(hour,cte.lastIntegrationExecuted,getdate()) > 2 then 1 else 0 end
			from  HC.Hasher h left outer join cte on h.id = cte.hid
			where h.id = @userId


	IF (@removed = 1) 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'Attempt to load a removed user ('+@userName+')',@userName + ' is attempting to launch the app even though the account has been removed',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000',@deviceId,@userId)

		SELECT 
		@errorId as errorId,
		cast (5 as int) as errorType 
		,'This user has been removed' as errorTitle
		,'The user account for "'+@userName+'" has been removed from our servers.~~Please attempt to have a new invite code emailed to you by pressing the ''Email me a new invite code'' text on this screen.~~You can also contact your Kennel''s Harrier Central admin for a new invite code or contact us at connect@harriercentral.com for assistance.' as errorUserMessage
		,'This is a standard error that is anticipated and does not require debugging' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindow) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,cast(@deviceId as nvarchar(40)))

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at connect@harriercentral.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		
		SET @invalidAccessToken = 1
	END

	INSERT HC.LaunchAndLogin 
	(
		UserId
		,UserName
		,HcVersion
		,DeviceType
		,DeviceId
		,DeviceName
		,SystemName
		,SystemVersion
		,Manufacturer
		,Latitude
		,Longitude
		,UsesLocSvcs
		,IpInfo
		,errorInfo
	)
	VALUES
	(
		@userId
		,@userName
		,'HC Ver: '+@hcVersion+', Bld: '+@buildNumber
		,@deviceType
		,@deviceId
		,@deviceName
		,@systemName
		,@systemVersion
		,@manufacturer
		,@latitude
		,@longitude
		,coalesce(@usesLocSvcs,-1)
		,@ipInfo
		,case when @invalidAccessToken != 0 then 'Invalid Access Token' else null end
	)

	IF (@invalidAccessToken != 0) RETURN

	---- This is now obsolete... we only use ThirdPartyToken in HC.Hasher
	---- but leave this in for now.
	--UPDATE HC.Hasher SET 
	--	FacebookAccessToken = @fbToken, 
	--	FacebookAccessTokenLastUpdated = getdate() 
	--FROM HC.Hasher where id = @userId 
	--and FacebookAccessToken != @fbToken

	--UPDATE HC.Hasher SET 
	--	ThirdPartyAccessToken = @fbToken, 
	--	ThirdPartyTokenLastUpdated = getdate(),
	--	ThirdPartyForceTokenRefresh = dateadd(day,30,getdate())
	--FROM HC.Hasher where id = @userId 
	--and ThirdPartyAccessToken != @fbToken

	UPDATE HC.Hasher SET 
		LastLoginDateTime = getdate(),
		HcVersion = @hcVersion
	FROM HC.Hasher where id = @userId 

	IF (@splashSequenceViewed IS NOT NULL)
	BEGIN
		INSERT HC.SplashSequenceViews (SplashSequenceId,UserId,ViewedOn)
		SELECT ss.id,@userId,@splashSequenceViewed 
		FROM HC.SplashSequence ss 
		WHERE ss.SplashSequenceRootName = @splashSequenceRootName
	END

	UPDATE HC.Device SET
		LastLogin = getdate()
		,Latitude = @latitude
		,Longitude = @longitude
		,updatedAt = getdate()
		,BuildNumber = @buildNumber
		,[Version] = @hcVersion
		,Locale = @locale
	WHERE id = @deviceId
	
	-- This is now handled by a trigger on HC.Hasher
	--UPDATE HC.Kennel set KennelFacebookToken = @fbToken, KennelFacebookTokenLastUpdated = getdate() FROM HC.Kennel where KennelFacebookTokenUsername = @email AND KennelFacebookToken != @fbToken

	DECLARE @ServerStatusCode smallint
	DECLARE @LoginMessageTitle nvarchar(120)
	DECLARE @LoginMessage nvarchar(500)
	DECLARE @MessageEndDate datetimeoffset(7)
	DECLARE @MessageDisplayType smallint
	DECLARE @MessageImageUrl nvarchar(500)

	-- Server status codes (to be implemented)
	-- 0 - Server down for maintenance
	-- 1 - Server full up
	-- 2 - Server running degraded

	-- Message display type codes
	-- 0 - None
	-- 1 - Alert
	-- 2 - Full view
	-- 3 - Full view with countdown timer
	-- 4 - Image from URL, do not continue
	-- 5 - Image from URL, allow continue

	-- Approval codes (to be implemented)
	-- 0 - Unknown
	-- 1 - Approved for login
	-- 2 - Not authorized device
	-- 3 - User account does not exist
	-- 4 - User account not authorized

	SELECT TOP 1 
	@ServerStatusCode = smp.ServerStatusCode,
	@LoginMessageTitle = smp.LoginMessageTitle,
	@LoginMessage = smp.LoginMessage,
	@MessageEndDate = smp.MessageWindowCloses,
	@MessageDisplayType = smp.MessageDisplayType,
	@MessageImageUrl = smp.MessageImageUrl
	FROM HC.LoginNotifications smp
	WHERE getdate() between smp.MessageWindowOpens and smp.MessageWindowCloses order by CreatedDate desc

	if (@ServerStatusCode is null) SET @ServerStatusCode = 1
	if (@LoginMessageTitle is null) SET @LoginMessageTitle = 'Harrier Central Message'
	if (@LoginMessage is null) SET @LoginMessage = 'Server running'
	if (@MessageEndDate is null) SET @MessageEndDate = '1/1/2100'
	if (@MessageDisplayType is null) SET @MessageDisplayType = 0
	if (@MessageImageUrl is null) SET @MessageImageUrl = ''

	DECLARE @ApprovalCode int
	SET @ApprovalCode = 1

	SELECT 
		@ThirdPartyForceTokenRefresh = h.ThirdPartyForceTokenRefresh,
		@betaFeaturesEnabled = h.BetaFeaturesEnabled
	FROM HC.Hasher h WHERE h.id = @userId

	-- reset the root name, technically this is not required, but alsways good to clean things up
	SET @splashSequenceRootName = NULL

	DECLARE @splashSequenceType smallint

	-- see if there are any 
	SELECT TOP 1
		@splashSequenceRootName = splash.SplashSequenceRootName,
		@splashSequenceType = splash.SequenceType
	FROM HC.SplashSequence splash 
	LEFT OUTER JOIN HC.SplashSequenceViews splashViews ON splash.id = splashViews.SplashSequenceId AND splashViews.UserId = @userId
	WHERE splash.Removed = 0 
	  AND splashViews.id IS NULL 
	  AND GETDATE() between splash.ValidFromDate and splash.ValidUntilDate
	ORDER BY splash.SequenceType, splash.SequenceOrder

	SELECT TOP 1 
		svr.ApiVersion as apiVersion
		,case when @ServerStatusCode = 1 then @ApprovalCode else 0 end as approvalCode
		,@LoginMessageTitle as loginMessageTitle
		,@LoginMessage as loginMessage
		,@ServerStatusCode as serverStatusCode
		,@MessageEndDate as messageEndDate
		,@MessageDisplayType as messageDisplayType
		,@MessageImageUrl as messageImageUrl
		,svr.IosDownloadLink as iosDownloadLink
		,svr.AndroidDownloadLink as androidDownloadLink
		,svr.ImageRootUrl as imageRootUrl
		,@isBetaTester as isBetaTester
		,@email as email
		,@homeKennelId as homeKennelId
		,@ThirdPartyForceTokenRefresh as thirdPartyForceTokenRefresh
		,0 as integrationCount
		,cast('1/1/2100'as datetime) as lastIntegrationExecuted
		,0 as integrationStopped
		,@splashSequenceRootName as splashSequenceRootName
		,@splashSequenceType as splashSequenceType
		,@betaFeaturesEnabled as betaFeaturesEnabled
		--,coalesce(@integrationCount,0) as integrationCount
		--,coalesce(@lastIntegrationExecuted,cast('1/1/2100' as datetime)) as lastIntegrationExecuted
		--,@integrationStopped as integrationStopped
	FROM HC.ServerStatus svr
	ORDER BY svr.CreatedDate desc

	--;with cte as (
	--SELECT
	--   p.PromotionId,
	--   hpm.id,
	--   ROW_NUMBER() OVER (Order by hpm.updatedAt desc) as rowNumber,
	--   hpm.updatedAt,
	--   hpm.SnoozeUntilDate
	--FROM [HC].[Promotion] p
	--LEFT OUTER JOIN [HC].HasherPromotionMap hpm 
	--on hpm.PromotionId = p.PromotionId AND hpm.UserId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
	--) select 
	--	   p.[PromotionId] as promotionId
 --     ,p.[KennelId] as kennelId
 --     ,p.[CityId] as cityId
 --     ,p.[EventId] as eventId
	--  ,p.[PromoGroupId] as promoGroupId
 --     ,p.[PromoName] as promoName
 --     ,p.[PromoStartDate] as promoStartDate
 --     ,p.[PromoEndDate] as promoEndDate
 --     ,p.[PromoDisplayButtons] as promoDisplayButtons
 --     ,p.[PromoImage] as promoImage
	--  ,p.[PromoImageExtension] as promoImageExtension
	--  ,p.[PromoOverlayTiming] as promoOverlayTiming
 --     ,p.[PromoExternalUrl] as promoExternalUrl
	--  ,p.[PromoExternalUrlButtonText] as promoExternalUrlButtonText
 --     ,p.[PromoPriority] as [promoPriority]
 --     ,p.[PromoLat] as promoLat
 --     ,p.[PromoLon] as promoLon
	--  ,p.[PromoRadius] as promoRadius
 --     ,p.[PromoGeographicScope] as promoGeographicScope
	--  ,p.[PromoDisplayTimeInMs] as promoDisplayTimeInMs
	--  ,p.[PromoDisplayTimingDotsToDisplay] as promoDisplayTimingDotsToDisplay
	--  ,p.[PromoDisplayTimingDotsShape] as promoDisplayTimingDotsShape
	--  ,p.[PromoDisplayTimingDotsSize] as promoDisplayTimingDotsSize
	--  ,p.[PromoImageIsDark] as promoImageIsDark
	--from cte
	--inner join HC.Promotion p on cte.PromotionId = p.PromotionId
	--	where cte.rowNumber = 1 and (cte.SnoozeUntilDate IS NULL OR cte.SnoozeUntilDate < getdate())
	--	and getdate() between p.PromoStartDate and p.PromoEndDate


	/* PromoButtons is a flag field with the following flag values

	const int promoButtonClose = 0x00000001;
	const int promoButtonPermanentlyDismiss = 0x00000002;
	const int promoButtonSnooze = 0x00000004;
	const int promoButtonGoToRun = 0x00000008;
	const int promoButtonLaunchExternalUrl = 0x00000010;

	*/



END
