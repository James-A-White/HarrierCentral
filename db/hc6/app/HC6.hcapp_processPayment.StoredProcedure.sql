CREATE OR ALTER PROCEDURE [HC6].[hcapp_processPayment]

    @deviceId               UNIQUEIDENTIFIER,
    @accessToken            NVARCHAR(1000),
    @userIdWhoPaid          UNIQUEIDENTIFIER    = NULL,
    @eventId                UNIQUEIDENTIFIER,
    @hasherEventMapId       UNIQUEIDENTIFIER    = NULL,
    @paymentType            SMALLINT,
    @productType            SMALLINT            = 1,
    @paymentAmount          DECIMAL(12,6)       = NULL,
    @minimumAttendenceValue SMALLINT            = NULL,
    @hasherEventMapUpdatedAfter   NVARCHAR(50)  = 'ignore',
    @hasherKennelMapUpdatedAfter  NVARCHAR(50)  = 'ignore',
    @paymentsUpdatedAfter         NVARCHAR(50)  = 'ignore',
    @kennelCreditsUpdatedAfter    NVARCHAR(50)  = 'ignore',
    @doPayForExtras         SMALLINT            = 0,
    @surcharge              DECIMAL(10,4)       = NULL,
    @paymentProvider        NVARCHAR(50)        = NULL,
    @appDomainType          NVARCHAR(50)        = 'AppDomainType.event',
    @paymentReference       NVARCHAR(50)        = NULL,
    @transactionTimestamp   NVARCHAR(50)        = NULL,
    @specialRunPrice        SMALLMONEY          = NULL,
    @specialRunPriceReason  NVARCHAR(50)        = NULL,
    @useSpecialPriceAsDefault SMALLINT          = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_processPayment
-- Description: Records, confirms, or cancels a single payment for an
--   event attendance. Uses a compound access token binding the
--   transaction to specific hasherEventMapId, payer, amount, and event.
--
--   paymentType codes: 1=not paid, 2=free, 3=cash, 4=bank transfer,
--   5=cash (other), 6=hash credit, 7=bank transfer (other),
--   8=credit (other), 100=confirm bank transfer.
--   productType codes: 1=event, 2=membership, 3=haberdashery.
--
--   @paymentType = 100: marks an existing payment as confirmed by the
--     WankerBanker (bank transfer verification). All other types insert
--     a new payment after cancelling any existing one for that HEM row.
-- Parameters:
--   @deviceId               - Registered device UUID
--   @accessToken            - Compound token: DeviceSecret + hemId + '#' + payerId + '#' + int(amount) + '#' + eventId
--   @userIdWhoPaid          - The hasher who owes the payment
--   @eventId                - The event being paid for
--   @hasherEventMapId       - HEM row; resolved from userIdWhoPaid if NULL
--   @paymentType            - See codes above
--   @productType            - 1=event, 2=membership, 3=haberdashery
--   @paymentAmount          - Amount paid/owed; required when paymentType < 100
--   @minimumAttendenceValue - Minimum attendance state to set; -1 = NULL
--   @doPayForExtras         - 1 = include EventPriceForExtras in debit
--   @appDomainType          - 'AppDomainType.event' → syncEventAdminData; else syncUserData
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): payment summary
--   On success (rowset 2+): sync SP rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_processPayment
-- Breaking Changes:
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   Delegation targets updated to HC6 SPs.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

