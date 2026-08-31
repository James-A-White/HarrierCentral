
CREATE PROCEDURE [HC5].[hcapp_processPayment]

@deviceId uniqueidentifier,
@accessToken nvarchar(1000),
@userIdWhoPaid uniqueidentifier = NULL,
@eventId uniqueidentifier,
@hasherEventMapId uniqueidentifier = NULL,
@paymentType smallint,
@productType smallint = 1,
@paymentAmount decimal(12,6) = NULL,
@minimumAttendenceValue smallint = NULL,

@hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
@hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
@paymentsUpdatedAfter nvarchar(50) = 'ignore',
@kennelCreditsUpdatedAfter nvarchar(50) = 'ignore',
@doPayForExtras smallint = 0,
@surcharge decimal(10,4) = NULL,
@paymentProvider nvarchar(50) = NULL,
@appDomainType nvarchar(50) = 'AppDomainType.event',
@paymentReference nvarchar(50) = NULL,
@transactionTimestamp nvarchar(50) = NULL,
@specialRunPrice smallmoney = NULL,
@specialRunPriceReason nvarchar(50) = NULL,
@useSpecialPriceAsDefault smallint = NULL

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

	DECLARE @userId uniqueidentifier,
			@deviceSecret nvarchar(150),
			@timeWindow int

	SELECT 
		@userId = d.UserId,
		@deviceSecret = upper(d.DeviceSecret),
		@timeWindow = d.TimeWindow
	FROM HC.Device d where d.id = @deviceId

	IF (@productType is null) SET @productType = 1
	IF (@doPayForExtras is null) SET @doPayForExtras = 0

	DECLARE @paramString nvarchar(500)

	SET @paramString = @deviceSecret + cast(coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(coalesce(@userIdWhoPaid,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(cast(@paymentAmount as int) as nvarchar(50)) + '#' + cast(@eventId as nvarchar(50))
	--SET @paramString = ''

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
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
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
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
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
	--	,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--	RETURN
	--END

	DECLARE @serverMessage nvarchar(120)

	IF (((@paymentAmount IS NULL) OR (@paymentAmount < 0)) AND (@paymentType < 100))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or negative payment amount','A null or negative payment amount was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or negative payment amount' as errorTitle
		,'A null or negative value was passed as the payment amount to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at harriercentral@gmail.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN_V2(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString,@timeWindow) = 0 
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

	DECLARE @kid uniqueidentifier
	SELECT @kid = KennelId from HC.Event where id = @eventId

	IF ((@hasherEventMapId IS NOT NULL) AND ((@userIdWhoPaid is null) OR (@userIdWhoPaid = '00000000-0000-0000-0000-000000000000')))
	BEGIN
		SELECT @userIdWhoPaid = UserId from HC.HasherEventMap where id = @hasherEventMapId and removed = 0
	END

	-- this is for payment confirmation where the wankerBanker is verifying
	-- that a bank transfer payment was actually received
	if (@paymentType = 100)
	BEGIN
		UPDATE HC.Payment SET ConfirmedDate = GETDATE(), ConfirmedBy_UserId = @userId, updatedAt = GETDATE() WHERE HasherEventMapId = @hasherEventMapId AND CancelledDate is null
	END
	ELSE
	BEGIN
			if (@minimumAttendenceValue < 0) SET @minimumAttendenceValue = NULL

			if ((@hasherEventMapId is null) OR (@hasherEventMapId = '00000000-0000-0000-0000-000000000000'))
			BEGIN
				SELECT @hasherEventMapId = id FROM HC.HasherEventMap hem where hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId


				IF ((@hasherEventMapId is null) OR (@hasherEventMapId = '00000000-0000-0000-0000-000000000000'))
				BEGIN

					SET @hasherEventMapId = newid()

					INSERT HC.HasherEventMap 
					(
						id,
						UserId,
						EventId,
						KennelId,
						RsvpState,
						Rsvp,
						UserStartEvent,
						AttendenceState,
						updatedAt
					) 
					VALUES 
					(
						@hasherEventMapId,
						@userIdWhoPaid,
						@eventId,
						@kid,
						3,
						getdate(),
						getdate(),
						coalesce(@minimumAttendenceValue,0),
						getdate()
					)
				END
			END

			DECLARE
				 @eventPrice money,
				 @originalEventPrice money,
				 @extrasPrice money,
				 @creditAmount money,
				 @debitAmount money,
				 @kennelId uniqueidentifier,
				 @kennelName nvarchar(250),
				 @payer_userIdGuid uniqueidentifier,
				 @attendenceState int,
				 @payer_userName nvarchar(120),
				 @discountAmount smallmoney,
				 @discountPercent smallint,
				 @discountDescription nvarchar(50),
				 @paymentExists int

			SELECT @paymentExists = COUNT(*) FROM HC.Payment p where p.HasherEventMapId = @hasherEventMapId AND p.CancelledDate IS NULL

			SELECT
			@originalEventPrice = CASE WHEN coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
			,@extrasPrice = CASE WHEN @doPayForExtras = 1 THEN coalesce(e.EventPriceForExtras,0) ELSE 0 END
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
			
			SET @eventPrice = @eventPrice + @extrasPrice

			if ((@paymentType = 1) AND (@paymentExists > 0)) -- handle the 'Not paid' case
			BEGIN
				UPDATE HC.Payment SET IsCancelled = 1, CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
			END

			IF (@paymentType = 2) 
			BEGIN
				SET @eventPrice = @extrasPrice -- in this case the run is "free", extras will be zero unless the @doPayForExtras flag is set, we still charge for extras even if the run is free
			END

			IF ((@paymentType >= 2) AND (@paymentType <= 8)) -- in this case the run is paid in cash, bank transfer or using credits or was free
			BEGIN

				-- set the track Hash Cash flag. This should only perform an update the first time a transaction is made.
				UPDATE HC.Event SET DoTrackHashCash = 1 FROM HC.Event e WHERE e.id = @eventId AND DoTrackHashCash != 1
				
				DECLARE @count int
				SET @count = 1
				IF (@paymentReference IS NULL) SET @paymentReference = 'HC:'+HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				
				-- loop until there are no duplicates
				WHILE (@count > 0)
				BEGIN
					SELECT @count = COUNT(*) FROM HC.Payment WHERE PaymentReference = @paymentReference
					IF (@count > 0) SET @paymentReference = LEFT(@paymentReference,3)+ HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				END
		
				
				IF ((@paymentType = 5) OR (@paymentType = 7) OR (@paymentType = 8))
				BEGIN
					-- in these three cases the user is paying 'other amount' by cash (@paymentType = 5) or bank transfer (@paymentType = 7) or credit (@paymentType = 8)
					
					SET @creditAmount = @paymentAmount
					
					IF (@specialRunPrice IS NOT NULL)
						BEGIN
							SET @debitAmount = @specialRunPrice
							IF ((@useSpecialPriceAsDefault != 0) AND (@userIdWhoPaid is not null))
							BEGIN
								SELECT @discountAmount = @originalEventPrice - @specialRunPrice,
									@discountPercent = 0,
									@discountDescription = coalesce(@specialRunPriceReason,'')
									
								UPDATE HC.HasherKennelMap 
									SET
										DiscountAmount = @discountAmount,
										DiscountPercent = 0,
										DiscountDescription = @discountDescription,
										updatedAt = getdate()
									WHERE userId = @userIdWhoPaid AND KennelId = @kid

							END
						END
					ELSE
						BEGIN
							SET @debitAmount = @eventPrice
						END
				END
				ELSE
				BEGIN
					-- otherwise for other payment scenarios, the credit amount is equal to the event type
					SET @creditAmount = @eventPrice
					SET @debitAmount = @eventPrice
				END

				IF ((@paymentType = 6) OR (@paymentType = 8)) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'

				if (@paymentExists > 0)
				BEGIN
					-- We only allow one payment per event, so cancel any previous payments when a new payment comes in for an event that is of type "free", "cash", "bank transfer", or "credit"
					UPDATE HC.Payment SET IsCancelled = 1, CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
				END

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
					@doPayForExtras, 
					@paymentProvider, 
					@discountAmount,
					@discountPercent,
					@discountDescription,
					coalesce(@specialRunPriceReason,''),
					coalesce(@surcharge,0), 
					getdate()
				)


				-- if they have paid, mark them as being at the event.
				UPDATE HC.HasherEventMap set UserStartEvent = getdate(), RsvpState = 3, AttendenceState = CASE when AttendenceState < @minimumAttendenceValue then @minimumAttendenceValue else AttendenceState end, updatedAt = getdate() where id = @hasherEventMapId

				SELECT @attendenceState = CASE WHEN coalesce(@attendenceState,0) < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE @attendenceState END


			END

			-- NOTE: this stored proc now updates the HKM record to reflect the 
			-- current amount of credit available to the Hasher
			EXEC HC.nonApi_updateKennelCreditByUser @userId = @payer_userIdGuid, @kennelId = @kennelId

			DECLARE @creditAvailable smallmoney

			SELECT @creditAvailable = hkm.KennelCredit FROM HC.HasherKennelMap hkm where hkm.UserId = @payer_userIdGuid and hkm.KennelId = @kennelId
			
			--SELECT @creditAvailable = SUM(pay.creditAmount) - SUM(pay.debitAmount) FROM HC.Payment pay WHERE pay.KennelId = @kennelId AND pay.UserId = @payer_userIdGuid AND pay.CancelledDate IS NULL AND pay.PaymentType BETWEEN 5 AND 8
			--if (@creditAvailable IS NOT NULL)
			--	BEGIN
			--		DECLARE @latestEventId uniqueidentifier
			--		SELECT top 1 @latestEventId = hem.EventId from HC.HasherEventMap hem 
			--		INNER JOIN HC.Event evt on hem.EventId = evt.id and hem.UserId = @payer_userIdGuid
			--		WHERE evt.KennelId = @kennelId AND hem.AttendenceState >= 20
			--		ORDER BY evt.EventStartDatetime desc

			--		MERGE HC.KennelCredit AS [Target] 
			--		USING (SELECT @payer_userIdGuid AS userId, @kennelId AS kennelId) AS [Source] ON [Target].kennelId = [Source].kennelId AND [Target].userId = [Source].userId 
			--		WHEN MATCHED THEN UPDATE SET [Target].currentBalance = @creditAvailable, [Target].balanceAsOfEventId = @eventId, [Target].updatedAt = getdate() 
			--		WHEN NOT MATCHED THEN INSERT (userId, kennelId,currentBalance,balanceAsOfEventId,updatedAt) VALUES (@payer_userIdGuid, @kennelId,@creditAvailable,@latestEventId,getdate());
						
			--		UPDATE hkm 
			--		SET 
			--			KennelCredit = @creditAvailable,
			--			updatedAt = getdate()
			--		FROM HC.HasherKennelMap hkm where hkm.UserId = @payer_userIdGuid and hkm.KennelId = @kennelId

			--	END
			--ELSE
			--	BEGIN
			--		UPDATE HC.KennelCredit SET currentBalance = 0, balanceAsOfEventId = @eventId, updatedAt = GETDATE() FROM HC.KennelCredit kc WHERE kc.userId = @payer_userIdGuid and kc.kennelId = @kennelId
			--	END



			IF (@userIdWhoPaid IS NOT NULL)
				BEGIN
					EXEC HC.nonApi_updateRunCountsByUser @userId = @userIdWhoPaid
				END
			-- I don't think this is needed because this only applies to visitors and virgins and we don't track run counts
			--ELSE
			--	BEGIN
			--		EXEC HC.nonApi_adjustHasherRunCounts @hasherEventMapId = @hasherEventMapId
			--	END
	END


	-- send back adHoc data to support cases when the user was scanned in at a Hash
	SELECT
		1 as adHocDataId,
		@payer_userName as hasherWhoPaid,
		@attendenceState as attendenceState,
		3 as rsvpState,
		@paymentType as paymentType,
		@productType as productType,
		@eventPrice as debitAmount,
		@creditAmount as creditAmount,
		@paymentAmount as paymentAmount,
		@creditAvailable as creditAvailable,
		@paymentReference as paymentReference,
		@discountAmount as discountAmount,
		@discountPercent as discountPercent,
		@discountDescription as discountDescription

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)

	if (@appDomainType = 'AppDomainType.event')
		BEGIN
			EXEC HC5.hcapp_syncEventAdminData 
				@deviceId = @deviceId,
				@accessToken = @accessToken,
				@eventId = @eventId,
				@hashersUpdatedAfter = 'ignore',
				@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
				@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
				@narrowEventsUpdatedAfter = 'ignore',
				@paymentsUpdatedAfter = @paymentsUpdatedAfter,
				@kennelCreditsUpdatedAfter = @kennelCreditsUpdatedAfter,
				@receiptsUpdatedAfter = 'ignore',
				@procName = @procName,
				@param = @paramString
		END
	ELSE
		BEGIN
			EXECUTE [HC5].[hcapp_syncUserData] 
			   @deviceId = @deviceId
			  ,@accessToken = @accessToken
			  ,@hashersUpdatedAfter = 'ignore'
			  ,@citiesUpdatedAfter = 'ignore'
			  ,@regionsUpdatedAfter = 'ignore'
			  ,@countriesUpdatedAfter = 'ignore'
			  ,@kennelsUpdatedAfter = 'ignore'
			  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
			  ,@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter
			  ,@narrowEventsUpdatedAfter = 'ignore'
			  ,@paymentsUpdatedAfter = @paymentsUpdatedAfter
			  ,@procName = @procName
			  ,@param = @paramString
		END

END
