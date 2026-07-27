-- =====================================================================
-- RUN-ONCE MIGRATION — add HC.Kennel.AllowCredit (per-kennel credit setting)
-- =====================================================================
-- Adds a kennel-level "allow credit payments" setting, sibling to
-- AllowNegativeCredit. DEFAULT 1 = opt-out model: every existing and new
-- kennel keeps credit ON (matches the app's prior hardcoded creditAllowed:1),
-- and a kennel can now turn credit OFF from the portal Hash Cash tab.
--
-- No data migration is required: DEFAULT 1 backfills all existing rows to 1,
-- which is the correct/no-regression value for every kennel (including the
-- ~40 that actively use credit).
--
-- HC.Kennel is a mobile-synced table. Per project rule, its UpdatedAt trigger
-- MUST be disabled before ALTER and re-enabled after, so the add-column does
-- not re-stamp every row and force a full re-replication to all clients.
--
-- ⚠️  RUN MANUALLY, ONCE. Do NOT add to the deploy script. After running,
--     move this file to db/hc6/app/archive/.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- 1. Silence the UpdatedAt trigger for the duration of the schema change.
DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];

-- 2. Add the column, defaulting every existing row to 1 (credit allowed).
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HC.Kennel') AND name = 'AllowCredit'
)
BEGIN
    ALTER TABLE [HC].[Kennel]
        ADD [AllowCredit] SMALLINT NOT NULL
        CONSTRAINT [DF_Kennel_AllowCredit] DEFAULT ((1));
END

-- 3. Re-enable the trigger.
ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];

COMMIT TRANSACTION;

-- Sanity check.
SELECT COUNT(*) AS totalKennels,
       SUM(CASE WHEN AllowCredit = 1 THEN 1 ELSE 0 END) AS creditAllowed,
       SUM(CASE WHEN AllowCredit = 0 THEN 1 ELSE 0 END) AS creditDisabled
FROM [HC].[Kennel];
