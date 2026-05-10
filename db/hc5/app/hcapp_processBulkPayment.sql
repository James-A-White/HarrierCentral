
CREATE PROCEDURE [HC5].[hcapp_processBulkPayment]

@deviceId uniqueidentifier,
@accessToken nvarchar(1000),
@userIdsWhoPaid varchar(8000) = NULL,
@eventId uniqueidentifier,
@paymentType smallint,
@productType smallint = 1,
@hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
@hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
@paymentsUpdatedAfter nvarchar(50) = 'ignore',
@transactionTimestamp nvarchar(50) = NULL

AS

BEGIN

-- payment type codes:
--    1 = not paid
--    2 = free run
--    3 = cash
--    4 = bank transfer
--    5 = cash (other amount)
--    6 = hash credit
--    7 = bank transfer (other amount)
--	100 = confirm bank transfer

-- product type codes:
--	  1 = event
--    2 = membership
--    3 = haberdashery

-- doPayForExtras:
--    0 = payForRunOnly
--    1 = payForRunAndExtras

-- exec HC.payForEvent @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @hasherEventMapId = '0bc3a6ea-0e9f-432e-acb0-079c1557f004', @paymentType = 3

SET NOCOUNT ON

	DECLARE @queryStart datetime = getdate()

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	IF (@productType is null) SET @productType = 1

	DECLARE @errorId uniqueidentifier

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

	IF ((@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000') AND (@productType = 1))
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

	--IF (@userIdWhoPaid IS NULL) OR (@userIdWhoPaid = '00000000-0000-0000-0000-000000000000')
	--BEGIN

	--	SET @errorId = newid()

	--	INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty userIdWhoPaid','A null or empty userIdWhoPaid was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
	--	SELECT 
	--	@errorId as errorId,
	--	cast (2 as int) as errorType 
	--	,'Null or empty userIdWhoPaid' as errorTitle
	--	,'A null or empty value was passed as the userIdWhoPaid to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
	--	,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--	RETURN
	--END

	DECLARE @serverMessage nvarchar(120)



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

	DECLARE @kennelId uniqueidentifier,
			@eventDate datetime,
			@eventName nvarchar(1000),
			@memberPrice money,
			@nonMemberPrice money

	SELECT 
		 @kennelId = evt.KennelId
		,@eventDate = evt.EventStartDatetime
		,@eventName = evt.EventName
		,@memberPrice = evt.EventPriceForMembers
		,@nonMemberPrice = evt.EventPriceForNonMembers
	FROM HC.Event evt where evt.id = @eventId

	DECLARE @updatedRowCount int,
			@insertedRowCount int


		;WITH ParsedGuids AS (
    SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
    FROM STRING_SPLIT(@userIdsWhoPaid, ',')
    WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
	)
	SELECT UserId 
	INTO #tempHashers
	FROM ParsedGuids

	-- Start with upserting the HEM records


	UPDATE hem SET 
			hem.AttendenceState = 20, -- assume this is check in at the start of the run
			hem.RsvpState = 3,
			hem.updatedAt = getdate()
		FROM HC.HasherEventMap hem inner join #tempHashers pg on pg.UserId = hem.UserId
		WHERE hem.EventId = @eventId
		
	SET @updatedRowCount = @@ROWCOUNT

	INSERT INTO [HC].[HasherEventMap]
				([id]
				,[EventId]
				,[KennelId]
				,[UserId]
				,[AttendenceState]
				,[RsvpState]
				,[IsHare]
				,[VirginVisitorType]
				,[updatedAt])

	SELECT 
		newid(),
		@eventId,
		@kennelId,
		pg.UserId,
		20, -- assume this is a check in at the beginning of the run,
		3, -- RSVP state is always 3 with a bulk update
		0, -- IsHare is always 0 with a bulk import
		0, -- VirginVisitorType is always 0 with a bulk import
		getdate()
	FROM #tempHashers pg left outer join HC.HasherEventMap hem on hem.UserId = pg.UserId AND hem.EventId = @eventId
	WHERE hem.id IS NULL

	SET @insertedRowCount = @@ROWCOUNT

	-- Now set the payment records

	-- set the track Hash Cash flag. This should only perform an update the first time a transaction is made.
	UPDATE HC.Event SET DoTrackHashCash = 1 FROM HC.Event e WHERE e.id = @eventId AND DoTrackHashCash != 1

	-- Start by cancelling any transactions that have already been registered for this event and these hashers
	UPDATE pay SET 
			pay.CancelledBy_UserId = @userId,
			pay.CancelledDate = getdate(),
			pay.isCancelled = 1,
			pay.updatedAt = getdate()
		FROM HC.Payment pay inner join #tempHashers pg on pg.UserId = pay.UserId
		WHERE pay.EventId = @eventId AND pay.CancelledDate IS NULL


	-- set the track Hash Cash flag. This should only perform an update the first time a transaction is made.
	UPDATE HC.Event SET DoTrackHashCash = 1 FROM HC.Event e WHERE e.id = @eventId AND DoTrackHashCash != 1

	DECLARE @hasherId uniqueidentifier,
			@hasherEventMapId uniqueidentifier,
			@eventPrice money,
			@originalEventPrice money,
			@creditAmount money,
			@debitAmount money,
			@kennelName nvarchar(250),
			@payer_userIdGuid uniqueidentifier,
			@attendenceState int,
			@payer_userName nvarchar(120),
			@discountAmount smallmoney,
			@discountPercent smallint,
			@discountDescription nvarchar(50),
			@paymentReference nvarchar(50)


	DECLARE hasherPayCursor CURSOR FOR
	SELECT t.userId, hem.id
	FROM #tempHashers t
	INNER JOIN HC.HasherEventMap hem on hem.UserId = t.UserId AND hem.EventId = @eventId

	OPEN hasherPayCursor;

	FETCH NEXT FROM hasherPayCursor INTO @hasherId, @hasherEventMapId

	-- 5. Loop through the rows
	WHILE @@FETCH_STATUS = 0
	BEGIN

			
			SELECT
			@originalEventPrice = CASE WHEN coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
			
			,@kennelId = k.id
			,@kennelName = coalesce(k.KennelShortName,k.KennelName,'<No kennel name>')
			,@payer_userIdGuid = hem.UserId
			,@attendenceState = hem.AttendenceState
			,@eventId = coalesce(@eventId,e.id)
			,@payer_userName = coalesce(CASE 
				WHEN (h.NameDisplayPreference = 1 AND datalength(h.HashName) > 0)
					THEN h.HashName
				WHEN (h.NameDisplayPreference = 2 OR datalength(h.HashName) = 0)
					THEN h.FirstName + ' ' + h.LastName
				ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
				END,hem.DisplayName,'<no name>')
			,@discountAmount = coalesce(hkm.DiscountAmount,0)
			,@discountPercent = coalesce(hkm.DiscountPercent,0)
			,@discountDescription = coalesce(hkm.DiscountDescription,'')
			FROM HC.HasherEventMap hem
			INNER JOIN HC.Event e ON e.id = hem.EventId
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			LEFT OUTER JOIN HC.HasherKennelMap hkm on hem.UserId = hkm.UserId AND hkm.KennelId = e.kennelId
			LEFT OUTER JOIN HC.Hasher h on h.id = hem.UserId
			WHERE hem.id = @hasherEventMapId --AND e.deleted = 0 AND e.IsVisible <> 0

			-- Apply any applicable discounts
			SET @eventPrice = @originalEventPrice - @discountAmount
			SET @eventPrice = @eventPrice - (@eventPrice * (@discountPercent / 100.0))

			IF ((@paymentType >= 2) AND (@paymentType <= 8)) -- in this case the run is paid in cash, bank transfer or using credits or was free
			BEGIN
				
				DECLARE @count int
				SET @count = 1
				IF (@paymentReference IS NULL) SET @paymentReference = 'HC:'+HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				
				-- loop until there are no duplicates
				WHILE (@count > 0)
				BEGIN
					SELECT @count = COUNT(*) FROM HC.Payment WHERE PaymentReference = @paymentReference
					IF (@count > 0) SET @paymentReference = LEFT(@paymentReference,3)+ HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				END
		
				SET @creditAmount = @eventPrice
				SET @debitAmount = @eventPrice
				

				IF ((@paymentType = 6) OR (@paymentType = 8)) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'

				-- Now insert a new payment record
				INSERT HC.Payment 
				(
					KennelId, 
					UserId, 
					EventId, 
					HasherEventMapId, 
					CreditAmount,
					DebitAmount,
					CreditAvailable,
					PaymentProcessedBy_userId,
					PaidDate, 
					PaymentType, 
					ProductType, 
					PaymentReference, 
					DoPayForExtras, 
					PaymentProvider, 
					DiscountAmount,
					DiscountPercent,
					DiscountDescription,
					SpecialRunPriceReason,
					Surcharge, 
					updatedAt
				) 
				VALUES (
					@kennelId,
					@payer_userIdGuid,
					@eventId,
					@hasherEventMapId,
					@creditAmount, -- this is what the Hasher paid
					@debitAmount, -- this is what the Hasher owes for this event
					0,
					@userId,
					coalesce(cast(left(@transactionTimestamp,23) as datetime),GETDATE()),
					@paymentType, 
					@productType, 
					@paymentReference,
					0,  -- DoPayForExtras
					'', 
					@discountAmount,
					@discountPercent,
					@discountDescription,
					'', -- SpecialPriceReason
					0, -- Surcharge, 
					getdate()
				)

			END

			-- NOTE: this stored proc now updates the HKM record to reflect the 
			-- current amount of credit available to the Hasher
			EXEC HC.nonApi_updateKennelCreditByUser @userId = @payer_userIdGuid, @kennelId = @kennelId
			

		-- Fetch the next row
		FETCH NEXT FROM hasherPayCursor INTO @hasherId, @hasherEventMapId
	END

	-- 6. Clean up
	CLOSE hasherPayCursor;
	DEALLOCATE hasherPayCursor;

	EXEC HC.nonApi_updateRunCountsForAllUsers @updatedSince = @queryStart
	
	DROP TABLE #tempHashers

	SELECT
	1 as adHocDataId
	,cast(@updatedRowCount as nvarchar(10)) + ' records updated, ' + cast(@insertedRowCount as nvarchar(10)) + ' records inserted, '  as serverMessage

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)

	EXEC HC5.hcapp_syncEventAdminData 
		@deviceId = @deviceId,
		@accessToken = @accessToken,
		@eventId = @eventId,
		@hashersUpdatedAfter = 'ignore',
		@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
		@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
		@narrowEventsUpdatedAfter = 'ignore',
		@paymentsUpdatedAfter = @paymentsUpdatedAfter,
		@kennelCreditsUpdatedAfter = 'ignore',
		@receiptsUpdatedAfter = 'ignore',
		@procName = @procName,
		@param = @deviceSecret
	
	

END
