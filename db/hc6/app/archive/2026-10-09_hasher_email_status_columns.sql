-- Run-once: HC.Hasher email delivery status + block (E19.F4, 2026-10-09).
--   EmailStatus          0 Unknown, 1 OK, 2 Suspect, 3 Bounced (describes the ADDRESS)
--   EmailStatusChangedAt when it last changed
--   EmailSoftBounceCount consecutive soft bounces; 3 => Suspect
--   EmailBlocked         1 = the member wants NO email from Harrier Central
--   EmailBlockedAt
-- Written only by nonApi_setEmailDeliveryStatus / nonApi_setEmailBlocked /
-- nonApi_resetEmailStatus, which never set updatedAt, so no re-sync.
SET NOCOUNT ON;
IF COL_LENGTH('HC.Hasher', 'EmailStatus') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasher] ON [HC].[Hasher];
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForNames] ON [HC].[Hasher];
    ALTER TABLE [HC].[Hasher] ADD
        [EmailStatus]          SMALLINT NOT NULL CONSTRAINT [DF_Hasher_EmailStatus] DEFAULT (0),
        [EmailStatusChangedAt] DATETIMEOFFSET(7) NULL,
        [EmailSoftBounceCount] SMALLINT NOT NULL CONSTRAINT [DF_Hasher_EmailSoftBounceCount] DEFAULT (0),
        [EmailBlocked]         SMALLINT NOT NULL CONSTRAINT [DF_Hasher_EmailBlocked] DEFAULT (0),
        [EmailBlockedAt]       DATETIMEOFFSET(7) NULL;
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasher] ON [HC].[Hasher];
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForNames] ON [HC].[Hasher];
    PRINT 'HC.Hasher email status columns added';
END
ELSE PRINT 'already exist';
GO
SELECT name, is_disabled FROM sys.triggers WHERE parent_id=OBJECT_ID('HC.Hasher') AND name LIKE 'trgUpdateModifiedOnDate%';
SELECT COUNT(*) touchedInLastMinute FROM HC.Hasher WHERE updatedAt >= DATEADD(minute,-1,SYSDATETIMEOFFSET());
