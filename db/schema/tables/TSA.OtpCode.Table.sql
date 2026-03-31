-- =====================================================================
-- Table: TSA.OtpCode
-- Description: Short-lived one-time passwords for phone verification.
--              Stores a SHA-256 hex hash of the 6-digit code — never plaintext.
--              Single-use; expires after 10 minutes.
--              Previous unused codes for the same phone are invalidated
--              when a new one is created.
-- =====================================================================

CREATE TABLE [TSA].[OtpCode] (
    [id]            UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [phoneNumber]   NVARCHAR(30)        NOT NULL,
    [otpHash]       NVARCHAR(64)        NOT NULL,
    [createdAt]     DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),
    [expiresAt]     DATETIMEOFFSET(7)   NOT NULL,
    [usedAt]        DATETIMEOFFSET(7)   NULL,

    CONSTRAINT [PK_TSA_OtpCode] PRIMARY KEY ([id])
);

CREATE INDEX [IX_TSA_OtpCode_phone_active]
    ON [TSA].[OtpCode] ([phoneNumber], [expiresAt])
    WHERE [usedAt] IS NULL;
