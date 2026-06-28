-- =====================================================================
-- Run-once: per-kennel Gmt-instant index for publicWeb_getEvents
-- Part of the StartDateTime indexing-strategy pass (2026-06-28).
-- publicWeb_getEvents filters one kennel's events by EventStartDateTimeGmt
-- range (after the COALESCE->sargable rewrite). The global IX_Event_GmtStart_Visible
-- would seek the date range across ALL kennels then filter KennelId; this
-- kennel-leading composite turns it into a pure seek+range for the (hot, ISR)
-- per-kennel public website events page. Verified: 4 logical reads.
-- No ADD COLUMN, so no UpdatedAt-trigger dance needed.
-- Author:  Harrier Central
-- Created: 2026-06-28
-- Run-once: archived (deploy script must not re-run it).
-- =====================================================================
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name='IX_Event_Kennel_GmtStart_Visible' AND object_id=OBJECT_ID('HC.Event'))
CREATE NONCLUSTERED INDEX IX_Event_Kennel_GmtStart_Visible
  ON HC.Event (KennelId, EventStartDateTimeGmt)
  WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
  WITH (FILLFACTOR = 80, ONLINE = ON);
GO
