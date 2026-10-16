CREATE OR ALTER FUNCTION [HC6].[KennelChatPushAudience]
(
    @kennelId     UNIQUEIDENTIFIER,
    @messageType  INT,
    @releasability INT,
    @senderId     UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.KennelChatPushAudience
-- Description: Who a message in one of a kennel's two chat threads pushes
--   to — one row per (hasher, device token) with their kennel bell (Pref:
--   1 or 4 a visible push, 3 a silent one). Moved out of
--   hcapp_sendKennelMessage on 2026-10-16 (E9.F1.S33) so the weekly
--   Mismanagement reminder (nonApi_postKennelReminders) pushes to exactly
--   the same people a member's post would. Rules, unchanged:
--     - a live HasherKennelMap row and a live hasher;
--     - a bell the hasher CHOSE (1, 3 or 4) — 0 means never touched and is
--       not consent (as nonApi_checkReminders has always used);
--     - not someone who blocked the sender (E9.F1.S16);
--     - a live device with a token, signed in within 180 days, on a build
--       that can route a kennel push (HC6.MinBuildForChatPush);
--     - general chat (MessageType 0): the releasability flags choose
--       (0x20 everyone, 0x01 mismanagement, 0x02 members, 0x04 followers);
--     - Mismanagement chat (any other MessageType): its members only —
--       the set-based HC6.UserInKennelMismanagement — on builds that can
--       open it (HC6.MinBuildForKennelMismanagement), whatever the flags.
-- Author: Harrier Central
-- Created: 2026-10-16
-- =====================================================================
RETURN
SELECT DISTINCT
    hkm.UserId,
    device.FcmToken,
    COALESCE(hkm.KennelNotificationPreference, 0) AS Pref
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Hasher h      ON h.id          = hkm.UserId
INNER JOIN HC.Device device ON device.UserId = hkm.UserId
WHERE hkm.KennelId = @kennelId
  AND hkm.removed  = 0
  AND h.Removed    = 0
  AND device.FcmToken IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = hkm.UserId AND blk.Friend_UserId = @senderId AND blk.Ignore = 1)
  AND device.removed   = 0
  AND device.LastLogin >= DATEADD(DAY, -180, SYSDATETIMEOFFSET())
  -- BuildNumber is NVARCHAR and can be '<unknown>': TRY_CAST yields NULL,
  -- the comparison is UNKNOWN, and the device is excluded. Fail closed.
  AND TRY_CAST(device.BuildNumber AS INT) >= HC6.MinBuildForChatPush()
  AND COALESCE(hkm.KennelNotificationPreference, 0) IN (1, 3, 4)
  AND (
      (@messageType = 0 AND (
          (@releasability & 0x0020) <> 0
       OR ((@releasability & 0x0001) <> 0 AND hkm.MismanagementRoles <> 0)
       OR ((@releasability & 0x0002) <> 0 AND hkm.MembershipExpirationDate > GETDATE())
       OR ((@releasability & 0x0004) <> 0 AND hkm.Following = 1)))
   OR (@messageType <> 0
       AND (ISNULL(hkm.MismanagementRoles, 0) <> 0 OR ISNULL(hkm.AppAccessFlags, 0) <> 0)
       AND TRY_CAST(device.BuildNumber AS INT) >= HC6.MinBuildForKennelMismanagement())
  );
GO
