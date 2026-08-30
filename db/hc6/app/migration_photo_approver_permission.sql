-- =====================================================================
-- Run-once migration: dedicated "Photo Approver" permission (2026-08-30)
--
-- James: photo approval should be grantable to anyone, on mismanagement or
-- not, and should no longer follow from the RA role.
--
--   reviewPhotos allowed by:
--     mm roles : GM, Vice GM, Web Meister, Hash Flash      (RA REMOVED)
--     flags    : Photo Approver (NEW 0x200)                (Manage Photos REMOVED)
--     plus SuperAdmin, which CheckKennelPermission always bypasses.
--
-- Why 0x200 is safe even though 23 rows already have that bit: those rows are
-- AppAccessFlags 0x3FFFFFFF/0x3FFFFFFD — a legacy "every functional flag"
-- value, not a deliberate grant. They already hold Manage Photos, so they gain
-- nothing new. The single deliberate Manage Photos holder (Drink Her Pretty,
-- OPH3) is 0x400001FF — SuperAdmin — so keeps access via the bypass.
--
-- ARCHIVE THIS FILE after running (tools/deploy_hc6.sh globs *.sql).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. New grantor: Photo Approver (app flag 0x200)
    IF NOT EXISTS (SELECT 1 FROM HC.PermissionRole WHERE GrantorKey = 'flagApprovePhotos')
    BEGIN
        INSERT HC.PermissionRole (GrantorKey, DisplayName, GrantorType, Bit, SortOrder)
        SELECT 'flagApprovePhotos', 'Photo Approver', 'appFlag', 0x00000200,
               ISNULL((SELECT MAX(SortOrder) FROM HC.PermissionRole WHERE GrantorType='appFlag'), 0) + 1;
    END

    DECLARE @fn INT = (SELECT id FROM HC.PermissionFunction WHERE FunctionKey = 'reviewPhotos');
    IF @fn IS NULL THROW 50001, 'reviewPhotos function not found', 1;

    -- 2. Grant reviewPhotos to the new flag (global default row)
    INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
    SELECT r.id, @fn, NULL, 1
    FROM HC.PermissionRole r
    WHERE r.GrantorKey = 'flagApprovePhotos'
      AND NOT EXISTS (SELECT 1 FROM HC.RolePermission rp
                      WHERE rp.GrantorId = r.id AND rp.FunctionId = @fn AND rp.KennelId IS NULL);

    -- 3. Revoke the two grantors James dropped: RA role, and Manage Photos flag.
    --    Deletes GLOBAL rows only; any per-kennel override is left alone.
    DELETE rp
    FROM HC.RolePermission rp
    JOIN HC.PermissionRole r ON r.id = rp.GrantorId
    WHERE rp.FunctionId = @fn AND rp.KennelId IS NULL
      AND r.GrantorKey IN ('ra', 'flagManagePhotos');

    COMMIT TRANSACTION;

    -- 4. Rebuild the compiled matrix the app downloads at login
    EXEC HC6.nonApi_compilePermissionMatrix;

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Photo Approver migration failed',
            ERROR_MESSAGE(), 'migration_photo_approver_permission', NULL);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
