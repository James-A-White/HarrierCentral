CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendDirectMessage]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @threadId       UNIQUEIDENTIFIER = NULL,
    @messageId      UNIQUEIDENTIFIER = NULL,
    @messageContent NVARCHAR(MAX)    = NULL,
    @messageKind    SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendDirectMessage
-- Description: Posts to a direct-message thread (E9.F1.S7): an
--   HC.EventMessage row with EventId and KennelId NULL and ThreadId set —
--   the third key HC.trgCreateSeqNum already numbers by. Mirrors
--   hcapp_sendRoomMessage's contract so the chat page and the API's push
--   dispatch work unchanged.
--
--   Refused unless BOTH HasherFriendMap rows for the thread are live:
--   the caller's not Removed (they ended it), the other's not Removed
--   (they ended it) and neither side blocking. The refusal names nobody's
--   reason: "You can't message <name>."
-- Returns:
--   Rowset 0: the message in the chat-page shape (+ messageKind, canDelete)
--   Rowset 1: push detail { MessageId, ThreadId, UserId, UserDisplayName,
--             UserPhoto, MessageTitle, MessageContent (preview), MessageKind }
--   Rowset 2: visible push recipients { UserId, FcmToken, BadgeTotal }
--   Rowset 3: silent recipients (the other party muted the thread)
--   Recipients are the other party's devices on builds >=
--   HC6.MinBuildForDmPush(); FriendNotificationPreference 2 = none.
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 134, @param = NULL,
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

DECLARE @detail NVARCHAR(300);
IF (@messageId IS NULL OR @threadId IS NULL OR LEN(COALESCE(@messageContent, '')) = 0)
BEGIN
    SET @detail = 'messageId, threadId and messageContent are required';
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields', @detail, @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 2010 AS errorCode,
           'Missing fields' AS errorTitle, 'The message could not be sent. Please try again.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (LEN(@messageContent) > 4000)
BEGIN
    SET @detail = CONCAT('thread=', CAST(@threadId AS NVARCHAR(40)), ' contentLen=', LEN(@messageContent));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Message too long', @detail, @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 2011 AS errorCode,
           'Message too long' AS errorTitle, CONCAT('Messages can be up to 4,000 characters; this one is ', LEN(@messageContent), '. Please shorten it and send again.') AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

SET @messageKind = COALESCE(@messageKind, 0);
DECLARE @kindError NVARCHAR(200) = HC6.ChatMessageKindError(@messageKind, @messageContent);
IF (@kindError IS NOT NULL)
BEGIN
    SET @detail = CONCAT('kind=', @messageKind, ' content=', LEFT(@messageContent, 300));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Message not sent', @detail, @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 2012 AS errorCode,
           'Message not sent' AS errorTitle, @kindError AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Both rows live, nobody blocking.
DECLARE @otherId UNIQUEIDENTIFIER, @otherName NVARCHAR(250), @otherPref SMALLINT;
SELECT @otherId = mine.Friend_UserId, @otherPref = ISNULL(theirs.FriendNotificationPreference, 0)
FROM HC.HasherFriendMap mine
JOIN HC.HasherFriendMap theirs ON theirs.UserId = mine.Friend_UserId AND theirs.Friend_UserId = @userId AND theirs.ThreadId = @threadId
WHERE mine.UserId = @userId AND mine.ThreadId = @threadId
  AND mine.Removed = 0 AND theirs.Removed = 0 AND mine.Ignore = 0 AND theirs.Ignore = 0;

