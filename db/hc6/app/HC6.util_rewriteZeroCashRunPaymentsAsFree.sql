CREATE OR ALTER PROCEDURE [HC6].[util_rewriteZeroCashRunPaymentsAsFree]
    @dryRun SMALLINT = 1
AS
-- =====================================================================
-- Procedure: HC6.util_rewriteZeroCashRunPaymentsAsFree
-- Description: One-time data correction (run BY HAND — never called by the
--   API). Historic run payments recorded as cash/bank-transfer/hash-credit
--   with ZERO money moved (Credit = 0 AND Debit = 0 — i.e. price was zero
--   and no extras) are fictions created by the treasurer's tap on a
--   free-for-members run. Rewrites them to PaymentType 2 (Free) with the
--   'member' provenance tag in Notes, matching what hcapp_processPayment
--   1.4.0 records going forward, so payment reports read consistently
--   across old and new runs.
--
--   Scope guards:
--     - ProductType 1 (run payments) only
--     - PaymentType IN (3, 4, 6) only — other-amount types (5/7/8) carry
--       deliberate explicit amounts and are never touched
--     - CreditAmount = 0 AND DebitAmount = 0 (no money, no extras)
--     - Live rows only (CancelledDate IS NULL)
--     - Notes only set when currently NULL (never overwrites)
--
--   The membership-status-at-the-time is not reliably reconstructible, so
--   the tag is 'member' across the board — a zero computed price is
--   overwhelmingly the member entitlement. updatedAt is stamped so the
--   rewritten rows flow to clients via the normal payment delta sync.
--
-- Parameters:
--   @dryRun — 1 (default) = report what WOULD change, write nothing.
--             0 = perform the rewrite.
-- Returns: one rowset — per-kennel count of affected rows, then a summary.
-- Author: Harrier Central
-- Created: 2026-08-16
-- HC5 Source: none (new)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT k.KennelName, COUNT(*) AS rowsAffected,
           MIN(p.PaidDate) AS earliest, MAX(p.PaidDate) AS latest
    FROM HC.Payment p
    INNER JOIN HC.Kennel k ON k.id = p.KennelId
    WHERE p.ProductType = 1
      AND p.PaymentType IN (3, 4, 6)
      AND p.CreditAmount = 0 AND p.DebitAmount = 0
      AND p.CancelledDate IS NULL
    GROUP BY k.KennelName
    ORDER BY COUNT(*) DESC;

    IF (@dryRun = 0)
    BEGIN
        UPDATE HC.Payment SET
            PaymentType = 2,
            Notes       = COALESCE(Notes, 'member'),
            updatedAt   = GETDATE()
        WHERE ProductType = 1
          AND PaymentType IN (3, 4, 6)
          AND CreditAmount = 0 AND DebitAmount = 0
          AND CancelledDate IS NULL;

        SELECT @@ROWCOUNT AS totalRewritten, 0 AS wasDryRun;
    END
    ELSE
        SELECT 0 AS totalRewritten, 1 AS wasDryRun;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in util_rewriteZeroCashRunPaymentsAsFree',
            ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
