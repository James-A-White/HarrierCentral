
CREATE PROCEDURE [HC5].[hcapp_getPaymentReport]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000'

AS

BEGIN

	--EXEC HC5.hcapp_getPaymentReport @deviceId = '723BB72E-3737-4B53-A3A9-D5B812AD930C', @accessToken = 'not required for testing', @eventId = 'AE3974C4-2641-49E2-B1BA-1B7F24B88D09'

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

	SET NOCOUNT ON

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

	select 
		hem.id as hemId,
		hem.UserId as userId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	
			ELSE 
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy
	into #tempHashersNotPaid
	from HC.HasherEventMap hem 
		left outer join HC.Hasher paidBy on hem.UserId = paidBy.id
	where @eventId is not null
	-- only look at people who are actually at the event
	and hem.EventId = @eventId and hem.AttendenceState >= 20 
	-- and remove any records where the user has paid
	and hem.id not in (select pay2.HasherEventMapId from HC.Payment pay2 where pay2.EventId = @eventId and pay2.PaymentType >= 2 and pay2.CancelledBy_UserId is null)
	
	
	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as creditAvailable
			,hnp.userId
			,hnp.hemId
			,hnp.paidBy
			,case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end as eventPrice
			,coun.CurrencySymbol
			,coun.DigitsAfterDecimal
	INTO #creditTemp
	FROM #tempHashersNotPaid hnp
	INNER JOIN HC.Event evt on evt.id = @eventId
	INNER JOIN HC.Kennel ken on ken.id = evt.KennelId
	INNER JOIN HC.Country coun on ken.CountryId = coun.id
	--INNER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.Payment p on p.UserId = hnp.userId and p.CancelledDate is null
	GROUP BY hnp.userId,hnp.hemId, hnp.paidBy, 
	case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end,
	coun.CurrencySymbol,
	coun.DigitsAfterDecimal

	declare @hashersNotPaidCount nvarchar(20)
	select @hashersNotPaidCount = cast(count(*) as nvarchar(20)) from #tempHashersNotPaid


select * from (
	select 
		pay.HasherEventMapId as hasherEventMapId,
		pay.UserId as userIdWhoPaid,
		pay.id as paymentId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	ELSE
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy, 
		coalesce(paidTo.DisplayName,'<user deleted>') as paidTo, 
		cancelledBy.DisplayName as cancelledBy, 
		pay.CreditAmount as creditAmount, 
		pay.DebitAmount as debitAmount, 
		pay.PaymentType as paymentType,
		pay.PaidDate as paymentDate,
		pay.CancelledDate as cancelledDate,
		pay.PaymentReference as paymentReference,
		pay.Notes as notes,
		pay.CreditAvailable as creditRemaining,
		coun.CurrencySymbol as currencySymbol,
		coun.DigitsAfterDecimal as digitsAfterDecimal
	from HC.Payment pay 
		inner join HC.HasherEventMap hem on hem.id = pay.HasherEventMapId
		inner join HC.Event evt on pay.EventId = evt.id
		inner join HC.Kennel k on k.id = evt.KennelId
		inner join HC.Country coun on coun.id = k.CountryId
		left outer join HC.Hasher paidBy on pay.UserId = paidBy.id
		left outer join HC.Hasher paidTo on pay.PaymentProcessedBy_userId = paidTo.id
		left outer join HC.Hasher cancelledBy on pay.CancelledBy_UserId = cancelledBy.id
	where 
		 pay.EventId = @eventId
		AND pay.CancelledBy_UserId is null


	union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide records of Hashers at events that have not paid yet

		select 
		t.hemId as hasherEventMapId,
		t.userId as userIdWhoPaid,
		null as paymentId,
		t.paidBy as paidBy, 
		'none' as paidTo, 
		null as cancelledBy, 
		0 as creditAmount, 
		eventPrice as debitAmount, 
		1 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		'none' as paymentReference,
		null as notes,
		creditAvailable as creditRemaining,
		t.CurrencySymbol as currencySymbol,
		t.DigitsAfterDecimal as digitsAfterDecimal
	from #creditTemp t

		union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide aggregate counts by payment type

		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		coalesce(sum(pay.CreditAmount),0) as creditTotal, 
		coalesce(sum(pay.DebitAmount),0) as debitTotal, 
		(coalesce(pay.PaymentType, 1)+100) as paymentType,
		null as paymentDate,
		null as cancelledDate,
		case when (coalesce(pay.PaymentType, 1)+100) = 101 then @hashersNotPaidCount else cast(count(*) as nvarchar(20)) end as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal

from HC.HasherEventMap hem
left outer join HC.Payment pay on pay.HasherEventMapId = hem.id
where @eventId is not null
and CancelledBy_UserId is null
and hem.EventId = @eventId
and pay.PaymentType > 1
group by (coalesce(pay.PaymentType, 1)+100)

union 
	-- and finally tag on the aggregate count of the number of hashers who have not paid for this event
		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		0 as creditTotal, 
		0 as debitTotal, 
		101 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		@hashersNotPaidCount as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal
		where @eventId is not null
) tbl
ORDER BY paidBy


drop table #creditTemp
drop table #tempHashersNotPaid

END
	

  
