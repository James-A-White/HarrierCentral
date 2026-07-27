-- =====================================================================
-- RUN-ONCE — Permissions V2: add editable "Hare" grantor + rename entry gates
-- =====================================================================
-- 1. Widen CK_PermissionRole_Type to allow the new 'hare' GrantorType.
-- 2. Rename the two entry-gate functions to "View ... Admin Tools".
-- 3. Add a 'hare' grantor (run-scoped — evaluated when the caller is the
--    designated hare of the event, via CheckKennelPermission's @isHareOfEvent).
-- 4. Seed the hare grantor's global grants from the functions currently flagged
--    HareScoped, so behaviour is unchanged at cutover.
--
-- After running, EXEC HC6.nonApi_compilePermissionMatrix (compile now derives
-- each function's hareScoped from this grantor). Archive this file.
-- =====================================================================
SET XACT_ABORT ON;

-- 1. Allow GrantorType = 'hare'.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_PermissionRole_Type')
    ALTER TABLE HC.PermissionRole DROP CONSTRAINT CK_PermissionRole_Type;
GO
ALTER TABLE HC.PermissionRole ADD CONSTRAINT CK_PermissionRole_Type
    CHECK (GrantorType IN ('mmRole', 'appFlag', 'bypass', 'hare'));
GO

BEGIN TRANSACTION;

UPDATE HC.PermissionFunction SET DisplayName = 'View Kennel Admin Tools'
WHERE FunctionKey = 'enterKennelAdmin';
UPDATE HC.PermissionFunction SET DisplayName = 'View Run Admin Tools'
WHERE FunctionKey = 'enterRunAdmin';

IF NOT EXISTS (SELECT 1 FROM HC.PermissionRole WHERE GrantorKey = 'hare')
    INSERT HC.PermissionRole (GrantorKey, DisplayName, GrantorType, Bit, SortOrder)
    VALUES ('hare', 'Hare (this run)', 'hare', 0, 2);

DECLARE @hareId INT = (SELECT id FROM HC.PermissionRole WHERE GrantorKey = 'hare');

INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT @hareId, f.id, NULL, 1
FROM HC.PermissionFunction f
WHERE f.HareScoped = 1
  AND NOT EXISTS (
      SELECT 1 FROM HC.RolePermission rp
      WHERE rp.GrantorId = @hareId AND rp.FunctionId = f.id AND rp.KennelId IS NULL);

COMMIT TRANSACTION;
GO

EXEC HC6.nonApi_compilePermissionMatrix;
GO
