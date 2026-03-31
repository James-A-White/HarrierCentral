-- =====================================================================
-- Table: TSA.WorkerInvite
-- Description: Admin-created invitation records for TSA officers.
--              Each invite generates a unique 64-char hex token
--              (CRYPT_GEN_RANDOM(32)) embedded in a registration QR code.
--              Single-use; expires after 48 hours.
-- =====================================================================

CREATE TABLE [TSA].[WorkerInvite] (
    [id]                UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [token]             NVARCHAR(100)       NOT NULL,
    [firstName]         NVARCHAR(100)       NOT NULL,
    [lastName]          NVARCHAR(100)       NOT NULL,
    [createdByAdmin]    NVARCHAR(100)       NOT NULL,
    [createdAt]         DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),
    [expiresAt]         DATETIMEOFFSET(7)   NOT NULL,
    [usedAt]            DATETIMEOFFSET(7)   NULL,

    CONSTRAINT [PK_TSA_WorkerInvite]        PRIMARY KEY ([id]),
    CONSTRAINT [UQ_TSA_WorkerInvite_token]  UNIQUE      ([token])
);
