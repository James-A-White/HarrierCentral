-- =====================================================================
-- Run-once migration: create HC.PushLog table
-- Already executed — archived here for reference.
-- =====================================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'PushLog'
)
BEGIN
    CREATE TABLE [HC].[PushLog] (
        [Id]              UNIQUEIDENTIFIER  NOT NULL DEFAULT NEWID(),
        [BatchId]         UNIQUEIDENTIFIER  NOT NULL,
        [SentAt]          DATETIMEOFFSET(7) NOT NULL DEFAULT SYSUTCDATETIME(),
        [QueryType]       NVARCHAR(100)     NOT NULL,
        [EventId]         UNIQUEIDENTIFIER  NULL,
        [RecipientUserId] UNIQUEIDENTIFIER  NULL,
        [FcmToken]        NVARCHAR(500)     NOT NULL,
        [IsVisible]       BIT               NOT NULL DEFAULT 0,
        [Summary]         NVARCHAR(500)     NULL,
        CONSTRAINT [PK_PushLog] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    CREATE INDEX [IX_PushLog_BatchId]  ON [HC].[PushLog] ([BatchId]);
    CREATE INDEX [IX_PushLog_SentAt]   ON [HC].[PushLog] ([SentAt] DESC);
    CREATE INDEX [IX_PushLog_EventId]  ON [HC].[PushLog] ([EventId]) WHERE [EventId] IS NOT NULL;

    PRINT 'HC.PushLog created.';
END
ELSE
BEGIN
    PRINT 'HC.PushLog already exists — skipped.';
END
