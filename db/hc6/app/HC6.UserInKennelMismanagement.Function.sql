CREATE OR ALTER FUNCTION [HC6].[UserInKennelMismanagement]
(
    @userId   UNIQUEIDENTIFIER,
    @kennelId UNIQUEIDENTIFIER
)
RETURNS SMALLINT
AS
-- =====================================================================
-- Function: HC6.UserInKennelMismanagement
-- Description: The ONE gate for a kennel's private Mismanagement chat
--   (E9.F1.S33, James 2026-10-16). Every SP that reads, writes, reacts to,
--   deletes, reports or lists that thread calls this, so they cannot drift.
--
--   A member is anyone who holds ANY office in the kennel (any
--   MismanagementRoles bit, "no matter how minor" — James) or ANY app
--   access flag there (admins, Super Admins included), on a live
--   HasherKennelMap row. Losing the office loses the thread at once: there
--   is no separate member list to forget to update.
--
--   Not the platform staff, not the role rooms' "anywhere" rule: this is
--   one kennel's business.
--
-- Returns: 1 if the hasher is in the kennel's mismanagement, otherwise 0.
-- Author: Harrier Central
-- Created: 2026-10-16
-- =====================================================================
BEGIN
    IF (@userId IS NULL OR @kennelId IS NULL) RETURN 0;
    IF EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
               WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId
                 AND hkm.removed = 0
                 AND (ISNULL(hkm.MismanagementRoles, 0) <> 0
                      OR ISNULL(hkm.AppAccessFlags, 0) <> 0))
        RETURN 1;
    RETURN 0;
END
GO
