-- =====================================================================
-- Table: TSA.Session
-- Description: Long-lived worker sessions. The session ID (UUID) is
--              stored in an httpOnly cookie on the worker's device.
--              Expires after 90 days; lastSeenAt updated on each visit.
-- =====================================================================

CREATE TABLE [TSA].[Session] (
    [id]            UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [workerId]      UNIQUEIDENTIFIER    NOT NULL,
    [createdAt]     DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),
    [expiresAt]     DATETIMEOFFSET(7)   NOT NULL,
    [lastSeenAt]    DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT [PK_TSA_Session]         PRIMARY KEY ([id]),
    CONSTRAINT [FK_TSA_Session_Worker]  FOREIGN KEY ([workerId]) REFERENCES [TSA].[Worker]([id])
);

CREATE INDEX [IX_TSA_Session_worker] ON [TSA].[Session] ([workerId]);
