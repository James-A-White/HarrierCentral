CREATE OR ALTER FUNCTION [HC6].[UserMayEnterChatRoom]
(
    @userId   UNIQUEIDENTIFIER,
    @roomType INT
)
RETURNS SMALLINT
AS
-- =====================================================================
-- Function: HC6.UserMayEnterChatRoom
-- Description: The ONE gate for platform-wide chat rooms. Every room SP
--   calls this, so the three of them cannot drift apart — the mask drift
--   that /hc-authorizations warns about (the same concept spelled four
--   different ways across SPs) is impossible when there is one test.
--
--   Reads whichever bitfield the catalog names for that room, across ANY
--   kennel: a room is global, so holding the role anywhere qualifies. A
--   'platform' room reads HC.PlatformAdmin instead (2026-09-30) — the
--   0x40000000 flag is the kennel-founder grant held by 294 hashers, so it
--   cannot stand for platform staff.
--
--   Returns 0 for an unknown room type, so a bad or retired @roomType is
--   refused rather than silently opening an empty room.
--
-- Returns: 1 if the hasher may enter, otherwise 0.
-- Author: Harrier Central
-- Created: 2026-09-14
-- =====================================================================
BEGIN
    DECLARE @allowed SMALLINT = 0;

    IF EXISTS (
        SELECT 1
        FROM HC6.ChatRoomCatalog() c
        WHERE c.RoomType = @roomType
          AND (   -- Platform staff: a row in HC.PlatformAdmin, no bitfield.
                  (c.GrantColumn = 'platform'
                   AND EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
                               WHERE pa.UserId = @userId AND pa.removed = 0))
                  -- A role or flag held in ANY kennel.
               OR EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
                          WHERE hkm.UserId = @userId
                            AND hkm.removed = 0
                            AND (   (c.GrantColumn = 'flags' AND (hkm.AppAccessFlags     & c.GrantMask) <> 0)
                                 OR (c.GrantColumn = 'mm'    AND (hkm.MismanagementRoles & c.GrantMask) <> 0)))))
        SET @allowed = 1;

    RETURN @allowed;
END
GO
