-- =====================================================================
-- Run-once: hc_agent_reader — the READ-ONLY database user for the cloud
-- Beta Testers assistant (E18.F9, James approved 2026-10-14).
--
-- The assistant researches what actually happened in the database. It must
-- never be able to change anything, whatever a tester's message says, so the
-- guarantee is the DATABASE's, not the prompt's:
--   * a contained user (no server login, no master access);
--   * SELECT on HC, LOG, EXT, DomainValues and HC6 only — no EXECUTE, no
--     INSERT/UPDATE/DELETE, no DDL; legacy schemas (dbo, HC3W, HC_BACKUP*,
--     TSA …) are not granted at all;
--   * DENY on every column that holds a secret (device secrets, codes,
--     tokens, API keys, bank details, merchant codes, passkey material) and
--     on the two token tables. DENY beats the schema GRANT.
-- The password is a sqlcmd variable ($(AGENT_PW)), never in this file. It
-- lives in the repo's .env (HC_AGENT_SQL_PASSWORD, gitignored) and, once the
-- assistant is deployed, in the API app's settings.
-- Re-runnable: the user is created once; grants and denies are idempotent.
-- =====================================================================
SET NOCOUNT ON;
IF DATABASE_PRINCIPAL_ID('hc_agent_reader') IS NULL
    CREATE USER hc_agent_reader WITH PASSWORD = '$(AGENT_PW)';
GO
GRANT SELECT ON SCHEMA::HC           TO hc_agent_reader;
GRANT SELECT ON SCHEMA::LOG          TO hc_agent_reader;
GRANT SELECT ON SCHEMA::EXT          TO hc_agent_reader;
GRANT SELECT ON SCHEMA::DomainValues TO hc_agent_reader;
GRANT SELECT ON SCHEMA::HC6          TO hc_agent_reader;
GRANT SHOWPLAN TO hc_agent_reader;   -- lets it ask why a query is slow
GO
DENY SELECT ON HC.PublicWebAdminToken             TO hc_agent_reader;
DENY SELECT ON HC.WebPortalAuthenticationRequests TO hc_agent_reader;
DENY SELECT ON HC.Device (DeviceSecret, ApnsToken, FcmToken, PasskeyCredentialId, PasskeyPublicKey, PasskeyCounter, PasskeyTransports) TO hc_agent_reader;
DENY SELECT ON HC.Hasher (ResetCode, QR_code, QR_secret_code, SupportCode, FacebookAccessToken, ThirdPartyAccessToken, ThirdPartyAuthorizationCode) TO hc_agent_reader;
DENY SELECT ON HC.HasherBackup (ResetCode, QR_code, QR_secret_code, SupportCode, FacebookAccessToken, ThirdPartyAccessToken, ThirdPartyAuthorizationCode) TO hc_agent_reader;
DENY SELECT ON HC.Kennel (ExtApiKey, KennelGoogleSheetApiKey, KennelFacebookToken, CardPaymentMerchantCode, BankAccountNumber, BankBic, BankBeneficiary) TO hc_agent_reader;
DENY SELECT ON HC.Event (BankAccountNumber, BankBic, BankBeneficiary) TO hc_agent_reader;
DENY SELECT ON HC.PushLog (FcmToken) TO hc_agent_reader;
DENY SELECT ON EXT.OfficeForms_KennelImport (ConfirmCode, KennelAdminInviteCode) TO hc_agent_reader;
GO
