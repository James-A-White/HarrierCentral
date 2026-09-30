CREATE OR ALTER PROCEDURE [HC6].[hcapp_reactToChatMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @messageId   UNIQUEIDENTIFIER = NULL,
    @reaction    NVARCHAR(20)     = NULL,
    @on          SMALLINT         = 1
AS
-- =====================================================================
-- Procedure: HC6.hcapp_reactToChatMessage
-- Description: Adds or removes the caller's emoji reaction on a chat
--   message — run, kennel, room or DM (E9.F1.S22, 2026-09-30). The rule
--   and the write are HC6.nonApi_reactToChatMessage; this authenticates,
--   replies, and hands the API what it needs to nudge the message's
--   author.
--
--   A standard token: the target is a message, and whether the caller may
--   react is decided from the token's user.
-- Parameters: @messageId; @reaction — a code from HC6.ChatReactionCatalog
--   (thumbs, heart, laugh, beer, run, fire); @on 1 add / 0 remove.
-- Returns:
--   rowset 0 — { success = 1, messageId, reactions } (reactions = the
--              message's JSON after the change, NULL when none are left);
--              on error { success = 0, errorCode, errorType } then the
--              standard error detail row.
--   rowset 1 — push detail { MessageId, EventId, KennelId, RoomType,
--              ThreadId, ThreadKind } — API ONLY, stripped before the reply
--   rowset 2 — silent recipients { UserId, FcmToken } — the message's
--              author's phones (not the reactor's own), so an open thread
--              refreshes; nobody is buzzed for a 🍺. API ONLY, stripped.
-- Author: Harrier Central
-- Created: 2026-09-30
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 140, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@messageId IS NULL OR @reaction IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            CONCAT('messageId=', CASE WHEN @messageId IS NULL THEN 'NULL' ELSE 'set' END,
                   ' reaction=', COALESCE(@reaction, 'NULL')), @procName, @userId);
    SELECT 0 AS success, 1990 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1990 AS errorCode,
           'Missing fields' AS errorTitle,
           'That reaction could not be saved. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @outcome SMALLINT, @reactions NVARCHAR(MAX);
    DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER, @threadId UNIQUEIDENTIFIER;
    DECLARE @messageType INT, @authorId UNIQUEIDENTIFIER;
    EXEC HC6.nonApi_reactToChatMessage
        @userId = @userId, @messageId = @messageId, @reaction = @reaction, @on = @on,
        @outcome = @outcome OUTPUT, @reactions = @reactions OUTPUT,
        @eventId = @eventId OUTPUT, @kennelId = @kennelId OUTPUT, @threadId = @threadId OUTPUT,
        @messageType = @messageType OUTPUT, @authorId = @authorId OUTPUT;

    IF (@outcome = 1)
    BEGIN
        SELECT 1 AS success, UPPER(CAST(@messageId AS NVARCHAR(36))) AS messageId, @reactions AS reactions;

        -- API only: where the message lives, in the keys the app's open chat
        -- page matches a push on (EventId / KennelId / RoomType / ThreadId).
        SELECT UPPER(CAST(@messageId AS NVARCHAR(36)))                         AS MessageId,
               CASE WHEN @threadId IS NOT NULL THEN 'dm'
                    WHEN @eventId  IS NOT NULL THEN 'run'
                    WHEN @kennelId IS NOT NULL THEN 'kennel' ELSE 'room' END   AS ThreadKind,
               @eventId                                                        AS EventId,
               (SELECT e.PublicEventId FROM HC.Event e WHERE e.id = @eventId)  AS PublicEventId,
               @kennelId                                                       AS KennelId,
               CASE WHEN @eventId IS NULL AND @kennelId IS NULL AND @threadId IS NULL
                    THEN @messageType END                                      AS RoomType,
               @threadId                                                       AS ThreadId;

        -- API only: the author's phones, never the reactor's own.
        SELECT DISTINCT d.UserId, d.FcmToken
        FROM HC.Device d
        WHERE d.UserId = @authorId
          AND @authorId <> @userId
          AND d.FcmToken IS NOT NULL
          AND d.removed = 0
          AND d.IsMobile = 1
          AND TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForChatPush();
        RETURN;
    END

    SET @errorId = NEWID();
    DECLARE @code INT = CASE @outcome WHEN 3 THEN 1992 WHEN 4 THEN 1993 ELSE 1991 END;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId),
            CASE @outcome WHEN 3 THEN 'Not allowed' WHEN 4 THEN 'Unknown reaction' ELSE 'Not found' END,
            CONCAT('message=', CAST(@messageId AS NVARCHAR(40)), ' reaction=', @reaction, ' on=', @on, ' outcome=', @outcome),
            @procName, @userId);
    SELECT 0 AS success, @code AS errorCode, 3 AS errorType;
    SELECT @errorId AS errorId, 3 AS errorType, @code AS errorCode,
           CASE @outcome WHEN 3 THEN 'Not allowed' WHEN 4 THEN 'Unknown reaction' ELSE 'Not found' END AS errorTitle,
           CASE @outcome
               WHEN 3 THEN 'You can''t react in that chat.'
               WHEN 4 THEN 'That reaction isn''t available.'
               ELSE 'That message is no longer in the chat.' END AS errorUserMessage,
           @procName AS errorProc;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in reactToChatMessage',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1994 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1994 AS errorCode,
           'Something went wrong' AS errorTitle,
           'That reaction could not be saved. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
