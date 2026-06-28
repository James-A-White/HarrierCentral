-- =====================================================================
-- Run-once: missing indexes identified by the 2026-06-28 static SP index
-- audit (see memory project_sp_index_audit). Additive, ONLINE, idempotent.
-- Creating an index does NOT fire the UpdatedAt trigger (only ALTER ADD
-- COLUMN does), so no trigger-disable needed.
-- After running, move to db/hc6/portal/archive/ per the run-once convention.
-- Deferred (need more data / a rewrite first): the DROP candidates, the
-- Kennel(CityId/ProvinceStateId) LOW indexes, and the publicWeb global-runs
-- index (requires a sargable query rewrite to be usable).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- HIGH 1: event-scoped payment lookups (processBulkPayment, getPaymentReport,
-- syncEventAdminData, nonApi_updateKennelCreditByUser) had no EventId index.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Payment_EventId' AND object_id=OBJECT_ID('HC.Payment'))
    CREATE NONCLUSTERED INDEX IX_Payment_EventId ON HC.Payment (EventId)
        INCLUDE (HasherEventMapId, UserId, PaymentType, CancelledBy_UserId, CancelledDate, NetPayment, CreditAvailable)
        WITH (ONLINE = ON);

-- HIGH 2: per-user incremental payment sync (syncUserData / syncKennelAdminData).
-- IX_CreditBalance is filtered isCancelled=0 so can't serve sync, and isn't
-- ordered by updatedAt.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Payment_UserId_UpdatedAt' AND object_id=OBJECT_ID('HC.Payment'))
    CREATE NONCLUSTERED INDEX IX_Payment_UserId_UpdatedAt ON HC.Payment (UserId, updatedAt)
        WITH (ONLINE = ON);

-- MED 3: chat fetch (getEventMessages) + the per-event badge subquery in getEvents.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_EventMessage_EventId' AND object_id=OBJECT_ID('HC.EventMessage'))
    CREATE NONCLUSTERED INDEX IX_EventMessage_EventId ON HC.EventMessage (EventId, Removed)
        INCLUDE (createdAt, UserId)
        WITH (ONLINE = ON);

-- MED 4: event-admin sync scans Receipt by EventId.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Receipt_EventId_UpdatedAt' AND object_id=OBJECT_ID('HC.Receipt'))
    CREATE NONCLUSTERED INDEX IX_Receipt_EventId_UpdatedAt ON HC.Receipt (EventId, updatedAt)
        WITH (ONLINE = ON);

-- MED 5: getLoginHistory filters UserId but every LaunchAndLogin index leads on LoginDate.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_LaunchAndLogin_UserId_LoginDate' AND object_id=OBJECT_ID('HC.LaunchAndLogin'))
    CREATE NONCLUSTERED INDEX IX_LaunchAndLogin_UserId_LoginDate ON HC.LaunchAndLogin (UserId, LoginDate DESC)
        INCLUDE (CityId, DeviceName, DeviceType, SystemName, SystemVersion, HcVersion)
        WITH (ONLINE = ON);

-- LOW 6: getEvents badge-count subquery filters EventMessageBadgeCounts by EventId.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_EventMessageBadgeCounts_EventId' AND object_id=OBJECT_ID('HC.EventMessageBadgeCounts'))
    CREATE NONCLUSTERED INDEX IX_EventMessageBadgeCounts_EventId ON HC.EventMessageBadgeCounts (EventId)
        INCLUDE (UserId, LastSequenceCount, Removed)
        WITH (ONLINE = ON);
