-- =====================================================================
-- Run-once: filtered index supporting publicWeb_getGlobalRuns after its date
-- filter was made sargable (was COALESCE(EventStartDateTimeGmt, EventStartDatetime)).
-- EventStartDateTimeGmt is 100% populated (trigger Kennel→City→Timezone) and is a
-- true UTC value, so the rewritten predicate (e.EventStartDateTimeGmt >= @cutoff …)
-- can now seek this index instead of scanning HC.Event on the Tier-1 landing page.
-- Additive, ONLINE, idempotent. After running, move to archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Event_GmtStart_Visible' AND object_id=OBJECT_ID('HC.Event'))
    CREATE NONCLUSTERED INDEX IX_Event_GmtStart_Visible
        ON HC.Event (EventStartDateTimeGmt)
        INCLUDE (KennelId)
        WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
        WITH (ONLINE = ON);
