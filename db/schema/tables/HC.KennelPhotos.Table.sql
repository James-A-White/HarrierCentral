CREATE TABLE [HC].[KennelPhotos] (
    [id]          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [EventId]     UNIQUEIDENTIFIER NOT NULL,
    [KennelId]    UNIQUEIDENTIFIER NOT NULL,
    [UserId]      UNIQUEIDENTIFIER NOT NULL,
    [BlobUrl]     NVARCHAR(500)    NOT NULL,
    [AssetId]     NVARCHAR(500)    NULL,
    -- Device-library identifier (iOS PHAsset.localIdentifier / Android MediaStore URI).
    -- Populated only when the uploader had "save to camera roll" enabled.
    -- Device-specific: only valid on the device that took the photo.
    [Latitude]    DECIMAL(9,6)     NOT NULL,
    [Longitude]   DECIMAL(9,6)     NOT NULL,
    [Status]      TINYINT          NOT NULL DEFAULT 0,
    -- Status values: 0 = private, 1 = pending_review, 2 = public
    [Title]       NVARCHAR(250)    NULL,
    [Description] NVARCHAR(MAX)    NULL,
    [CreatedAt]   DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]   DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    -- NULL = not deleted; non-NULL = soft-deleted (always recoverable)
    [DeletedAt]   DATETIME2        NULL,
    CONSTRAINT [PK_KennelPhotos]        PRIMARY KEY ([id]),
    CONSTRAINT [FK_KennelPhotos_Event]  FOREIGN KEY ([EventId])  REFERENCES [HC].[Event]([id]),
    CONSTRAINT [FK_KennelPhotos_Kennel] FOREIGN KEY ([KennelId]) REFERENCES [HC].[Kennel]([id]),
    CONSTRAINT [FK_KennelPhotos_Hasher] FOREIGN KEY ([UserId])   REFERENCES [HC].[Hasher]([id])
);

CREATE INDEX [IX_KennelPhotos_EventId_UpdatedAt]
    ON [HC].[KennelPhotos] ([EventId], [UpdatedAt]);
