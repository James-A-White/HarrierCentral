-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions "derived entry + surfaces", Phase 7
-- Two PORTAL-ONLY capabilities: editWebsite + designWebsite.
-- =====================================================================
-- These gate the "Edit Website" / "Design Website" buttons on the portal only
-- (Surfaces = 2 = portal). Because they are portal-surface, the app's
-- canEnterArea('web', app) never sees them — proving the surface bitmask.
--
-- Default grants (global): flagManageWebContent + flagAdmin (preserves today's
-- "canManagePublicWebContent || isAdmin" button visibility) + webMeister (mmRole,
-- so web meisters without the flag also get it). SuperAdmin bypasses. Both
-- functions seed to the SAME grantors but are independent (separately tunable).
-- Adjust further in the portal permissions editor.
--
-- HC.PermissionFunction / RolePermission are not mobile-synced (no trigger).
-- ⚠️  RUN MANUALLY, ONCE. Archived after running. Recompile the matrix after.
-- =====================================================================
SET XACT_ABORT ON;
GO

-- 1. The two portal-only capability rows (idempotent on FunctionKey).
MERGE HC.PermissionFunction AS t
USING (VALUES
    ('editWebsite',   'Edit website',   'Web / Newsletter', 'web', 2, 0, 62),
    ('designWebsite', 'Design website', 'Web / Newsletter', 'web', 2, 0, 63)
) AS s(FunctionKey, DisplayName, FeatureArea, AreaKey, Surfaces, HareScoped, SortOrder)
   ON t.FunctionKey = s.FunctionKey
WHEN MATCHED THEN UPDATE SET
    DisplayName = s.DisplayName, FeatureArea = s.FeatureArea,
    AreaKey = s.AreaKey, Surfaces = s.Surfaces,
    HareScoped = s.HareScoped, SortOrder = s.SortOrder
WHEN NOT MATCHED THEN
    INSERT (FunctionKey, DisplayName, FeatureArea, AreaKey, Surfaces, HareScoped, SortOrder)
    VALUES (s.FunctionKey, s.DisplayName, s.FeatureArea, s.AreaKey, s.Surfaces, s.HareScoped, s.SortOrder);
GO

-- 2. Default global grants: webMeister + flagManageWebContent get both functions.
INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT g.id, f.id, NULL, 1
FROM HC.PermissionRole g
JOIN HC.PermissionFunction f ON f.FunctionKey IN ('editWebsite', 'designWebsite')
WHERE g.GrantorKey IN ('webMeister', 'flagManageWebContent', 'flagAdmin')
  AND NOT EXISTS (
      SELECT 1 FROM HC.RolePermission x
      WHERE x.GrantorId = g.id AND x.FunctionId = f.id AND x.KennelId IS NULL);
GO

-- 3. Verify.
SELECT f.FunctionKey, f.Surfaces, f.AreaKey,
       (SELECT STRING_AGG(g.GrantorKey, ', ')
        FROM HC.RolePermission rp JOIN HC.PermissionRole g ON g.id = rp.GrantorId
        WHERE rp.FunctionId = f.id AND rp.KennelId IS NULL AND rp.Allowed = 1) AS GrantedTo
FROM HC.PermissionFunction f
WHERE f.FunctionKey IN ('editWebsite', 'designWebsite');
GO
