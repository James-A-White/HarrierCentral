-- =====================================================================
-- RUN-ONCE — add HC.PlatformAdmin.CanManagePermissions (Permissions V2, Phase 5)
-- =====================================================================
-- New platform-admin privilege gating the super-admin Permissions Matrix editor
-- (hcportal_getPermissionMatrix / hcportal_savePermissionMatrix). Mirrors the
-- CanEditKennel precedent. HC.PlatformAdmin is portal-only (not mobile-synced),
-- so this is a plain ALTER — no trigger dance.
--
-- ⚠️  RUN MANUALLY, ONCE. Not picked up by deploy_hc6.sh. Archive after running.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('HC.PlatformAdmin') AND name = 'CanManagePermissions')
    ALTER TABLE [HC].[PlatformAdmin]
    ADD [CanManagePermissions] SMALLINT NOT NULL
        CONSTRAINT [DF_PlatformAdmin_CanManagePermissions] DEFAULT 0;
GO

-- Seed: Opee (James White) only — permission management is the most sensitive
-- platform privilege. Grant others by hand as needed.
UPDATE HC.PlatformAdmin
SET CanManagePermissions = 1
WHERE UserId = (
    SELECT id FROM HC.Hasher
    WHERE PublicHasherId = 'B6BAFD0D-5D2E-41CD-8495-811D551F01D0'
      AND removed = 0
);
GO

SELECT UserId, CanViewMonitor, CanManageNewsflash, CanEditKennel, CanManagePermissions
FROM HC.PlatformAdmin WHERE removed = 0;
GO
