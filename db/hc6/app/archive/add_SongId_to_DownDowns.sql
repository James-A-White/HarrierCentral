-- Run-once migration: add SongId to HC.DownDowns
-- Links a down-down to a specific song from HC.Song for push-on-delivery.
-- HC.DownDowns is not a mobile-sync table so no trigger concern.
ALTER TABLE HC.DownDowns
    ADD SongId UNIQUEIDENTIFIER NULL;
