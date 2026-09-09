-- Run-once: create HC.EventTrack (see db/schema/tables/HC.EventTrack.Table.sql).
-- Not synced, no trigger. Archive after running.
IF OBJECT_ID('HC.EventTrack') IS NULL
BEGIN
    CREATE TABLE [HC].[EventTrack]
    (
        [EventId]      UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_EventTrack] PRIMARY KEY CLUSTERED,
        [FirstPointAt] DATETIME2(3)     NOT NULL,
        [LastPointAt]  DATETIME2(3)     NULL,
        [PointCount]   INT              NOT NULL CONSTRAINT [DF_EventTrack_PointCount] DEFAULT (0),
        [UpdatedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_EventTrack_UpdatedAt] DEFAULT (SYSUTCDATETIME())
    );
END
GO
