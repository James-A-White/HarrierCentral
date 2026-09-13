-- =====================================================================
-- Run-once: the manageProducts permission (3.1, 2026-09-13)
--
--   Editing the kennel catalogue — what is on sale, what it costs, what
--   promotional credit it grants — is a money decision, so it gets its own
--   function key rather than borrowing one. Anything that reads or writes
--   kennel-scoped money data needs an explicit gate beyond ValidateAppAuth
--   (see /hc-authorizations).
--
--   Granted by DEFAULT to:
--     gm, vgm            — the kennel's leadership, as for every admin task
--     hashCash           — the treasurer; a catalogue is their instrument
--     haberdasher        — runs the shop, which is most of what a catalogue
--                          will hold once haberdashery lands
--     flagManageHashCash — the per-hasher override for money work. Note this
--                          flag is checked by NO SP today (the 2026-07-19
--                          audit found money auth piggybacking on RA); this
--                          is the first function to wire it up, which is
--                          what the audit asked for.
--
--   NOT granted to RA. RA carries money authority today only because the
--   dedicated hash-cash bit was never wired in; propagating that here would
--   entrench the very mistake the audit flagged.
--
--   A kennel can still override either way — HC.RolePermission rows with a
--   KennelId beat these NULL-kennel defaults, with -1 meaning "denied here".
--   SuperAdmin bypasses everything and needs no row.
--
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

DECLARE @functionId INT;

IF NOT EXISTS (SELECT 1 FROM HC.PermissionFunction WHERE FunctionKey = 'manageProducts')
BEGIN
    -- Explicit id: the table is seeded data with stable ids quoted by the
    -- grant rows below, not an identity nobody looks at.
    SET @functionId = (SELECT ISNULL(MAX(id), 0) + 1 FROM HC.PermissionFunction);
    INSERT HC.PermissionFunction (id, FunctionKey)
    VALUES (@functionId, 'manageProducts');
    PRINT CONCAT('PermissionFunction manageProducts added as id ', @functionId);
END
ELSE
BEGIN
    SET @functionId = (SELECT id FROM HC.PermissionFunction WHERE FunctionKey = 'manageProducts');
    PRINT CONCAT('PermissionFunction manageProducts already exists as id ', @functionId);
END

INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT g.id, @functionId, NULL, 1
FROM HC.PermissionRole g
WHERE g.GrantorKey IN ('gm', 'vgm', 'hashCash', 'haberdasher', 'flagManageHashCash')
  AND NOT EXISTS (
        SELECT 1 FROM HC.RolePermission rp
        WHERE rp.GrantorId = g.id AND rp.FunctionId = @functionId AND rp.KennelId IS NULL
  );
PRINT CONCAT('Default grants added: ', @@ROWCOUNT);
GO

-- Who can manage products now?
SELECT g.GrantorKey, g.DisplayName, g.GrantorType
FROM HC.RolePermission rp
JOIN HC.PermissionRole g     ON g.id = rp.GrantorId
JOIN HC.PermissionFunction f ON f.id = rp.FunctionId
WHERE f.FunctionKey = 'manageProducts' AND rp.KennelId IS NULL AND rp.Allowed = 1
ORDER BY g.SortOrder;
GO
