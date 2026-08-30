-- =====================================================================
-- Run-once migration: RA no longer grants photo permissions (2026-08-30)
--
-- James: photo approval should be grantable to anyone, on mismanagement or
-- not, and should stop following from the RA role.
--
-- No new flag is added. AppAccessFlags "Manage Photos" (0x100) is ALREADY
-- grantable to any hasher regardless of role, so it is the photo permission;
-- the only change needed is removing RA.
--
-- Removing RA from reviewPhotos ALONE would not have worked: reviewPhotos only
-- gates SEEING the pending queue (hcapp_getKennelPendingPhotos). The approve /
-- reject action is gated by editPhoto (hcapp_updatePhotoStatus) and
-- batchPhotos (hcapp_batchUpdatePhotoStatus), so an RA could still have
-- approved photos from the run photo grid. All three are changed together.
--
-- After this, reviewPhotos / editPhoto / batchPhotos are granted by:
--     mm roles : GM, Vice GM, Web Meister, Hash Flash
--     flag     : Manage Photos (0x100) — grantable to anyone
--     plus SuperAdmin, which CheckKennelPermission always bypasses.
--
-- 38 hashers hold RA without GM/VGM/HashFlash/WebMeister, SuperAdmin or the
-- Manage Photos flag; they lose photo access. That is the requested change.
--
-- ARCHIVE THIS FILE after running (tools/deploy_hc6.sh globs *.sql).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE rp
    FROM HC.RolePermission rp
    JOIN HC.PermissionRole r     ON r.id = rp.GrantorId
    JOIN HC.PermissionFunction f ON f.id = rp.FunctionId
    WHERE r.GrantorKey = 'ra'
      AND f.FunctionKey IN ('reviewPhotos', 'editPhoto', 'batchPhotos')
      AND rp.KennelId IS NULL;          -- global defaults only; per-kennel overrides untouched

    DECLARE @removed INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    -- Rebuild the compiled matrix the app downloads at login.
    EXEC HC6.nonApi_compilePermissionMatrix;

    SELECT 1 AS Success, @removed AS grantsRemoved, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Photo RA-removal migration failed',
            ERROR_MESSAGE(), 'migration_photos_drop_ra', NULL);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
