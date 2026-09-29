-- =====================================================================
-- RUN-ONCE: chat photos/locations + the chat administrator permission
-- E9.F1.S11-S14 (James, 2026-09-29). docs/chat_photos_location_delete_plan.md
--
-- 1. HC.EventMessage.MessageKind (0 text, 1 photo, 2 location).
--    HC.EventMessage has NO updatedAt trigger and is not in the mobile
--    sync, so this ALTER does not stamp any row or force a re-sync.
--    (Checked live 2026-09-29: triggers are trgCreateSeqNum, AFTER INSERT,
--    and trgEventMessageActivityCount, which returns early unless Removed
--    or EventId changed.)
-- 2. Permission "Delete any chat message" (moderateChat), a new app flag
--    Manage chat (0x200), and global defaults for GM, Web Meister and
--    the flag. Kennels override per kennel like every other function.
--
-- Idempotent: every step checks before it writes. Run BEFORE the SPs that
-- reference MessageKind are deployed. Archive to db/hc6/app/archive/ after.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('HC.EventMessage', 'MessageKind') IS NULL
BEGIN
    ALTER TABLE HC.EventMessage
        ADD MessageKind SMALLINT NOT NULL
            CONSTRAINT DF_EventMessage_MessageKind DEFAULT (0);
END;

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EventMessage_MessageKind')
    EXEC ('ALTER TABLE HC.EventMessage WITH CHECK
           ADD CONSTRAINT CK_EventMessage_MessageKind CHECK (MessageKind IN (0, 1, 2));');

IF NOT EXISTS (SELECT 1 FROM HC.PermissionRole WHERE GrantorKey = 'flagManageChat')
    INSERT HC.PermissionRole (GrantorKey, DisplayName, GrantorType, Bit, SortOrder)
    VALUES ('flagManageChat', 'Manage chat', 'appFlag', 512, 59);

IF NOT EXISTS (SELECT 1 FROM HC.PermissionFunction WHERE FunctionKey = 'moderateChat')
    INSERT HC.PermissionFunction (FunctionKey, DisplayName, FeatureArea, HareScoped, SortOrder, Surfaces, AreaKey)
    VALUES ('moderateChat', 'Delete any chat message', 'Chat', 0, 70, 3, 'chat');

INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT r.id, f.id, NULL, 1
FROM HC.PermissionFunction f
JOIN HC.PermissionRole r ON r.GrantorKey IN ('gm', 'webMeister', 'flagManageChat')
WHERE f.FunctionKey = 'moderateChat'
  AND NOT EXISTS (SELECT 1 FROM HC.RolePermission rp
                  WHERE rp.GrantorId = r.id AND rp.FunctionId = f.id AND rp.KennelId IS NULL);

COMMIT TRANSACTION;

-- Check
SELECT f.FunctionKey, r.GrantorKey, rp.Allowed
FROM HC.RolePermission rp
JOIN HC.PermissionFunction f ON f.id = rp.FunctionId
JOIN HC.PermissionRole r     ON r.id = rp.GrantorId
WHERE f.FunctionKey = 'moderateChat' AND rp.KennelId IS NULL;
