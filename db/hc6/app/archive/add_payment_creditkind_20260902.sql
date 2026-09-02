-- ============================ SUPERSEDED ============================
-- RAN 2026-09-02, then BACKED OUT the same day by
-- add_promotional_credit_columns_20260902.sql.
--
-- CreditKind marked which bucket a payment row moved. That was only
-- needed while the plan was to SPLIT a payment straddling the promo/cash
-- boundary across two rows. James's four-amount design puts both
-- movements on ONE row, so the marker is redundant and the column is
-- gone. No code ever used it.
--
-- The ProductType 4 / PaymentType 9 allocations noted below were never
-- implemented anywhere and are not part of the final design.
-- Kept for the record only. DO NOT RUN.
-- ===================================================================

-- =====================================================================
-- RUN-ONCE: HC.Payment.CreditKind - paid vs promotional credit
--
-- HC.Payment is a synced table carrying trgUpdateModifiedOnDateForPayment.
-- The project rule is that no ALTER TABLE ADD COLUMN goes near a synced
-- table without the trigger being disabled first: ~91,000 rows would
-- otherwise risk a fresh updatedAt each, and every client would re-sync
-- the lot. James gave explicit approval to run this on 2026-09-02.
--
-- (Adding a fixed-length NOT NULL column with a DEFAULT should be
-- metadata-only on Azure SQL - no row updates - and DML triggers do not
-- fire on DDL anyway. The disable/enable is belt and braces and costs
-- nothing. The verification at the end proves whether anything churned.)
--
-- Batches are separated by GO so the ENABLE TRIGGER still runs even if the
-- ALTER fails. Kept ASCII-only: non-ASCII in comments broke sqlcmd parsing
-- on the first attempt.
--
-- WHY THE COLUMN IS NEEDED
--   Credit is a running SUM(NetPayment) per (UserId, KennelId). To spend
--   promotional credit FIRST you must know which bucket every row moves,
--   and a spend cannot be inferred: paying a run fee from credit is
--   PaymentType 6 ('H', Hash Credit) whether it draws on cash or a bonus.
--       promoBalance = SUM(NetPayment) WHERE CreditKind = 2
--       paidBalance  = SUM(NetPayment) WHERE CreditKind = 1
--   A spend straddling the boundary is written as two rows.
--
--   Existing rows default to 1 (paid), which is correct: no promotional
--   credit has ever been issued.
--
-- ALSO ALLOCATED BY THIS WORK (values are free, no schema change needed):
--   ProductType 4 = kennel credit purchase / grant
--       (1 = run fee 90,899 rows; 2 = membership 4; 3 = haberdashery 1)
--   PaymentType 9 = 'P' / 'Promotional' - a grant, no tender taken
--       (existing 0 ?, 1 X, 2 F Free, 3 C Cash, 4 B Bank Transfer,
--        5 C?, 6 H Hash Credit, 7 B?, 8 H?)
-- =====================================================================

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.Payment') AND name = 'CreditKind')
    ALTER TABLE HC.Payment
        ADD CreditKind SMALLINT NOT NULL
            CONSTRAINT DF_Payment_CreditKind DEFAULT (1);
GO

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
GO

SET NOCOUNT ON;

SELECT (SELECT COUNT(*) FROM sys.columns
        WHERE object_id = OBJECT_ID('HC.Payment') AND name = 'CreditKind') AS ColumnPresent,
       (SELECT is_disabled FROM sys.triggers
        WHERE parent_id = OBJECT_ID('HC.Payment')
          AND name = 'trgUpdateModifiedOnDateForPayment')                  AS TriggerDisabled,
       (SELECT COUNT(*) FROM HC.Payment WITH (NOLOCK)
        WHERE updatedAt >= DATEADD(MINUTE, -5, SYSUTCDATETIME()))          AS RowsChurnedLast5Min;

SELECT CreditKind, COUNT(*) AS Rows_ FROM HC.Payment WITH (NOLOCK) GROUP BY CreditKind;
