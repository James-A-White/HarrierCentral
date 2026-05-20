-- Run-once migration: add PhotoSharingPreference to HC.HasherKennelMap
-- 0 = off (photos stay private), 1 = share with Hash Flash
-- Archive this file after executing.

ALTER TABLE [HC].[HasherKennelMap]
    ADD [PhotoSharingPreference] TINYINT NOT NULL DEFAULT 0;
