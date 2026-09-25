-- =====================================================================
-- Trigger:     HC.trgUpdateKennelAdminList
-- Description: Keeps HC.Kennel.KennelAdminEmailList — the comma-separated
--              emails of the kennel's admins (AppAccessFlags bit 0x1) who
--              follow it — current when a HasherKennelMap row changes.
--              Read by HC6.hcportal_getKennel / hcportal_editKennel.
--
-- Table:       HC.HasherKennelMap  (AFTER INSERT, UPDATE)
--
-- 2026-09-25 fix: the list was rebuilt from the INSERTED rows alone, not
--   from the kennel's whole membership, so any follow change by one
--   non-admin replaced the kennel's list with NULL. 210 of 393 live
--   kennels had an empty list although 388 had an admin who followed
--   them. It is now rebuilt from every row of each affected kennel.
--
--   Also:
--   * Written only when the list actually changes. HC.Kennel's updatedAt
--     trigger stamps every write, and a stamped kennel re-syncs to every
--     phone; the old trigger wrote on every follow change.
--   * Removed kennel links and deleted hashers are left out, and a change
--     to HasherKennelMap.removed now also triggers a rebuild.
--   * Capped at the column's 2,000 characters (the longest list on
--     2026-09-25 was 564) so an unusually large kennel can never make the
--     follow change that fired this fail.
--   * Emails are in a stable order, so an unchanged list compares equal.
--   The hard-coded exclusion of one address is kept as it was.
--
-- Source of truth (James, 2026-09-25): the list is DERIVED from the
-- kennel's admins who follow it. The portal's "Admin Emails" field
-- (kennel info page) writes the same column through hcportal_editKennel;
-- a typed value now lasts only until the kennel's next membership change,
-- and the field should become read-only in the portal (not yet done).
-- The 2026-09-25 backfill replaced 69 hand-typed lists.
--
-- Not covered (unchanged from before): an admin changing their email
-- address, or a HasherKennelMap row being deleted, does not refresh the
-- list until the kennel's next membership change.
-- =====================================================================
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
