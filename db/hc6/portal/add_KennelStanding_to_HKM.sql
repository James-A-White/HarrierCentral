-- =====================================================================
-- Run-once migration: add HC.HasherKennelMap.KennelStanding (INT bit-field)
-- Date: 2026-07-06 — design of record: project_kennel_standing_design
--
-- Kennel-granted access grants, provenance by bit:
--   0x0001 MEMBER   — AUTOMATION ONLY (payment/expiration machinery)
--   0x0002 ALUMNI   — manual grant, never touched by automation
--   0x0004 TRUSTED  — manual grant
--   0x0100 ADMIN    — manual, mismanagement-gated
-- Member-tier content = KennelStanding & 0x0107 != 0 (OR-mask read side).
--
-- HKM is SYNCED: disable the updatedAt trigger (and the admin-list trigger)
-- around the ALTER + backfill so 60k+ rows don't restamp and force a full
-- HKM re-sync to every client. JAMES RUNS THIS — not autonomous.
-- Idempotent. Deploy order: this FIRST, then deploy SPs (they reference the
-- column and the TVF).
-- =====================================================================
SET XACT_ABORT ON;
GO
DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherKennelMap] ON [HC].[HasherKennelMap];
DISABLE TRIGGER [HC].[trgUpdateKennelAdminList] ON [HC].[HasherKennelMap];
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.HasherKennelMap') AND name = 'KennelStanding')
    ALTER TABLE [HC].[HasherKennelMap] ADD [KennelStanding] INT NOT NULL DEFAULT 0;
GO
-- Backfill: MEMBER where membership is current; ADMIN (+MEMBER cascade) where
-- the user already holds any app-access grant (permissive, per James).
UPDATE hkm SET KennelStanding =
      CASE WHEN hkm.MembershipExpirationDate IS NOT NULL
                AND hkm.MembershipExpirationDate >= GETDATE() THEN 0x0001 ELSE 0 END
    | CASE WHEN COALESCE(hkm.AppAccessFlags, 0) <> 0
             OR COALESCE(hkm.MismanagementRoleFlags, 0) <> 0 THEN 0x0101 ELSE 0 END
FROM HC.HasherKennelMap hkm
WHERE hkm.KennelStanding = 0;  -- only unmigrated rows
GO
ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherKennelMap] ON [HC].[HasherKennelMap];
ENABLE TRIGGER [HC].[trgUpdateKennelAdminList] ON [HC].[HasherKennelMap];
GO
-- The single access oracle. All content-access SPs consume this — never
-- re-derive membership inline (NULLIF-drift lesson).
CREATE OR ALTER FUNCTION [HC].[KennelAccessTier] (@userId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER)
RETURNS TABLE AS RETURN
(
    SELECT
        CASE WHEN COALESCE(hkm.KennelStanding, 0) & 0x0100 <> 0 THEN 20      -- admin
             WHEN COALESCE(hkm.KennelStanding, 0) & 0x0107 <> 0 THEN 10      -- member-tier (MEMBER|ALUMNI|TRUSTED|ADMIN)
             ELSE 0 END AS Tier,
        COALESCE(hkm.KennelStanding, 0) AS Standing
    FROM (SELECT 1 AS one) AS d
    LEFT JOIN HC.HasherKennelMap hkm
        ON hkm.UserId = @userId AND hkm.KennelId = @kennelId
);
GO
SELECT COUNT(*) AS TotalHkm,
       SUM(CASE WHEN KennelStanding & 0x0001 <> 0 THEN 1 ELSE 0 END) AS MemberBits,
       SUM(CASE WHEN KennelStanding & 0x0100 <> 0 THEN 1 ELSE 0 END) AS AdminBits
FROM HC.HasherKennelMap;
GO
