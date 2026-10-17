-- Run-once data change (James, 2026-10-17: "Please set them all").
-- A survey of 707 runs (89 kennels, 2026-07-17 .. 2026-12-16) found six
-- kennels whose run descriptions consistently give a gather time and a
-- set-off 30 minutes later ("2pm gather, 2:30pm pack off", "meet @ 6:30pm,
-- pack away by 7pm", "meet at 14:00 for a 14:30 start", "circle up at 9.30
-- for a 10.00 start", "Meet at Noon / Hares off 12:30", "meet at noon,
-- launch by 12:30"). Their runs already start at the gather; this sets the
-- kennel's pack-off default so cards show it and auto start counts from it.
-- Only where none is set, so a kennel admin's own choice is never replaced.
-- The Kennel trigger bumps updatedAt, so phones get it on their next sync.
SET NOCOUNT ON;
BEGIN TRANSACTION;
UPDATE HC.Kennel
SET PackOffMinutes = 30
WHERE KennelUniqueShortName IN ('SWH3', 'SeaMon', 'MH3-GB', 'A3H', 'SH3', 'RCH3')
  AND PackOffMinutes IS NULL;
SELECT @@ROWCOUNT AS updated;
COMMIT TRANSACTION;
