CREATE PROCEDURE [HC5].[hcapp_getEventMessageCounts]

-- required parameters
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL


-- EXEC [HC5].[hcportal_getEventMessages] @hasherId ='B6BAFD0D-5D2E-41CD-8495-811D551F01D0', @accessToken = 'not required', @eventId = 'BFBB5280-A1C8-48CF-9DE2-E563E5F944F2'

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @hasherId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int,
			@publicHasherId uniqueidentifier


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
		@timeWindow = d.TimeWindow,
		@publicHasherId = h.PublicHasherId
	FROM HC.Device d 
	INNER JOIN HC.Hasher h on d.UserId = h.id
	where d.id = @deviceId


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

	IF (HC.CHECK_ACCESS_TOKEN_V2(@hasherId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret, @timeWindow) = 0) AND (@isError = 0) 
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

	--DECLARE @hasherId2 as uniqueidentifier = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'

	---- Start by getting all of the event message counts for future events where the user is following the Kennel or a member of the Kennel
	--SELECT 
	--	evt.id,
	--	evt.PublicEventId,
	--	(SELECT COUNT(*) FROM HC.EventMessage em WHERE em.EventId = evt.id and em.PublicHasherId != @publicHasherId) AS EventChatMessageCount
	--FROM HC.HasherKennelMap hkm
	--INNER JOIN HC.Event evt ON evt.KennelId = hkm.KennelId
	--WHERE hkm.UserId = @hasherId
	--  AND (hkm.MembershipExpirationDate > GETDATE() OR hkm.Following = 1)
	--  AND evt.EventStartDatetime > DATEADD(year, -1, GETDATE())
	--  AND EXISTS (
	--	  SELECT 1 
	--	  FROM HC.EventMessage em 
	--	  WHERE em.EventId = evt.id
	--	)
	--UNION
	---- Union that with future events that the user has attended or RSVP'ed to
	--SELECT 
	--	evt.id,
	--	evt.PublicEventId,
	--	(SELECT COUNT(*) FROM HC.EventMessage em WHERE em.EventId = evt.id and em.PublicHasherId != @publicHasherId) AS EventChatMessageCount
	--	FROM HC.HasherEventMap hem
	--	INNER JOIN HC.Event evt on hem.EventId = evt.id
	--	WHERE hem.UserId = @hasherId
	--	AND evt.EventStartDatetime > DATEADD(year, -1, GETDATE())
	--	AND (hem.RsvpState >= 2 OR hem.AttendenceState >= 20)
	--	AND EXISTS (
	--	  SELECT 1 
	--	  FROM HC.EventMessage em 
	--	  WHERE em.EventId = evt.id
	--	)

		SELECT 
			em.EventId as id,
			em.PublicEventId,
			MAX(em.MessageSequenceCount)-embc.LastSequenceCount as EventChatMessageCount
			FROM HC.EventMessage em
			INNER JOIN HC.Hasher h on em.UserId = h.id
			INNER JOIN HC.EventMessageBadgeCounts embc on embc.EventId = em.EventId AND embc.UserId = h.id
			WHERE h.PublicHasherId = @publicHasherId
			GROUP BY em.eventId, em.PublicEventId, embc.LastSequenceCount


END	




