CREATE OR ALTER PROCEDURE [HC6].[hcapp_processBulkPayment]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @userIdsWhoPaid              NVARCHAR(MAX)      = NULL,
    @eventId                     UNIQUEIDENTIFIER,
    @paymentType                 SMALLINT,
    @productType                 SMALLINT           = 1,
    @hasherEventMapUpdatedAfter  NVARCHAR(50)       = 'ignore',
    @hasherKennelMapUpdatedAfter NVARCHAR(50)       = 'ignore',
    @paymentsUpdatedAfter        NVARCHAR(50)       = 'ignore',
    @transactionTimestamp        NVARCHAR(50)       = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_processBulkPayment
-- Description: Records payments for multiple hashers at a single event
--   in one operation. @userIdsWhoPaid is a comma-separated list of
--   UNIQUEIDENTIFIER strings. HEM rows are upserted (attendance set to
--   20), existing uncancelled payments cancelled, and new payment rows
--   inserted with per-hasher pricing (member vs. non-member rate with
--   discount applied). Uses a set-based INSERT instead of a cursor.
--
--   Supported paymentTypes: 2=free, 3=cash, 4=bank transfer,
--   5=cash other, 6=hash credit, 7=bank transfer other, 8=credit other.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @userIdsWhoPaid              - Comma-separated UNIQUEIDENTIFIER strings
--   @eventId                     - The event being paid for
--   @paymentType                 - Payment method (2–8 only; 1 and 100 not supported)
--   @productType                 - 1=event, 2=membership, 3=haberdashery
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
--   @paymentsUpdatedAfter        - Sync watermark for Payments
--   @transactionTimestamp        - Optional PaidDate override (ISO string)
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, serverMessage }
--   On success (rowset 2+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_processBulkPayment
-- Breaking Changes:
--   @userIdsWhoPaid widened VARCHAR(8000) → NVARCHAR(MAX).
--   CURSOR replaced with set-based INSERT (removes per-row locking,
--     avoids cursor overhead, improves performance).
--   TRY/CATCH and transaction added (HC5 had neither).
--   DATALENGTH → LEN for string checks.
--   Success envelope added.
--   Delegation target updated to HC6.hcapp_syncEventAdminData.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

IF (@productType IS NULL) SET @productType = 1;

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 41,
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
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Parameter validation
-- ---------------------------------------------------------------
IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1241; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId', 'eventId is required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@userIdsWhoPaid IS NULL)
BEGIN
    SET @errorCode = 1241; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null userIdsWhoPaid', '@userIdsWhoPaid is required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing hasher list' AS errorTitle, 'At least one hasher must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        DECLARE @queryStart  DATETIME = DATEADD(SECOND, -1, GETDATE());
        DECLARE @kennelId    UNIQUEIDENTIFIER;
        SELECT @kennelId = evt.KennelId FROM HC.Event evt WHERE evt.id = @eventId;

        -- ---------------------------------------------------------------
        -- Upsert HEM rows: update existing, insert missing
        -- ---------------------------------------------------------------
        ;WITH ParsedGuids AS (
            SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
            FROM STRING_SPLIT(@userIdsWhoPaid, ',')
            WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
        )
        UPDATE hem SET
            hem.AttendenceState = 20,
            hem.RsvpState       = 3,
            hem.updatedAt       = GETDATE()
        FROM HC.HasherEventMap hem
        INNER JOIN ParsedGuids pg ON pg.UserId = hem.UserId
        WHERE hem.EventId = @eventId;

        DECLARE @updatedRowCount INT = @@ROWCOUNT;

        ;WITH ParsedGuids AS (
            SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
            FROM STRING_SPLIT(@userIdsWhoPaid, ',')
            WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
        )
        INSERT INTO HC.HasherEventMap
            ([id], [EventId], [KennelId], [UserId],
             [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
        SELECT
            NEWID(), @eventId, @kennelId, pg.UserId,
            20, 3, 0, 0, GETDATE()
        FROM ParsedGuids pg
        LEFT OUTER JOIN HC.HasherEventMap hem ON hem.UserId = pg.UserId AND hem.EventId = @eventId
        WHERE hem.id IS NULL;

        DECLARE @insertedRowCount INT = @@ROWCOUNT;

        -- ---------------------------------------------------------------
        -- Set DoTrackHashCash flag
        -- ---------------------------------------------------------------
        UPDATE HC.Event SET DoTrackHashCash = 1
        WHERE id = @eventId AND DoTrackHashCash != 1;

        -- ---------------------------------------------------------------
        -- Cancel any existing uncancelled payments for these hashers
        -- ---------------------------------------------------------------
        ;WITH ParsedGuids AS (
            SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
            FROM STRING_SPLIT(@userIdsWhoPaid, ',')
            WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
        )
        UPDATE pay SET
            pay.CancelledBy_UserId = @userId,
            pay.CancelledDate      = GETDATE(),
            pay.IsCancelled        = 1,
            pay.updatedAt          = GETDATE()
        FROM HC.Payment pay
        INNER JOIN ParsedGuids pg ON pg.UserId = pay.UserId
        WHERE pay.EventId = @eventId AND pay.CancelledDate IS NULL;

        -- ---------------------------------------------------------------
        -- Insert new payment rows (set-based, per-hasher pricing)
        -- ---------------------------------------------------------------
        IF (@paymentType >= 2 AND @paymentType <= 8)
        BEGIN
            -- paymentType = 6 (hash credit): auto-create follower HKM records for
            -- hashers who don't have one yet so credit can be accumulated and spent
            -- by non-members and visitors.
            IF (@paymentType = 6)
            BEGIN
                INSERT HC.HasherKennelMap (
                    UserId, KennelId, Following, IsKennelFollowing, IsMember,
                    CanEditRunAttendence, MemberSince, updatedAtBias
                )
                SELECT
                    TRY_CAST(s.value AS UNIQUEIDENTIFIER), @kennelId, 1, 1, 0, 0, NULL,
                    CONVERT(INT, ABS(CONVERT(BIGINT, CONVERT(VARBINARY(8), NEWID(), 1)) / 40020.2323 % 999999))
                FROM STRING_SPLIT(@userIdsWhoPaid, ',') s
                WHERE TRY_CAST(s.value AS UNIQUEIDENTIFIER) IS NOT NULL
                  AND EXISTS (SELECT 1 FROM HC.Hasher WHERE id = TRY_CAST(s.value AS UNIQUEIDENTIFIER))
                  AND NOT EXISTS (
                      SELECT 1 FROM HC.HasherKennelMap hkm
                      WHERE hkm.UserId = TRY_CAST(s.value AS UNIQUEIDENTIFIER)
                        AND hkm.KennelId = @kennelId
                        AND hkm.removed = 0
                  );
            END

            ;WITH ParsedGuids AS (
                SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
                FROM STRING_SPLIT(@userIdsWhoPaid, ',')
                WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
            ),
            Pricing AS (
                SELECT
                    hem.id                                          AS hasherEventMapId,
                    hem.UserId                                      AS payerUserId,
                    k.id                                            AS kennelId,
                    (CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE()
                        THEN COALESCE(e.EventPriceForMembers, k.DefaultEventPriceForMembers,
                                      e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
                        ELSE COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers,
                                      e.EventPriceForMembers, k.DefaultEventPriceForMembers, 0)
                    END
                    - COALESCE(hkm.DiscountAmount, 0)
                    ) * (1.0 - (COALESCE(hkm.DiscountPercent, 0) / 100.0)) AS basePrice,
                    COALESCE(hkm.DiscountAmount, 0)                         AS discountAmount,
                    COALESCE(hkm.DiscountPercent, 0)                        AS discountPercent,
                    COALESCE(hkm.DiscountDescription, '')                   AS discountDescription
                FROM HC.HasherEventMap hem
                INNER JOIN HC.Event e     ON e.id  = hem.EventId
                INNER JOIN HC.Kennel k    ON k.id  = e.KennelId
                INNER JOIN ParsedGuids pg ON pg.UserId = hem.UserId
                LEFT OUTER JOIN HC.HasherKennelMap hkm ON hem.UserId = hkm.UserId AND hkm.KennelId = e.KennelId
                WHERE hem.EventId = @eventId
            )
            INSERT HC.Payment
                ([KennelId], [UserId], [EventId], [HasherEventMapId],
                 [CreditAmount], [DebitAmount], [CreditAvailable],
                 [PaymentProcessedBy_userId], [PaidDate],
                 [PaymentType], [ProductType], [PaymentReference],
                 [DoPayForExtras], [PaymentProvider],
                 [DiscountAmount], [DiscountPercent], [DiscountDescription],
                 [SpecialRunPriceReason], [Surcharge], [updatedAt])
            SELECT
                p.kennelId,
                p.payerUserId,
                @eventId,
                p.hasherEventMapId,
                CASE WHEN @paymentType IN (6, 8) THEN 0 ELSE p.basePrice END,
                p.basePrice,
                0,
                @userId,
                COALESCE(CAST(LEFT(@transactionTimestamp, 23) AS DATETIME), GETDATE()),
                @paymentType,
                @productType,
                'HC:' + REPLACE(CAST(NEWID() AS NVARCHAR(40)), '-', ''),
                0, '',
                p.discountAmount, p.discountPercent, p.discountDescription,
                '', 0,
                GETDATE()
            FROM Pricing p;
        END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1941; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- Post-commit: update kennel credits and run counts for all affected users
;WITH ParsedGuids AS (
    SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
    FROM STRING_SPLIT(@userIdsWhoPaid, ',')
    WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
)
SELECT pg.UserId, @kennelId AS kennelId
INTO #tempCreditUpdate
FROM ParsedGuids pg;

DECLARE @curUserId UNIQUEIDENTIFIER;
DECLARE creditCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT UserId FROM #tempCreditUpdate;
OPEN creditCursor;
FETCH NEXT FROM creditCursor INTO @curUserId;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC HC.nonApi_updateKennelCreditByUser @userId = @curUserId, @kennelId = @kennelId;
    FETCH NEXT FROM creditCursor INTO @curUserId;
END
CLOSE creditCursor;
DEALLOCATE creditCursor;
DROP TABLE #tempCreditUpdate;

EXEC HC.nonApi_updateRunCountsForAllUsers @updatedSince = @queryStart;

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

SELECT
    1                                                                              AS adHocDataId,
    CAST(@updatedRowCount AS NVARCHAR(10)) + ' records updated, '
    + CAST(@insertedRowCount AS NVARCHAR(10)) + ' records inserted'               AS serverMessage;

-- ---------------------------------------------------------------
-- Delegate to syncEventAdminData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');
SET @paymentsUpdatedAfter        = COALESCE(@paymentsUpdatedAfter,        'ignore');

EXEC HC6.hcapp_syncEventAdminData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @eventId                     = @eventId,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = 'ignore',
    @paymentsUpdatedAfter        = @paymentsUpdatedAfter,
    @kennelCreditsUpdatedAfter   = 'ignore',
    @receiptsUpdatedAfter        = 'ignore',
    @procName                    = @procName,
    @param                       = @deviceSecret;
