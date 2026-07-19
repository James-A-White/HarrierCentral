CREATE OR ALTER PROCEDURE [HC6].[hcapp_getPaymentReport]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @eventId     UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getPaymentReport
-- Description: Returns a combined payment report for an event as a
--   single rowset. Three row types are UNION'd together and
--   distinguished by paymentType:
--     2–8  = actual payment rows (including cancelled)
--     1    = virtual "not paid" rows for attendees without a payment
--     101+ = aggregate summary rows per payment type (paymentType + 100)
--   Also returns each unpaid attendee's overall kennel credit balance
--   (creditRemaining) so the WankerBanker can apply offsets.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @eventId     - Event to report on
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): combined payment report ordered by paidBy name
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getPaymentReport
-- Breaking Changes:
--   isMember computed dynamically from MembershipExpirationDate (HC5 used
--     stored IsMember flag which can be stale).
--   @eventId default changed from '00000000-...' to NULL; null UUID is
--     also normalised to NULL.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 42,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Authorization: feature "View payment report" (see /hc-authorizations).
DECLARE @rptKennelId     UNIQUEIDENTIFIER;
SELECT @rptKennelId = KennelId FROM HC.Event WHERE id = @eventId;

DECLARE @rptAllowed SMALLINT;
EXEC HC6.CheckKennelPermission @userId, @rptKennelId, 0x0004040E, 0x00000008, @rptAllowed OUTPUT;

IF (@rptAllowed = 0)
BEGIN
    SET @errorCode = 1342; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised to view payment report',
            'Caller does not hold required role for kennel', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to view the payment report for this event.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Build set of attendees without a payment (used in two places below)
-- ---------------------------------------------------------------
SELECT
    hem.id                                                                                 AS hemId,
    hem.UserId                                                                             AS userId,
    CASE WHEN hem.VirginVisitorType != 0
         THEN COALESCE(hem.DisplayName, '<no name>') + CASE WHEN hem.VirginVisitorType = 1 THEN ' (Virgin)' ELSE ' (Visitor)' END
         ELSE COALESCE(paidBy.DisplayName, hem.DisplayName)
    END                                                                                    AS paidBy
INTO #tempHashersNotPaid
FROM HC.HasherEventMap hem
LEFT OUTER JOIN HC.Hasher paidBy ON hem.UserId = paidBy.id
WHERE @eventId IS NOT NULL
  AND hem.EventId = @eventId
  AND hem.AttendenceState >= 20
  AND hem.id NOT IN (
      SELECT pay2.HasherEventMapId FROM HC.Payment pay2
      WHERE pay2.EventId = @eventId AND pay2.PaymentType >= 2 AND pay2.CancelledBy_UserId IS NULL
  );

-- Credit balance and event price for each unpaid attendee
SELECT
    COALESCE(SUM(p.CreditAmount) - SUM(p.DebitAmount), 0)                                 AS creditAvailable,
    hnp.userId,
    hnp.hemId,
    hnp.paidBy,
    CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE()
         THEN COALESCE(evt.EventPriceForMembers,    ken.DefaultEventPriceForMembers,    0)
         ELSE COALESCE(evt.EventPriceForNonMembers, ken.DefaultEventPriceForNonMembers, 0)
    END                                                                                    AS eventPrice,
    coun.CurrencySymbol,
    coun.DigitsAfterDecimal
INTO #creditTemp
FROM #tempHashersNotPaid hnp
INNER JOIN HC.Event evt      ON evt.id   = @eventId
INNER JOIN HC.Kennel ken     ON ken.id   = evt.KennelId
INNER JOIN HC.Country coun   ON ken.CountryId = coun.id
LEFT OUTER JOIN HC.HasherKennelMap hkm ON hnp.userId = hkm.UserId AND hkm.KennelId = evt.KennelId
LEFT OUTER JOIN HC.Payment p ON p.UserId = hnp.userId AND p.CancelledDate IS NULL
GROUP BY
    hnp.userId, hnp.hemId, hnp.paidBy,
    CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE()
         THEN COALESCE(evt.EventPriceForMembers,    ken.DefaultEventPriceForMembers,    0)
         ELSE COALESCE(evt.EventPriceForNonMembers, ken.DefaultEventPriceForNonMembers, 0)
    END,
    coun.CurrencySymbol, coun.DigitsAfterDecimal;

