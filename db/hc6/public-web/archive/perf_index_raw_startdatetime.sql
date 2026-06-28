-- =====================================================================
-- Run-once: raw EventStartDatetime indexes (instant-ordered, NOT NULL)
-- Part of the "split CASE ORDER BY -> IF/ELSE, index-served sort" pass (2026-06-28).
--
-- publicWeb_getEvents / publicWeb_getMultiKennelRuns now filter+order the data
-- rowset by raw EventStartDatetime instead of COALESCE(Gmt, raw):
--   * raw EventStartDatetime is NOT NULL and its UTC instant equals
--     EventStartDateTimeGmt, so results are identical to the old COALESCE filter;
--   * being NOT NULL it needs no defensive OR (Gmt IS NULL ...) disjunction,
--     which was forcing a Concatenation + Sort and defeating the index order.
-- A datetimeoffset index orders by UTC instant, which is exactly the chronological
-- order these feeds want.
--
-- IX_Event_Kennel_StartDatetime_Visible: per-kennel seek + ordered range. Makes
--   publicWeb_getEvents (hot per-kennel website page) SORT-FREE (verified: data
--   rowset 0 sorts, 3 logical reads). Also serves getMultiKennelRuns' per-valid-
--   kennel seeks.
-- IX_Event_StartDatetime_Visible: global instant-ordered range; kept for large
--   multi-kennel discovery (over-index preference; HC.Event is small).
--
-- No ADD COLUMN, so no UpdatedAt-trigger dance.
-- Author:  Harrier Central
-- Created: 2026-06-28
-- Run-once: archived (deploy script must not re-run it).
-- =====================================================================
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Event_Kennel_StartDatetime_Visible' AND object_id=OBJECT_ID('HC.Event'))
CREATE NONCLUSTERED INDEX IX_Event_Kennel_StartDatetime_Visible
  ON HC.Event (KennelId, EventStartDatetime)
  WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
  WITH (FILLFACTOR = 80, ONLINE = ON);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Event_StartDatetime_Visible' AND object_id=OBJECT_ID('HC.Event'))
CREATE NONCLUSTERED INDEX IX_Event_StartDatetime_Visible
  ON HC.Event (EventStartDatetime) INCLUDE (KennelId)
  WHERE IsVisible = 1 AND deleted = 0 AND removed = 0
  WITH (FILLFACTOR = 80, ONLINE = ON);
GO
