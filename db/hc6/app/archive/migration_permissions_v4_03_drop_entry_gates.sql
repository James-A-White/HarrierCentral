-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions "derived entry", Phase 4b (CUTOVER)
-- =====================================================================
-- Deletes the legacy explicit entry-gate functions enterRunAdmin / enterKennelAdmin
-- and their grants. Entry is now DERIVED everywhere (CheckAreaEntry server-side;
-- canEnterArea in the shipped app; the portal editor no longer shows them). After
-- this the compiled JSON no longer carries them, and CheckAreaEntry's transitional
-- NOT IN clause becomes a harmless no-op.
--
-- Ships WITH the app 2.15.17+1231 and portal 2.0.57+692 release. Old app installs
-- fall back to their KennelFeature enum floor for enter*, so they stay safe in the
-- brief update window.
--
-- Reversible: re-insert from migration_permissions_v2_02_seed.sql if ever needed.
-- ⚠️  RUN MANUALLY, ONCE. Archived after running. Recompiles the matrix at the end.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- 1. Drop grants first (FK: RolePermission.FunctionId -> PermissionFunction.id).
DELETE rp
FROM HC.RolePermission rp
JOIN HC.PermissionFunction f ON f.id = rp.FunctionId
WHERE f.FunctionKey IN ('enterRunAdmin', 'enterKennelAdmin');

-- 2. Drop the gate functions.
DELETE FROM HC.PermissionFunction
WHERE FunctionKey IN ('enterRunAdmin', 'enterKennelAdmin');

COMMIT TRANSACTION;
GO

-- 3. Recompile the projections (JSON now excludes enter*).
EXEC HC6.nonApi_compilePermissionMatrix;
GO

-- 4. Verify: no enter* rows remain; JSON no longer references them.
SELECT COUNT(*) AS EnterRowsRemaining
FROM HC.PermissionFunction WHERE FunctionKey IN ('enterRunAdmin','enterKennelAdmin');

SELECT CASE WHEN PermissionMatrixJson LIKE '%enterRunAdmin%'
            OR PermissionMatrixJson LIKE '%enterKennelAdmin%'
       THEN 'STILL PRESENT (bad)' ELSE 'gone (good)' END AS JsonEnterCheck
FROM HC.ServerStatus;
GO