-- Normalise null UUIDs before token construction
IF (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = NULL;
IF (@userIdWhoPaid    = '00000000-0000-0000-0000-000000000000') SET @userIdWhoPaid    = NULL;
IF (@eventId          = '00000000-0000-0000-0000-000000000000') SET @eventId          = NULL;
IF (@productType IS NULL) SET @productType = 1;
IF (@doPayForExtras IS NULL) SET @doPayForExtras = 0;
IF (@minimumAttendenceValue < 0) SET @minimumAttendenceValue = NULL;

-- Compound token suffix — ValidateAppAuth prepends DeviceSecret
DECLARE @paramSuffix NVARCHAR(500) =
    CAST(COALESCE(@hasherEventMapId, '00000000-0000-0000-0000-000000000000') AS NVARCHAR(50)) + '#' +
    CAST(COALESCE(@userIdWhoPaid,    '00000000-0000-0000-0000-000000000000') AS NVARCHAR(50)) + '#' +
    CAST(CAST(COALESCE(@paymentAmount, 0) AS INT) AS NVARCHAR(50))           + '#' +
    CAST(COALESCE(@eventId,          '00000000-0000-0000-0000-000000000000') AS NVARCHAR(50));

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 40,
    @param        = @paramSuffix,
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
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Parameter validation
-- ---------------------------------------------------------------
IF (@eventId IS NULL AND @productType = 1)
BEGIN
    SET @errorCode = 1240; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId',
            'eventId required for productType = 1', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF ((@paymentAmount IS NULL OR @paymentAmount < 0) AND @paymentType < 100)
BEGIN
    SET @errorCode = 1240; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid payment amount',
            'paymentAmount must be >= 0 for paymentType < 100', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid payment amount' AS errorTitle,
           'A valid payment amount is required.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @kennelId         UNIQUEIDENTIFIER;
DECLARE @payer_userName   NVARCHAR(120);
DECLARE @attendenceState  INT;
DECLARE @eventPrice       MONEY;
DECLARE @creditAmount     MONEY;
DECLARE @creditAvailable  SMALLMONEY;
DECLARE @discountAmount   SMALLMONEY = 0;
DECLARE @discountPercent  SMALLINT   = 0;
DECLARE @discountDescription NVARCHAR(50) = '';

BEGIN TRY
    BEGIN TRANSACTION;

        -- ---------------------------------------------------------------
        -- paymentType = 100: confirm bank transfer only
        -- ---------------------------------------------------------------
        IF (@paymentType = 100)
        BEGIN
            UPDATE HC.Payment SET
                ConfirmedDate      = GETDATE(),
                ConfirmedBy_UserId = @userId,
                updatedAt          = GETDATE()
            WHERE HasherEventMapId = @hasherEventMapId AND CancelledDate IS NULL;

            COMMIT TRANSACTION;

            SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

            SELECT
                1                  AS adHocDataId,
                NULL               AS hasherWhoPaid,
                NULL               AS attendenceState,
                NULL               AS rsvpState,
                @paymentType       AS paymentType,
                @productType       AS productType,
                NULL               AS debitAmount,
                NULL               AS creditAmount,
                @paymentAmount     AS paymentAmount,
                NULL               AS creditAvailable,
                @paymentReference  AS paymentReference,
                0                  AS discountAmount,
                0                  AS discountPercent,
                ''                 AS discountDescription;

            GOTO SyncAndReturn;
        END

        -- ---------------------------------------------------------------
        -- Resolve @hasherEventMapId: lookup by userIdWhoPaid if not given
        -- ---------------------------------------------------------------
        SELECT @kennelId = e.KennelId FROM HC.Event e WHERE e.id = @eventId;

        IF (@hasherEventMapId IS NOT NULL)
        BEGIN
            IF (@userIdWhoPaid IS NULL)
                SELECT @userIdWhoPaid = hem.UserId
                FROM HC.HasherEventMap hem WHERE hem.id = @hasherEventMapId AND hem.removed = 0;
        END
        ELSE
        BEGIN
            SELECT @hasherEventMapId = hem.id
            FROM HC.HasherEventMap hem WHERE hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId;

            IF (@hasherEventMapId IS NULL)
            BEGIN
                SET @hasherEventMapId = NEWID();

                INSERT HC.HasherEventMap
                    ([id], [UserId], [EventId], [KennelId], [RsvpState],
                     [Rsvp], [UserStartEvent], [AttendenceState], [updatedAt])
                VALUES
                    (@hasherEventMapId, @userIdWhoPaid, @eventId, @kennelId,
                     3, GETDATE(), GETDATE(), COALESCE(@minimumAttendenceValue, 0), GETDATE());
            END
        END

        -- ---------------------------------------------------------------
        -- Load pricing / payer context
        -- ---------------------------------------------------------------
        DECLARE @originalEventPrice MONEY;
        DECLARE @extrasPrice        MONEY;
        DECLARE @debitAmount        MONEY;
        DECLARE @payer_userIdGuid   UNIQUEIDENTIFIER;
        DECLARE @paymentExists      INT;

        SELECT @paymentExists = COUNT(*)
        FROM HC.Payment p
        WHERE p.HasherEventMapId = @hasherEventMapId AND p.CancelledDate IS NULL;

        SELECT
            @originalEventPrice = CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE() THEN
                COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers,    e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
            ELSE
                COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, e.EventPriceForMembers,    k.DefaultEventPriceForMembers,    0)
            END,
            @extrasPrice        = CASE WHEN @doPayForExtras = 1 THEN COALESCE(e.EventPriceForExtras, 0) ELSE 0 END,
            @kennelId           = k.id,
            @payer_userIdGuid   = hem.UserId,
            @attendenceState    = hem.AttendenceState,
            @eventId            = COALESCE(@eventId, e.id),
            @payer_userName     = COALESCE(
                CASE
                    WHEN h.NameDisplayPreference = 1 AND LEN(h.HashName) > 0 THEN h.HashName
                    WHEN h.NameDisplayPreference = 2 OR LEN(COALESCE(h.HashName, '')) = 0 THEN h.FirstName + ' ' + h.LastName
                    ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
                END, hem.DisplayName, '<no name>'),
            @discountAmount     = COALESCE(hkm.DiscountAmount, 0),
            @discountPercent    = COALESCE(hkm.DiscountPercent, 0),
            @discountDescription = COALESCE(hkm.DiscountDescription, '')
        FROM HC.HasherEventMap hem
        INNER JOIN HC.Event e     ON e.id  = hem.EventId
        INNER JOIN HC.Kennel k    ON k.id  = e.KennelId
        LEFT OUTER JOIN HC.HasherKennelMap hkm ON hem.UserId = hkm.UserId AND hkm.KennelId = e.KennelId
        LEFT OUTER JOIN HC.Hasher h ON h.id = hem.UserId
        WHERE hem.id = @hasherEventMapId;

        -- Apply discounts
        SET @eventPrice = @originalEventPrice - @discountAmount;
        SET @eventPrice = @eventPrice - (@eventPrice * (@discountPercent / 100.0));
        SET @eventPrice = @eventPrice + @extrasPrice;

        -- ---------------------------------------------------------------
        -- paymentType = 1: mark as not paid (cancel existing)
        -- ---------------------------------------------------------------
        IF (@paymentType = 1 AND @paymentExists > 0)
        BEGIN
            UPDATE HC.Payment SET
                IsCancelled        = 1,
                CancelledDate      = GETDATE(),
                CancelledBy_UserId = @userId,
                updatedAt          = GETDATE()
            WHERE CancelledDate IS NULL AND HasherEventMapId = @hasherEventMapId;
        END

        -- ---------------------------------------------------------------
        -- paymentType = 2: free run — only charge extras
        -- ---------------------------------------------------------------
        IF (@paymentType = 2) SET @eventPrice = @extrasPrice;

        -- ---------------------------------------------------------------
        -- paymentType 2–8: insert payment (cancel any existing first)
        -- ---------------------------------------------------------------
        IF (@paymentType >= 2 AND @paymentType <= 8)
        BEGIN
            -- Set DoTrackHashCash flag on first payment
            UPDATE HC.Event SET DoTrackHashCash = 1
            WHERE id = @eventId AND DoTrackHashCash != 1;

            -- Generate unique payment reference
            DECLARE @refCount INT = 1;
            IF (@paymentReference IS NULL)
                SET @paymentReference = 'HC:' + HC.NUMBER_TO_STR_BASE(36, (RAND() * (2147483647 - 60466177)) + 60466176);
            WHILE (@refCount > 0)
            BEGIN
                SELECT @refCount = COUNT(*) FROM HC.Payment WHERE PaymentReference = @paymentReference;
                IF (@refCount > 0)
                    SET @paymentReference = LEFT(@paymentReference, 3) + HC.NUMBER_TO_STR_BASE(36, (RAND() * (2147483647 - 60466177)) + 60466176);
            END

            IF (@paymentType = 5 OR @paymentType = 7 OR @paymentType = 8)
            BEGIN
                -- Other amount: credit = what was paid, debit = event price (or special price)
                SET @creditAmount = @paymentAmount;
                IF (@specialRunPrice IS NOT NULL)
                BEGIN
                    SET @debitAmount = @specialRunPrice;
                    IF (@useSpecialPriceAsDefault != 0 AND @userIdWhoPaid IS NOT NULL)
                    BEGIN
                        SET @discountAmount      = @originalEventPrice - @specialRunPrice;
                        SET @discountPercent     = 0;
                        SET @discountDescription = COALESCE(@specialRunPriceReason, '');

                        UPDATE HC.HasherKennelMap SET
                            DiscountAmount      = @discountAmount,
                            DiscountPercent     = 0,
                            DiscountDescription = @discountDescription,
                            updatedAt           = GETDATE()
                        WHERE UserId = @userIdWhoPaid AND KennelId = @kennelId;
                    END
                END
                ELSE
                    SET @debitAmount = @eventPrice;
            END
            ELSE
            BEGIN
                SET @creditAmount = @eventPrice;
                SET @debitAmount  = @eventPrice;
            END

            -- Hash credits: credit amount = 0 (balance already tracked elsewhere)
            IF (@paymentType = 6 OR @paymentType = 8) SET @creditAmount = 0;

            -- Cancel existing payment before inserting new one
            IF (@paymentExists > 0)
            BEGIN
                UPDATE HC.Payment SET
                    IsCancelled        = 1,
                    CancelledDate      = GETDATE(),
                    CancelledBy_UserId = @userId,
                    updatedAt          = GETDATE()
                WHERE CancelledDate IS NULL AND HasherEventMapId = @hasherEventMapId;
            END

            INSERT HC.Payment
                ([KennelId], [UserId], [EventId], [HasherEventMapId],
                 [CreditAmount], [DebitAmount], [CreditAvailable],
                 [PaymentProcessedBy_userId], [PaidDate],
                 [PaymentType], [ProductType], [PaymentReference],
                 [DoPayForExtras], [PaymentProvider],
                 [DiscountAmount], [DiscountPercent], [DiscountDescription],
                 [SpecialRunPriceReason], [Surcharge], [updatedAt])
            VALUES
                (@kennelId, @payer_userIdGuid, @eventId, @hasherEventMapId,
                 @creditAmount, @debitAmount, 0,
                 @userId,
                 COALESCE(CAST(LEFT(@transactionTimestamp, 23) AS DATETIME), GETDATE()),
                 @paymentType, @productType, @paymentReference,
                 @doPayForExtras, @paymentProvider,
                 @discountAmount, @discountPercent, @discountDescription,
                 COALESCE(@specialRunPriceReason, ''),
                 COALESCE(@surcharge, 0),
                 GETDATE());

            -- Mark HEM as attended and RSVP'd (minimum state if set)
            UPDATE HC.HasherEventMap SET
                UserStartEvent   = GETDATE(),
                RsvpState        = 3,
                AttendenceState  = CASE WHEN AttendenceState < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE AttendenceState END,
                updatedAt        = GETDATE()
            WHERE id = @hasherEventMapId;

            SELECT @attendenceState = CASE WHEN COALESCE(@attendenceState, 0) < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE @attendenceState END;
        END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1940; SET @errorType = 9; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- Post-commit: update kennel credit and run counts
