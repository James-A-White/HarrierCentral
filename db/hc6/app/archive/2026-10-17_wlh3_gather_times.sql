-- Run-once data repair (James, 2026-10-17: "fix West London's runs ... 19:00
-- gather with a 15 minute pack off"). WLH3's page gives the time the pack
-- SETS OFF ("will start at our usual time of 19.15", "12.15 start time");
-- the runs-page import stored that as the gather, and the kennel's 15-minute
-- pack-off then showed a set-off 15 minutes late. Moves the three imported
-- runs that carry a :15 start back 15 minutes, so gather + 15 = the page's
-- start. The kennel itself is already 19:00 + 15 (checked). FbEventStartDatetime
-- is left as read, so the importer will not move them back.
SET NOCOUNT ON;
BEGIN TRANSACTION;
UPDATE e
SET EventStartDatetime = DATEADD(MINUTE, -15, e.EventStartDatetime)
FROM HC.Event e
JOIN HC.Kennel k ON k.id = e.KennelId
WHERE k.KennelUniqueShortName = 'WLH3'
  AND e.EventFacebookId LIKE 'runspage:%'
  AND e.EventNumber IN (2126, 2127, 2128)
  AND e.deleted = 0
  AND DATEPART(MINUTE, e.EventStartDatetime) = 15;
SELECT @@ROWCOUNT AS moved;
COMMIT TRANSACTION;
