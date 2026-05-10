


CREATE PROCEDURE [HC5].[hcapp_addEditReceipt]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @receiptId uniqueidentifier,
 @eventId uniqueidentifier,
 @receiptShortDesc nvarchar(500),
 @receiptAmount decimal(12,4),
 @notes nvarchar(1000),
 @reimbursedBy uniqueidentifier,
 @reimbursedOn nvarchar(50),
 @reimbursedAmount decimal(12,4),
 @reimbursedNotes nvarchar(1000),
 @imageUrl nvarchar(1000),
 @receiptsUpdatedAfter nvarchar(50),
 @removed smallint

AS

BEGIN

-- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

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

	IF (@removed = -1) SET @removed = NULL
	IF (@reimbursedAmount < 0) SET @reimbursedAmount = NULL
	IF (@reimbursedBy = '00000000-0000-0000-0000-000000000000') SET @reimbursedBy = NULL
	IF (@reimbursedNotes = '') SET @reimbursedNotes = NULL
	IF (@notes = '') SET @notes = NULL
	IF (@receiptAmount < 0) SET @receiptAmount = NULL
	IF (@receiptShortDesc = '') SET @receiptShortDesc = NULL

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
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

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@deviceSecret,@timeWindow) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE 
		@finished smallint,
		@reimbursedOnDate datetimeoffset(7)
		
	SET @reimbursedOnDate = CAST(@reimbursedOn as datetimeoffset(7)) 
	if (@reimbursedOnDate < '1/1/2000') SET @reimbursedOnDate = NULL

	SET @finished = 0
	

	if (datalength(@imageUrl) < 20) SET @imageUrl = NULL
	
	if ((@receiptId IS NOT NULL) AND (@receiptId != '00000000-0000-0000-0000-000000000000'))
	BEGIN
		IF ((@reimbursedBy IS NOT NULL) AND (@reimbursedBy != '00000000-0000-0000-0000-000000000000') AND (@reimbursedBy != 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'))
		BEGIN
			SET @reimbursedOnDate = getdate()
			SELECT @reimbursedAmount = ReceiptAmount from HC.Receipt where id = @receiptId
		END

		if ((SELECT count(*) from HC.Receipt where id = @receiptId) > 0)
		BEGIN
			UPDATE HC.Receipt 
				SET 
					ReceiptAmount = coalesce(@receiptAmount,ReceiptAmount),
					ReceiptShortDesc = coalesce(@receiptShortDesc,ReceiptShortDesc),
					UserId = @userId,
					ImageUrl = coalesce(@imageUrl,ImageUrl),
					removed = coalesce(@removed,removed),
					notes = coalesce(@notes,Notes),
					ReimbursedBy = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedBy,ReimbursedBy) END,
					ReimbursedOn = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedOnDate,ReimbursedOn) END,
					ReimbursedAmount = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedAmount,ReimbursedAmount) END,
					ReimbursedNotes = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedNotes,ReimbursedNotes) END,
					updatedAt = getdate()
				 WHERE id = @receiptId
			SET @finished = 1
		END	
	END

	if (@finished = 0)
	BEGIN
		SET @receiptId = newid()
	
		INSERT HC.Receipt (
			id,
			EventId,
			UserId,
			ReceiptAmount,
			CostCategory,
			DateUploaded,
			ImageUrl,
			ReceiptShortDesc,
			Notes,
			ReimbursedBy,
			ReimbursedOn,
			ReimbursedAmount,
			ReimbursedNotes,
			removed,
			updatedAt
		)
		VALUES (
			@receiptId, 
			@eventId, 
			@userId, 
			@receiptAmount, 
			0, 
			getdate(), 
			@imageUrl,
			@receiptShortDesc,
			@notes,
			@reimbursedBy,
			@reimbursedOnDate,
			@reimbursedAmount,
			@reimbursedNotes,
			@removed,getdate())

	END

		DECLARE @procName nvarchar(500)
		SET @procName = OBJECT_NAME(@@PROCID)

		EXEC HC5.hcapp_syncEventAdminData
		 @deviceId = @deviceId,
		 @accessToken = @accessToken,
		 @eventId = @eventId,
		 @hashersUpdatedAfter = 'ignore',
		 @hasherEventMapUpdatedAfter = 'ignore',
		 @hasherKennelMapUpdatedAfter = 'ignore',
		 @narrowEventsUpdatedAfter = 'ignore',
		 @paymentsUpdatedAfter = 'ignore', 
		 @receiptsUpdatedAfter = @receiptsUpdatedAfter,
		 @procName = @procName,
		 @param = NULL
END





