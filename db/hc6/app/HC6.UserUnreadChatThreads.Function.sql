CREATE OR ALTER FUNCTION [HC6].[UserUnreadChatThreads]
(
    @userId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.UserUnreadChatThreads
-- Description: Every chat thread a hasher can see, with its unread count —
--   the ONE definition of "unread chat" (2026-09-28). Moved verbatim out of
--   hcapp_getEventBadgeCount Mode 3, which now reads it, so that the app's
--   chat list and badges, and the number the chat pushes put on the app
--   ICON (HC6.UserUnreadChatTotal), are the same rule and cannot drift.
--   Four arms: run threads, kennel threads, pinned kennel threads with no
--   messages, and the platform-wide rooms. See hcapp_getEventBadgeCount for
--   the columns and the unread rules (unread before first open; ignore (2)
--   forces 0; muted (3) still counts).
-- Returns: one row per thread, the hcapp_getEventBadgeCount Mode 3 shape.
-- Author: Harrier Central
-- Created: 2026-09-28
-- =====================================================================
RETURN
-- Run threads. Scope: any event the user holds a badge row for (has posted
-- or read — not time-bounded), OR an event in a kennel they follow / have an
-- attendance row for, starting within the last 90 days or in the future.
-- No badge row ⇒ every message is unread (surfaces before first read, same
-- as kennel threads). BadgeCount is forced to 0 when the effective
-- notification preference for the run is ignore (2) — see header.
SELECT
    CASE WHEN COALESCE(NULLIF(hem.EventNotificationPreference, 0),
                       hkm.KennelNotificationPreference, 0) <> 2
         THEN t.MaxSeq - COALESCE(embc.LastSequenceCount, 0) - blocked.N
         ELSE 0 END          AS BadgeCount,
    e.PublicEventId,
    e.id                    AS EventId,
    e.EventName,
    e.EventNumber,
    e.EventStartDatetimeGmt,
    e.EventImage,
    e.KennelId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS PublicKennelId,   -- run threads: no kennel-thread identity
    k.KennelShortName,
    k.KennelLogo,
    t.MsgCount              AS MessageCount,
    -- When the thread last had something said in it. The chat list sorts on
    -- this: a run's START time is not when people talked about it, and the
    -- list now keeps threads after they are read, so it needs a real
    -- most-recent order (James, 2026-09-13).
    t.LastMessageAt         AS LastMessageAt,
    -- Pinned (E9.F1.S8). A run never auto-pins, so absent means 0.
    ISNULL(hem.Pinned, 0)   AS Pinned,
    CAST(NULL AS INT)       AS RoomType,
    CAST(NULL AS NVARCHAR(500)) AS RoomIcon,
    CAST(NULL AS UNIQUEIDENTIFIER) AS ThreadId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS OtherPublicHasherId,
    CAST(NULL AS NVARCHAR(250))    AS OtherDisplayName,
    CAST(NULL AS NVARCHAR(500))    AS OtherPhoto
FROM (
    SELECT em.EventId,
           MAX(em.MessageSequenceCount) AS MaxSeq,
           COUNT(*)                     AS MsgCount,
           MAX(em.createdAt)            AS LastMessageAt
    FROM HC.EventMessage em
    WHERE em.EventId IS NOT NULL AND em.Removed = 0
    GROUP BY em.EventId
) AS t
INNER JOIN HC.Event  e ON e.id = t.EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId
-- OUTER APPLY + TOP 1 everywhere below: none of HasherKennelMap,
-- HasherEventMap or EventMessageBadgeCounts is guaranteed unique per
-- (user, thread), so a plain LEFT JOIN could fan out into duplicate rows.
-- `Found` is the existence flag — HasherEventMap.EventNotificationPreference
-- is nullable, so the preference column itself can't stand in for "row
-- exists".
OUTER APPLY (
    SELECT TOP 1 1 AS Found, h.KennelNotificationPreference
    FROM HC.HasherKennelMap h
    WHERE h.KennelId = e.KennelId AND h.UserId = @userId
) AS hkm
OUTER APPLY (
    SELECT TOP 1 1 AS Found, h.EventNotificationPreference, h.Pinned
    FROM HC.HasherEventMap h
    WHERE h.EventId = e.id AND h.UserId = @userId
) AS hem
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount
    FROM HC.EventMessageBadgeCounts b
    WHERE b.EventId = t.EventId AND b.UserId = @userId
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc
OUTER APPLY (
    -- Messages above the read mark from hashers this user has BLOCKED
    -- (E9.F1.S16). The readers hide them, so they must not count as unread
    -- or the badge could never be cleared by reading. Zero for the many
    -- hashers with no blocks: the EXISTS seeks the unique (UserId, Friend)
    -- key and finds nothing.
    SELECT COUNT(*) AS N
    FROM HC.EventMessage bm
    WHERE bm.EventId = t.EventId
      AND bm.Removed = 0
      AND bm.MessageSequenceCount > COALESCE(embc.LastSequenceCount, 0)
      AND EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = bm.UserId AND blk.Ignore = 1)
) AS blocked
WHERE e.deleted = 0
  AND e.IsVisible <> 0
  AND (
        embc.LastSequenceCount IS NOT NULL
        OR (
            e.EventStartDatetimeGmt >= DATEADD(DAY, -90, SYSUTCDATETIME())
            AND (hkm.Found = 1 OR hem.Found = 1)
        )
      )

