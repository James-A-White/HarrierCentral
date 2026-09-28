CREATE OR ALTER FUNCTION [HC6].[UserUnreadChatTotal]
(
    @userId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.UserUnreadChatTotal
-- Description: The number on the app icon: a hasher's unread messages
--   across every chat thread, from HC6.UserUnreadChatThreads — the same sum
--   the app folds into globalTotalBadgeCount. The chat push SPs return it
--   per recipient, and the API puts it in aps.badge (iOS) and
--   notification_count (Android), so the icon is right even when the app
--   is closed (2026-09-28). Inline so a CROSS APPLY per recipient stays set-based.
-- Returns: one row { BadgeTotal INT } (0 when nothing is unread).
-- Author: Harrier Central
-- Created: 2026-09-28
-- =====================================================================
RETURN
    SELECT CAST(COALESCE(SUM(CASE WHEN t.BadgeCount > 0 THEN t.BadgeCount ELSE 0 END), 0) AS INT) AS BadgeTotal
    FROM HC6.UserUnreadChatThreads(@userId) t;
