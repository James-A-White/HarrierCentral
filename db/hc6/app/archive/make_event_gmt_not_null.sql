-- =====================================================================
-- Run-once: make HC.Event.EventStartDateTimeGmt NOT NULL with a DEFAULT
-- =====================================================================
-- EventStartDateTimeGmt is the true UTC instant of a run start and must never be
-- null (trigger trgUpdateModifiedOnDateForEvent always populates it). This adds the
-- hard NOT NULL constraint plus a DEFAULT.
--
-- The DEFAULT is a TRANSIENT placeholder: the AFTER trigger overwrites Gmt in the same
-- transaction on every insert (EventStartDatetime is NOT NULL, so the trigger always
-- fires), so committed rows never contain the default. The far-past sentinel makes any
-- trigger-bypassed row obviously broken and sorts it to the distant past (never pollutes
-- upcoming lists).
--
-- ALTER COLUMN is blocked while the column keys the two FILTERED Gmt indexes, so they
-- are dropped and recreated around it (ONLINE). All rows are already non-null, so the
-- NOT NULL change itself is metadata-only. updatedAt trigger disabled across the change.
-- Author:  Harrier Central   Created: 2026-06-28   Run-once: archived.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- DEFAULT (idempotent)
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_Event_EventStartDateTimeGmt')
    ALTER TABLE HC.Event
        ADD CONSTRAINT DF_Event_EventStartDateTimeGmt
        DEFAULT ('1900-01-01T00:00:00.0000000+00:00') FOR EventStartDateTimeGmt;
GO

-- Drop the filtered Gmt indexes that block the ALTER COLUMN
DROP INDEX IF EXISTS IX_Event_GmtStart_Visible        ON HC.Event;
DROP INDEX IF EXISTS IX_Event_Kennel_GmtStart_Visible ON HC.Event;
GO

ALTER TABLE HC.Event
    ALTER COLUMN EventStartDateTimeGmt datetimeoffset(7) NOT NULL;
GO

-- Recreate the Gmt indexes exactly as they were
CREATE NONCLUSTERED INDEX IX_Event_GmtStart_Visible
    ON HC.Event (EventStartDateTimeGmt) INCLUDE (KennelId)
    WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
    WITH (ONLINE = ON);
GO
CREATE NONCLUSTERED INDEX IX_Event_Kennel_GmtStart_Visible
    ON HC.Event (KennelId, EventStartDateTimeGmt)
    WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
    WITH (FILLFACTOR = 80, ONLINE = ON);
GO

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO
