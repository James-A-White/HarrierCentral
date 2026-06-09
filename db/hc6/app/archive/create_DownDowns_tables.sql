-- =====================================================================
-- Run-once: Create HC.DownDowns and HC.DownDownHashers tables
-- Description: Creates the tables for the DownDowns feature. DownDowns
--   are charges called during the circle — any run attendee can submit
--   one; only GM and RA can view the list and mark charges as done.
-- Author: Harrier Central
-- Created: 2026-06-08
-- ARCHIVE AFTER RUNNING — do not leave alongside deployable SPs.
-- =====================================================================

CREATE TABLE [HC].[DownDowns] (
    [id]              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [EventId]         UNIQUEIDENTIFIER NOT NULL,
    [KennelId]        UNIQUEIDENTIFIER NOT NULL,
    [ChargeText]      NVARCHAR(MAX)    NOT NULL,
    [IsDone]          BIT              NOT NULL DEFAULT 0,
    [CreatedByUserId] UNIQUEIDENTIFIER NOT NULL,
    [CreatedAt]       DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_DownDowns]               PRIMARY KEY ([id]),
    CONSTRAINT [FK_DownDowns_Event]         FOREIGN KEY ([EventId])         REFERENCES [HC].[Event]([id]),
    CONSTRAINT [FK_DownDowns_Kennel]        FOREIGN KEY ([KennelId])        REFERENCES [HC].[Kennel]([id]),
    CONSTRAINT [FK_DownDowns_CreatedBy]     FOREIGN KEY ([CreatedByUserId]) REFERENCES [HC].[Hasher]([id])
);

CREATE INDEX [IX_DownDowns_EventId]
    ON [HC].[DownDowns] ([EventId]);

CREATE TABLE [HC].[DownDownHashers] (
    [id]          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    [DownDownId]  UNIQUEIDENTIFIER NOT NULL,
    [HasherId]    UNIQUEIDENTIFIER NOT NULL,
    [CreatedAt]   DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_DownDownHashers]              PRIMARY KEY ([id]),
    CONSTRAINT [FK_DownDownHashers_DownDown]     FOREIGN KEY ([DownDownId]) REFERENCES [HC].[DownDowns]([id]),
    CONSTRAINT [FK_DownDownHashers_Hasher]       FOREIGN KEY ([HasherId])   REFERENCES [HC].[Hasher]([id])
);

CREATE UNIQUE INDEX [IX_DownDownHashers_DownDownId_HasherId]
    ON [HC].[DownDownHashers] ([DownDownId], [HasherId]);
