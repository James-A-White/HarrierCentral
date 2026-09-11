-- Run-once (E5.F5.S7): create HC.TrackImport — the job row for a file a
-- hasher uploads to be imported as PackTrack trails (single GPX/TCX/FIT or a
-- whole Strava/Garmin zip). Bytes live in blob storage; see
-- db/schema/tables/HC.TrackImport.Table.sql for the column notes.
-- James chose this table 2026-09-11. Not synced; no trigger to disable.
-- Idempotent. Archive after running.
IF OBJECT_ID('HC.TrackImport', 'U') IS NULL
BEGIN
    CREATE TABLE [HC].[TrackImport]
    (
        [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [PK_TrackImport] PRIMARY KEY CLUSTERED,
        [HasherId]      UNIQUEIDENTIFIER NOT NULL,
        [FileName]      NVARCHAR(250)    NULL,
        [BlobUrl]       NVARCHAR(1000)   NOT NULL,
        [ByteSize]      BIGINT           NULL,
        [Kind]          SMALLINT         NOT NULL CONSTRAINT [DF_TrackImport_Kind] DEFAULT (0),
        [Status]        SMALLINT         NOT NULL CONSTRAINT [DF_TrackImport_Status] DEFAULT (0),
        [UploadedAt]    DATETIME2(3)     NOT NULL CONSTRAINT [DF_TrackImport_UploadedAt] DEFAULT (SYSUTCDATETIME()),
        [StartedAt]     DATETIME2(3)     NULL,
        [ProcessedAt]   DATETIME2(3)     NULL,
        [NextIndex]        INT              NOT NULL CONSTRAINT [DF_TrackImport_NextIndex] DEFAULT (0),
        [ActivityCount] INT              NULL,
        [ImportedCount] INT              NOT NULL CONSTRAINT [DF_TrackImport_ImportedCount] DEFAULT (0),
        [SkippedCount]  INT              NOT NULL CONSTRAINT [DF_TrackImport_SkippedCount] DEFAULT (0),
        [HeldCount]     INT              NOT NULL CONSTRAINT [DF_TrackImport_HeldCount] DEFAULT (0),
        [ResultJson]    NVARCHAR(MAX)    NULL,
        [ErrorMessage]  NVARCHAR(2500)   NULL
    );
    CREATE NONCLUSTERED INDEX [IX_TrackImport_Hasher] ON [HC].[TrackImport] ([HasherId], [UploadedAt] DESC);
    CREATE NONCLUSTERED INDEX [IX_TrackImport_Status] ON [HC].[TrackImport] ([Status], [UploadedAt]);
    PRINT 'HC.TrackImport created';
END
ELSE
    PRINT 'HC.TrackImport already exists';
GO
