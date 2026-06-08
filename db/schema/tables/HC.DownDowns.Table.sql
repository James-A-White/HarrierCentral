CREATE TABLE [HC].[DownDowns] (
    [id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [EventId]         UNIQUEIDENTIFIER NOT NULL,
    [KennelId]        UNIQUEIDENTIFIER NOT NULL,
    [ChargeText]      NVARCHAR(MAX)    NOT NULL,
    [IsDone]          BIT              NOT NULL DEFAULT 0,
    [CreatedByUserId] UNIQUEIDENTIFIER NOT NULL,
    [CreatedAt]       DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_DownDowns]           PRIMARY KEY ([id]),
    CONSTRAINT [FK_DownDowns_Event]     FOREIGN KEY ([EventId])         REFERENCES [HC].[Event]([id]),
    CONSTRAINT [FK_DownDowns_Kennel]    FOREIGN KEY ([KennelId])        REFERENCES [HC].[Kennel]([id]),
    CONSTRAINT [FK_DownDowns_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [HC].[Hasher]([id])
);

CREATE INDEX [IX_DownDowns_EventId]
    ON [HC].[DownDowns] ([EventId]);
