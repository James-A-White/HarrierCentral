-- Run-once migration: add SongChoice to HC.DownDowns
-- HC.DownDowns is not a mobile-sync table so no trigger concern.
ALTER TABLE HC.DownDowns
    ADD SongChoice NVARCHAR(500) NULL;
