CREATE OR ALTER PROCEDURE [HC6].[CheckKennelPermission]
    @userId       UNIQUEIDENTIFIER,
    @kennelId     UNIQUEIDENTIFIER,
    @functionKey  NVARCHAR(80),          -- HC.PermissionFunction.FunctionKey
    @allowed      SMALLINT OUTPUT,       -- 1 = allowed, 0 = denied
    @isHareOfEvent SMALLINT = 0          -- 1 when the caller is the designated hare of the event
AS
-- =====================================================================
-- Procedure: HC6.CheckKennelPermission
-- Description: The single authorizer for kennel-scoped features (Permissions V2).
--   Data-driven: resolves the gate from the permission tables
--   (HC.PermissionFunction / PermissionRole / RolePermission) for @functionKey,
--   honouring per-kennel tri-state overrides.
--
--   Access model:
--       SuperAdmin (0x40000000)                     -- the only "everything" bypass
--    OR the user holds a grantor (mm-role or app-flag bit) that grants the function,
--       where the effective grant resolves as:
--         kennel override  1 -> grant, -1 -> revoke, 0/absent -> inherit global.
--   IsAdmin (0x01) is NOT a bypass. Run-scoped (Hare) access is handled by the
--   caller via HasherEventMap.IsHare for hare-scoped functions.
--
--   (The legacy positional mask parameters were removed 2026-07-27 once all
--   callers migrated to @functionKey.)
-- Parameters: @userId / @kennelId, @functionKey. Returns @allowed OUTPUT (1/0).
-- Author: Harrier Central
-- Created: 2026-07-19 (V2 data-driven: 2026-07-27)
-- =====================================================================
SET NOCOUNT ON;

DECLARE @mm INT = 0, @flags INT = 0;

SELECT
    @mm    = ISNULL(MismanagementRoles, 0),
    @flags = ISNULL(AppAccessFlags, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId AND removed = 0;

-- SuperAdmin bypasses every feature.
IF (@flags & 0x40000000) <> 0
BEGIN
    SET @allowed = 1;
    RETURN;
END

-- Allowed iff the user holds a grantor whose EFFECTIVE grant for
-- (function, kennel) resolves to 1 (kennel tri-state over global default).
SET @allowed = CASE WHEN EXISTS (
    SELECT 1
    FROM HC.PermissionFunction f
    JOIN HC.PermissionRole g
      ON ( (g.GrantorType = 'mmRole'  AND (@mm    & g.Bit) <> 0)
        OR (g.GrantorType = 'appFlag' AND (@flags & g.Bit) <> 0)
        OR (g.GrantorType = 'hare'    AND @isHareOfEvent = 1) )
    LEFT JOIN HC.RolePermission kr
           ON kr.FunctionId = f.id AND kr.GrantorId = g.id AND kr.KennelId = @kennelId
    LEFT JOIN HC.RolePermission gr
           ON gr.FunctionId = f.id AND gr.GrantorId = g.id AND gr.KennelId IS NULL
    WHERE f.FunctionKey = @functionKey
      AND CASE WHEN kr.Allowed = 1  THEN 1
               WHEN kr.Allowed = -1 THEN 0
               WHEN kr.Allowed = 0  THEN COALESCE(gr.Allowed, 0)
               ELSE COALESCE(gr.Allowed, 0) END = 1
) THEN 1 ELSE 0 END;
