-- =====================================================================
-- Run-once (James, 2026-10-16). Idempotent: safe to run twice.
--
-- 1. Two system hashers (data rows in HC.Hasher, not a new table):
--      Harrier Central  — posts the weekly reminders in each kennel's
--                         Mismanagement chat (E9.F1.S33).
--      Claude Beta Bot  — James's assistant in the Beta Testers room
--                         (E18.F9), so its replies stop coming from
--                         James's own account. In the beta cohort, which
--                         is what lets it into room 8.
--    Fixed ids, so code and settings can name them. Each email is the
--    generated "<GUID>@harriercentral.com" form: HC6.IsGeneratedEmail is
--    true for it, so no mailer will ever send to it. No home kennel, so
--    trgInsertHkmRecordForHomeHash adds no membership.
--
-- 2. HCTEST-ABC: office and admin roles trimmed to James (Opee) and Tuna
--    Melt, so the test kennel's Mismanagement chat and reminders reach
--    only them. The four rows cleared, with their values before, so this
--    can be undone:
--      Comes Too Soon  MismanagementRoles 1537      AppAccessFlags 0
--      HashGoof        MismanagementRoles 0         AppAccessFlags 1073741845
--      Test 1 Hasher   MismanagementRoles 557057    AppAccessFlags 1073742079
--      Test 2 Hasher   MismanagementRoles 92798993  AppAccessFlags 197
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @hcId  UNIQUEIDENTIFIER = 'a7c0e6f2-5b1d-4c8e-9f3a-0d2b6e4c1a01';
DECLARE @botId UNIQUEIDENTIFIER = 'b3e1d9c4-7a2f-4e6b-8c5d-1f0a9b8c2d02';

BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM HC.Hasher WITH (UPDLOCK, HOLDLOCK) WHERE id = @hcId)
    INSERT HC.Hasher (id, HashName, Email)
    VALUES (@hcId, N'Harrier Central',
            LOWER(CAST(@hcId AS NVARCHAR(40))) + N'@harriercentral.com');

IF NOT EXISTS (SELECT 1 FROM HC.Hasher WITH (UPDLOCK, HOLDLOCK) WHERE id = @botId)
    INSERT HC.Hasher (id, HashName, Email, BetaFeaturesEnabled)
    VALUES (@botId, N'Claude Beta Bot',
            LOWER(CAST(@botId AS NVARCHAR(40))) + N'@harriercentral.com', N'BetaRoom');

UPDATE m SET MismanagementRoles = 0, AppAccessFlags = 0
FROM HC.HasherKennelMap m
JOIN HC.Kennel k ON k.id = m.KennelId
JOIN HC.Hasher h ON h.id = m.UserId
WHERE k.KennelShortName = N'HCTEST-ABC'
  AND h.HashName IN (N'Comes Too Soon', N'HashGoof', N'Test 1 Hasher', N'Test 2 Hasher')
  AND (m.MismanagementRoles <> 0 OR m.AppAccessFlags <> 0);

COMMIT TRANSACTION;

SELECT h.HashName, h.DisplayName, HC6.IsGeneratedEmail(h.Email) AS generatedEmail,
       h.BetaFeaturesEnabled, h.HomeKennelId
FROM HC.Hasher h WHERE h.id IN (@hcId, @botId);

SELECT h.HashName, m.MismanagementRoles, m.AppAccessFlags
FROM HC.HasherKennelMap m
JOIN HC.Kennel k ON k.id = m.KennelId
JOIN HC.Hasher h ON h.id = m.UserId
WHERE k.KennelShortName = N'HCTEST-ABC' AND m.removed = 0
  AND (m.MismanagementRoles <> 0 OR m.AppAccessFlags <> 0)
ORDER BY h.HashName;
