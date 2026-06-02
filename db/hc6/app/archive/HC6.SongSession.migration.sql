-- =====================================================================
-- Run-once migration: create HC.SongSession table
-- Move to archive/ after executing.
-- =====================================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'SongSession'
)
BEGIN
    CREATE TABLE [HC].[SongSession] (
        [Id]               UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWID(),
        [EventId]          UNIQUEIDENTIFIER  NOT NULL,
        [SongId]           UNIQUEIDENTIFIER  NOT NULL,
        [SelectedByUserId] UNIQUEIDENTIFIER  NOT NULL,
        [SelectedAt]       DATETIMEOFFSET(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        [Removed]          BIT               NOT NULL DEFAULT 0,
        CONSTRAINT [PK_SongSession] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_SongSession_Event]  FOREIGN KEY ([EventId])          REFERENCES [HC].[Event]  ([id]),
        -- FK_SongSession_Song omitted: HC.Song predates FK enforcement in this schema
        CONSTRAINT [FK_SongSession_Hasher] FOREIGN KEY ([SelectedByUserId]) REFERENCES [HC].[Hasher] ([id])
    );

    CREATE INDEX [IX_SongSession_EventSelectedAt]
        ON [HC].[SongSession] ([EventId], [SelectedAt] DESC)
        WHERE [Removed] = 0;

    PRINT 'HC.SongSession created.';
END
ELSE
BEGIN
    PRINT 'HC.SongSession already exists — skipped.';
END
