-- Run-once data repair (James, 2026-10-17: "Yes, clear it"). SWH3 #1814 carried
-- its own pack-off of 0 minutes ("at the gather"), saved by the portal on
-- 2026-10-15 when an OK on the Pack off picker (which opens at the start
-- time) wrote 0 — before SWH3 had a default. It hid the kennel's 30-minute
-- default set that morning. NULL = follow the kennel (pack off 2:30, as the
-- run's description says). The Event trigger bumps updatedAt, so phones sync it.
SET NOCOUNT ON;
UPDATE e SET PackOffMinutes = NULL
FROM HC.Event e JOIN HC.Kennel k ON k.id = e.KennelId
WHERE k.KennelUniqueShortName = 'SWH3' AND e.EventNumber = 1814 AND e.deleted = 0 AND e.PackOffMinutes = 0;
SELECT @@ROWCOUNT AS cleared;
