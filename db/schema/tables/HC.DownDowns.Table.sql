CREATE TABLE [HC].[DownDowns] (
    [id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [EventId]         UNIQUEIDENTIFIER NOT NULL,
    [KennelId]        UNIQUEIDENTIFIER NOT NULL,
    [ChargeText]      NVARCHAR(MAX)    NOT NULL,
    [SongChoice]      NVARCHAR(500)    NULL,
    [SongId]          UNIQUEIDENTIFIER NULL,
    [IsDone]          BIT              NOT NULL DEFAULT 0,
    [IsCancelled]     BIT              NOT NULL DEFAULT 0,
    [ChargePhotoUrl]  NVARCHAR(MAX)    NULL,
    -- JSON array of names for people charged who are NOT registered HC users,
    -- e.g. ["Dizzy Lizzy","Two-Buck Chuck"]. NULL when the charge has none.
    -- In-app hashers are still recorded in HC.DownDownHashers; a charge may mix both.
    [ExternalNames]   NVARCHAR(MAX)    NULL,
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

GO
-- 2026-09-12 (E5.F7.S1): keep HC.Event's run-card activity counts right from
-- whichever path writes this table; see HC6.nonApi_refreshEventActivity and
-- db/hc6/app/archive/2026-09-12_event_activity_counts.sql.
CREATE OR ALTER TRIGGER [HC].[trgDownDownsActivityCount] ON [HC].[DownDowns]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(IsCancelled) OR UPDATE(EventId) OR NOT EXISTS (SELECT 1 FROM INSERTED) OR NOT EXISTS (SELECT 1 FROM DELETED)) RETURN;
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
