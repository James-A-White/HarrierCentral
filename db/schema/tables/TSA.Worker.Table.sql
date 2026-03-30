-- =====================================================================
-- Table: TSA.Worker
-- Description: Registered TSA officers. Created on successful OTP
--              verification after scanning an admin invite QR code.
--              Phone number stored in E.164 format.
-- =====================================================================

CREATE TABLE [TSA].[Worker] (
    [id]                UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [inviteId]          UNIQUEIDENTIFIER    NOT NULL,
    [firstName]         NVARCHAR(100)       NOT NULL,
    [lastName]          NVARCHAR(100)       NOT NULL,
    [phoneNumber]       NVARCHAR(30)        NOT NULL,
    [status]            NVARCHAR(20)        NOT NULL    DEFAULT 'Active',
    [termsAcceptedAt]   DATETIMEOFFSET(7)   NOT NULL,
    [createdAt]         DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT [PK_TSA_Worker]              PRIMARY KEY ([id]),
    CONSTRAINT [UQ_TSA_Worker_invite]       UNIQUE      ([inviteId]),
    CONSTRAINT [UQ_TSA_Worker_phone]        UNIQUE      ([phoneNumber]),
    CONSTRAINT [FK_TSA_Worker_Invite]       FOREIGN KEY ([inviteId])    REFERENCES [TSA].[WorkerInvite]([id]),
    CONSTRAINT [CK_TSA_Worker_status]       CHECK       ([status] IN ('Active', 'Suspended'))
);
