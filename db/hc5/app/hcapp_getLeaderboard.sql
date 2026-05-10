

CREATE PROCEDURE [HC5].[hcapp_getLeaderboard]

@deviceId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = NULL

AS



-- EXEC HC3.getLeaderboard @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', @accessToken = 'sasdafasf', @kennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'
-- EXEC HC3.getLeaderboard @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', @accessToken = 'sasdafasf'

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

	IF (@userId IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END


	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindow) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,'unknown','Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,'<unknown>')

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at connect@harriercentral.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

IF (@kennelId IS NOT NULL)
	BEGIN

		;WITH cte as (select hkm.userId from HC.HasherKennelMap hkm
			group by hkm.userId
			having max(DateOfLastRun) > dateadd(year,-1,getdate()))
		SELECT 
			   h.DisplayName as a -- displayName
			  ,coalesce(hkm.[HcTotalRunCount],0) + coalesce(hkm.[HistoricalTotalRunCount],0) as b -- totalRunCount
			  ,coalesce(hkm.[HcHaringCount],0) + coalesce(hkm.[HistoricalHaringCount],0) as c -- totalHaringCount
			  ,coalesce(hkm.[YtdTotalRunCount],0) as d -- ytdTotalRunCount
			  ,coalesce(hkm.[YtdHaringCount],0) as e -- ytdHaringCount
			  ,coalesce(hkm.[RollingYearTotalRunCount],0) as f -- rollingYearTotalRunCount
			  ,coalesce(hkm.[RollingYearHaringCount],0) as g -- rollingYearHaringCount
			  ,k.id as h -- kennelId
			  ,h.HomeKennelId as i -- homeKennelId
			  ,hkm.UserId as j -- hasherId
		  FROM [HC].[HasherKennelMap] hkm
		  inner join cte on cte.userId = hkm.userId
		  inner join HC.Hasher h on hkm.UserId = h.id
		  inner join HC.Kennel k on hkm.KennelId = k.id
		  WHERE hkm.KennelId = @kennelId
		  AND hkm.DateOfLastRun is not null
		  AND h.id != k.id
		  AND h.DisplayName not like 'Placeholder user for%'
		  AND h.HashName not like N'👣 Anonymous%'
		  AND k.ExcludeFromLeaderboard = 0
		  --order by hkm.[RollingYearTotalRunCount] desc
	END
ELSE
	BEGIN
		;WITH cte as (select hkm.userId from HC.HasherKennelMap hkm
			group by hkm.userId
			having max(DateOfLastRun) > dateadd(year,-1,getdate()))
		SELECT 
			   h.DisplayName as a -- displayName
			  ,coalesce(hkm.[HcTotalRunCount],0) + coalesce(hkm.[HistoricalTotalRunCount],0) as b -- totalRunCount
			  ,coalesce(hkm.[HcHaringCount],0) + coalesce(hkm.[HistoricalHaringCount],0) as c -- totalHaringCount
			  ,coalesce(hkm.[YtdTotalRunCount],0) as d -- ytdTotalRunCount
			  ,coalesce(hkm.[YtdHaringCount],0) as e -- ytdHaringCount
			  ,coalesce(hkm.[RollingYearTotalRunCount],0) as f -- rollingYearTotalRunCount
			  ,coalesce(hkm.[RollingYearHaringCount],0) as g -- rollingYearHaringCount
			  ,k.id as h -- kennelId
			  ,h.HomeKennelId as i -- homeKennelId
			  ,hkm.UserId as j -- hasherId
		  FROM [HC].[HasherKennelMap] hkm
		  inner join cte on cte.userId = hkm.userId
		  inner join HC.Hasher h on hkm.UserId = h.id
		  inner join HC.Kennel k on hkm.KennelId = k.id
		  WHERE hkm.DateOfLastRun is not null
		  AND h.id != k.id
		  AND h.DisplayName not like 'Placeholder user for%'
		  AND h.HashName not like N'👣 Anonymous%'
		  AND k.ExcludeFromLeaderboard = 0
		  --order by hkm.[RollingYearTotalRunCount] desc
	END


END

