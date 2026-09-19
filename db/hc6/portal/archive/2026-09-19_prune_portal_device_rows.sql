-- =====================================================================
-- Run-once: retire the portal device rows nobody is using.
--
-- WHY THERE ARE SO MANY. hcportal_confirmAuthentication was handed a fresh
-- UUID by the portal on EVERY login (admin_portal_controller: Uuid().v4()),
-- so a row was inserted per login unconditionally — 392 rows across 68
-- people by 2026-09-19, one hasher on 49. Each row also kept its own push
-- token, which is where the duplicate notifications came from.
--
-- The cause is fixed in the same change as this script: the portal now
-- offers the device it already holds, and the SP reuses that row when it
-- belongs to the person logging in. This script clears up what the old
-- behaviour left behind.
--
-- WHAT IT RETIRES: a browser row only when BOTH are true —
--   * it is NOT that hasher's most recent browser row, and
--   * it has not been used in 30 days.
-- So nobody mid-session is touched, and a second browser genuinely in use
-- keeps working. Everyone keeps at least one row.
--
-- Marks Removed = 1 and clears the push token rather than DELETEing, so the
-- row stays available for the push log's token lookups and the change is
-- reversible.
--
-- Expected on 2026-09-19: 353 live browser rows -> 258 retired, 95 kept
-- across the same 68 people, 32 live tokens cleared.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

WITH browserRows AS (
    SELECT d.id,
           d.LastLogin,
           ROW_NUMBER() OVER (PARTITION BY d.UserId ORDER BY d.LastLogin DESC) AS rn
    FROM HC.Device d
    WHERE d.removed = 0
      AND d.OperatingSystem IN ('firefox','chrome','safari','Firefox','Chrome','Safari')
)
UPDATE d
SET d.removed         = 1,
    d.FcmToken        = NULL,
    d.FcmTokenDeleted = SYSUTCDATETIME()
FROM HC.Device d
INNER JOIN browserRows b ON b.id = d.id
WHERE b.rn > 1
  AND b.LastLogin < DATEADD(DAY, -30, SYSDATETIMEOFFSET());

SELECT @@ROWCOUNT AS RowsRetired;

COMMIT TRANSACTION;
