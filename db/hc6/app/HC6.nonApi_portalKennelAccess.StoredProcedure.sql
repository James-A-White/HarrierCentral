CREATE OR ALTER PROCEDURE [HC6].[nonApi_portalKennelAccess]
    @hasherId     UNIQUEIDENTIFIER,
    @callerType   INT              = 0,
    @kennelId     UNIQUEIDENTIFIER = NULL,
    @flagMask     INT              = 0,
    @functionKey  NVARCHAR(80)     = NULL,
    @platformCap  NVARCHAR(40)     = NULL,
    @allowed      SMALLINT OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_portalKennelAccess
-- Description: The one permission check for hcportal_ SPs that act on a
--   kennel (or on the platform). Signing in to the portal proves only who
--   the caller is -- any Harrier Central account can sign in -- and the
--   portal API passes every call straight through, so this check is the
--   only thing between a signed-in hasher and another kennel's data.
--   Added 2026-10-13 after eleven portal SPs were found with none.
--
--   Allowed when ANY of these holds (a union, so no admin who could use
--   the screen yesterday is locked out today):
--     1. (REMOVED 2026-10-16) service accounts no longer pass — they are
--        refused here and can reach only confirmAuthentication.
--     2. @platformCap names an HC.PlatformAdmin right the caller holds
--        ('CanViewMonitor', 'CanManageNewsflash', 'CanEditKennel',
--        'CanManagePermissions'). For platform-only SPs pass @kennelId
--        NULL and only this test (and 1) applies.
--     3. The caller's HasherKennelMap row for @kennelId has SuperAdmin
--        (0x40000000) or any bit of @flagMask in AppAccessFlags -- the
--        same bits the portal's own screens test before showing a button.
--     4. HC6.CheckKennelPermission grants @functionKey for the kennel.
-- Parameters:
--   @hasherId    - Caller (ValidatePortalAuth @hasherId OUTPUT)
--   @callerType  - ValidatePortalAuth @callerType OUTPUT (0 = person)
--   @kennelId    - Kennel acted on; NULL for platform-only checks
--   @flagMask    - AppAccessFlags bits that grant this action
--   @functionKey - HC.PermissionFunction.FunctionKey that grants it
--   @platformCap - HC.PlatformAdmin column that grants it
--   @allowed     - OUTPUT 1 = allowed, 0 = refused
-- Returns: nothing (OUTPUT only). Never writes.
-- Author: Harrier Central
-- Created: 2026-10-13
-- =====================================================================
SET NOCOUNT ON;

SET @allowed = 0;

-- Service accounts get NOTHING here (2026-10-16, permissions audit): they
-- used to pass every gate, and their token could be built from public values.
-- HC6.ValidatePortalAuth now lets them reach only
-- hcportal_confirmAuthentication; this is the second lock on the same door.
IF (@callerType IS NOT NULL AND @callerType <> 0) RETURN;

IF (@hasherId IS NULL) RETURN;

IF (@platformCap IS NOT NULL AND EXISTS (
        SELECT 1 FROM HC.PlatformAdmin pa
        WHERE pa.UserId = @hasherId AND pa.removed = 0
          AND (   (@platformCap = 'CanViewMonitor'       AND pa.CanViewMonitor       = 1)
               OR (@platformCap = 'CanManageNewsflash'   AND pa.CanManageNewsflash   = 1)
               OR (@platformCap = 'CanEditKennel'        AND pa.CanEditKennel        = 1)
               OR (@platformCap = 'CanManagePermissions' AND pa.CanManagePermissions = 1))))
BEGIN
    SET @allowed = 1;
    RETURN;
END

IF (@kennelId IS NULL) RETURN;

IF EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
           WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId
             AND hkm.removed = 0   -- as CheckKennelPermission
             AND (ISNULL(hkm.AppAccessFlags, 0) & (0x40000000 | ISNULL(@flagMask, 0))) <> 0)
BEGIN
    SET @allowed = 1;
    RETURN;
END

IF (@functionKey IS NOT NULL)
BEGIN
    DECLARE @byFunction SMALLINT = 0;
    EXEC HC6.CheckKennelPermission @userId = @hasherId, @kennelId = @kennelId,
         @functionKey = @functionKey, @allowed = @byFunction OUTPUT;
    IF (@byFunction = 1) SET @allowed = 1;
END
