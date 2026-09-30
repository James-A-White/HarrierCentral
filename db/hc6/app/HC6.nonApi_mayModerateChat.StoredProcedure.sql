CREATE OR ALTER PROCEDURE [HC6].[nonApi_mayModerateChat]
    @userId   UNIQUEIDENTIFIER,
    @eventId  UNIQUEIDENTIFIER = NULL,   -- run chat
    @kennelId UNIQUEIDENTIFIER = NULL,   -- kennel chat (ignored when @eventId is set)
    @allowed  SMALLINT OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_mayModerateChat
-- Description: May this user delete ANYONE's message in this thread?
--   (E9.F1.S14, James 2026-09-29.) The one place the rule lives: the
--   message readers call it once per fetch to fill canDelete, and
--   nonApi_deleteChatMessage calls it before removing a message.
--
--   Run chat     -> moderateChat in the RUN'S kennel
--   Kennel chat  -> moderateChat in that kennel
--   Room or DM   -> (both NULL) platform admins only (HC.PlatformAdmin):
--                   rooms span kennels, so no kennel's office can moderate
--                   them, and a direct message belongs to no kennel at all
--                   (E9.F1.S7)
--   A platform admin moderates everything and need not follow a kennel to
--   clean up its chat. A kennel's own SuperAdmin (AppAccessFlags
--   0x40000000 on THAT kennel's row) still passes CheckKennelPermission
--   for that kennel's run and kennel chats.
--
--   moderateChat is a HC.PermissionFunction row (defaults: GM, Web
--   Meister, the Manage chat flag 0x200), so a kennel can widen or narrow
--   it in its permissions like any other function.
-- Returns: nothing; @allowed OUTPUT 1/0
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;

SET @allowed = 0;
IF (@userId IS NULL) RETURN;

-- Platform staff moderate everything. This read AppAccessFlags 0x40000000
-- on any kennel row until 2026-09-30 — the kennel-FOUNDER grant, held by
-- 294 hashers, every one of whom could delete any room or DM message.
IF EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
           WHERE pa.UserId = @userId AND pa.removed = 0)
BEGIN
    SET @allowed = 1;
    RETURN;
END

IF (@eventId IS NOT NULL)
    SELECT @kennelId = e.KennelId FROM HC.Event e WHERE e.id = @eventId;
ELSE IF (@eventId IS NULL AND @kennelId IS NULL)
    RETURN;   -- a room or DM, and the caller is not a platform admin

IF (@kennelId IS NOT NULL)
    EXEC HC6.CheckKennelPermission
        @userId = @userId, @kennelId = @kennelId,
        @functionKey = N'moderateChat', @allowed = @allowed OUTPUT;

SET @allowed = COALESCE(@allowed, 0);
GO
