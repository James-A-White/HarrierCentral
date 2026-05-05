-- Run-once script: map decisionhall.org to the London City Hash (cithh3) kennel.
-- After running, move this file to archive/.
UPDATE kw
SET    kw.CustomDomain = 'decisionhall.org'
FROM   HC.KennelWebsite kw
JOIN   HC.Kennel        k  ON k.id = kw.KennelId
WHERE  k.KennelUniqueShortName = 'cithh3';
