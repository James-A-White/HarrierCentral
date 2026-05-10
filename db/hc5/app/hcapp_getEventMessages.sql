CREATE PROCEDURE [HC5].[hcapp_getEventMessages]

-- required parameters
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@eventId uniqueidentifier = NULL


-- EXEC [HC5].[hcportal_getEventMessages] @hasherId ='B6BAFD0D-5D2E-41CD-8495-811D551F01D0', @accessToken = 'not required', @eventId = 'BFBB5280-A1C8-48CF-9DE2-E563E5F944F2'

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @hasherId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int


	DECLARE @errorId uniqueidentifier
	DECLARE @isError smallint = 0
	DECLARE @errorTitle nvarchar(500) = ''

	IF (@deviceId IS NULL) OR (datalength(@deviceId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid hasherId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName) VALUES (@errorId,'<unknown>','Null or empty deviceId','Null or empty deviceId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID))
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'Null or empty value was passed as the deviceId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END

	SELECT 
		@hasherId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	IF (@eventId IS NULL) OR (datalength(@eventId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid eventId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','Null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'Null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END


	IF (@hasherId IS NULL) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'No record found with provided @hasherId'
		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','No record found with provided @hasherId','@hasherId was not found by ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,@errorTitle as errorTitle
		,'@hasherId was not found by'+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
	END

	IF (HC.CHECK_ACCESS_TOKEN_V2(@hasherId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret + cast(@eventId as nvarchar(50)), @timeWindow) = 0) AND (@isError = 0) 
	BEGIN
		SET @errorId = newid()
		SET @errorTitle = 'Invalid access token'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@hasherId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,@errorTitle as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		SET @isError = 1
	END

	if (@isError = 1)
	BEGIN
		RETURN
	END

	SELECT 
		msg.id AS [id],
		'text' AS [type],
		msg.MessageContent AS [text],
		msg.PublicEventId as roomId,
		DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt) AS [createdAt],

		    JSON_QUERY(
        CASE 
            WHEN h.id IS NOT NULL 
            THEN (
                SELECT 
				h.PublicHasherId AS [id],
				h.DisplayName AS [firstName],
				h.Photo AS [imageUrl]
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) 
            ELSE NULL 
        END
    ) AS [author]

	FROM HC.EventMessage msg
	INNER JOIN HC.Hasher h on msg.UserId = h.id
	WHERE msg.EventId = @eventId
	ORDER BY createdAt desc
	

END	

