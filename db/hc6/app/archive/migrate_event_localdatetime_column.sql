-- =====================================================================
-- Run-once migration: HC.Event.EventStartLocal persisted computed column
-- Purpose: Introduce a clean, deterministic local-wall-clock datetime
--          column to replace the trigger-maintained EventStartDatetimeIndexed
--          as the sort/seek key for run-numbering, stats, sync narrowing and
--          usage queries.
--
-- EventStartDatetimeIndexed is currently a base column maintained by trigger
-- trgRecalculateRunCounts as: CASE WHEN UseFbRunDetails=1 THEN FB time ELSE
-- manual time END, CONVERT(datetime2,...) then implicitly re-wrapped to
-- datetimeoffset +00:00. That is the wall-clock of the EFFECTIVE (FB-aware)
-- start time. It has 4 stale rows (trigger only fires on specific UPDATEs).
--
-- EventStartLocal reproduces the SAME value as a PERSISTED COMPUTED column
-- (same expression as SyncEventStartDatetime, wrapped to datetime2). Being
-- computed it is always correct (self-heals the drift) and needs no trigger.
-- CONVERT(datetime2, datetimeoffset) is deterministic, so the column is
-- persistable and indexable (proven via temp-table test on this DB).
--
-- PHASED / NON-DESTRUCTIVE: EventStartDatetimeIndexed, its trigger and its
-- indexes are LEFT IN PLACE. Consumers are repointed to EventStartLocal in
-- this same change-set; the old column is dropped in a later phase once the
-- new column is proven in production.
--
-- IMPORTANT: HC.Event is a mobile-synced table. The UpdatedAt/ModifiedOn
-- stamping trigger (trgUpdateModifiedOnDateForEvent) is disabled across the
-- ALTER so it does not stamp every row and force an unnecessary full re-sync,
-- then re-enabled.
--
-- Author:  Harrier Central
-- Created: 2026-06-28
-- Run-once: archive after running (deploy script must not re-run it).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Step 1: disable the UpdatedAt/ModifiedOn stamping trigger.
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- Step 2: add the persisted computed local-wall-clock column (FB-aware,
-- identical value to EventStartDatetimeIndexed, as datetime2).
ALTER TABLE HC.Event
    ADD EventStartLocal AS CONVERT(datetime2(7),
        CASE WHEN UseFbRunDetails = 1 THEN CONVERT(datetimeoffset, FbEventStartDatetime)
             ELSE CONVERT(datetimeoffset, EventStartDatetime) END) PERSISTED;
GO

-- Step 3: re-enable the stamping trigger.
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- Step 4: mirror indexes on EventStartLocal (parallel the existing
-- EventStartDatetimeIndexed indexes so repointed SPs stay fast). FILLFACTOR 80
-- matches the existing family; ONLINE to avoid blocking.
CREATE NONCLUSTERED INDEX IX_Event_EventStartLocal
    ON HC.Event (EventStartLocal)
    WITH (FILLFACTOR = 80, ONLINE = ON);
GO

CREATE NONCLUSTERED INDEX IX_EvtRunCount_Local
    ON HC.Event (EventStartLocal)
    INCLUDE (KennelId, EventNumber)
    WHERE IsCountedRun = 1 AND IsVisible = 1 AND removed = 0
    WITH (FILLFACTOR = 80, ONLINE = ON);
GO

CREATE NONCLUSTERED INDEX IX_EventUsageData_Local
    ON HC.Event (EventStartLocal)
    INCLUDE (KennelId, EventName, EventStartDatetime, FbEventName, createdAt, updatedAt, UseFbRunDetails)
    WHERE IsVisible = 1
    WITH (FILLFACTOR = 80, ONLINE = ON);
GO
