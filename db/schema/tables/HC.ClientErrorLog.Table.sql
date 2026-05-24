-- =====================================================================
-- Table: HC.ClientErrorLog
-- Description: Session-level client error logs uploaded by the mobile app
--              on the boot following an error-bearing session. Each row
--              is one session's accumulated exception log, sent as a single
--              payload rather than per-error entries.
--
-- Relationship: DeviceId references HC.Device.id (no FK constraint — error
--              logging must succeed even if the device row is stale).
--
-- Author: Harrier Central
-- Created: 2026-05-24
-- =====================================================================

CREATE TABLE [HC].[ClientErrorLog]
(
    [Id]          UNIQUEIDENTIFIER    NOT NULL    CONSTRAINT [DF_ClientErrorLog_Id]       DEFAULT (NEWID()),
    [DeviceId]    UNIQUEIDENTIFIER    NOT NULL,
    [ErrorLog]    NVARCHAR(MAX)       NOT NULL,
    [LoggedAt]    DATETIMEOFFSET(7)   NOT NULL    CONSTRAINT [DF_ClientErrorLog_LoggedAt] DEFAULT (SYSDATETIMEOFFSET()),

    CONSTRAINT [PK_ClientErrorLog]
        PRIMARY KEY CLUSTERED ([Id])
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_ClientErrorLog_DeviceId]
    ON [HC].[ClientErrorLog] ([DeviceId])
GO
