CREATE OR ALTER PROCEDURE [HC6].[hcportal_savePermissionMatrix]
    @deviceId     UNIQUEIDENTIFIER = NULL,
    @accessToken  NVARCHAR(1000)   = NULL,
    @grantorKey   NVARCHAR(80)     = NULL,
    @functionKeys NVARCHAR(MAX)    = NULL   -- '|'-delimited granted function keys for this grantor
AS
-- =====================================================================
-- Procedure: HC6.hcportal_savePermissionMatrix
-- Description: Saves the GLOBAL grants for one grantor (Permissions V2 editor):
--   replaces the grantor's global rows with the supplied granted function keys,
--   then recompiles the JSON projections (HC6.nonApi_compilePermissionMatrix) in
--   the same transaction — the compile-on-save invariant.
-- Parameters:
--   @deviceId, @accessToken - portal auth
--   @grantorKey             - HC.PermissionRole.GrantorKey being edited
--   @functionKeys           - '|'-delimited HC.PermissionFunction.FunctionKey list
--                             (the checked functions); empty = grantor grants nothing
-- Returns: rowset 0 { Success, ErrorMessage }
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

DECLARE @grantorId INT =
    (SELECT id FROM HC.PermissionRole WHERE GrantorKey = @grantorKey AND GrantorType <> 'bypass');
IF @grantorId IS NULL
BEGIN
    SELECT 0 AS Success, 'Unknown or non-editable grantor' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    -- Replace this grantor's GLOBAL grants (KennelId NULL) with the supplied set.
    DELETE HC.RolePermission WHERE KennelId IS NULL AND GrantorId = @grantorId;

    INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
    SELECT @grantorId, f.id, NULL, 1
    FROM STRING_SPLIT(COALESCE(@functionKeys, ''), '|') s
    JOIN HC.PermissionFunction f ON f.FunctionKey = s.value
    WHERE LEN(s.value) > 0;

    -- Recompile projections (global JSON + any affected kennel overrides) + bump watermark.
    EXEC HC6.nonApi_compilePermissionMatrix;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_savePermissionMatrix',
            ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
