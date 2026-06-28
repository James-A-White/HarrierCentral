-- =====================================================================
-- Run-once DATA PATCH: copy FbEventStartDatetime -> EventStartDatetime
-- =====================================================================
-- Facebook integration is retired. For rows where UseFbRunDetails = 1 the effective
-- start time was surfaced via SyncEventStartDatetime (= FbEventStartDatetime). This
-- bakes that value into EventStartDatetime so it is the single source of truth, which
-- also repairs EventStartDateTimeGmt: the trigger computes Gmt from EventStartDatetime,
-- so FB rows whose EventStartDatetime differed from the FB time had a Gmt based on the
-- wrong wall-clock (some off by hours, some by days/years).
--
-- UseFbRunDetails is intentionally LEFT AS-IS (it still controls other FB-sourced
-- fields). Only rows where the two datetimes actually differ are touched.
--
-- The updatedAt trigger is intentionally LEFT ENABLED: this is a real data correction,
-- so the touched rows SHOULD re-sync to clients, and the trigger recomputes
-- EventStartDateTimeGmt / EventStartLocal / EventStartLocalDate for them.
-- Author:  Harrier Central   Created: 2026-06-28   Run-once: archived.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

UPDATE HC.Event
SET EventStartDatetime = FbEventStartDatetime
WHERE UseFbRunDetails = 1
  AND FbEventStartDatetime IS NOT NULL
  AND (EventStartDatetime <> FbEventStartDatetime
       OR DATEPART(TZOFFSET, EventStartDatetime) <> DATEPART(TZOFFSET, FbEventStartDatetime));

SELECT @@ROWCOUNT AS rows_repaired;