UNION ALL

-- Kennel-level chat threads the user follows that have ANY messages. A user
-- with NO badge row yet sees the full thread count as unread. Fully-read
-- threads are returned too (BadgeCount = 0) so the kennel card can draw a
-- solid "has chats" icon vs an outline "no chats yet" icon — the app's
-- chat list keeps showing a thread AFTER it is read (a chat you have read
-- is the hardest one to find again — James, 2026-09-13). BadgeCount is forced
-- to 0 when the kennel notification preference is ignore (2).
SELECT
    CASE WHEN hkm.KennelNotificationPreference <> 2
         THEN t.MaxSeq - COALESCE(embc.LastSequenceCount, 0) - blocked.N
         ELSE 0 END                                AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    k.KennelName                                   AS EventName,
    0                                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    k.id                                           AS KennelId,
    k.PublicKennelId                               AS PublicKennelId,
    k.KennelShortName,
    k.KennelLogo,
    t.MsgCount                                     AS MessageCount,
    t.LastMessageAt                                AS LastMessageAt,
    -- Pinned (E9.F1.S8), tri-state resolved here: an explicit 0/1 is the
    -- hasher's choice, and NULL falls back to the default, which is pinned
    -- for the home kennel only (James, 2026-09-14).
    CASE WHEN hkm.Pinned IS NOT NULL THEN hkm.Pinned
         WHEN hkm.IsHomeKennel = 1   THEN 1
         ELSE 0 END                                AS Pinned,
    CAST(NULL AS INT)                              AS RoomType,
    CAST(NULL AS NVARCHAR(500))                    AS RoomIcon,
    CAST(NULL AS UNIQUEIDENTIFIER) AS ThreadId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS OtherPublicHasherId,
    CAST(NULL AS NVARCHAR(250))    AS OtherDisplayName,
    CAST(NULL AS NVARCHAR(500))    AS OtherPhoto
FROM (
    SELECT em.KennelId,
           MAX(em.MessageSequenceCount) AS MaxSeq,
           COUNT(*)                     AS MsgCount,
           MAX(em.createdAt)            AS LastMessageAt
    FROM HC.EventMessage em
    WHERE em.KennelId IS NOT NULL AND em.EventId IS NULL AND em.Removed = 0
    GROUP BY em.KennelId
) AS t
INNER JOIN HC.Kennel k ON k.id = t.KennelId
-- CROSS APPLY + TOP 1 (not JOIN) so a duplicate HasherKennelMap row can't
-- fan out into duplicate rows for the same kennel thread; it also filters
-- to followed kennels (no HKM row ⇒ no row).
CROSS APPLY (
    SELECT TOP 1 h.KennelNotificationPreference, h.Pinned, h.IsHomeKennel
    FROM HC.HasherKennelMap h
    WHERE h.KennelId = t.KennelId AND h.UserId = @userId
) AS hkm
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount
    FROM HC.EventMessageBadgeCounts b
    WHERE b.KennelId = t.KennelId AND b.UserId = @userId AND b.EventId IS NULL
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc
OUTER APPLY (
    -- Messages above the read mark from hashers this user has BLOCKED
    -- (E9.F1.S16). The readers hide them, so they must not count as unread
    -- or the badge could never be cleared by reading. Zero for the many
    -- hashers with no blocks: the EXISTS seeks the unique (UserId, Friend)
    -- key and finds nothing.
    SELECT COUNT(*) AS N
    FROM HC.EventMessage bm
    WHERE bm.KennelId = t.KennelId AND bm.EventId IS NULL
      AND bm.Removed = 0
      AND bm.MessageSequenceCount > COALESCE(embc.LastSequenceCount, 0)
      AND EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = bm.UserId AND blk.Ignore = 1)
) AS blocked

UNION ALL

