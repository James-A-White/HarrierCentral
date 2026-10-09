-- =====================================================================
-- Run-once: HC.Event columns recording run emails (E9.F6.S8).
--   EmailSendCount      how many run emails have been sent for the run
--   EmailLastSentAt     when the last one went out
--   EmailLastSentCount  how many recipients that last send had
-- The UpdatedAt trigger is OFF for the ALTER so 140k rows do not re-sync.
-- After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
IF COL_LENGTH('HC.Event', 'EmailSendCount') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForEvent] ON [HC].[Event];
    ALTER TABLE [HC].[Event] ADD
        [EmailSendCount]     SMALLINT NOT NULL CONSTRAINT [DF_Event_EmailSendCount] DEFAULT (0),
        [EmailLastSentAt]    DATETIMEOFFSET(7) NULL,
        [EmailLastSentCount] INT NULL;
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForEvent] ON [HC].[Event];
    PRINT 'HC.Event email columns added';
END
ELSE PRINT 'HC.Event email columns already exist';
GO
SELECT name, is_disabled FROM sys.triggers WHERE name = 'trgUpdateModifiedOnDateForEvent';
SELECT COUNT(*) AS touchedInLastMinute FROM HC.Event WHERE updatedAt >= DATEADD(minute, -1, SYSDATETIMEOFFSET());
