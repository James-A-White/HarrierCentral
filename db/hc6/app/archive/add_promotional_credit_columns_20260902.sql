-- =====================================================================
-- RUN-ONCE: promotional credit as a second pair of amounts per payment
--
-- James's design, 2026-09-02. Every payment row carries FOUR values:
--     CreditAmount        money the hasher paid in
--     DebitAmount         money the kennel charged
--     PromotionalCredit   promotional credit granted
--     PromotionalDebit    promotional credit consumed
--
-- A run costing 7 paid by a hasher with 2 promo left is ONE row:
--     Credit 0 | Debit 5 | PromoCredit 0 | PromoDebit 2
-- A package (pay 70, get 7 bonus) is also ONE row:
--     Credit 70 | Debit 0 | PromoCredit 7 | PromoDebit 0
--
-- One payment stays one row, which keeps clientPaymentId usable as the
-- primary key (the idempotency design), keeps isCancelled meaningful, and
-- keeps the transaction screen showing one line per real-world event.
-- Cancelling a row restores consumed promo for free, since a cancelled row
-- drops out of both sums.
--
-- Promotional balance FLOORS AT ZERO: PromotionalDebit = MIN(fee, available).
-- Cash absorbs any overdraft, as it already does for 72 hashers today. You
-- cannot owe the kennel a favour it gave you.
--
-- BACKS OUT CreditKind, added earlier the same day. It marked which bucket a
-- row moved, which was only needed while the plan was to SPLIT a straddling
-- payment across two rows. Four amounts on one row make it redundant, and an
-- unused column implying a design we did not build is a trap.
--
-- ProductType 4 and PaymentType 9 were allocated in a comment earlier and
-- were NEVER implemented anywhere. Not introduced here either: a grant is
-- just a row with PromotionalCredit set.
--
-- smallmoney to match CreditAmount/DebitAmount and the computed NetPayment.
-- (CLAUDE.md prefers DECIMAL(10,4) for new money columns; symmetry with the
-- sibling columns this sits beside matters more, and NetPromotional has to
-- derive cleanly alongside NetPayment.)
--
-- Synced tables: triggers disabled around the DDL per project rule. Adding a
-- fixed-length NOT NULL column with a DEFAULT is metadata-only, so no churn
-- is expected; the verification at the end proves it.
-- =====================================================================

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
GO
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherKennelMap ON HC.HasherKennelMap;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id=OBJECT_ID('HC.Payment') AND name='PromotionalCredit')
    ALTER TABLE HC.Payment ADD
        PromotionalCredit SMALLMONEY NOT NULL CONSTRAINT DF_Payment_PromoCredit DEFAULT (0),
        PromotionalDebit  SMALLMONEY NOT NULL CONSTRAINT DF_Payment_PromoDebit  DEFAULT (0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id=OBJECT_ID('HC.Payment') AND name='NetPromotional')
    ALTER TABLE HC.Payment ADD
        NetPromotional AS ([PromotionalCredit] - [PromotionalDebit]);
GO

-- Back out CreditKind (added 2026-09-02, superseded before any code used it).
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id=OBJECT_ID('HC.Payment') AND name='CreditKind')
BEGIN
    IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name='DF_Payment_CreditKind')
        ALTER TABLE HC.Payment DROP CONSTRAINT DF_Payment_CreditKind;
    ALTER TABLE HC.Payment DROP COLUMN CreditKind;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id=OBJECT_ID('HC.HasherKennelMap') AND name='PromotionalCredit')
    ALTER TABLE HC.HasherKennelMap ADD
        PromotionalCredit SMALLMONEY NOT NULL CONSTRAINT DF_HKM_PromoCredit DEFAULT (0);
GO

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
GO
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherKennelMap ON HC.HasherKennelMap;
GO

SET NOCOUNT ON;
SELECT
  (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('HC.Payment')
     AND name IN ('PromotionalCredit','PromotionalDebit','NetPromotional'))        AS PaymentColsAdded_expect3,
  (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('HC.Payment')
     AND name='CreditKind')                                                        AS CreditKindRemaining_expect0,
  (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('HC.HasherKennelMap')
     AND name='PromotionalCredit')                                                 AS HkmColAdded_expect1,
  (SELECT COUNT(*) FROM sys.triggers WHERE parent_id IN
     (OBJECT_ID('HC.Payment'),OBJECT_ID('HC.HasherKennelMap')) AND is_disabled=1)   AS TriggersLeftDisabled_expect0,
  (SELECT COUNT(*) FROM HC.Payment WITH (NOLOCK)
     WHERE updatedAt >= DATEADD(MINUTE,-5,SYSUTCDATETIME()))                        AS PaymentRowsChurned,
  (SELECT COUNT(*) FROM HC.HasherKennelMap WITH (NOLOCK)
     WHERE updatedAt >= DATEADD(MINUTE,-5,SYSUTCDATETIME()))                        AS HkmRowsChurned;
