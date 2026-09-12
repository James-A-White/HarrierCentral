-- =====================================================================
-- Table: HC.TrackImport
-- Description: One row per file a hasher uploads to be imported as
--   PackTrack trails (E5.F5.S6 / S7): a single GPX, TCX or FIT activity,
--   or a whole Strava/Garmin archive (zip). The bytes live in blob storage
--   (container track-imports); this row is the job — who, which blob,
--   status, progress, and the itemised result. ResultJson records EVERY
--   activity found (start time, start position, distance, duration and
--   what happened to it), matched or not, so a later "find the recurring
--   runs across these members' archives" feature can cluster on it without
--   re-parsing the blobs. Retention of the blobs is an open question
--   (James, 2026-09-11) — nothing deletes them yet.
--   Written by the ProcessTrackImport / ProcessTrackImportsNightly Azure
--   Functions through HC6.nonApi_* SPs; read by hcapp_getTrackImports.
--   Not a synced table; no trigger. James chose this table on 2026-09-11.
-- Author: Harrier Central
-- Created: 2026-09-11
-- =====================================================================
CREATE TABLE [HC].[TrackImport]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_TrackImport] PRIMARY KEY CLUSTERED,
    [HasherId]      UNIQUEIDENTIFIER NOT NULL,
    [FileName]      NVARCHAR(250)    NULL,
    [BlobUrl]       NVARCHAR(1000)   NOT NULL,
    [ByteSize]      BIGINT           NULL,
    -- 0 unknown · 1 gpx · 2 tcx · 3 fit · 4 zip archive (set by the processor)
    [Kind]          SMALLINT         NOT NULL CONSTRAINT [DF_TrackImport_Kind] DEFAULT (0),
    -- 0 uploaded · 1 processing · 2 done · 3 failed
    [Status]        SMALLINT         NOT NULL CONSTRAINT [DF_TrackImport_Status] DEFAULT (0),
    [UploadedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_TrackImport_UploadedAt] DEFAULT (SYSUTCDATETIME()),
    [StartedAt]     DATETIME2(3)     NULL,
    [ProcessedAt]   DATETIME2(3)     NULL,
    -- Slice resumption: activities before this index are done (NextIndex; "Cursor" is reserved).
    [NextIndex]        INT              NOT NULL CONSTRAINT [DF_TrackImport_NextIndex] DEFAULT (0),
    [ActivityCount] INT              NULL,
    [ImportedCount] INT              NOT NULL CONSTRAINT [DF_TrackImport_ImportedCount] DEFAULT (0),
    [SkippedCount]  INT              NOT NULL CONSTRAINT [DF_TrackImport_SkippedCount] DEFAULT (0),
    [HeldCount]     INT              NOT NULL CONSTRAINT [DF_TrackImport_HeldCount] DEFAULT (0),
    [ResultJson]    NVARCHAR(MAX)    NULL,
    [ErrorMessage]  NVARCHAR(2500)   NULL,
    [DeletedAt]     DATETIME2(3)     NULL
)
GO
CREATE NONCLUSTERED INDEX [IX_TrackImport_Hasher] ON [HC].[TrackImport] ([HasherId], [UploadedAt] DESC)
GO
CREATE NONCLUSTERED INDEX [IX_TrackImport_Status] ON [HC].[TrackImport] ([Status], [UploadedAt])
GO
