-- =====================================================================
-- RUN-ONCE script: membership payment columns (2026-08-07)
-- See docs/membership_payments_plan.md
--
-- ⚠️  BOTH tables are mobile-synced. Their updatedAt triggers MUST be
--     disabled around the ALTER or every row gets re-stamped and every
--     client is forced into a full re-sync. This script does the
--     disable/enable itself — run it as a whole, in one go.
--
-- ⚠️  After running: move this file to db/hc6/archive/ so the deploy
--     script never picks it up.
-- =====================================================================

-- ── HC.Kennel ────────────────────────────────────────────────────────
DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennel] ON [HC].[Kennel];
GO

ALTER TABLE [HC].[Kennel] ADD
    -- 1 = Rolling (extend by MembershipDurationInMonths from max(expiry, today))
    -- 2 = Fixed year (every payment expires at MembershipPeriodEndDate)
    -- 3 = Lifetime (one payment, expiry set to 2999-12-31)
    [MembershipRenewalMode]      SMALLINT       NOT NULL CONSTRAINT [DF_Kennel_MembershipRenewalMode] DEFAULT ((1)),
    -- Fixed-year mode only: the kennel's membership year.
    [MembershipPeriodStartDate]  DATE           NULL,
    [MembershipPeriodEndDate]    DATE           NULL,
    -- Default fee pre-filled in the charge dialog; admin may override.
    [MembershipPrice]            DECIMAL(10, 4) NOT NULL CONSTRAINT [DF_Kennel_MembershipPrice] DEFAULT ((0));
GO

ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennel] ON [HC].[Kennel];
GO

-- ── HC.Payment ───────────────────────────────────────────────────────
DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForPayment] ON [HC].[Payment];
GO

ALTER TABLE [HC].[Payment] ADD
    -- Membership payments only (ProductType = 2): the member's
    -- MembershipExpirationDate as it was BEFORE this payment applied.
    -- The unwind anchor — a replaced/cancelled membership payment
    -- restores this value before a fresh extension is applied.
    [PreviousMembershipExpiry]   DATETIMEOFFSET(7) NULL;
GO

ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForPayment] ON [HC].[Payment];
GO

-- Verify: both triggers re-enabled, columns present.
SELECT t.name AS trigger_name, t.is_disabled
FROM sys.triggers t
WHERE t.name IN ('trgUpdateModifiedOnDateForKennel', 'trgUpdateModifiedOnDateForPayment');

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (TABLE_NAME = 'Kennel'  AND COLUMN_NAME LIKE 'Membership%')
   OR (TABLE_NAME = 'Payment' AND COLUMN_NAME = 'PreviousMembershipExpiry')
ORDER BY TABLE_NAME, COLUMN_NAME;
