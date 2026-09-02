-- =====================================================================
-- RUN-ONCE: HC.Payment.CreditKind — paid vs promotional credit
--
-- ⚠️ JAMES MUST RUN THIS. Not run autonomously: HC.Payment is a synced
--    table carrying trgUpdateModifiedOnDateForPayment, and the project rule
--    is that no ALTER TABLE ADD COLUMN goes near a synced table without the
--    trigger being disabled first. ~91,000 payment rows would otherwise risk
--    a fresh updatedAt each, and every client would re-sync the lot.
--
--    (For what it is worth, adding a fixed-length NOT NULL column with a
--    DEFAULT should be metadata-only on Azure SQL — no row updates, and DML
--    triggers do not fire on DDL anyway. The disable/enable below is belt and
--    braces, and costs nothing.)
--
-- WHY THE COLUMN IS NEEDED
--   Credit is a running SUM(NetPayment) per (UserId, KennelId). To spend
--   promotional credit FIRST you must know, for every row, which bucket it
--   moves — and a spend cannot be inferred: paying a run fee from credit is
--   PaymentType 6 ('H', Hash Credit) whether it draws on cash or on a bonus.
--   With CreditKind the balance splits cleanly:
--       promoBalance = SUM(NetPayment) WHERE CreditKind = 2
--       paidBalance  = SUM(NetPayment) WHERE CreditKind = 1
--   and a spend that straddles the boundary is written as two rows.
--
--   Existing rows default to 1 (paid), which is correct: no promotional
--   credit has ever been issued.
--
-- ALSO ALLOCATED BY THIS WORK (no schema change needed, values are free):
--   ProductType 4 = kennel credit purchase / grant
--       (1 = run fee, 90,899 rows; 2 = membership, 4; 3 = haberdashery, 1)
--   PaymentType 9 = 'P' / 'Promotional' — a grant, no tender taken
--       (existing: 0 ?, 1 X, 2 F Free, 3 C Cash, 4 B Bank Transfer,
--        5 C?, 6 H Hash Credit, 7 B?, 8 H?)
-- =====================================================================
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('HC.Payment') AND name = 'CreditKind')
BEGIN
    PRINT 'CreditKind already present — nothing to do.';
    RETURN;
END

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;

BEGIN TRY
    ALTER TABLE HC.Payment
        ADD CreditKind SMALLINT NOT NULL
            CONSTRAINT DF_Payment_CreditKind DEFAULT (1);   -- 1 = paid, 2 = promotional
END TRY
BEGIN CATCH
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
    THROW;
END CATCH

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;

-- Confirm nothing was churned: UpdatedAt should NOT have moved.
SELECT COUNT(*) AS PaymentsTouchedInLastMinute
FROM   HC.Payment WITH (NOLOCK)
WHERE  updatedAt >= DATEADD(MINUTE, -1, SYSUTCDATETIME());

SELECT CreditKind, COUNT(*) AS Rows_
FROM   HC.Payment WITH (NOLOCK) GROUP BY CreditKind;
