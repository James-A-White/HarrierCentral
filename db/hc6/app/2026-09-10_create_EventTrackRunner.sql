-- Run-once: create HC.EventTrackRunner (see db/schema/tables/HC.EventTrackRunner.Table.sql).
-- Not synced, no trigger. Archive after running.
IF OBJECT_ID('HC.EventTrackRunner') IS NULL
BEGIN
    CREATE TABLE [HC].[EventTrackRunner]
    (
        [EventId]      UNIQUEIDENTIFIER NOT NULL,
        [UserId]       UNIQUEIDENTIFIER NOT NULL,
        [FirstPointAt] DATETIME2(3)     NOT NULL,
        [LastPointAt]  DATETIME2(3)     NULL,
        [PointCount]   INT              NOT NULL CONSTRAINT [DF_EventTrackRunner_PointCount] DEFAULT (0),
        [UpdatedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_EventTrackRunner_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_EventTrackRunner] PRIMARY KEY CLUSTERED ([EventId], [UserId])
    );
END
GO
