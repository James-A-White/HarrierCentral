-- Run-once schema change (James, 2026-10-17, E8.F5.S6, option A): who
-- APPOINTED a hare. HC.HasherEventMap.IsHare keeps meaning "hared this run"
-- (anyone may mark themselves, for their history); HareAppointedBy is the run
-- or kennel admin who marked them, and only an appointed hare gets the run's
-- hare rights (payments, editing the run). Synced table: its updatedAt trigger
-- is disabled around the ALTER so the ALTER does not re-stamp every row.
-- Idempotent.
SET NOCOUNT ON;
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
IF COL_LENGTH('HC.HasherEventMap', 'HareAppointedBy') IS NULL
    ALTER TABLE HC.HasherEventMap ADD HareAppointedBy UNIQUEIDENTIFIER NULL;
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
GO
IF OBJECT_ID('HC.FK_HasherEventMap_HareAppointedBy') IS NULL
    ALTER TABLE HC.HasherEventMap ADD CONSTRAINT FK_HasherEventMap_HareAppointedBy
        FOREIGN KEY (HareAppointedBy) REFERENCES HC.Hasher (id);
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('HC.HasherEventMap')
               AND minor_id = COLUMNPROPERTY(OBJECT_ID('HC.HasherEventMap'), 'HareAppointedBy', 'ColumnId') AND name = 'MS_Description')
    EXEC sp_addextendedproperty 'MS_Description',
        N'The run or kennel admin who marked this hasher hare (E8.F5.S6). NULL = not appointed: a hare who marked themselves still counts in history but gets no hare rights (payments, editing the run). Read through HC6.IsAppointedHare.',
        'SCHEMA', 'HC', 'TABLE', 'HasherEventMap', 'COLUMN', 'HareAppointedBy';
GO
-- Keep today's hares of upcoming runs (from yesterday on) appointed, credited
-- to the Harrier Central system account, so no hare loses rights mid-week
-- (James). updatedAt moves with it (trigger on), so phones re-sync these rows.
UPDATE hem
SET HareAppointedBy = 'A7C0E6F2-5B1D-4C8E-9F3A-0D2B6E4C1A01'
FROM HC.HasherEventMap hem
JOIN HC.Event e ON e.id = hem.EventId
WHERE hem.IsHare = 1 AND hem.removed = 0 AND hem.HareAppointedBy IS NULL
  AND e.EventStartDateTimeGmt >= DATEADD(DAY, -1, SYSDATETIMEOFFSET());
SELECT @@ROWCOUNT AS haresKeptAppointed;
SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.HasherEventMap');
