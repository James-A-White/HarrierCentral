-- =====================================================================
-- Seed: HC.Device — HC6 Service Account Devices
-- Description: Pre-seeds two HC.Device rows required by
--              HC6.ValidatePortalAuth before any HC6 portal SPs can run.
--
-- Service accounts:
--   11111111-... → HashRuns.org service account (callerType = 1)
--   22222222-... → Admin portal service account (callerType = 2)
--
-- Design decisions:
--   - Device.id matches each service account's Hasher.PublicHasherId.
--     This makes device IDs predictable and reduces magic values.
--   - DeviceSecret = '' (empty string). This means HC6 service account
--     tokens are algebraically identical to HC5 tokens, so the Flutter
--     portal does NOT need a token-generation change to call HC6 SPs
--     for these accounts.
--   - TimeWindow = 86469 to match HC.CHECK_PORTAL_ACCESS_TOKEN's
--     primary window (HC5 portal behaviour).
--
-- Flutter portal changes still required (separate work):
--   - confirmAuthentication: change 'deviceId' body field from the new
--     random UUID to '22222222-2222-2222-2222-222222222222', and add a
--     'newDeviceId' field with the new random UUID.
--   - Token bypass in HC6.CHECK_PORTAL_ACCESS_TOKEN is active until
--     2026-06-01, so HC6 endpoints are usable before that change ships.
--
-- Idempotent: skips insert if the row already exists.
-- Run once on initial HC6 deployment.
-- =====================================================================

SET NOCOUNT ON;

DECLARE @hasherId1 UNIQUEIDENTIFIER;
DECLARE @hasherId2 UNIQUEIDENTIFIER;

-- Look up hasher internal IDs from well-known public GUIDs
SELECT @hasherId1 = id FROM HC.Hasher WHERE PublicHasherId = '11111111-1111-1111-1111-111111111111';
SELECT @hasherId2 = id FROM HC.Hasher WHERE PublicHasherId = '22222222-2222-2222-2222-222222222222';

-- Abort if service account hashers are missing — they must exist before devices can be seeded
IF @hasherId1 IS NULL
BEGIN
    RAISERROR('HashRuns.org service account hasher (PublicHasherId = 11111111-...) not found in HC.Hasher. Seed aborted.', 16, 1);
    RETURN;
END

IF @hasherId2 IS NULL
BEGIN
    RAISERROR('Admin portal service account hasher (PublicHasherId = 22222222-...) not found in HC.Hasher. Seed aborted.', 16, 1);
    RETURN;
END

-- Seed HashRuns.org service account device (callerType = 1)
IF NOT EXISTS (SELECT 1 FROM HC.Device WHERE id = '11111111-1111-1111-1111-111111111111')
BEGIN
    INSERT INTO HC.Device
        (id, UserId, DeviceSecret, TimeWindow, DeviceData)
    VALUES
        (
            '11111111-1111-1111-1111-111111111111',
            @hasherId1,
            N'',               -- empty secret: HC6 tokens == HC5 tokens for this account
            86469,             -- matches HC5 CHECK_PORTAL_ACCESS_TOKEN primary window
            N'{"service":"hashRunsDotOrg"}'
        );
    PRINT 'Seeded: HashRuns.org service account device (11111111-1111-1111-1111-111111111111)';
END
ELSE
    PRINT 'Skipped: HashRuns.org service account device already exists';

-- Seed admin portal service account device (callerType = 2)
IF NOT EXISTS (SELECT 1 FROM HC.Device WHERE id = '22222222-2222-2222-2222-222222222222')
BEGIN
    INSERT INTO HC.Device
        (id, UserId, DeviceSecret, TimeWindow, DeviceData)
    VALUES
        (
            '22222222-2222-2222-2222-222222222222',
            @hasherId2,
            N'',               -- empty secret: HC6 tokens == HC5 tokens for this account
            86469,             -- matches HC5 CHECK_PORTAL_ACCESS_TOKEN primary window
            N'{"service":"adminPortal"}'
        );
    PRINT 'Seeded: Admin portal service account device (22222222-2222-2222-2222-222222222222)';
END
ELSE
    PRINT 'Skipped: Admin portal service account device already exists';
