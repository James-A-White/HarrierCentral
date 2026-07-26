-- =====================================================================
-- Run-once migration: add HC.DownDowns.ExternalNames
-- Adds a nullable JSON column holding the names of charged people who are
-- NOT registered Harrier Central users, e.g. ["Dizzy Lizzy","Two-Buck Chuck"].
-- In-app hashers continue to be recorded in HC.DownDownHashers; a single
-- charge may mix both.
--
-- HC.DownDowns is NOT a mobile-synced table (it is in no sync domain), so
-- there is no UpdatedAt-trigger / forced-re-replication concern for this ALTER.
--
-- Idempotent: safe to run more than once. Archive to db/hc6/app/archive/
-- after it has been run in production.
-- =====================================================================
SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HC.DownDowns') AND name = 'ExternalNames'
)
BEGIN
    ALTER TABLE HC.DownDowns ADD ExternalNames NVARCHAR(MAX) NULL;
END
