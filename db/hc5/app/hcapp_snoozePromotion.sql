
CREATE PROCEDURE [HC5].[hcapp_snoozePromotion]

@deviceId uniqueidentifier,
@accessToken nvarchar(1000),
@promotionId uniqueidentifier,
@snoozeUntilDate datetime

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

	DECLARE @errorId uniqueidentifier

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


	--IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	--BEGIN
	--	SET @errorId = newid()

	--	INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,'','Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,'')

	--	select 
	--	@errorId as errorId,
	--	cast (1 as int) as errorType 
	--	,'Invalid access token' as errorTitle
	--	,'A security safety feature has been activated. Contact the Harrier Central support team at harriercentral@gmail.com to resolve the issue.' as errorUserMessage
	--	,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--	RETURN
	--END

	INSERT INTO [HC].[HasherPromotionMap]
           ([UserId]
           ,[PromotionId]
           ,[SnoozeUntilDate]
           )
     VALUES
           (
			@userId,
			@promotionId,
			@snoozeUntilDate
		   )

END
