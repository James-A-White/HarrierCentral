-- =====================================================================
-- Run-once migration: HC.Event.EventStartLocalDate persisted computed column
-- Purpose: Make publicWeb_getGlobalCalendar's date filter sargable.
--          The SP filters/groups on CAST(EventStartDatetime AS DATE) (the
--          LOCAL calendar date of the run). Wrapping the column in CAST()
--          in the WHERE clause is non-sargable -> full scan of HC.Event.
--          This adds a PERSISTED computed column holding that exact local
--          date, plus a filtered index, so the filter becomes an index seek
--          with identical day-boundary semantics.
--
-- IMPORTANT: HC.Event is a mobile-synced table. The ModifiedOn/UpdatedAt
--          stamping trigger (trgUpdateModifiedOnDateForEvent) MUST be disabled
--          across the ALTER, otherwise it fires per-row and forces a full
--          unnecessary re-sync to every client. It is re-enabled immediately
--          after.
--
-- CAST(datetimeoffset AS DATE) is deterministic (proven via temp-table test)
-- so it is persistable and indexable. The result is the LOCAL wall-clock date
-- of EventStartDatetime, matching the existing SP semantics exactly.
--
-- Author:  Harrier Central
-- Created: 2026-06-28
-- Run-once: archive after running (deploy script must not re-run it).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Step 1: disable the ModifiedOn/UpdatedAt stamping trigger so the ALTER
-- does not touch every row's modified date (which would force a full re-sync).
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- Step 2: add the persisted computed local-date column.
ALTER TABLE HC.Event
    ADD EventStartLocalDate AS CAST(EventStartDatetime AS DATE) PERSISTED;
GO

-- Step 3: re-enable the stamping trigger.
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- Step 4: filtered index on the new local-date column. Mirrors the
-- IX_Event_GmtStart_Visible pattern used for publicWeb_getGlobalRuns.
-- INCLUDE covers every Event-side column the SP reads: KennelId (join +
-- group) and EventNumber (the MIN() aggregate), so the calendar query is
-- served entirely from the index.
CREATE NONCLUSTERED INDEX IX_Event_LocalDate_Visible
ON HC.Event (EventStartLocalDate)
INCLUDE (KennelId, EventNumber)
WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
WITH (ONLINE = ON);
GO
