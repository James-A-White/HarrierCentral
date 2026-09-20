-- =====================================================================
-- RUN ONCE. Archive to db/hc6/app/archive/ after running.
--
-- E9.F7.S19 — tell a signed-out device WHY it is being refused.
--
-- Rotating DeviceSecret already revokes a device, but the refusal that
-- follows is HC.CHECK_ACCESS_TOKEN_V2 returning 0 — which is exactly what
-- a phone with a drifting clock produces. The client must be able to tell
-- those apart, because one of them means "wipe this install and start
-- again" and the other must never do that.
--
-- So sign-out leaves a mark, and ValidateAppAuth reads it.
--
-- Why a column and not a flag we already have: `removed` cannot be used.
-- 300 devices carry removed = 1 today and 46 of them signed in within 90
-- days, so treating it as "signed out" would wipe the app for people who
-- are using it. SignedOutAt is set ONLY by hcapp_signOutDevice, so it
-- starts empty and means exactly one thing.
--
-- SAFE TO ALTER DIRECTLY: HC.Device has no triggers (verified 2026-09-20
-- against sys.triggers) and does not take part in the mobile sync, so the
-- UpdatedAt-trigger dance that other tables need does not apply here.
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.Device') AND name = 'SignedOutAt')
BEGIN
    ALTER TABLE HC.Device ADD SignedOutAt DATETIMEOFFSET NULL;
END
