CREATE OR ALTER PROCEDURE [HC6].[hcportal_getPermissionMatrix]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL   -- when set, also return that kennel's overrides
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getPermissionMatrix
-- Description: Loads the data-driven permission matrix (Permissions V2) for the
--   super-admin editor. Returns the function catalog, the grantor catalog
--   (mismanagement roles + app-access flags; the SuperAdmin bypass is excluded —
--   it is not a togglable cell), and the current GLOBAL grants.
-- Parameters: @deviceId, @accessToken (portal auth)
-- Returns:
--   rowset 0: { Success, ErrorMessage }  (0 on auth/permission failure)
--   on success, rowset 1: functions, rowset 2: grantors, rowset 3: global grants
-- Auth: HC6.ValidatePortalAuth + caller must hold HC.PlatformAdmin.CanManagePermissions.
-- Author: Harrier Central
-- Created: 2026-07-27  (Permissions V2, Phase 5)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @authError NVARCHAR(255);
DECLARE @hasherId  UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF @callerType != 0
BEGIN
    SELECT 0 AS Success, 'Service accounts may not call this endpoint' AS ErrorMessage;
    RETURN;
END

-- Platform-admin gate: caller must hold the CanManagePermissions privilege.
IF NOT EXISTS (
    SELECT 1 FROM HC.PlatformAdmin
    WHERE UserId = @hasherId AND removed = 0 AND CanManagePermissions = 1
)
BEGIN
    SELECT 0 AS Success, 'Not authorised — permission management privilege required' AS ErrorMessage;
    RETURN;
END

DECLARE @kennelScopeId UNIQUEIDENTIFIER = NULL;
IF @publicKennelId IS NOT NULL
    SELECT @kennelScopeId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId;

BEGIN TRY
    SELECT 1 AS Success, NULL AS ErrorMessage;

    -- rowset 1: functions (matrix columns, grouped by FeatureArea)
    SELECT id, FunctionKey, DisplayName, FeatureArea, HareScoped, SortOrder
    FROM HC.PermissionFunction
    ORDER BY SortOrder;

    -- rowset 2: grantors (matrix rows). Bypass (SuperAdmin) excluded.
    SELECT id, GrantorKey, DisplayName, GrantorType, SortOrder
    FROM HC.PermissionRole
    WHERE GrantorType <> 'bypass'
    ORDER BY GrantorType, SortOrder;

    -- rowset 3: current global grants (KennelId NULL, granted)
    SELECT GrantorId, FunctionId
    FROM HC.RolePermission
    WHERE KennelId IS NULL AND Allowed = 1;

    -- rowset 4: per-kennel override rows for the selected kennel (empty if global).
    SELECT GrantorId, FunctionId, Allowed
    FROM HC.RolePermission
    WHERE KennelId = @kennelScopeId;
END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getPermissionMatrix',
            ERROR_MESSAGE(), @procName, @hasherId);
    THROW;
END CATCH
GO
