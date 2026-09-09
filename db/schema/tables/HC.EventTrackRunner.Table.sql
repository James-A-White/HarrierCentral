-- =====================================================================
-- Table: HC.EventTrackRunner
-- Description: One row per hasher who has stored at least one PackTrack
--   point on a run. Written by the StorePositions Azure Function (one
--   MERGE per accepted batch, alongside HC.EventTrack), removed by
--   DeletePositions when a runner's last point on the run goes, and
--   backfilled from GetPositions on 2026-09-10. Answers "how many runners
--   tracked this run?" for the count beside the PackTrack icon on a past
--   run's card (E3.F3.S7) — and is the per-hasher record that the gzipped
--   trail on the HEM row (E5.F6.S4) will hang off later. Not synced; no
--   trigger.
-- Author: Harrier Central
-- Created: 2026-09-10
-- =====================================================================
CREATE TABLE [HC].[EventTrackRunner]
(
    [EventId]      UNIQUEIDENTIFIER NOT NULL,
    [UserId]       UNIQUEIDENTIFIER NOT NULL,
    [FirstPointAt] DATETIME2(3)     NOT NULL,
    [LastPointAt]  DATETIME2(3)     NULL,
    [PointCount]   INT              NOT NULL CONSTRAINT [DF_EventTrackRunner_PointCount] DEFAULT (0),
    [UpdatedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_EventTrackRunner_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_EventTrackRunner] PRIMARY KEY CLUSTERED ([EventId], [UserId])
)
GO
