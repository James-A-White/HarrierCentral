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
    @useSpecialPriceAsDefault SMALLINT          = NULL,
    -- Free-text payment note (haberdashery item description). Stored on
    -- Payment.Notes, which the payment report already returns.
    @notes                  NVARCHAR(500)       = NULL,
    -- productType 2 only: 1 = also record the run fee (member pricing) and
    -- check the payer in, atomically with the membership charge. Ignored for
    -- other product types. See "Combined membership + run" in the header.
    @alsoPayRunFee          SMALLINT            = 0

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
--     a new payment after cancelling any existing one for that HEM row
--     IN THE SAME PRODUCT — the exists/cancel logic is ProductType-scoped
--     so a membership charge never cancels the run payment on the HEM.
--
--   productType = 2 (membership, 2026-08-08 — docs/membership_payments_plan.md):
--     Debit = the membership fee (@specialRunPrice override, else
--     Kennel.MembershipPrice); event pricing, extras and HKM discounts do
--     not apply. Credit-neutral by construction (credit=paid, debit=fee).
--     On success HKM.MembershipExpirationDate advances per the kennel's
--     MembershipRenewalMode: 1=rolling (max(expiry, now) +
--     MembershipDurationInMonths), 2=fixed year — RECURRING annual window;
--     only the month/day of MembershipPeriodEndDate matter (its year is a
--     sentinel); expiry = day after the NEXT occurrence of that month/day;
--     refused only if the end month/day is unconfigured,
--     3=lifetime (2999-12-31 sentinel; charging an existing lifetime
--     member is refused). The expiry-as-was is stored in
--     Payment.PreviousMembershipExpiry; replacing or cancelling
--     (paymentType 1) a membership payment restores it first, so
--     replays and corrections are idempotent. The HEM is only an anchor:
--     membership charges never mark attendance/RSVP.
-- Parameters:
--   @deviceId               - Registered device UUID
--   @accessToken            - Compound token: paramString = DeviceSecret + HemId + '#' + INT(paymentAmount)
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
-- Modified: 2026-07-25 — added UPDLOCK/HOLDLOCK serialization on the HEM row
--   before the check-then-cancel-then-insert, preventing a concurrent
--   double-tap from inserting two non-cancelled payments for the same HEM.
-- Modified: 2026-08-16 — two additions (docs/membership_payments_plan.md):
--   (1) Zero-price ⇒ FREE: a cash/transfer/credit tap (types 3/4/6) on a run
--       whose computed price is zero records PaymentType 2 with a provenance
--       tag in Notes ('member'/'non-member') instead of a zero-amount "cash"
--       fiction. Other-amount types (5/7/8) are never coerced.
--   (2) Combined membership + run (@alsoPayRunFee = 1, productType 2 only):
--       after the membership charge, atomically records the run fee at MEMBER
--       pricing (zero ⇒ FREE + 'member' tag), same method family (other-
--       amount variants map to base types), no extras, and checks the payer
--       in (attendance floor @minimumAttendenceValue, default 20). adHocData
--       gains runFeeAmount + runFeePaymentType (additive).
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
-- Combined membership+run is a productType-2-only concept.
IF (@alsoPayRunFee IS NULL OR @productType != 2) SET @alsoPayRunFee = 0;

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

-- Look up the device secret so the compound param can be built before calling ValidateAppAuth.
-- ValidateAppAuth will overwrite @deviceSecret via OUTPUT with the same value.
SELECT @deviceSecret = UPPER(d.DeviceSecret) FROM HC.Device d WHERE d.id = @deviceId;

