-- =====================================================================
-- Run-once: collapse the HC.Device rows that made one chat message arrive
-- 43 times on one hasher's devices (2026-09-17).
--
-- hcapp_setFcmTokens now retires a device's older rows as each device
-- re-registers, but that only fires when a device next checks in. This
-- applies exactly the same two rules to the rows already in the table, so
-- the fix takes effect immediately instead of trickling in.
--
-- Rule (a): the same token STRING on more than one row is the same app
--           install. Keep the most recently seen row, clear the rest.
-- Rule (b): Apple only. The same hasher with the same identifierForVendor
--           is the same physical device under a re-minted device id. Keep
--           the most recently seen row, clear the rest. Android and
--           browsers carry no identifier that distinguishes two devices,
--           so neither is touched (James, 2026-09-17).
--
-- Nothing is deleted: only FcmToken is cleared and FcmTokenDeleted stamped,
-- so the row's history, secret and login record survive, and the device
-- re-arms itself the next time it registers a token.
-- HC.Device is not a mobile-synced table, so this causes no client re-sync.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- (a) duplicate token strings
;WITH dupTok AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY FcmToken ORDER BY LastLogin DESC, updatedAt DESC) AS rn
    FROM HC.Device
    WHERE FcmToken IS NOT NULL
)
UPDATE d
SET d.FcmToken        = NULL,
    d.FcmTokenDeleted = SYSUTCDATETIME()
FROM HC.Device d
INNER JOIN dupTok ON dupTok.id = d.id
WHERE dupTok.rn > 1;
PRINT 'rule (a) duplicate token strings cleared: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- (b) Apple: same hasher, same identifierForVendor
;WITH iosDup AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY UserId, JSON_VALUE(CAST(DeviceData AS NVARCHAR(MAX)), '$.identifierForVendor')
               ORDER BY LastLogin DESC) AS rn
    FROM HC.Device
    WHERE FcmToken IS NOT NULL
      AND OperatingSystem IN ('iOS', 'iPadOS')
      AND JSON_VALUE(CAST(DeviceData AS NVARCHAR(MAX)), '$.identifierForVendor') IS NOT NULL
)
UPDATE d
SET d.FcmToken        = NULL,
    d.FcmTokenDeleted = SYSUTCDATETIME()
FROM HC.Device d
INNER JOIN iosDup ON iosDup.id = d.id
WHERE iosDup.rn > 1;
PRINT 'rule (b) superseded Apple device rows cleared: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

SELECT COUNT(*) AS tokenRowsRemaining FROM HC.Device WHERE FcmToken IS NOT NULL;

COMMIT TRANSACTION;
