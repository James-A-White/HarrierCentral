CREATE PROCEDURE [HC5].[hcapp_getMyKennelRunTotals]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000'

AS

BEGIN

	--EXEC HC5.hcapp_getMyKennelRunTotals @deviceId = '723BB72E-3737-4B53-A3A9-D5B812AD930C',@accessToken = 'not needed for testing'

	SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindows int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindows = d.TimeWindow
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

	IF (HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindows) = 0)
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

	if @kennelId = '00000000-0000-0000-0000-000000000000' SET @kennelId = NULL

	;WITH cte AS (
	SELECT 
		ROW_NUMBER() OVER (ORDER BY count(CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE NULL END) DESC) as rowNum,
		evt.KennelId, 
		k.KennelLogo, 
		k.KennelName,
		count(CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE NULL END) as totalRunsThisKennel, 
		count(CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE NULL END) - count(CASE WHEN hem.IsHare != 0 THEN 1 ELSE NULL END) as totalPackRunsThisKennel,
		count(CASE WHEN hem.IsHare != 0 THEN 1 ELSE NULL END) as totalHaringThisKennel,
		coalesce(hkm.[Following],0) as [following],
		k.kennelShortName
	FROM HC.HasherEventMap hem
	INNER JOIN HC.Event evt on hem.EventId = evt.id
	INNER JOIN HC.Kennel k on evt.KennelId = k.id
	LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId AND hkm.KennelId = k.id
	WHERE hem.UserId = @userId AND (@kennelId IS NULL OR k.id = @kennelId) AND evt.IsCountedRun = 1 AND evt.IsVisible = 1
	GROUP BY evt.KennelId,k.KennelLogo,k.KennelName,k.KennelShortName,coalesce(hkm.[Following],0)) 
	SELECT * into #temp from cte where totalRunsThisKennel > 0 ORDER BY totalRunsThisKennel desc

	INSERT #temp (
				rowNum,
				KennelId,
				KennelLogo,
				KennelName,
				totalRunsThisKennel,
				totalPackRunsThisKennel,
				totalHaringThisKennel,
				following,
				KennelShortName
			)
	SELECT	0,
			cast('00000000-0000-0000-0000-000000000000' as uniqueidentifier),
			'<no logo>',
			'GRAND TOTAL ALL KENNELS',
			sum(totalRunsThisKennel),
			sum(totalPackRunsThisKennel),
			sum(totalHaringThisKennel),
			0,
			'TOTALS'
			FROM #temp

	SELECT 
		KennelId,
		KennelLogo,
		KennelName,
		totalRunsThisKennel,
		totalPackRunsThisKennel,
		totalHaringThisKennel,
		following,
		KennelShortName
	from #temp order by rowNum
	
	DROP TABLE #temp
END
	

  
