-- Run-once: HC.Kennel.RunEmailInstruction — the kennel's saved instruction for
-- AI-drafted run emails ("write it in French"), pre-filled for every sender
-- (James, 2026-10-09). Trigger OFF so 400 kennel rows do not re-sync.
SET NOCOUNT ON;
IF COL_LENGTH('HC.Kennel', 'RunEmailInstruction') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
    ALTER TABLE [HC].[Kennel] ADD [RunEmailInstruction] NVARCHAR(500) NULL;
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels] ON [HC].[Kennel];
    PRINT 'HC.Kennel.RunEmailInstruction added';
END
ELSE PRINT 'already exists';
GO
SELECT name, is_disabled FROM sys.triggers WHERE name='trgUpdateModifiedOnDateForKennels';
SELECT COUNT(*) touchedInLastMinute FROM HC.Kennel WHERE updatedAt >= DATEADD(minute,-1,SYSDATETIMEOFFSET());