-- ---------------------------------------------------------------
-- PINNED kennel threads that have NO messages yet (E9.F1.S8).
--
-- A SEPARATE arm rather than loosening the one above, and deliberately so:
-- that arm is driven by HC.EventMessage, so a kennel nobody has posted in
-- produces no row at all. Auto-pinning the home kennel would then do nothing
-- visible for the 292 hashers who have one, because only 1 of 390 kennels
-- has ever had a kennel-chat message.
--
-- Restructuring that arm to be driven from HasherKennelMap would have put
-- every existing kennel thread through new join logic. This set is DISJOINT
-- from it (NOT EXISTS any message), so nothing already working changes shape
-- and no row can appear twice.
-- ---------------------------------------------------------------
SELECT
    0                                              AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    k.KennelName                                   AS EventName,
    0                                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    k.id                                           AS KennelId,
    k.PublicKennelId                               AS PublicKennelId,
    k.KennelShortName,
    k.KennelLogo,
    0                                              AS MessageCount,
    CAST(NULL AS DATETIMEOFFSET(7))                AS LastMessageAt,
    1                                              AS Pinned,
    CAST(NULL AS INT)                              AS RoomType,
    CAST(NULL AS NVARCHAR(500))                    AS RoomIcon,
    CAST(NULL AS UNIQUEIDENTIFIER) AS ThreadId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS OtherPublicHasherId,
    CAST(NULL AS NVARCHAR(250))    AS OtherDisplayName,
    CAST(NULL AS NVARCHAR(500))    AS OtherPhoto
FROM HC.Kennel k
CROSS APPLY (
    -- TOP 1 for the same reason as above: HasherKennelMap is not guaranteed
    -- unique per (user, kennel).
    SELECT TOP 1 h.Pinned, h.IsHomeKennel
    FROM HC.HasherKennelMap h
    WHERE h.KennelId = k.id AND h.UserId = @userId
    ORDER BY h.Pinned DESC
) AS hkm
WHERE k.Removed = 0
  AND (CASE WHEN hkm.Pinned IS NOT NULL THEN hkm.Pinned
            WHEN hkm.IsHomeKennel = 1   THEN 1
            ELSE 0 END) = 1
  AND NOT EXISTS (
        SELECT 1 FROM HC.EventMessage em
        WHERE em.KennelId = k.id AND em.EventId IS NULL AND em.Removed = 0)

UNION ALL

-- ---------------------------------------------------------------
-- PLATFORM-WIDE ROOMS (E9.F1.S8) — admins, GMs, RAs and whatever the
-- catalogue grows. Driven from HC6.ChatRoomCatalog() rather than from
-- messages, so a room appears the moment a hasher's role grants it, with no
-- message needed. Every one of these is empty today; being listed is how
-- they get used at all.
--
-- Opted-out rooms (ParticipationState 2) are omitted entirely — that state
-- means "do not participate", and the room is not to be listed. Unpinned is
-- NOT the same thing and still appears.
-- ---------------------------------------------------------------
SELECT
    CASE WHEN ISNULL(embc.ParticipationState, 0) = 2 THEN 0
         ELSE ISNULL(t.MaxSeq, 0) - ISNULL(embc.LastSequenceCount, 0) - blocked.N
    END                                            AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    c.RoomName                                     AS EventName,
    0                                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS KennelId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicKennelId,
    CAST(NULL AS NVARCHAR(250))                    AS KennelShortName,
    CAST(NULL AS NVARCHAR(500))                    AS KennelLogo,
    ISNULL(t.MsgCount, 0)                          AS MessageCount,
    t.LastMessageAt                                AS LastMessageAt,
    -- Rooms default to pinned; the mirrors store the deviations.
    CASE WHEN (c.GrantColumn = 'mm'
               AND (ISNULL(hs.UnpinnedMismanagementRooms, 0) & c.GrantMask) <> 0)
           OR (c.GrantColumn = 'flags'
               AND (ISNULL(hs.UnpinnedAppAccessRooms, 0) & c.GrantMask) <> 0)
         THEN 0 ELSE 1 END                         AS Pinned,
    c.RoomType                                     AS RoomType,
    -- The room's coin. NULL means no art yet; the client falls back to its
    -- own glyph rather than showing a hole.
    c.IconUrl                                      AS RoomIcon,
    CAST(NULL AS UNIQUEIDENTIFIER) AS ThreadId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS OtherPublicHasherId,
    CAST(NULL AS NVARCHAR(250))    AS OtherDisplayName,
    CAST(NULL AS NVARCHAR(500))    AS OtherPhoto
