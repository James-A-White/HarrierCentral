-- =====================================================================
-- Run-once performance indexes supporting HC6.hcportal_getKennelHashers
-- (the Kennel Members & Followers page). Safe/additive — no row changes,
-- built ONLINE. Idempotent (guarded by sys.indexes checks).
-- Created: 2026-06-28
-- After running, move to db/hc6/portal/archive/ per the run-once convention.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- #1 Payment.HasherEventMapId — the biggest win. Without it the per-event
-- payment joins (cte2/cte3) scan the entire, ever-growing Payment table twice
-- on every load. This lets them seek; INCLUDE covers the projected columns.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Payment_HasherEventMapId'
      AND object_id = OBJECT_ID('HC.Payment')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Payment_HasherEventMapId
        ON HC.Payment (HasherEventMapId)
        INCLUDE (paymentTypeCode, CancelledBy_UserId)
        WITH (ONLINE = ON);
END

-- #2 Event(KennelId, IsCountedRun, EventStartDatetime) — makes the
-- last/second-last/next-event TOP(1) lookups pure seeks (they were sorting on
-- EventStartDatetime, which only the unrelated *Indexed datetimeoffset column
-- covered).
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Event_Kennel_Counted_Start'
      AND object_id = OBJECT_ID('HC.Event')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Event_Kennel_Counted_Start
        ON HC.Event (KennelId, IsCountedRun, EventStartDatetime)
        WITH (ONLINE = ON);
END

-- #3 KennelCredit(kennelId, userId) — the credit-balance LEFT JOIN couldn't
-- seek because the PK is clustered on id only.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_KennelCredit_Kennel_User'
      AND object_id = OBJECT_ID('HC.KennelCredit')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_KennelCredit_Kennel_User
        ON HC.KennelCredit (kennelId, userId)
        INCLUDE (currentBalance)
        WITH (ONLINE = ON);
END