IF (@otherId IS NULL)
BEGIN
    SELECT @otherName = h.DisplayName FROM HC.HasherFriendMap f JOIN HC.Hasher h ON h.id = f.Friend_UserId
    WHERE f.UserId = @userId AND f.ThreadId = @threadId;
    SET @detail = CONCAT('thread=', CAST(@threadId AS NVARCHAR(40)), ' not open for sender');
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not sent', @detail, @procName, @userId);
    SELECT @errorId AS errorId, 3 AS errorType, 2013 AS errorCode,
           'Not sent' AS errorTitle, CONCAT('You can''t message ', COALESCE(@otherName, 'this hasher'), '.') AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO HC.EventMessage
        ([id], [EventId], [KennelId], [ThreadId], [UserId], [PublicHasherId],
         [MessageTitle], [MessageContent], [MessageReleasabilityFlags], [MessageType], [MessageKind])
    VALUES
        (@messageId, NULL, NULL, @threadId, @userId, @publicHasherId,
         '', @messageContent, 63, 0, @messageKind);

    DECLARE @seq INT;
    SELECT @seq = em.MessageSequenceCount FROM HC.EventMessage em WHERE em.id = @messageId;

    -- The sender never sees their own message as unread. Keyed on the full
    -- thread identity, like the room MERGE and for the same reason.
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @seq)) AS Source (UserId, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.EventId IS NULL AND Target.KennelId IS NULL
        AND Target.ThreadId = @threadId AND Target.MessageType = 0)
    WHEN MATCHED THEN UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount, Target.LastReadAt = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, EventId, KennelId, ThreadId, MessageType, LastSequenceCount, LastReadAt)
        VALUES (Source.UserId, NULL, NULL, @threadId, 0, Source.LastSequenceCount, SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in sendDirectMessage', ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, 5 AS errorType, 2014 AS errorCode,
           'Unexpected error' AS errorTitle, 'The message could not be sent. Please try again.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END CATCH

-- Rowset 0: the chat-page shape.
SELECT
    UPPER(msg.id)                                                    AS id,
    'text'                                                           AS type,
    msg.MessageContent                                               AS text,
    UPPER(msg.ThreadId)                                              AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)  AS createdAt,
    UPPER(h.PublicHasherId)                                          AS authorId,
    h.DisplayName                                                    AS authorFirstName,
    h.Photo                                                          AS authorImageUrl,
    msg.MessageSequenceCount                                         AS sequenceCount,
    msg.MessageKind                                                  AS messageKind,
    CAST(1 AS SMALLINT)                                              AS canDelete
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.id = @messageId;

-- Committed above; push plumbing must not fail the send.
BEGIN TRY
    SELECT
        msg.id                                   AS MessageId,
        UPPER(CAST(msg.ThreadId AS NVARCHAR(40))) AS ThreadId,
        h.PublicHasherId                         AS UserId,
        h.DisplayName                            AS UserDisplayName,
        h.Photo                                  AS UserPhoto,
        h.DisplayName                            AS MessageTitle,
        HC6.ChatMessagePreview(msg.MessageKind, msg.MessageContent) AS MessageContent,
        msg.MessageKind                          AS MessageKind
    FROM HC.EventMessage msg
    INNER JOIN HC.Hasher h ON msg.UserId = h.id
    WHERE msg.id = @messageId;

    DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());
    SELECT DISTINCT d.UserId, d.FcmToken,
           CASE WHEN TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForIconBadge() THEN bt.BadgeTotal END AS BadgeTotal
    INTO #dmAudience
    FROM HC.Device d CROSS APPLY HC6.UserUnreadChatTotal(d.UserId) bt
    WHERE d.UserId = @otherId AND d.removed = 0 AND d.FcmToken IS NOT NULL AND d.LastLogin >= @idleCutoff
      AND TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForDmPush()
      AND @otherPref <> 2;

    -- Rowset 2: visible; Rowset 3: silent (the other party muted this thread).
    SELECT UserId, FcmToken, BadgeTotal FROM #dmAudience WHERE @otherPref <> 3;
    SELECT UserId, FcmToken, BadgeTotal FROM #dmAudience WHERE @otherPref = 3;
    DROP TABLE #dmAudience;
END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Push plumbing failed in sendDirectMessage (message was sent)', ERROR_MESSAGE(), @procName, @userId);
END CATCH
GO