FROM HC6.ChatRoomCatalog() c
LEFT JOIN HC.Hasher hs ON hs.id = @userId
OUTER APPLY (
    SELECT MAX(em.MessageSequenceCount) AS MaxSeq,
           COUNT(*)                     AS MsgCount,
           MAX(em.createdAt)            AS LastMessageAt
    FROM HC.EventMessage em
    WHERE em.EventId IS NULL AND em.KennelId IS NULL AND em.ThreadId IS NULL
      AND em.MessageType = c.RoomType AND em.Removed = 0
) AS t
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount, b.ParticipationState
    FROM HC.EventMessageBadgeCounts b
    WHERE b.UserId = @userId AND b.EventId IS NULL AND b.KennelId IS NULL
      AND b.ThreadId IS NULL AND b.MessageType = c.RoomType
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc
OUTER APPLY (
    -- Messages above the read mark from hashers this user has BLOCKED
    -- (E9.F1.S16). The readers hide them, so they must not count as unread
    -- or the badge could never be cleared by reading. Zero for the many
    -- hashers with no blocks: the EXISTS seeks the unique (UserId, Friend)
    -- key and finds nothing.
    SELECT COUNT(*) AS N
    FROM HC.EventMessage bm
    WHERE bm.EventId IS NULL AND bm.KennelId IS NULL AND bm.ThreadId IS NULL
      AND bm.MessageType = c.RoomType
      AND bm.Removed = 0
      AND bm.MessageSequenceCount > COALESCE(embc.LastSequenceCount, 0)
      AND EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = bm.UserId AND blk.Ignore = 1)
) AS blocked
WHERE HC6.UserMayEnterChatRoom(@userId, c.RoomType) = 1
  AND ISNULL(embc.ParticipationState, 0) <> 2

UNION ALL

-- ---------------------------------------------------------------
-- DIRECT MESSAGES (E9.F1.S7, 2026-09-29): one row per thread the user
-- holds a HasherFriendMap row in — friends, and ended (Removed) threads
-- that still have messages, which stay readable. A thread with no message
-- yet is listed too, so an accepted request has somewhere to go.
-- Blocked senders' messages are subtracted like everywhere else. Older
-- builds are shielded from these rows in hcapp_getEventBadgeCount.
-- ---------------------------------------------------------------
SELECT
    CASE WHEN f.Ignore = 1 THEN 0
         ELSE ISNULL(t.MaxSeq, 0) - ISNULL(embc.LastSequenceCount, 0) - blocked.N
    END                                            AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    o.DisplayName                                  AS EventName,
    CAST(NULL AS INT)                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS KennelId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicKennelId,
    CAST(NULL AS NVARCHAR(100))                    AS KennelShortName,
    o.Photo                                        AS KennelLogo,
    ISNULL(t.MsgCount, 0)                          AS MessageCount,
    COALESCE(t.LastMessageAt, f.FriendSince)       AS LastMessageAt,
    CAST(0 AS SMALLINT)                            AS Pinned,
    CAST(NULL AS INT)                              AS RoomType,
    CAST(NULL AS NVARCHAR(500))                    AS RoomIcon,
    f.ThreadId                                     AS ThreadId,
    o.PublicHasherId                               AS OtherPublicHasherId,
    o.DisplayName                                  AS OtherDisplayName,
    o.Photo                                        AS OtherPhoto
FROM HC.HasherFriendMap f
INNER JOIN HC.Hasher o ON o.id = f.Friend_UserId AND o.Removed = 0
OUTER APPLY (
    SELECT MAX(em.MessageSequenceCount) AS MaxSeq, COUNT(*) AS MsgCount, MAX(em.createdAt) AS LastMessageAt
    FROM HC.EventMessage em
    WHERE em.ThreadId = f.ThreadId AND em.Removed = 0
) AS t
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount
    FROM HC.EventMessageBadgeCounts b
    WHERE b.UserId = @userId AND b.EventId IS NULL AND b.KennelId IS NULL
      AND b.ThreadId = f.ThreadId AND b.MessageType = 0
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc
OUTER APPLY (
    SELECT COUNT(*) AS N
    FROM HC.EventMessage bm
    WHERE bm.ThreadId = f.ThreadId AND bm.Removed = 0
      AND bm.MessageSequenceCount > COALESCE(embc.LastSequenceCount, 0)
      AND EXISTS (SELECT 1 FROM HC.HasherFriendMap blk
                  WHERE blk.UserId = @userId AND blk.Friend_UserId = bm.UserId AND blk.Ignore = 1)
) AS blocked
WHERE f.UserId = @userId
  AND f.ThreadId IS NOT NULL
  AND f.FriendSince IS NOT NULL
  AND (f.Removed = 0 OR t.MsgCount > 0);