DECLARE @hashersNotPaidCount NVARCHAR(20);
SELECT @hashersNotPaidCount = CAST(COUNT(*) AS NVARCHAR(20)) FROM #tempHashersNotPaid;

-- ---------------------------------------------------------------
-- Combined report (UNION of 4 parts)
-- ---------------------------------------------------------------
SELECT * FROM (

    -- Part 1: actual payment rows
    SELECT
        pay.HasherEventMapId                                                                   AS hasherEventMapId,
        pay.UserId                                                                             AS userIdWhoPaid,
        pay.id                                                                                 AS paymentId,
        CASE WHEN hem.VirginVisitorType != 0
             THEN COALESCE(hem.DisplayName, '<no name>') + CASE WHEN hem.VirginVisitorType = 1 THEN ' (Virgin)' ELSE ' (Visitor)' END
             ELSE COALESCE(paidBy.DisplayName, hem.DisplayName)
        END                                                                                    AS paidBy,
        COALESCE(paidTo.DisplayName, '<user deleted>')                                         AS paidTo,
        cancelledBy.DisplayName                                                                AS cancelledBy,
        pay.CreditAmount                                                                       AS creditAmount,
        pay.DebitAmount                                                                        AS debitAmount,
        pay.PaymentType                                                                        AS paymentType,
        pay.PaidDate                                                                           AS paymentDate,
        pay.CancelledDate                                                                      AS cancelledDate,
        pay.PaymentReference                                                                   AS paymentReference,
        pay.Notes                                                                              AS notes,
        pay.CreditAvailable                                                                    AS creditRemaining,
        coun.CurrencySymbol                                                                    AS currencySymbol,
        coun.DigitsAfterDecimal                                                                AS digitsAfterDecimal
    FROM HC.Payment pay
    INNER JOIN HC.HasherEventMap hem ON hem.id   = pay.HasherEventMapId
    INNER JOIN HC.Event evt          ON pay.EventId = evt.id
    INNER JOIN HC.Kennel k           ON k.id     = evt.KennelId
    INNER JOIN HC.Country coun       ON coun.id  = k.CountryId
    LEFT OUTER JOIN HC.Hasher paidBy      ON pay.UserId                   = paidBy.id
    LEFT OUTER JOIN HC.Hasher paidTo      ON pay.PaymentProcessedBy_userId = paidTo.id
    LEFT OUTER JOIN HC.Hasher cancelledBy ON pay.CancelledBy_UserId        = cancelledBy.id
    WHERE pay.EventId = @eventId AND pay.CancelledBy_UserId IS NULL

    UNION

    -- Part 2: virtual "not paid" rows for attendees without a payment
    SELECT
        t.hemId,
        t.userId,
        NULL,
        t.paidBy,
        'none',
        NULL,
        0,
        t.eventPrice,
        1,
        NULL,
        NULL,
        'none',
        NULL,
        t.creditAvailable,
        t.CurrencySymbol,
        t.DigitsAfterDecimal
    FROM #creditTemp t

    UNION

    -- Part 3: aggregate summary rows per payment type (paymentType + 100 distinguishes them)
    SELECT
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000000',
        NULL,
        'not used',
        'not used',
        NULL,
        COALESCE(SUM(pay.CreditAmount), 0),
        COALESCE(SUM(pay.DebitAmount),  0),
        COALESCE(pay.PaymentType, 1) + 100,
        NULL,
        NULL,
        CASE WHEN (COALESCE(pay.PaymentType, 1) + 100) = 101 THEN @hashersNotPaidCount ELSE CAST(COUNT(*) AS NVARCHAR(20)) END,
        NULL,
        0,
        '',
        0
    FROM HC.HasherEventMap hem
    LEFT OUTER JOIN HC.Payment pay ON pay.HasherEventMapId = hem.id
    WHERE @eventId IS NOT NULL
      AND hem.EventId = @eventId
      AND pay.CancelledBy_UserId IS NULL
      AND pay.PaymentType > 1
    GROUP BY COALESCE(pay.PaymentType, 1) + 100

    UNION

    -- Part 4: count of hashers not paid (paymentType = 101)
    SELECT
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000000',
        NULL,
        'not used',
        'not used',
        NULL,
        0, 0,
        101,
        NULL, NULL,
        @hashersNotPaidCount,
        NULL,
        0,
        '', 0
    WHERE @eventId IS NOT NULL

) tbl
ORDER BY paidBy;

DROP TABLE #creditTemp;
DROP TABLE #tempHashersNotPaid;
