-- =====================================================================
-- RUN-ONCE: fix HC.trgUpdateKennelAdminList and rebuild every kennel's
-- KennelAdminEmailList (2026-09-25).
--
-- The trigger rebuilt a kennel's admin email list from the INSERTED rows
-- only, so one non-admin's follow change blanked it: 210 of 393 live
-- kennels had an empty list although 388 had an admin who followed them.
-- The canonical definition is db/schema/triggers/HC.trgUpdateKennelAdminList.sql
-- and is repeated below; see its header for the details.
--
-- Step 2 rebuilds the list for every kennel, writing ONLY those whose list
-- changes (each write stamps HC.Kennel.updatedAt and that kennel re-syncs
-- to every phone once — one row per changed kennel, a few hundred rows).
--
-- James chose DERIVED as the source of truth (2026-09-25), knowing this
-- replaces 69 lists kennels had typed into the portal's "Admin Emails"
-- field. The portal field should become read-only (not yet done).
--
-- Idempotent. After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
GO

-- Step 1: the trigger.
CREATE OR ALTER TRIGGER [HC].[trgUpdateKennelAdminList]
   ON  [HC].[HasherKennelMap]
   AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(Following) OR UPDATE(AppAccessFlags) OR UPDATE(removed))
        RETURN;

    UPDATE ken
       SET ken.KennelAdminEmailList = LEFT(x.List, 2000)
      FROM HC.Kennel ken
     CROSS APPLY (
            SELECT STRING_AGG(CAST(h.Email AS NVARCHAR(MAX)), ', ')
                   WITHIN GROUP (ORDER BY h.Email) AS List
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h ON h.id = hkm.UserId
            WHERE hkm.KennelId = ken.id
              AND hkm.Following = 1
              AND hkm.AppAccessFlags & 0x00000001 != 0
              AND hkm.removed = 0
              AND h.Removed = 0
              AND h.Email != 'melissatunawhite@gmail.com'
          ) x
     WHERE ken.id IN (SELECT KennelId FROM inserted)
       AND ISNULL(ken.KennelAdminEmailList, N'') <> ISNULL(LEFT(x.List, 2000), N'');
END
GO

-- Step 2: rebuild every kennel's list once.
SET NOCOUNT ON;
SET XACT_ABORT ON;

SELECT 'before' AS stage, COUNT(*) AS liveKennels,
       SUM(CASE WHEN ISNULL(KennelAdminEmailList, N'') = N'' THEN 1 ELSE 0 END) AS emptyList
FROM HC.Kennel WHERE deleted = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE ken
       SET ken.KennelAdminEmailList = LEFT(x.List, 2000)
      FROM HC.Kennel ken
     CROSS APPLY (
            SELECT STRING_AGG(CAST(h.Email AS NVARCHAR(MAX)), ', ')
                   WITHIN GROUP (ORDER BY h.Email) AS List
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h ON h.id = hkm.UserId
            WHERE hkm.KennelId = ken.id
              AND hkm.Following = 1
              AND hkm.AppAccessFlags & 0x00000001 != 0
              AND hkm.removed = 0
              AND h.Removed = 0
              AND h.Email != 'melissatunawhite@gmail.com'
          ) x
     WHERE ISNULL(ken.KennelAdminEmailList, N'') <> ISNULL(LEFT(x.List, 2000), N'');

    SELECT @@ROWCOUNT AS kennelsRewritten;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;   -- FIRST: the log must survive
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Run-once KennelAdminEmailList rebuild failed',
            ERROR_MESSAGE(), '2026-09-25_fix_trgUpdateKennelAdminList', NULL);
    THROW;
END CATCH

SELECT 'after' AS stage, COUNT(*) AS liveKennels,
       SUM(CASE WHEN ISNULL(KennelAdminEmailList, N'') = N'' THEN 1 ELSE 0 END) AS emptyList
FROM HC.Kennel WHERE deleted = 0;
GO
