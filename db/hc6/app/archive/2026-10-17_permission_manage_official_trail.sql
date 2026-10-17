-- Run-once (James, 2026-10-17): who may add or set a run's official trail —
-- the run's (appointed) hare, Hare Raiser, GM, VGM, and Super Admin (the
-- bypass, implicit). Its own permission instead of createEditRuns, which
-- reaches more roles. Rows in the existing permission tables (no new table);
-- adjustable on the portal's Permissions page like every other function.
-- Mirrored in the app as KennelFeature.manageOfficialTrail (0x206, hare-scoped).
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM HC.PermissionFunction WHERE FunctionKey = 'manageOfficialTrail')
    INSERT HC.PermissionFunction (FunctionKey, DisplayName, FeatureArea, HareScoped, SortOrder, Surfaces, AreaKey)
    VALUES ('manageOfficialTrail', 'Set the official trail', 'Kennel Tools', 1, 39, 1, 'kennelTools');
DECLARE @f INT = (SELECT id FROM HC.PermissionFunction WHERE FunctionKey = 'manageOfficialTrail');
INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT r.id, @f, NULL, 1
FROM HC.PermissionRole r
WHERE r.GrantorKey IN ('gm', 'vgm', 'hareRaiser', 'hare')
  AND NOT EXISTS (SELECT 1 FROM HC.RolePermission x WHERE x.FunctionId = @f AND x.GrantorId = r.id AND x.KennelId IS NULL);
SELECT f.FunctionKey, r.DisplayName FROM HC.RolePermission rp
JOIN HC.PermissionFunction f ON f.id = rp.FunctionId JOIN HC.PermissionRole r ON r.id = rp.GrantorId
WHERE f.FunctionKey = 'manageOfficialTrail';
