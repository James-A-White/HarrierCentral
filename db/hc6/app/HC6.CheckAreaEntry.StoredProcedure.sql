CREATE OR ALTER PROCEDURE [HC6].[CheckAreaEntry]
    @userId        UNIQUEIDENTIFIER,
    @kennelId      UNIQUEIDENTIFIER,
    @areaKey       NVARCHAR(40),          -- HC.PermissionFunction.AreaKey
    @surface       SMALLINT,              -- 1 = app, 2 = portal (bit-tested vs Surfaces)
    @allowed       SMALLINT OUTPUT,       -- 1 = may enter the area, 0 = may not
    @isHareOfEvent SMALLINT = 0           -- 1 when the caller is the designated hare of the event
AS
-- =====================================================================
-- Procedure: HC6.CheckAreaEntry
-- Description: Derived-entry oracle for the Permissions system. A UI "doorway"
--   (the app's Run/Kennel Admin gear, the portal's section) is shown iff the user
--   holds AT LEAST ONE capability in that area on that surface. This is the
--   server-side twin of the client's canEnterArea() — used to gate the admin data
--   sync SPs, which must not hand a user an admin domain they can't act in.
--
--   Entry = OR, over every capability f where f.AreaKey = @areaKey and
--   (f.Surfaces & @surface) <> 0, of CheckKennelPermission's effective grant
--   (mm-role / app-flag / hare bit test, with per-kennel tri-state over global).
--   SuperAdmin (0x40000000) bypasses. Hare-scoped capabilities count only when
--   @isHareOfEvent = 1.
--
--   NOTE (transitional): the legacy explicit gate functions enterRunAdmin /
--   enterKennelAdmin are excluded from the OR so entry is PURELY derived from real
--   capabilities. Those rows are deleted in a later phase, after which the NOT IN
--   clause is a no-op and can be dropped.
-- Parameters: @userId / @kennelId, @areaKey, @surface. Returns @allowed OUTPUT (1/0).
-- Author: Harrier Central
-- Created: 2026-07-28
-- =====================================================================
SET NOCOUNT ON;

DECLARE @mm INT = 0, @flags INT = 0;

SELECT
    @mm    = ISNULL(MismanagementRoles, 0),
    @flags = ISNULL(AppAccessFlags, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId AND removed = 0;

-- SuperAdmin may enter everything.
IF (@flags & 0x40000000) <> 0
BEGIN
    SET @allowed = 1;
    RETURN;
END

-- May enter iff SOME capability in the area/surface resolves to an effective grant.
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
    WHERE f.AreaKey = @areaKey
      AND (f.Surfaces & @surface) <> 0
      AND f.FunctionKey NOT IN ('enterRunAdmin', 'enterKennelAdmin')  -- transitional; see header
      AND CASE WHEN kr.Allowed = 1  THEN 1
               WHEN kr.Allowed = -1 THEN 0
               WHEN kr.Allowed = 0  THEN COALESCE(gr.Allowed, 0)
               ELSE COALESCE(gr.Allowed, 0) END = 1
) THEN 1 ELSE 0 END;
