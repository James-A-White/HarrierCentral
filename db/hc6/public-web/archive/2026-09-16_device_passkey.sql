-- Run-once (E9.F7.S6, 2026-09-16): a passkey is a device credential, so it
-- lives on the browser's HC.Device row — no new table. HC.Device is not a
-- synced table (no UpdatedAt trigger dance). Archive after running.
ALTER TABLE HC.Device ADD
    PasskeyCredentialId NVARCHAR(500)  NULL,   -- base64url credential id from the authenticator
    PasskeyPublicKey    NVARCHAR(2000) NULL,   -- base64url COSE public key
    PasskeyCounter      BIGINT         NULL,   -- signature counter (clone detection)
    PasskeyTransports   NVARCHAR(100)  NULL;   -- 'internal,hybrid' etc., hint for the browser
GO
CREATE UNIQUE INDEX IX_Device_PasskeyCredentialId
    ON HC.Device (PasskeyCredentialId)
    WHERE PasskeyCredentialId IS NOT NULL;
GO