EXEC HC.nonApi_updateKennelCreditByUser @userId = @payer_userIdGuid, @kennelId = @kennelId;
SELECT @creditAvailable = hkm.KennelCredit FROM HC.HasherKennelMap hkm
WHERE hkm.UserId = @payer_userIdGuid AND hkm.KennelId = @kennelId;

IF (@userIdWhoPaid IS NOT NULL)
    EXEC HC.nonApi_updateRunCountsByUser @userId = @userIdWhoPaid;

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

SELECT
    1                    AS adHocDataId,
    @payer_userName      AS hasherWhoPaid,
    @attendenceState     AS attendenceState,
    3                    AS rsvpState,
    @paymentType         AS paymentType,
    @productType         AS productType,
    @eventPrice          AS debitAmount,
    @creditAmount        AS creditAmount,
    @paymentAmount       AS paymentAmount,
    @creditAvailable     AS creditAvailable,
    @paymentReference    AS paymentReference,
    @discountAmount      AS discountAmount,
    @discountPercent     AS discountPercent,
    @discountDescription AS discountDescription;

SyncAndReturn:

-- ---------------------------------------------------------------
-- Delegate to sync SP (outside TRY — runs after all writes)
-- ---------------------------------------------------------------
IF (@appDomainType = 'AppDomainType.event')
BEGIN
    EXEC HC6.hcapp_syncEventAdminData
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @eventId                     = @eventId,
        @hashersUpdatedAfter         = 'ignore',
        @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
        @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
        @narrowEventsUpdatedAfter    = 'ignore',
        @paymentsUpdatedAfter        = @paymentsUpdatedAfter,
        @kennelCreditsUpdatedAfter   = @kennelCreditsUpdatedAfter,
        @receiptsUpdatedAfter        = 'ignore',
        @procName                    = @procName,
        @param                       = @paramSuffix;
END
ELSE
BEGIN
    EXEC HC6.hcapp_syncUserData
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @hashersUpdatedAfter         = 'ignore',
        @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
        @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
        @narrowEventsUpdatedAfter    = 'ignore',
        @usePaging                   = 0,
        @procName                    = @procName,
        @param                       = @paramSuffix;
END
