-- =====================================================================
-- Run-once: a run's PACK-OFF time (E3.F1.S6, James 2026-10-14)
--
-- Many kennels gather at one time and set off at another ("gather 12:00,
-- on-out 12:30"). Harrier Central held one start time, so the gather was
-- also when PackTrack expected the pack to leave. Two columns, no table
-- (James agreed the shape on 2026-10-14):
--
--   HC.Kennel.PackOffMinutes  the kennel's default: the pack leaves N
--                             minutes after the gather. NULL = at the gather
--                             (what every kennel does today).
--   HC.Event.PackOffMinutes   this run's override, also minutes after the
--                             gather. NULL = use the kennel's default.
--
-- MINUTES, NOT A CLOCK TIME: moving a run's start carries its pack-off with
-- it, so a run is never left with a pack-off before its gather.
-- The effective pack-off of a run is
--   EventStartDatetime + COALESCE(e.PackOffMinutes, k.PackOffMinutes, 0) min.
--
-- Both tables sync to phones, so each table's UpdatedAt trigger is DISABLED
-- around its ALTER (an ALTER with it live would stamp every row and push
-- every kennel and run to every phone). No updatedAt sweep is needed: every
-- existing row is NULL, which is what a phone already holds for a column it
-- has never had. Idempotent; run once, then move to archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH('HC.Kennel', 'PackOffMinutes') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
    ALTER TABLE HC.Kennel ADD PackOffMinutes SMALLINT NULL
        CONSTRAINT CK_Kennel_PackOffMinutes CHECK (PackOffMinutes BETWEEN 0 AND 600);
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
    PRINT 'HC.Kennel.PackOffMinutes added';
END

IF COL_LENGTH('HC.Event', 'PackOffMinutes') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
    ALTER TABLE HC.Event ADD PackOffMinutes SMALLINT NULL
        CONSTRAINT CK_Event_PackOffMinutes CHECK (PackOffMinutes BETWEEN 0 AND 600);
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
    PRINT 'HC.Event.PackOffMinutes added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('HC.Kennel')
               AND minor_id = COLUMNPROPERTY(OBJECT_ID('HC.Kennel'), 'PackOffMinutes', 'ColumnId') AND name = 'MS_Description')
    EXEC sp_addextendedproperty 'MS_Description',
        N'E3.F1.S6: the pack leaves this many minutes after the gather (EventStartDatetime), by default for every run of the kennel. NULL = at the gather. A run overrides it with HC.Event.PackOffMinutes.',
        'SCHEMA', 'HC', 'TABLE', 'Kennel', 'COLUMN', 'PackOffMinutes';
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('HC.Event')
               AND minor_id = COLUMNPROPERTY(OBJECT_ID('HC.Event'), 'PackOffMinutes', 'ColumnId') AND name = 'MS_Description')
    EXEC sp_addextendedproperty 'MS_Description',
        N'E3.F1.S6: this run''s pack-off, minutes after the gather (EventStartDatetime). NULL = the kennel''s HC.Kennel.PackOffMinutes (NULL there = at the gather). Minutes, not a clock time, so moving the start carries the pack-off with it.',
        'SCHEMA', 'HC', 'TABLE', 'Event', 'COLUMN', 'PackOffMinutes';

SELECT OBJECT_NAME(parent_id) AS tbl, name, is_disabled FROM sys.triggers
WHERE name IN ('trgUpdateModifiedOnDateForKennels', 'trgUpdateModifiedOnDateForEvent');
SELECT MAX(updatedAt) AS kennelMaxUpdatedAt FROM HC.Kennel;
SELECT MAX(updatedAt) AS eventMaxUpdatedAt FROM HC.Event;
