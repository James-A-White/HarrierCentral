-- =====================================================================
-- Run-once: HC.Kennel gains its card-payment provider configuration
--
-- Story:  E8.F7.S2 — "say which payment app my kennel uses, and which
--         merchant account is ours"
-- Author: Harrier Central
-- Created: 2026-09-22
--
-- ⚠ JAMES RUNS THIS, NOT THE DEPLOY SCRIPT, AND NOT CLAUDE.
--   HC.Kennel is a synced table carrying trgUpdateModifiedOnDateForKennels.
--   An ALTER that fires it stamps a current modified date on all ~400 rows,
--   and the sync then pushes every kennel to every phone on the planet. The
--   trigger is disabled and re-enabled around the ALTER below for that
--   reason — check it is ENABLED again afterwards before walking away.
--
--   The file lives in db/hc6/app/ only until it has been run. It matches
--   none of deploy_hc6.sh's globs (HC6.hcapp_*, HC6.nonApi_*, HC6.util_*),
--   so it cannot be re-run by a deploy; move it to db/hc6/app/archive/
--   once executed.
--
-- WHY TWO COLUMNS AND NO TABLE
--   The merchant account itself lives in the provider's own app, not here.
--   All Harrier Central needs to know is which app to hand off to, and which
--   account the money is supposed to land in. That is a property of a
--   kennel, so it is two columns on the kennel — the same shape as
--   DefaultMessagingPlatform / MessagingGroupInviteUrl (E9.F6.S4).
--
-- WHY A LOWERCASE STRING AND NOT AN INT ENUM (James, 2026-09-22)
--   HC.Payment.PaymentProvider is ALREADY NVARCHAR and already holds 331
--   rows of 'PayPal' and 'Tikkie'. An int here would mean translating on
--   every write and leaving the payment reports grouping by one vocabulary
--   while the kennel's config used another. The token a kennel is configured
--   with is the token written onto the payment, and it is the same word the
--   provider's own export uses. The collation is CI_AS, so 'PayPal' and
--   'paypal' are equal on the server; Dart lowercases at the boundary.
--
--   What went wrong with KennelPaymentScheme was not string-ness, it was that
--   it is UNCONSTRAINED — which is why it holds '12', '14' and '16' next to
--   'PayPal'. Hence the CHECK below. Adding a provider means altering that
--   constraint, which is a deploy; with two providers that is the right
--   trade for making junk impossible.
--
-- WHY CardPaymentMerchantCode IS A SAFEGUARD, NOT CONFIG
--   The provider's app on a Hash Cash's phone may be signed into their
--   PERSONAL account. The tap succeeds, the hasher is charged, we record it
--   as paid — and the club never sees the money. A callback alone cannot
--   detect that. Both providers return the merchant identity with the
--   result, so it is compared against this column and a payment taken on the
--   wrong account is refused rather than confirmed.
--
-- SYNC
--   Adding these to the kennel sync rowset is safe for shipped clients:
--   BaseService.normalizeMap filters wire fields down to the columns the
--   local SQLite table actually has, and logs the difference. An older app
--   silently ignores them.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ── 1. Silence the sync-touching trigger ─────────────────────────────
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
GO

-- ── 2. The columns ───────────────────────────────────────────────────
-- Both NULLable with no default, so this is a metadata-only change: no
-- row is written and no table is rewritten.

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.Kennel')
                 AND name = 'CardPaymentProvider')
BEGIN
    -- 'sumup'  — Payment Switch: hand off to their app, the tap happens there
    -- 'zettle' — Payments SDK: the tap happens in Harrier Central, OAuth per
    --            merchant
    -- NULL     — this kennel does not take card through Harrier Central,
    --            which is every kennel on the day this runs.
    ALTER TABLE HC.Kennel ADD CardPaymentProvider NVARCHAR(30) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_Kennel_CardPaymentProvider')
BEGIN
    -- Junk cannot land the way it did in KennelPaymentScheme. Lowercase is
    -- the convention; the CI_AS collation means a stray 'Zettle' still
    -- passes, and still matches, which is the forgiving half of the rule.
    ALTER TABLE HC.Kennel ADD CONSTRAINT CK_Kennel_CardPaymentProvider
        CHECK (CardPaymentProvider IS NULL
               OR CardPaymentProvider IN ('sumup', 'zettle'));
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.Kennel')
                 AND name = 'CardPaymentMerchantCode')
BEGIN
    -- The account the club's money is supposed to land in: SumUp's merchant
    -- code, or Zettle's organisation/merchant id. Compared against what the
    -- provider returns with a completed payment.
    ALTER TABLE HC.Kennel ADD CardPaymentMerchantCode NVARCHAR(100) NULL;
END
GO

-- ── 3. Put the trigger back ──────────────────────────────────────────
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
GO

-- ── 4. Prove it ──────────────────────────────────────────────────────
SELECT c.name AS col, t.name AS type, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('HC.Kennel')
  AND c.name IN ('CardPaymentProvider', 'CardPaymentMerchantCode');

SELECT name AS triggerName, is_disabled
FROM sys.triggers
WHERE parent_id = OBJECT_ID('HC.Kennel')
  AND name = 'trgUpdateModifiedOnDateForKennels';   -- is_disabled MUST be 0
GO
