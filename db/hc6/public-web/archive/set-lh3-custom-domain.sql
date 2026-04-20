-- Run-once script: map decisionhall.com to the LH3 kennel.
-- After running, move this file to archive/.
UPDATE kw
SET    kw.CustomDomain = 'decisionhall.com'
FROM   HC.KennelWebsite kw
JOIN   HC.Kennel        k  ON k.id = kw.KennelId
WHERE  k.KennelUniqueShortName = 'lh3';
