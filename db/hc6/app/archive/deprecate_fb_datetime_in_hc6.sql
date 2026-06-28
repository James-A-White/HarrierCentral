-- =====================================================================
-- Run-once: remove FbEventStartDatetime USAGE from HC6 (column is KEPT)
-- =====================================================================
-- FB integration is retired; the FB-effective time is baked into EventStartDatetime
-- (b8506682). The FbEventStartDatetime COLUMN stays (read by ~40 legacy objects across
-- HC/HC3/HC3W/HC4/HC5/HC_BACKUP/DEV), but nothing in HC6 should read its VALUE.
--
-- HC6 SPs were cleaned in 1aea840b. Remaining HC6-path FB-datetime usage:
--   1. EventStartLocal computed column (HC6 run-numbering/feeds) — CASE on Fb.
--   2. trgRecalculateRunCounts — writes EventStartDatetimeIndexed from the Fb value
--      on every HC.Event write.
--   3. trgUpdateHemDates — change-detects UPDATE(FbEventStartDatetime).
-- All collapse to EventStartDatetime (identical values, data is baked). FbEventName /
-- UseFbRunDetails (non-datetime FB fields) are intentionally kept.
-- SyncEventStartDatetime is HC5-only and left for HC5 retirement.
--
-- EventStartLocal is indexed (3 filtered indexes), so they are dropped and recreated
-- around the computed-column rebuild. updatedAt trigger disabled across it (synced table).
-- Author: Harrier Central  Created: 2026-06-28  Run-once: archived.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- 1. Rebuild EventStartLocal without the FB CASE
DROP INDEX IF EXISTS IX_Event_EventStartLocal  ON HC.Event;
DROP INDEX IF EXISTS IX_EvtRunCount_Local       ON HC.Event;
DROP INDEX IF EXISTS IX_EventUsageData_Local    ON HC.Event;
GO
ALTER TABLE HC.Event DROP COLUMN EventStartLocal;
GO
ALTER TABLE HC.Event
    ADD EventStartLocal AS CONVERT(datetime2(7), EventStartDatetime) PERSISTED;
GO
CREATE NONCLUSTERED INDEX IX_Event_EventStartLocal
    ON HC.Event (EventStartLocal) WITH (FILLFACTOR = 80, ONLINE = ON);
GO
CREATE NONCLUSTERED INDEX IX_EvtRunCount_Local
    ON HC.Event (EventStartLocal) INCLUDE (KennelId, EventNumber)
    WHERE IsCountedRun = 1 AND IsVisible = 1 AND removed = 0
    WITH (FILLFACTOR = 80, ONLINE = ON);
GO
CREATE NONCLUSTERED INDEX IX_EventUsageData_Local
    ON HC.Event (EventStartLocal)
    INCLUDE (KennelId, EventName, EventStartDatetime, FbEventName, createdAt, updatedAt, UseFbRunDetails)
    WHERE IsVisible = 1 WITH (FILLFACTOR = 80, ONLINE = ON);
GO

ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
GO

-- 2. trgRecalculateRunCounts: EventStartDatetimeIndexed from EventStartDatetime only
CREATE OR ALTER TRIGGER [HC].[trgRecalculateRunCounts] ON [HC].[Event]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Maintain the legacy EventStartDatetimeIndexed key from EventStartDatetime
    -- (FB-effective time is already baked into EventStartDatetime).
    IF UPDATE(EventStartDateTime)
    BEGIN
        UPDATE evt
            SET EventStartDatetimeIndexed = CONVERT(datetime2, ins.EventStartDatetime)
            FROM HC.Event evt
            INNER JOIN Inserted ins ON evt.id = ins.id;
    END
    IF (UPDATE(IsCountedRun) OR UPDATE(AbsoluteEventNumber))
    BEGIN
        DECLARE @eid UNIQUEIDENTIFIER;
        SELECT TOP 1 @eid = id FROM inserted ORDER BY EventStartDatetime ASC;
        EXEC [HC6].[nonApi_updateRunNumbers] @eventId = @eid;
    END
END
GO

-- 3. trgUpdateHemDates: bump HEM updatedAt on sync-relevant Event field changes
--    (the FB start-datetime change-detection term has been removed)
CREATE OR ALTER TRIGGER [HC].[trgUpdateHemDates]
   ON  HC.Event
   AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF (   UPDATE(IsCountedRun)
	    OR UPDATE(AbsoluteEventNumber)
		OR UPDATE(EventNumber)
		OR UPDATE(EventName)
		OR UPDATE(FbEventName)
		OR UPDATE(IsVisible)
		OR UPDATE(UseFbRunDetails)
		OR UPDATE(EventStartDatetime)
		OR UPDATE(CanEditRunAttendence)
		)
	BEGIN
		UPDATE h
		SET h.updatedAt = getdate()
		FROM HC.HasherEventMap h
		INNER JOIN INSERTED ins ON h.EventId = ins.id
	END
END
GO
