CREATE TABLE [HC].[KennelPhotos] (
    [id]          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [EventId]     UNIQUEIDENTIFIER NOT NULL,
    [KennelId]    UNIQUEIDENTIFIER NOT NULL,
    [UserId]      UNIQUEIDENTIFIER NOT NULL,
    [BlobUrl]        NVARCHAR(500)    NOT NULL,
    [EditedBlobUrl]  NVARCHAR(500)    NULL,
    -- Populated when a Hash Flash crops or edits the photo. Always NULL until
    -- an edit is made. BlobUrl is never modified — re-edits always start from
    -- the original. Display logic: EditedBlobUrl ?? BlobUrl.
    [AssetId]        NVARCHAR(500)    NULL,
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

GO
-- 2026-09-12 (E5.F7.S1): keep HC.Event's run-card activity counts right from
-- whichever path writes this table; see HC6.nonApi_refreshEventActivity and
-- db/hc6/app/archive/2026-09-12_event_activity_counts.sql.
CREATE OR ALTER TRIGGER [HC].[trgKennelPhotosActivityCount] ON [HC].[KennelPhotos]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(Status) OR UPDATE(DeletedAt) OR UPDATE(EventId) OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED)) RETURN;
    DECLARE @ids TABLE (EventId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT INTO @ids (EventId)
    SELECT DISTINCT EventId FROM (SELECT EventId FROM INSERTED UNION SELECT EventId FROM DELETED) s
     WHERE EventId IS NOT NULL;
    DECLARE @eventId UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT EventId FROM @ids;
    OPEN c; FETCH NEXT FROM c INTO @eventId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_refreshEventActivity @eventId = @eventId;
        FETCH NEXT FROM c INTO @eventId;
    END
    CLOSE c; DEALLOCATE c;
END
GO
