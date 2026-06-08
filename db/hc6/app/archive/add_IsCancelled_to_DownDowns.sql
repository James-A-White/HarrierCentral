-- Run-once migration: add IsCancelled to HC.DownDowns
-- Required by hcapp_cancelDownDown / hcapp_uncancelDownDown feature.
-- HC.DownDowns is not a mobile-sync table so no trigger concern.
ALTER TABLE HC.DownDowns
    ADD IsCancelled BIT NOT NULL DEFAULT 0;
