-- Run-once data repair (James, 2026-10-17: "It should be start at noon").
-- London H3's runs page says "12 Noon for 12:30": gather at noon, pack off
-- 12:30. The runs-page import (2026-10-05, before pack-off existed) stored
-- 12:30 as the start, and LH3's 30-minute pack-off default then showed
-- "Gather 12:30 · Pack off 1:00". Moves the six imported upcoming runs that
-- still say 12:30 back to a 12:00 gather; the kennel default gives 12:30.
-- FbEventStartDatetime (what the import read) is left alone: the importer
-- overwrites the start only while it equals that mirror, so it will not
-- put 12:30 back. The Event trigger recomputes EventStartDateTimeGmt and
-- bumps updatedAt, so phones pick the change up on their next sync.
SET NOCOUNT ON;
BEGIN TRANSACTION;
UPDATE e
SET EventStartDatetime = DATEADD(MINUTE, -30, e.EventStartDatetime)
FROM HC.Event e
JOIN HC.Kennel k ON k.id = e.KennelId
WHERE k.KennelUniqueShortName = 'LH3'
  AND e.EventFacebookId LIKE 'runspage:%'
  AND e.EventNumber IN (2857, 2862, 2863, 2864, 2865, 2866)
  AND e.deleted = 0
  AND CAST(e.EventStartDatetime AS time) = '12:30';
SELECT @@ROWCOUNT AS moved;
COMMIT TRANSACTION;
