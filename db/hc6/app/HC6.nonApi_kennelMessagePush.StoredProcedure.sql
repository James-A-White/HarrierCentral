CREATE OR ALTER PROCEDURE [HC6].[nonApi_kennelMessagePush]
    @messageId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_kennelMessagePush
-- Description: The push for a kennel-thread message that was NOT posted by
--   a client — the weekly Mismanagement reminder (E9.F1.S33,
--   nonApi_postKennelReminders) — in exactly hcapp_sendKennelMessage's
--   three-rowset shape, so the API sends it with the same kennel-chat push
--   code (SendChatNotifications, ChatPushKind.Kennel). The audience is
--   HC6.KennelChatPushAudience, the same function the send uses, so a
--   reminder reaches exactly the people a member's post would.
--   Called by the API's weekly timer once per NEW reminder; never by a
--   client. Reading it twice would push twice, so the timer calls it only
--   for rows nonApi_postKennelReminders reports as AlreadyPosted = 0.
-- Returns:
--   Rowset 0: message detail (as hcapp_sendKennelMessage rowset 0, with
--             KennelThread and ThreadKind)
--   Rowset 1: visible push recipients { UserId, FcmToken, BadgeTotal }
--   Rowset 2: silent recipients       { UserId, FcmToken, BadgeTotal }
--   All empty for an unknown, removed or non-kennel message.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none
-- Breaking Changes: none (new)
-- Idempotency: read-only — computes the push; the caller sends it once
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER, @messageType INT, @flags INT, @senderId UNIQUEIDENTIFIER;
    SELECT @kennelId = em.KennelId, @messageType = em.MessageType,
           @flags = em.MessageReleasabilityFlags, @senderId = em.UserId
    FROM HC.EventMessage em
    WHERE em.id = @messageId AND em.Removed = 0
      AND em.KennelId IS NOT NULL AND em.EventId IS NULL;

    -- Rowset 0: message detail (empty when there is no such kennel message)
    SELECT
        msg.id                                   AS MessageId,
        msg.KennelId                             AS KennelId,
        msg.PublicKennelId                       AS PublicKennelId,
        h.PublicHasherId                         AS UserId,
        h.DisplayName                            AS UserDisplayName,
        h.Photo                                  AS UserPhoto,
        -- The push title: "<sender> - <title>", or the sender alone when the
    -- message has no title (every app post and every reminder) — it read
    -- "Harrier Central -" until 2026-10-16.
    CASE WHEN LEN(COALESCE(msg.MessageTitle, '')) = 0 THEN h.DisplayName
         ELSE h.DisplayName + ' - ' + msg.MessageTitle END AS MessageTitle,
        HC6.ChatMessagePreview(msg.MessageKind, msg.MessageContent) AS MessageContent,
        msg.MessageKind                          AS MessageKind,
        msg.MessageReleasabilityFlags            AS MessageReleasabilityFlags,
        0                                        AS EventChatMessageCount,
        msg.MessageType                          AS MessageType,
        k.KennelShortName                        AS KennelShortName,
        CAST(CASE WHEN msg.MessageType = 0 THEN 0 ELSE 1 END AS SMALLINT) AS KennelThread,
        CASE WHEN msg.MessageType = 0 THEN 'kennel' ELSE 'kennelMisman' END AS ThreadKind
    FROM HC.EventMessage msg
    INNER JOIN HC.Hasher h ON msg.UserId = h.id
    LEFT JOIN HC.Kennel k  ON k.id = msg.KennelId
    WHERE @kennelId IS NOT NULL AND msg.id = @messageId;

    SELECT a.UserId, a.FcmToken, a.Pref
    INTO #pushAudience
    FROM HC6.KennelChatPushAudience(@kennelId, @messageType, @flags, @senderId) a
    WHERE @kennelId IS NOT NULL;

    -- Rowset 1: visible push recipients (BadgeTotal as hcapp_sendKennelMessage)
    SELECT DISTINCT a.UserId, a.FcmToken,
        CASE WHEN EXISTS (SELECT 1 FROM HC.Device dv WHERE dv.FcmToken = a.FcmToken
                        AND TRY_CAST(dv.BuildNumber AS INT) >= HC6.MinBuildForIconBadge())
         THEN bt.BadgeTotal END AS BadgeTotal FROM #pushAudience a
    CROSS APPLY HC6.UserUnreadChatTotal(a.UserId, a.FcmToken) bt WHERE a.Pref IN (1, 4);

    -- Rowset 2: silent recipients
    SELECT DISTINCT a.UserId, a.FcmToken,
        CASE WHEN EXISTS (SELECT 1 FROM HC.Device dv WHERE dv.FcmToken = a.FcmToken
                        AND TRY_CAST(dv.BuildNumber AS INT) >= HC6.MinBuildForIconBadge())
         THEN bt.BadgeTotal END AS BadgeTotal FROM #pushAudience a
    CROSS APPLY HC6.UserUnreadChatTotal(a.UserId, a.FcmToken) bt WHERE a.Pref = 3;

    DROP TABLE #pushAudience;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), 'api timer', 'Unhandled error in nonApi_kennelMessagePush',
            CONCAT('messageId=', CAST(@messageId AS NVARCHAR(40)), ' ', ERROR_MESSAGE()), @procName, NULL);
    THROW;
END CATCH
GO
