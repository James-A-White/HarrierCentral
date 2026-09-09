-- =====================================================================
-- Table: HC.EventTrack
-- Description: One row per run that has had at least one PackTrack GPS
--   point stored. Written by the StorePositions Azure Function (one MERGE
--   per accepted batch) and backfilled from Azure Table Storage on
--   2026-09-10. Answers "does this run have a track?" from SQL, which
--   nothing could before (E5.F6.S3). Not a synced table; no trigger.
-- Author: Harrier Central
-- Created: 2026-09-10
-- =====================================================================
CREATE TABLE [HC].[EventTrack]
(
    [EventId]      UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_EventTrack] PRIMARY KEY CLUSTERED,
    [FirstPointAt] DATETIME2(3)     NOT NULL,
    [LastPointAt]  DATETIME2(3)     NULL,
    [PointCount]   INT              NOT NULL CONSTRAINT [DF_EventTrack_PointCount] DEFAULT (0),
    [UpdatedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_EventTrack_UpdatedAt] DEFAULT (SYSUTCDATETIME())
)
GO
