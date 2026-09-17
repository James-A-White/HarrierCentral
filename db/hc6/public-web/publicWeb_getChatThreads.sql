-- =====================================================================
-- Procedure: HC6.publicWeb_getChatThreads
-- Description: The app's chat thread list for a web member (E9.F7.S15):
--   every run, kennel and room thread with its unread badge and message
--   count — hcapp_getEventBadgeCount in its list mode (no event given),
--   the same rows the app's "Unseen Chats" list and the three-state chat
--   bubbles on the cards read. The token is signed for that SP.
-- Returns: rowset 0 envelope with my PublicHasherId (Me); then the
--   thread rows as hcapp_getEventBadgeCount returns them
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getChatThreads]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @me NVARCHAR(40);
    SELECT @me = UPPER(CAST(h.PublicHasherId AS NVARCHAR(40)))
    FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
    WHERE d.id = @deviceId AND d.removed = 0;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType, @me AS Me;

    EXEC HC6.hcapp_getEventBadgeCount
        @deviceId = @deviceId, @accessToken = @accessToken,
        @publicEventId = NULL, @resetBadgeCount = 0, @resetAllBadgeCounts = 0;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getChatThreads', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
