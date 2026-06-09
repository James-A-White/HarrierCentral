CREATE TABLE [HC].[DownDownHashers] (
    [id]         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [DownDownId] UNIQUEIDENTIFIER NOT NULL,
    [HasherId]   UNIQUEIDENTIFIER NOT NULL,
    [CreatedAt]  DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_DownDownHashers]          PRIMARY KEY ([id]),
    CONSTRAINT [FK_DownDownHashers_DownDown] FOREIGN KEY ([DownDownId]) REFERENCES [HC].[DownDowns]([id]),
    CONSTRAINT [FK_DownDownHashers_Hasher]   FOREIGN KEY ([HasherId])   REFERENCES [HC].[Hasher]([id])
);

CREATE UNIQUE INDEX [IX_DownDownHashers_DownDownId_HasherId]
    ON [HC].[DownDownHashers] ([DownDownId], [HasherId]);
