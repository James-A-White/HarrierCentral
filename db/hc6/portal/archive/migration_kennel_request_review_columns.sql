-- =====================================================================
-- Run-once: review columns on EXT.OfficeForms_KennelImport (E12.F1.S5)
-- James approved 2026-09-28 (no new table — columns on the existing one).
-- The table is NOT synced to phones; its only trigger reacts to
-- KennelFacebookId updates, so neither the ALTER nor the backfill fires it.
-- Idempotent. Archive after running.
-- =====================================================================
SET XACT_ABORT ON;

IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'RequestStatus') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport
        ADD RequestStatus SMALLINT NOT NULL
            CONSTRAINT DF_OfficeForms_KennelImport_RequestStatus DEFAULT (1);
-- 0 awaiting email · 1 new · 2 approved · 3 rejected · 4 spam · 5 duplicate
GO
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ConfirmCode') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ConfirmCode NVARCHAR(10) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ConfirmAttempts') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ConfirmAttempts SMALLINT NOT NULL
        CONSTRAINT DF_OfficeForms_KennelImport_ConfirmAttempts DEFAULT (0);
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ConfirmedAt') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ConfirmedAt DATETIMEOFFSET(7) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ReviewedBy') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ReviewedBy UNIQUEIDENTIFIER NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ReviewedAt') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ReviewedAt DATETIMEOFFSET(7) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'ReviewNote') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD ReviewNote NVARCHAR(1000) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'SubmitIp') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD SubmitIp NVARCHAR(64) NULL;
GO

-- Backfill: imported ⇒ approved; removed ⇒ rejected; the rest stay 1 (new)
-- and appear in the portal queue, where the spam is marked.
UPDATE EXT.OfficeForms_KennelImport SET RequestStatus = 2
WHERE KennelId IS NOT NULL AND RequestStatus = 1;
UPDATE EXT.OfficeForms_KennelImport SET RequestStatus = 3
WHERE KennelId IS NULL AND removed <> 0 AND RequestStatus = 1;
GO

-- The queue is read by status, newest first.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OfficeForms_KennelImport_Status'
               AND object_id = OBJECT_ID('EXT.OfficeForms_KennelImport'))
    CREATE INDEX IX_OfficeForms_KennelImport_Status
        ON EXT.OfficeForms_KennelImport (RequestStatus, SubmittedOn DESC);
GO

SELECT RequestStatus, COUNT(*) AS n FROM EXT.OfficeForms_KennelImport
GROUP BY RequestStatus ORDER BY RequestStatus;
