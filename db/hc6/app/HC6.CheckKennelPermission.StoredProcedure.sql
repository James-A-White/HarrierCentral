CREATE OR ALTER PROCEDURE [HC6].[CheckKennelPermission]
    @userId           UNIQUEIDENTIFIER,
    @kennelId         UNIQUEIDENTIFIER,
    @requiredMmRoles  INT = NULL,             -- LEGACY (positional 3rd). Used only when @functionKey IS NULL.
    @requiredAppFlags INT = NULL,             -- LEGACY (positional 4th).
    @allowed          SMALLINT OUTPUT,        -- 1 = allowed, 0 = denied
    @functionKey      NVARCHAR(80) = NULL     -- NEW: when supplied, resolves the gate from the permission tables.
AS
-- =====================================================================
-- Procedure: HC6.CheckKennelPermission
-- Description: The single authorizer for kennel-scoped features (Permissions V2).
--   Preferred call passes @functionKey (named) and the gate is resolved from the
--   data-driven tables (HC.PermissionFunction / PermissionRole / RolePermission),
--   honouring per-kennel tri-state overrides. The LEGACY mask form
--   (@requiredMmRoles / @requiredAppFlags, positional) is retained ONLY so callers
--   can be migrated to keys without a deploy window; it will be removed in the
--   Permissions V2 cleanup phase once no caller uses it.
--
--   Access model (unchanged in meaning):
--       SuperAdmin (0x40000000)                     -- the only "everything" bypass
--    OR the user holds a grantor (mm-role or app-flag bit) that grants the function.
--   Data path resolves each grantor's effective grant as:
--       kennel override 1 -> grant, -1 -> revoke, 0/absent -> inherit global.
--   IsAdmin (0x01) is NOT a bypass — it only matches functions that explicitly
--   list the admin flag as a grantor (none do).
--
--   Run-scoped (Hare) access is NOT handled here — callers add an inline
--   HasherEventMap.IsHare check for hare-scoped functions, as before.
-- Parameters:
--   @userId / @kennelId  - who + which kennel (the HKM row)
--   @functionKey         - HC.PermissionFunction.FunctionKey (preferred)
--   @requiredMmRoles / @requiredAppFlags - legacy masks (transitional)
-- Returns: @allowed OUTPUT (SMALLINT 1/0). No rowset.
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

-- SuperAdmin bypasses every feature (both paths).
IF (@flags & 0x40000000) <> 0
BEGIN
    SET @allowed = 1;
    RETURN;
END

IF @functionKey IS NOT NULL
BEGIN
    -- Data-driven path: allowed iff the user holds a grantor whose EFFECTIVE grant
    -- for (function, kennel) resolves to 1 (kennel tri-state over global default).
    SET @allowed = CASE WHEN EXISTS (
        SELECT 1
        FROM HC.PermissionFunction f
        JOIN HC.PermissionRole g
          ON ( (g.GrantorType = 'mmRole'  AND (@mm    & g.Bit) <> 0)
            OR (g.GrantorType = 'appFlag' AND (@flags & g.Bit) <> 0) )
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
    RETURN;
END

-- LEGACY mask path (transitional; identical to the pre-V2 comparator).
SET @allowed =
    CASE WHEN
            (@mm    & ISNULL(@requiredMmRoles, 0))  <> 0
         OR (@flags & ISNULL(@requiredAppFlags, 0)) <> 0
    THEN 1 ELSE 0 END;
