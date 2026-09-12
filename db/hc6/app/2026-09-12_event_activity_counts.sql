-- =====================================================================
-- Run-once: activity counts on HC.Event for the run cards (2026-09-12)
--   Run by hand in this order (the SPs read the new columns, and SQL Server
--   binds a column of an EXISTING table at CREATE PROCEDURE, so deploying
--   them before the ALTER fails with "Invalid column name"):
--     a. step 1 below (the ALTER) on its own;
--     b. ./tools/deploy_hc6.sh (nonApi_refreshEventActivity + the sync SPs);
--     c. this whole script — step 1 no-ops, the triggers and backfill run
--        (the backfill EXECs the SP, so it must exist by then).
--
--   1. Four SMALLINT columns on HC.Event, trigger DISABLED for the ALTER so
--      no row is stamped (HC.Event is synced; see CLAUDE.md).
--   2. Four triggers that keep them right from whichever path writes:
--      HasherEventMap (track columns / removal), KennelPhotos, EventMessage,
--      DownDowns. Each recounts only the runs touched, through the guarded
--      SP, so a live run's batches change nothing after the first.
--   3. Backfill with the event trigger ENABLED: every run that has any
--      activity gets its counts and re-syncs ONCE (a few hundred rows,
--      2026-09-12: ~495 runs with tracks plus those with photos, chat or
--      charges). Runs with nothing stay untouched.
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

-- 1. Columns ---------------------------------------------------------------
IF COL_LENGTH('HC.Event', 'TrackRunnerCount') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForEvent] ON [HC].[Event];
    ALTER TABLE [HC].[Event] ADD
        [TrackRunnerCount] SMALLINT NOT NULL CONSTRAINT [DF_Event_TrackRunnerCount] DEFAULT (0),
        [PhotoCount]       SMALLINT NOT NULL CONSTRAINT [DF_Event_PhotoCount]       DEFAULT (0),
        [MessageCount]     SMALLINT NOT NULL CONSTRAINT [DF_Event_MessageCount]     DEFAULT (0),
        [DownDownCount]    SMALLINT NOT NULL CONSTRAINT [DF_Event_DownDownCount]    DEFAULT (0);
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForEvent] ON [HC].[Event];
    PRINT 'HC.Event activity count columns added';
END
ELSE PRINT 'HC.Event activity count columns already exist';
GO

-- 2. Triggers --------------------------------------------------------------

CREATE OR ALTER TRIGGER [HC].[trgHasherEventMapActivityCount] ON [HC].[HasherEventMap]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Only a change that can move the count: a track column, removal, or a
    -- row coming or going. An RSVP or a check-in does not fire the recount.
    IF NOT (UPDATE(TrackPointCount) OR UPDATE(removed)
            OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED))
        RETURN;
    DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT INTO @ids (EventId)
    SELECT DISTINCT EventId FROM (SELECT EventId FROM INSERTED UNION SELECT EventId FROM DELETED) s
     WHERE EventId IS NOT NULL;
    DECLARE @eventId UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
    OPEN c; FETCH NEXT FROM c INTO @eventId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
        FETCH NEXT FROM c INTO @eventId;
    END
    CLOSE c; DEALLOCATE c;
END
GO

CREATE OR ALTER TRIGGER [HC].[trgKennelPhotosActivityCount] ON [HC].[KennelPhotos]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(Status) OR UPDATE(DeletedAt) OR UPDATE(EventId) OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED)) RETURN;
    DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT INTO @ids (EventId)
    SELECT DISTINCT EventId FROM (SELECT EventId FROM INSERTED UNION SELECT EventId FROM DELETED) s
     WHERE EventId IS NOT NULL;
    DECLARE @eventId UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
    OPEN c; FETCH NEXT FROM c INTO @eventId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
        FETCH NEXT FROM c INTO @eventId;
    END
    CLOSE c; DEALLOCATE c;
END
GO

CREATE OR ALTER TRIGGER [HC].[trgEventMessageActivityCount] ON [HC].[EventMessage]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(Removed) OR UPDATE(EventId) OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED)) RETURN;
    DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT INTO @ids (EventId)
    SELECT DISTINCT EventId FROM (SELECT EventId FROM INSERTED UNION SELECT EventId FROM DELETED) s
     WHERE EventId IS NOT NULL;
    DECLARE @eventId UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
    OPEN c; FETCH NEXT FROM c INTO @eventId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
        FETCH NEXT FROM c INTO @eventId;
    END
    CLOSE c; DEALLOCATE c;
END
GO

CREATE OR ALTER TRIGGER [HC].[trgDownDownsActivityCount] ON [HC].[DownDowns]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(IsCancelled) OR UPDATE(EventId) OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED)) RETURN;
    DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT INTO @ids (EventId)
    SELECT DISTINCT EventId FROM (SELECT EventId FROM INSERTED UNION SELECT EventId FROM DELETED) s
     WHERE EventId IS NOT NULL;
    DECLARE @eventId UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
    OPEN c; FETCH NEXT FROM c INTO @eventId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
        FETCH NEXT FROM c INTO @eventId;
    END
    CLOSE c; DEALLOCATE c;
END
GO

-- 3. Backfill (event trigger ON: these rows re-sync once) --------------------
DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
INSERT INTO @ids (EventId)
SELECT DISTINCT EventId FROM (
    SELECT EventId FROM HC.HasherEventMap WHERE removed = 0 AND TrackPointCount > 0
    UNION SELECT EventId FROM HC.KennelPhotos WHERE DeletedAt IS NULL AND Status >= 2
    UNION SELECT EventId FROM HC.EventMessage WHERE Removed = 0
    UNION SELECT EventId FROM HC.DownDowns WHERE IsCancelled = 0
) s;
DECLARE @n INT = (SELECT COUNT(*) FROM @ids);
DECLARE @eventId UNIQUEIDENTIFIER;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
OPEN c; FETCH NEXT FROM c INTO @eventId;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
    FETCH NEXT FROM c INTO @eventId;
END
CLOSE c; DEALLOCATE c;
PRINT CONCAT('Backfilled activity counts for ', @n, ' runs');
GO
