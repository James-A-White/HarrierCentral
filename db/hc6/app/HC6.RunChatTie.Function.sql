CREATE OR ALTER FUNCTION [HC6].[RunChatTie] (@userId UNIQUEIDENTIFIER, @eventId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.RunChatTie
-- Description: How a hasher is tied to a run, for its chat (E9.F1.S27,
--   decided with James 2026-10-02 after Kilty's phone). THE one rule that
--   the Chats list / unread counts / icon badge (HC6.UserUnreadChatThreads)
--   and the run-chat push audience (hcapp_ and hcportal_sendEventMessage)
--   all read, so they cannot drift.
--
--   IsPersonal   — the run is the hasher's own: RSVP Yes (3), attended
--                  (AttendenceState >= 20), or they have POSTED in its
--                  chat. Not Maybe; not merely having opened the chat.
--   HasKennelTie — a member of the run's kennel (membership not yet
--                  expired: MembershipExpirationDate in the future, which
--                  includes the permanent 2100 / 2999 dates — NOT the
--                  IsMember flag) OR following it (Following = 1). A bare
--                  HasherKennelMap row — "ran there once" — is no tie.
--   IsGmOrOnSec  — holds the GM (0x02) or On-Sec (0x40) role at the run's
--                  kennel: the only people a kennel bell alone buzzes for
--                  every run.
--
--   Used per RECIPIENT for one run by the send SPs. HC6.UserUnreadChatThreads
--   holds the same rule worked out once per user as sets (per thread it was
--   0.4-1.2 s): change one, change the other.
-- Returns: one row { IsPersonal, HasPosted, HasKennelTie, IsGmOrOnSec } (0/1 each)
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
RETURN
    SELECT
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.HasherEventMap h
                               WHERE h.EventId = @eventId AND h.UserId = @userId
                                 AND ISNULL(h.removed, 0) = 0
                                 AND (h.RsvpState = 3 OR h.AttendenceState >= 20))
                    OR EXISTS (SELECT 1 FROM HC.EventMessage m
                               WHERE m.EventId = @eventId AND m.UserId = @userId
                                 AND m.Removed = 0)
                  THEN 1 ELSE 0 END AS SMALLINT) AS IsPersonal,
        -- Posted alone, because the Chats list keeps a run you POSTED in
        -- without a time limit, while RSVP Yes / attended follow the
        -- 90-day window like a kennel tie (today's windows, kept).
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.EventMessage m
                               WHERE m.EventId = @eventId AND m.UserId = @userId
                                 AND m.Removed = 0)
                  THEN 1 ELSE 0 END AS SMALLINT) AS HasPosted,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.HasherKennelMap k
                               JOIN HC.Event e ON e.KennelId = k.KennelId
                               WHERE e.id = @eventId AND k.UserId = @userId
                                 AND k.removed = 0
                                 AND (k.Following = 1
                                      OR k.MembershipExpirationDate > SYSDATETIMEOFFSET()))
                  THEN 1 ELSE 0 END AS SMALLINT) AS HasKennelTie,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.HasherKennelMap k
                               JOIN HC.Event e ON e.KennelId = k.KennelId
                               WHERE e.id = @eventId AND k.UserId = @userId
                                 AND k.removed = 0
                                 AND (k.MismanagementRoles & 66) <> 0)   -- 0x02 GM | 0x40 On-Sec
                  THEN 1 ELSE 0 END AS SMALLINT) AS IsGmOrOnSec;
GO
