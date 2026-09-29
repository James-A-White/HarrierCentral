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
--   Room         -> (both NULL) SuperAdmin only: rooms span kennels, so
--                   no kennel's office can moderate them
--   SuperAdmin anywhere moderates everything — it is the platform's own
--   bypass, and a platform admin need not follow a kennel to clean up
--   its chat.
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

IF EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
           WHERE hkm.UserId = @userId AND hkm.removed = 0
             AND (hkm.AppAccessFlags & 0x40000000) <> 0)
BEGIN
    SET @allowed = 1;
    RETURN;
END

IF (@eventId IS NOT NULL)
    SELECT @kennelId = e.KennelId FROM HC.Event e WHERE e.id = @eventId;
ELSE IF (@eventId IS NULL AND @kennelId IS NULL)
    RETURN;   -- a room, and the caller is not a SuperAdmin

IF (@kennelId IS NOT NULL)
    EXEC HC6.CheckKennelPermission
        @userId = @userId, @kennelId = @kennelId,
        @functionKey = N'moderateChat', @allowed = @allowed OUTPUT;

SET @allowed = COALESCE(@allowed, 0);
GO
