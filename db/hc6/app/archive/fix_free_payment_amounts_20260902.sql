-- =====================================================================
-- RUN-ONCE: zero the amounts on historic "Free" payments
--
-- NOT RUN YET. Safe to run as-is: every affected row nets to zero both
-- before and after, in whatever currency it is denominated.
--
-- A Free payment (PaymentType 2) should record no money in and nothing
-- charged. Most already do: 9,601 of 9,629 live Free rows are already 0/0,
-- because the event price was itself zero. The exception is a comped run at
-- a PRICED event, which took the ELSE branch in hcapp_processPayment and
-- recorded CreditAmount = DebitAmount = the event price. That nets to zero,
-- so BALANCES ARE UNAFFECTED - but it books phantom cash received and
-- phantom revenue earned.
--
-- Live but uncommon: 7 of 487 Free rows in the last 90 days (1.4%).
-- The SP is fixed separately; this only cleans history.
--
-- 28 rows total. NOTE the amounts are NOT evenly spread:
--     2026  8 rows     162.50   (largest    50.00)
--     2025  4 rows      35.00   (largest    10.00)
--     2023  8 rows   20260.00   (largest 20000.00)  <-- see below
--     2021  3 rows     180.00   (largest    60.00)
--     2020  4 rows      20.00   (largest     5.00)
--     2019  1 row        5.00
--
-- The 2023 row for 20,000.00 is NOT an error, despite looking like one: it is
-- Osan Bulgogi H3 in South Korea, so that is 20,000 KRW, about GBP 12 - an
-- ordinary run fee. Likewise Beijing at 60 CNY and Fengyuan at 50 TWD.
--
-- NOTE FOR ANY FUTURE MONEY REPORTING: the total above mixes currencies and is
-- therefore meaningless. HC.Kennel.CurrencyCode exists but is unpopulated for
-- 393 of 394 kennels, so the database offers no signal here - currency is
-- implied only by where the kennel is. Money may be summed WITHIN a kennel and
-- must never be summed ACROSS kennels.
--
-- Sync impact: unlike the CreditKind ALTER (metadata-only, zero churn), this
-- is a real UPDATE and WILL fire trgUpdateModifiedOnDateForPayment, so these
-- rows re-sync to clients. 28 rows is negligible.
--
-- Balances are provably untouched: NetPayment is computed as
-- CreditAmount - DebitAmount, and both sides go to zero together, so every
-- affected row's NetPayment stays 0. No balance recompute is needed.
-- =====================================================================
SET NOCOUNT ON;

-- 1. Review the rows first, largest first.
SELECT TOP 30
       id, KennelId, UserId, PaidDate,
       CreditAmount, DebitAmount, NetPayment, Notes
FROM   HC.Payment WITH (NOLOCK)
WHERE  isCancelled = 0 AND PaymentType = 2
  AND  (CreditAmount <> 0 OR DebitAmount <> 0)
ORDER  BY DebitAmount DESC;

-- 2. Zero them. Deliberately skips anything whose NetPayment is not already
--    zero: such a row is not the symptom described above and must be looked
--    at by hand rather than swept up here.
/*  UNCOMMENT TO RUN
UPDATE HC.Payment
SET    CreditAmount = 0,
       DebitAmount  = 0,
       updatedAt    = GETDATE()
WHERE  isCancelled = 0
  AND  PaymentType = 2
  AND  (CreditAmount <> 0 OR DebitAmount <> 0)
  AND  NetPayment = 0;

SELECT @@ROWCOUNT AS RowsZeroed;
*/