-- Compound token context: deviceSecret + hemId + '#' + INT(paymentAmount)
-- @hasherEventMapId may already be NULL here (normalised from GUID_EMPTY above).
-- @paymentAmount uses COALESCE(0) so the token is still deterministic if the SP returns
-- an early validation error before amount is checked.
DECLARE @paramSuffix NVARCHAR(650) =
    @deviceSecret
    + UPPER(CAST(COALESCE(@hasherEventMapId, '00000000-0000-0000-0000-000000000000') AS NVARCHAR(50)))
    + '#' + CAST(CAST(COALESCE(@paymentAmount, 0) AS INT) AS NVARCHAR(50));

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
-- Membership payments also need the event anchor (Payment.EventId is NOT
-- NULL; the members-list surface anchors to the kennel's most recent run).
IF (@eventId IS NULL AND @productType IN (1, 2))
BEGIN
    SET @errorCode = 1240; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId',
            'eventId required for productType 1 and 2', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF ((@paymentAmount IS NULL OR @paymentAmount < 0) AND @paymentType < 100)
BEGIN
    SET @errorCode = 1240; SET @errorType = 12; SET @errorId = NEWID();
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
        -- Authorization: feature "Take payment" (see /hc-authorizations).
        -- ALL money paths (record types 2-8, cancel type 1, confirm type 100)
        -- require hash-cash rights for the kennel. Previously only type 100 was
        -- gated, leaving single-payment record/cancel open. Run-scoped: a hare
        -- of THIS event may also take payment for it (check-in flow, @eventId set;
        -- does not extend to confirm-only calls where @eventId is null).
        -- ---------------------------------------------------------------
        DECLARE @payKennelId UNIQUEIDENTIFIER;
        IF (@eventId IS NOT NULL)
            SELECT @payKennelId = KennelId FROM HC.Event WHERE id = @eventId;
        IF (@payKennelId IS NULL AND @hasherEventMapId IS NOT NULL)
            SELECT @payKennelId = e.KennelId
            FROM HC.HasherEventMap hem INNER JOIN HC.Event e ON e.id = hem.EventId
            WHERE hem.id = @hasherEventMapId;

        DECLARE @payAllowed SMALLINT;
        DECLARE @payIsHare SMALLINT = CASE WHEN @eventId IS NOT NULL AND EXISTS (
                SELECT 1 FROM HC.HasherEventMap
                WHERE UserId = @userId AND EventId = @eventId AND IsHare = 1) THEN 1 ELSE 0 END;
        EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @payKennelId, @functionKey = 'takePayment', @isHareOfEvent = @payIsHare, @allowed = @payAllowed OUTPUT;
        IF (@payAllowed = 0)
        BEGIN
            SET @errorCode = 1340; SET @errorType = 13; SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, '<unknown>', 'Not authorised to take payment',
                    'Caller does not hold required role for kennel', @procName, @userId);
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
            SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                   'Not authorised' AS errorTitle,
                   'You are not authorised to take payments for this event.' AS errorUserMessage,
                   @procName AS errorProc;
            RETURN;
        END

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
                ''                 AS discountDescription,
                NULL               AS newMembershipExpiry,
                NULL               AS runFeeAmount,
                NULL               AS runFeePaymentType;

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
            -- Serialize this check-then-insert against a concurrent payment or
            -- check-in for the same (UserId, EventId). Without a lock, two
            -- transactions both find no row and both INSERT, and the second
            -- violates the UNIQUE index IX_HasherEventMap_EventId
            -- (EventId, UserId, DisplayName) — the duplicate-key 500 seen in
            -- HC.ErrorLog (2026-06-14). UPDLOCK+HOLDLOCK takes a key-range lock
            -- so the racing transaction blocks, then finds this row instead of
            -- inserting a duplicate. Held to COMMIT (inside the open transaction).
            SELECT @hasherEventMapId = hem.id
            FROM HC.HasherEventMap hem WITH (UPDLOCK, HOLDLOCK)
            WHERE hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId;

            IF (@hasherEventMapId IS NULL)
            BEGIN
                SET @hasherEventMapId = NEWID();

                -- Membership/haberdashery charges (productType 2/3) use the
                -- HEM purely as a payment anchor: create it neutral (no RSVP,
                -- no attendance) rather than marking the hasher as going to
                -- the anchor run. Exception: a combined membership+run charge
                -- (@alsoPayRunFee) IS an attendance — create it like a run
                -- payment would.
                INSERT HC.HasherEventMap
                    ([id], [UserId], [EventId], [KennelId], [RsvpState],
                     [Rsvp], [UserStartEvent], [AttendenceState], [updatedAt])
                VALUES
                    (@hasherEventMapId, @userIdWhoPaid, @eventId, @kennelId,
                     CASE WHEN @productType IN (2, 3) AND @alsoPayRunFee = 0 THEN 0 ELSE 3 END,
                     CASE WHEN @productType IN (2, 3) AND @alsoPayRunFee = 0 THEN NULL ELSE GETDATE() END,
                     CASE WHEN @productType IN (2, 3) AND @alsoPayRunFee = 0 THEN NULL ELSE GETDATE() END,
                     COALESCE(@minimumAttendenceValue, 0), GETDATE());
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

        -- Membership (productType = 2) context — see plan doc.
        DECLARE @membershipMode      SMALLINT;
        DECLARE @membershipFee       DECIMAL(10,4);
        DECLARE @membershipMonths    INT;
        DECLARE @membershipPeriodEnd DATE;
        DECLARE @memberExpiry        DATETIMEOFFSET(7);
        DECLARE @newMemberExpiry     DATETIMEOFFSET(7);
        -- Lifetime sentinel: works with every existing
        -- "MembershipExpirationDate > GETDATE()" check unchanged.
        DECLARE @lifetimeExpiry      DATETIMEOFFSET(7) = '2999-12-31';

        -- Combined membership+run leg (@alsoPayRunFee) — surfaced in adHocData.
        DECLARE @runFeeCharged       MONEY    = NULL;
        DECLARE @runFeePaymentType   SMALLINT = NULL;

        -- Serialize concurrent payment operations for this HEM. Two racing calls
        -- (a double-tap / client retry) could otherwise BOTH read
        -- @paymentExists = 0, both skip the "cancel existing" step below, and
        -- both INSERT — leaving two non-cancelled payment rows for the same HEM
        -- (the duplicate found 2026-07-25: two identical type-3 rows created the
        -- same second). An UPDLOCK/HOLDLOCK on the HEM row makes the second call
        -- block here until the first commits; it then sees the inserted payment
        -- and cancels it before inserting its own, so exactly one stays live.
        -- Same pattern used for the HEM create race above. Held to COMMIT.
        DECLARE @serialiseHemId UNIQUEIDENTIFIER;
        SELECT @serialiseHemId = hem.id
        FROM HC.HasherEventMap hem WITH (UPDLOCK, HOLDLOCK)
        WHERE hem.id = @hasherEventMapId;

        -- ProductType-scoped: a membership charge on a check-in HEM must not
        -- count (or later cancel) the run payment sharing that HEM, and vice
        -- versa. Each product keeps its own single-active-payment invariant.
        SELECT @paymentExists = COUNT(*)
        FROM HC.Payment p
        WHERE p.HasherEventMapId = @hasherEventMapId AND p.CancelledDate IS NULL
          AND p.ProductType = @productType;

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
            @discountDescription = COALESCE(hkm.DiscountDescription, ''),
            @membershipMode      = k.MembershipRenewalMode,
            @membershipFee       = k.MembershipPrice,
            @membershipMonths    = k.MembershipDurationInMonths,
            @membershipPeriodEnd = k.MembershipPeriodEndDate,
            @memberExpiry        = hkm.MembershipExpirationDate
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
        -- productType = 2: membership pricing replaces event pricing.
        -- Fee = @specialRunPrice override, else the kennel default. Run
        -- discounts and extras never apply to memberships.
        -- ---------------------------------------------------------------
        IF (@productType = 2)
        BEGIN
            SET @originalEventPrice  = COALESCE(@specialRunPrice, @membershipFee, 0);
            SET @eventPrice          = @originalEventPrice;
            SET @extrasPrice         = 0;
            SET @discountAmount      = 0;
            SET @discountPercent     = 0;
            SET @discountDescription = '';

            -- Fixed-year mode is a RECURRING annual window: only the month/day
            -- of MembershipPeriodEndDate matter (the stored year is a
            -- sentinel). The window never "lapses" — it rolls to next year —
            -- so we only refuse when the end date has not been configured.
            IF (@membershipMode = 2 AND @paymentType BETWEEN 2 AND 8
                AND @membershipPeriodEnd IS NULL)
            BEGIN
                SET @errorCode = 1245; SET @errorType = 2; SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
                VALUES (@errorId, '<unknown>', 'Membership year not set',
                        'MembershipPeriodEndDate is not configured', @procName, @userId);
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
                SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                       'Membership year not set' AS errorTitle,
                       'This kennel''s membership year end is not configured. Set it in kennel settings first.' AS errorUserMessage,
                       @procName AS errorProc;
                RETURN;
            END

            -- Lifetime members can't be charged again.
            IF (@membershipMode = 3 AND @paymentType BETWEEN 2 AND 8
                AND @memberExpiry >= @lifetimeExpiry)

            BEGIN
                SET @errorCode = 1246; SET @errorType = 2; SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
                VALUES (@errorId, '<unknown>', 'Already a lifetime member',
                        'Attempt to charge membership to a lifetime member', @procName, @userId);
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
                SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                       'Already a lifetime member' AS errorTitle,
                       'This hasher already holds a lifetime membership.' AS errorUserMessage,
                       @procName AS errorProc;
                RETURN;
            END
        END

        -- ---------------------------------------------------------------
        -- productType = 3: haberdashery sale — price is the sale amount
        -- (or @specialRunPrice override); no event pricing, extras or
        -- discounts. Multiple sales per HEM co-exist (see below), and
        -- "mark as not paid" is refused: with several live rows it is
        -- ambiguous which sale it would cancel.
        -- ---------------------------------------------------------------
        IF (@productType = 3)
        BEGIN
            IF (@paymentType = 1)
            BEGIN
                SET @errorCode = 1247; SET @errorType = 2; SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
                VALUES (@errorId, '<unknown>', 'Cannot bulk-cancel haberdashery',
                        'paymentType 1 is not supported for productType 3', @procName, @userId);
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
                SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                       'Not supported' AS errorTitle,
                       'Haberdashery sales cannot be bulk-cancelled.' AS errorUserMessage,
                       @procName AS errorProc;
                RETURN;
            END

            SET @originalEventPrice  = COALESCE(@specialRunPrice, @paymentAmount, 0);
            SET @eventPrice          = @originalEventPrice;
            SET @extrasPrice         = 0;
            SET @discountAmount      = 0;
            SET @discountPercent     = 0;
            SET @discountDescription = '';
        END

        -- ---------------------------------------------------------------
        -- paymentType = 1: mark as not paid (cancel existing, same product)
        -- ---------------------------------------------------------------
        IF (@paymentType = 1 AND @paymentExists > 0)
        BEGIN
            -- Cancelling a membership payment un-applies its extension:
            -- restore the expiry the member had before that payment.
            IF (@productType = 2)
            BEGIN
                UPDATE hkm SET
                    hkm.MembershipExpirationDate = p.PreviousMembershipExpiry,
                    hkm.updatedAt                = GETDATE()
                FROM HC.HasherKennelMap hkm
                INNER JOIN HC.Payment p ON p.UserId = hkm.UserId AND p.KennelId = hkm.KennelId
                WHERE p.HasherEventMapId = @hasherEventMapId
                  AND p.CancelledDate IS NULL AND p.ProductType = 2;
            END

            UPDATE HC.Payment SET
                IsCancelled        = 1,
                CancelledDate      = GETDATE(),
                CancelledBy_UserId = @userId,
                updatedAt          = GETDATE()
            WHERE CancelledDate IS NULL AND HasherEventMapId = @hasherEventMapId
              AND ProductType = @productType;
        END

        -- ---------------------------------------------------------------
        -- Zero-price ⇒ FREE (2026-08-16): a cash / bank-transfer / hash-
        -- credit tap (types 3/4/6) on a run whose computed price is zero is
        -- really a free run — record PaymentType 2 with a provenance tag in
        -- Notes ('member' / 'non-member') instead of a zero-amount "cash"
        -- fiction, so payment reports count real money only. Other-amount
        -- types (5/7/8) carry deliberate explicit amounts — never coerced.
        -- ---------------------------------------------------------------
        IF (@productType = 1 AND @paymentType IN (3, 4, 6)
            AND (@eventPrice - @extrasPrice) <= 0)
        BEGIN
            SET @paymentType = 2;
            IF (@notes IS NULL)
                SET @notes = CASE WHEN COALESCE(@memberExpiry, '2000-01-01') > GETDATE()
                                  THEN 'member' ELSE 'non-member' END;
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

            -- paymentType = 6 (hash credit): auto-create a follower HKM record for
            -- hashers who don't have one yet so credit can be accumulated and spent
            -- by non-members and visitors. Membership purchases (productType = 2)
            -- need the HKM row too — it carries the expiration date being bought.
            IF ((@paymentType = 6 OR @productType = 2) AND @payer_userIdGuid IS NOT NULL)
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM HC.HasherKennelMap
                    WHERE UserId = @payer_userIdGuid AND KennelId = @kennelId AND removed = 0
                )
                AND EXISTS (SELECT 1 FROM HC.Hasher WHERE id = @payer_userIdGuid)
                BEGIN
                    INSERT HC.HasherKennelMap (
                        UserId, KennelId, Following, IsKennelFollowing, IsMember,
                        CanEditRunAttendence, MemberSince, updatedAtBias
                    )
                    VALUES (
                        @payer_userIdGuid, @kennelId, 1, 1, 0,
                        0, NULL,
                        CONVERT(INT, ABS(CONVERT(BIGINT, CONVERT(VARBINARY(8), NEWID(), 1)) / 40020.2323 % 999999))
                    );
                END
            END

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

            -- Cancel existing same-product payment before inserting new one.
            -- For a replaced MEMBERSHIP payment, first un-apply its extension
            -- (restore the pre-payment expiry it recorded) so re-charges and
            -- client replays are idempotent rather than compounding.
            -- Haberdashery (productType 3) NEVER replaces: each sale is its
            -- own row and multiple purchases per HEM co-exist.
            IF (@paymentExists > 0 AND @productType != 3)
            BEGIN
                IF (@productType = 2)
                BEGIN
                    SELECT TOP 1 @memberExpiry = p.PreviousMembershipExpiry
                    FROM HC.Payment p
                    WHERE p.HasherEventMapId = @hasherEventMapId
                      AND p.CancelledDate IS NULL AND p.ProductType = 2
                    ORDER BY p.createdAt ASC;

                    UPDATE HC.HasherKennelMap SET
                        MembershipExpirationDate = @memberExpiry,
                        updatedAt                = GETDATE()
                    WHERE UserId = @payer_userIdGuid AND KennelId = @kennelId;
                END

                UPDATE HC.Payment SET
                    IsCancelled        = 1,
                    CancelledDate      = GETDATE(),
                    CancelledBy_UserId = @userId,
                    updatedAt          = GETDATE()
                WHERE CancelledDate IS NULL AND HasherEventMapId = @hasherEventMapId
                  AND ProductType = @productType;
            END

            INSERT HC.Payment
                ([KennelId], [UserId], [EventId], [HasherEventMapId],
                 [CreditAmount], [DebitAmount], [CreditAvailable],
                 [PaymentProcessedBy_userId], [PaidDate],
                 [PaymentType], [ProductType], [PaymentReference],
                 [DoPayForExtras], [PaymentProvider],
                 [DiscountAmount], [DiscountPercent], [DiscountDescription],
                 [SpecialRunPriceReason], [Surcharge],
                 [PreviousMembershipExpiry], [Notes], [updatedAt])
            VALUES
                (@kennelId, @payer_userIdGuid, @eventId, @hasherEventMapId,
                 @creditAmount, @debitAmount, 0,
                 @userId,
                 COALESCE(TRY_CAST(LEFT(@transactionTimestamp, 23) AS DATETIME), GETDATE()),
                 @paymentType, @productType, @paymentReference,
                 @doPayForExtras, @paymentProvider,
                 @discountAmount, @discountPercent, @discountDescription,
                 COALESCE(@specialRunPriceReason, ''),
                 COALESCE(@surcharge, 0),
                 CASE WHEN @productType = 2 THEN @memberExpiry ELSE NULL END,
                 NULLIF(LTRIM(RTRIM(@notes)), ''),
                 GETDATE());

            -- ---------------------------------------------------------------
            -- productType = 2: advance the membership expiration date.
            -- @memberExpiry is the pre-payment value (restored above if this
            -- replaced an earlier charge) — also stamped on the payment row
            -- as the unwind anchor.
            -- ---------------------------------------------------------------
            IF (@productType = 2)
            BEGIN
                IF (@membershipMode = 2)
                BEGIN
                    -- Fixed-year: expiry = the day AFTER the NEXT occurrence of
                    -- the configured end month/day (so the anniversary itself is
                    -- still a valid membership day under "> GETDATE()"). Only
                    -- month/day of @membershipPeriodEnd are used; its year is a
                    -- sentinel. Day is clamped to the target month's length so a
                    -- 29-Feb end never errors in a non-leap year.
                    DECLARE @annToday DATE = CAST(SYSDATETIMEOFFSET() AS DATE);
                    DECLARE @annMonth INT = MONTH(@membershipPeriodEnd);
                    DECLARE @annDay   INT = DAY(@membershipPeriodEnd);
                    DECLARE @annYear  INT = YEAR(@annToday);
                    DECLARE @annFirst DATE = DATEFROMPARTS(@annYear, @annMonth, 1);
                    DECLARE @annCand  DATE = DATEADD(DAY,
                        (CASE WHEN @annDay > DAY(EOMONTH(@annFirst))
                              THEN DAY(EOMONTH(@annFirst)) ELSE @annDay END) - 1, @annFirst);
                    IF (@annCand < @annToday)
                    BEGIN
                        SET @annFirst = DATEFROMPARTS(@annYear + 1, @annMonth, 1);
                        SET @annCand  = DATEADD(DAY,
                            (CASE WHEN @annDay > DAY(EOMONTH(@annFirst))
                                  THEN DAY(EOMONTH(@annFirst)) ELSE @annDay END) - 1, @annFirst);
                    END
                    SET @newMemberExpiry = CAST(DATEADD(DAY, 1, @annCand) AS DATETIMEOFFSET(7));
                END
                ELSE IF (@membershipMode = 3)
                    SET @newMemberExpiry = @lifetimeExpiry;
                ELSE
                    -- Rolling: add the duration to max(current expiry, now).
                    SET @newMemberExpiry = DATEADD(MONTH, COALESCE(@membershipMonths, 12),
                         CASE WHEN COALESCE(@memberExpiry, '2000-01-01') > SYSDATETIMEOFFSET()
                              THEN @memberExpiry ELSE SYSDATETIMEOFFSET() END);

                UPDATE HC.HasherKennelMap SET
                    MembershipExpirationDate = @newMemberExpiry,
                    updatedAt                = GETDATE()
                WHERE UserId = @payer_userIdGuid AND KennelId = @kennelId;
            END
            ELSE IF (@productType = 1)
            BEGIN
                -- Mark HEM as attended and RSVP'd (minimum state if set).
                -- Membership and haberdashery charges skip this: their HEM is
                -- only an anchor — a non-run charge must not mark someone as
                -- attending the anchor run.
                UPDATE HC.HasherEventMap SET
                    UserStartEvent   = GETDATE(),
                    RsvpState        = 3,
                    AttendenceState  = CASE WHEN AttendenceState < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE AttendenceState END,
                    updatedAt        = GETDATE()
                WHERE id = @hasherEventMapId;

                SELECT @attendenceState = CASE WHEN COALESCE(@attendenceState, 0) < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE @attendenceState END;
            END

            -- ---------------------------------------------------------------
            -- Combined membership + run (@alsoPayRunFee = 1, productType 2):
            -- the expiry update above has just made the payer a member, so the
            -- run leg charges MEMBER pricing (with their HKM discounts). Zero
            -- price ⇒ FREE + 'member' tag. Extras never apply on the combined
            -- path (use the normal run-payment flow for extras). Same
            -- transaction: membership, run fee and check-in commit or roll
            -- back together.
            -- ---------------------------------------------------------------
            IF (@productType = 2 AND @alsoPayRunFee = 1)
            BEGIN
                DECLARE @runPrice               MONEY;
                DECLARE @runDiscountAmount      SMALLMONEY   = 0;
                DECLARE @runDiscountPercent     SMALLINT     = 0;
                DECLARE @runDiscountDescription NVARCHAR(50) = '';

                SELECT
                    @runPrice = COALESCE(e.EventPriceForMembers, k.DefaultEventPriceForMembers,
                                         e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0),
                    @runDiscountAmount      = COALESCE(hkm.DiscountAmount, 0),
                    @runDiscountPercent     = COALESCE(hkm.DiscountPercent, 0),
                    @runDiscountDescription = COALESCE(hkm.DiscountDescription, '')
                FROM HC.Event e
                INNER JOIN HC.Kennel k ON k.id = e.KennelId
                LEFT OUTER JOIN HC.HasherKennelMap hkm
                    ON hkm.UserId = @payer_userIdGuid AND hkm.KennelId = k.id
                WHERE e.id = @eventId;

                SET @runPrice = @runPrice - @runDiscountAmount;
                SET @runPrice = @runPrice - (@runPrice * (@runDiscountPercent / 100.0));
                IF (@runPrice < 0) SET @runPrice = 0;

                -- Run-leg method: same family as the membership payment;
                -- other-amount variants map to their base type (the explicit
                -- amount was the membership fee — the run leg is charged at
                -- the computed price). Zero price ⇒ FREE + provenance tag.
                DECLARE @runPaymentType SMALLINT =
                    CASE WHEN @runPrice <= 0 THEN 2
                         WHEN @paymentType = 5 THEN 3
                         WHEN @paymentType = 7 THEN 4
                         WHEN @paymentType = 8 THEN 6
                         ELSE @paymentType END;
                DECLARE @runNotes NVARCHAR(500) =
                    CASE WHEN @runPrice <= 0 THEN 'member' ELSE NULL END;
                -- Hash-credit legs record credit 0 (balance is recomputed
                -- post-commit), mirroring the main path.
                DECLARE @runCredit MONEY =
                    CASE WHEN @runPaymentType IN (6, 8) THEN 0 ELSE @runPrice END;

                -- One active run payment per HEM — same invariant as the
                -- main productType-1 path.
                UPDATE HC.Payment SET
                    IsCancelled        = 1,
                    CancelledDate      = GETDATE(),
                    CancelledBy_UserId = @userId,
                    updatedAt          = GETDATE()
                WHERE CancelledDate IS NULL AND HasherEventMapId = @hasherEventMapId
                  AND ProductType = 1;

                DECLARE @runRef NVARCHAR(50) =
                    'HC:' + HC.NUMBER_TO_STR_BASE(36, (RAND() * (2147483647 - 60466177)) + 60466176);
                DECLARE @runRefCount INT = 1;
                WHILE (@runRefCount > 0)
                BEGIN
                    SELECT @runRefCount = COUNT(*) FROM HC.Payment WHERE PaymentReference = @runRef;
                    IF (@runRefCount > 0)
                        SET @runRef = LEFT(@runRef, 3) + HC.NUMBER_TO_STR_BASE(36, (RAND() * (2147483647 - 60466177)) + 60466176);
                END

                INSERT HC.Payment
                    ([KennelId], [UserId], [EventId], [HasherEventMapId],
                     [CreditAmount], [DebitAmount], [CreditAvailable],
                     [PaymentProcessedBy_userId], [PaidDate],
                     [PaymentType], [ProductType], [PaymentReference],
                     [DoPayForExtras], [PaymentProvider],
                     [DiscountAmount], [DiscountPercent], [DiscountDescription],
                     [SpecialRunPriceReason], [Surcharge],
                     [PreviousMembershipExpiry], [Notes], [updatedAt])
                VALUES
                    (@kennelId, @payer_userIdGuid, @eventId, @hasherEventMapId,
                     @runCredit, @runPrice, 0,
                     @userId, GETDATE(),
                     @runPaymentType, 1, @runRef,
                     0, @paymentProvider,
                     @runDiscountAmount, @runDiscountPercent, @runDiscountDescription,
                     '', 0,
                     NULL, @runNotes, GETDATE());

                -- Check the payer in — attendance floor defaults to 20
                -- (at the hash) when the caller didn't specify.
                UPDATE HC.HasherEventMap SET
                    UserStartEvent   = GETDATE(),
                    RsvpState        = 3,
                    AttendenceState  = CASE WHEN COALESCE(AttendenceState, 0) < COALESCE(@minimumAttendenceValue, 20)
                                            THEN COALESCE(@minimumAttendenceValue, 20) ELSE AttendenceState END,
                    updatedAt        = GETDATE()
                WHERE id = @hasherEventMapId;

                SELECT @attendenceState = AttendenceState
                FROM HC.HasherEventMap WHERE id = @hasherEventMapId;

                SET @runFeeCharged     = @runPrice;
                SET @runFeePaymentType = @runPaymentType;
            END
        END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1940; SET @errorType = 19; SET @errorId = NEWID();
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
EXEC HC6.nonApi_updateKennelCreditByUser @userId = @payer_userIdGuid, @kennelId = @kennelId;
SELECT @creditAvailable = hkm.KennelCredit FROM HC.HasherKennelMap hkm
WHERE hkm.UserId = @payer_userIdGuid AND hkm.KennelId = @kennelId;

IF (@userIdWhoPaid IS NOT NULL)
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @userIdWhoPaid;

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
    @discountDescription AS discountDescription,
    -- productType = 2 only: the expiry just written, so the app can show
    -- "membership now valid until X" without waiting for a sync. NULL for
    -- other products (additive column — see contract).
    @newMemberExpiry     AS newMembershipExpiry,
    -- Combined membership+run only (@alsoPayRunFee = 1): what the run leg
    -- charged and how it was recorded (2 = free run). NULL otherwise
    -- (additive columns — see contract).
    @runFeeCharged       AS runFeeAmount,
    @runFeePaymentType   AS runFeePaymentType;

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
