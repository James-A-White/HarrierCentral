CREATE OR ALTER FUNCTION [HC6].[MinBuildForIconBadge] ()
RETURNS INT
AS
-- =====================================================================
-- Function: HC6.MinBuildForIconBadge
-- Description: The lowest app build whose chat pushes carry the unread
--   total for the app ICON (aps.badge / notification_count, E9.F2.S6).
--
--   WHY A GATE: a push that sets the icon number is only half of it — the
--   app must lower it again as chats are read. Builds before this one never
--   touched the icon (their clear was a stub), so a number pushed to them
--   would stay on the icon after the chats were read. They get the pushes
--   they always got, with no number.
--
--   THIS IS THE ONLY PLACE THE NUMBER LIVES; every chat send SP and
--   hcapp_markEventChatRead read it. Fail closed, as MinBuildForChatPush:
--   callers compare TRY_CAST(device.BuildNumber AS INT) >= this, so a build
--   that will not parse gets no number.
--
-- Returns: INT — the minimum build number (1418 = the first build with the
--   app side, 2026-09-28).
-- Author: Harrier Central
-- Created: 2026-09-28
-- =====================================================================
BEGIN
    RETURN 1418;
END
GO
