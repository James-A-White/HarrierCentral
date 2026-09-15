CREATE OR ALTER FUNCTION [HC6].[ChatRoomCatalog] ()
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.ChatRoomCatalog
-- Description: THE registry of platform-wide chat rooms. This is the one
--   place a room is defined, and the only file that changes to add one.
--
--   ADDING A ROOM: append a row below, redeploy this function. Nothing
--   else. The SPs read the catalog, and the app FETCHES the room list from
--   hcapp_getChatRooms rather than hard-coding it — so a new room reaches
--   every phone already installed, with no app release and no store review.
--   That is the whole point of the shape (James, 2026-09-14: "make it easy
--   to extend to other rooms as well").
--
--   RoomType is the value stored in HC.EventMessage.MessageType, so it is
--   permanent once a room has traffic. Never renumber one; retire a room by
--   deleting its row here, which hides it without touching its messages.
--
-- GrantColumn is which bitfield on HC.HasherKennelMap decides membership,
--   and it genuinely differs per room — this is not over-engineering:
--     'flags' → AppAccessFlags      (SuperAdmin is 0x40000000)
--     'mm'    → MismanagementRoles  (club offices)
--   ⚠ The two collide: 0x08 is ManageHashCash in AppAccessFlags but RA in
--   MismanagementRoles. A room must say which column it reads, never just
--   which bit. See /hc-authorizations.
--
--   Membership is by ROLE, not by capability, so SuperAdmin is deliberately
--   NOT folded in as the usual all-features bypass: being able to do
--   anything is not the same as belonging in the Haberdashers' room. A
--   super admin who is also an RA is in the RA room because they are an RA.
--
--   A room's mask may name more than one bit, so several roles can share one
--   room: `(MismanagementRoles & GrantMask) <> 0` means any of them grants
--   it. Grand Masters is GM|VGM and Web & Social Media is WebMeister|Social.
--   Masks must stay DISJOINT between rooms — the pin mirrors key on the mask,
--   so a bit in two rooms would make unpinning one unpin the other.
--
--   Rooms chosen from the active-holder counts on 2026-09-14 (people /
--   opened the app in 30 days): GM 72/26, Hash Cash 64/26, RA 58/15, Hare
--   Raiser 46/17. The thin tail was left out on purpose — Haberdasher is
--   10 active worldwide and Trail Master is 0, and sixteen empty rooms read
--   as a broken feature. Add them here when there is evidence anyone wants
--   one; it is a one-line change.
--
-- Returns: one row per room.
-- Author: Harrier Central
-- Created: 2026-09-14
-- =====================================================================
RETURN
    SELECT c.RoomType, c.RoomName, c.GrantColumn, c.GrantMask, c.SortOrder
    FROM (VALUES
        --  Type  Name                       Column   Mask          Sort
            (1,  N'Harrier Central Admins',  'flags', 0x40000000,   10),
            -- GM + VGM together (James, 2026-09-15): 72 GMs and 87 once the
            -- vice GMs are in. A mask may name SEVERAL bits — the test is
            -- `& mask <> 0`, so any one of them grants the room.
            (2,  N'Grand Masters',           'mm',    0x00000006,   20),
            (3,  N'Hash Cash',               'mm',    0x00000400,   30),
            (4,  N'Religious Advisors',      'mm',    0x00000008,   40),
            (5,  N'Hare Raisers',            'mm',    0x00000200,   50),
            -- Web Meister (32) + Social Media (8) = 39. NOTE there is also a
            -- separate Communications role (0x00100000, 13 people) which is
            -- NOT included — add 0x00100000 to this mask if it should be.
            (6,  N'Web & Social Media',      'mm',    0x02001000,   60)
        ) AS c (RoomType, RoomName, GrantColumn, GrantMask, SortOrder);
GO
