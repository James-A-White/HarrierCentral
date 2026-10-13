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

    -- Check the token BEFORE saying success (2026-10-13). The inner app SP
    -- checks it too, but by then rowset 0 already said success = 1, so a
    -- refused token (a drifted clock, a signed-out device) reached the
    -- browser as an empty list instead of an error. Same name and number
    -- as the inner SP, so the token and the error codes are the same.
    DECLARE @gUserId UNIQUEIDENTIFIER, @gSecret NVARCHAR(150), @gWindow INT,
            @gCode INT, @gType INT, @gErrorId UNIQUEIDENTIFIER, @gTitle NVARCHAR(500), @gMsg NVARCHAR(MAX);
    DECLARE @gProc NVARCHAR(128) = N'hcapp_getEventBadgeCount';
    DECLARE @gSp INT = 63;
    EXEC HC6.ValidateAppAuth @deviceId = @deviceId, @accessToken = @accessToken, @procName = @gProc,
         @spNumber = @gSp, @param = NULL, @userId = @gUserId OUTPUT, @deviceSecret = @gSecret OUTPUT,
         @timeWindow = @gWindow OUTPUT, @errorCode = @gCode OUTPUT, @errorType = @gType OUTPUT,
         @errorId = @gErrorId OUTPUT, @errorTitle = @gTitle OUTPUT, @errorMsg = @gMsg OUTPUT;
    IF (@gCode IS NOT NULL)
    BEGIN
        SELECT 0 AS success, @gCode AS errorCode, @gType AS errorType, @me AS Me;
        SELECT @gErrorId AS errorId, @gType AS errorType, @gCode AS errorCode,
               @gTitle AS errorTitle, @gMsg AS errorUserMessage, @gProc AS errorProc;
        RETURN;
    END

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
