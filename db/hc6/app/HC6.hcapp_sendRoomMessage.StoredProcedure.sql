CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendRoomMessage]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @roomType       INT              = NULL,
    @messageId      UNIQUEIDENTIFIER = NULL,
    @messageContent NVARCHAR(500)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendRoomMessage
-- Description: Posts to a platform-wide chat room — one of the rooms in
--   HC6.ChatRoomCatalog(), not scoped to any kennel or run.
--
--   NO NEW TABLE AND NO NEW COLUMN FOR THE MESSAGE. HC.EventMessage already
--   carries two kinds of message and tells them apart by which key is set:
--   event chat has EventId, kennel chat has KennelId, and BOTH are nullable.
--   A room is the third kind — both NULL, with MessageType naming WHICH
--   room. MessageType already existed and is 0 on all 1,227 stored rows, so
--   nothing already there changes meaning (James, 2026-09-13/14).
--
--   ThreadId stays NULL here and is reserved for one-to-one DMs, so it is
--   written into every predicate that selects room rows — without it a DM
--   would eventually leak into a room's history.
--
-- Authorization: HC6.UserMayEnterChatRoom — the one gate, shared with
--   hcapp_getRoomMessages and hcapp_getChatRooms so the three cannot drift.
--   NOT HC6.CheckKennelPermission: that answers "may this user do X in
--   kennel K", and a room belongs to no kennel.
--
-- Returns: rowset 0 — the message, in the same shape the chat UI already
--   reads for kennel and event threads.
-- Author: Harrier Central
-- Created: 2026-09-13
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
    @spNumber = 104, @param = NULL,
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

IF (@roomType IS NULL
    OR @messageId IS NULL
    OR NULLIF(LTRIM(RTRIM(ISNULL(@messageContent, ''))), '') IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            'roomType, messageId or messageContent was empty', @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1941 AS errorCode,
           'Missing fields' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Authorization. ValidateAppAuth proved WHO, not what they may do. An
-- unknown @roomType returns 0 here, so a bad room is refused rather than
-- opening an empty one.
IF (HC6.UserMayEnterChatRoom(@userId, @roomType) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not an admin',
            'Sender does not hold the role this room is for', @procName, @userId);
    SELECT @errorId AS errorId, 13 AS errorType, 1942 AS errorCode,
           'Not authorised' AS errorTitle,
           'That chat room is for the hashers who hold its role.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

DECLARE @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;

BEGIN TRY
    BEGIN TRANSACTION;

    -- EventId, KennelId and ThreadId all NULL; MessageType names the room.
    INSERT INTO HC.EventMessage
        ([id], [EventId], [KennelId], [UserId], [PublicHasherId],
         [MessageTitle], [MessageContent], [MessageReleasabilityFlags], [MessageType])
    VALUES
        (@messageId, NULL, NULL, @userId, @publicHasherId,
         '', @messageContent, 63, @roomType);

    DECLARE @seq INT;
    SELECT @seq = em.MessageSequenceCount FROM HC.EventMessage em WHERE em.id = @messageId;

    -- The sender never sees their own message as unread.
    --
    -- MERGE ON IS NULL predicates rather than `Target.KennelId =
    -- Source.KennelId`: the kennel version compares a column to a value,
    -- and NULL = NULL is never true, so that form would insert a duplicate
    -- badge row on every single message.
    --
    -- MessageType and ThreadId are part of the match, not decoration. Every
    -- global room and every future DM has EventId and KennelId both NULL,
    -- so without them a hasher would hold ONE badge row shared by this room,
    -- every role room, and every private conversation they ever have.
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @seq)) AS Source (UserId, LastSequenceCount)
    ON (Target.UserId = Source.UserId
        AND Target.EventId IS NULL
        AND Target.KennelId IS NULL
        AND Target.ThreadId IS NULL
        AND Target.MessageType = @roomType)
    WHEN MATCHED THEN
        UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, EventId, KennelId, MessageType, LastSequenceCount)
        VALUES (Source.UserId, NULL, NULL, @roomType, Source.LastSequenceCount);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_sendRoomMessage',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, 5 AS errorType, 1943 AS errorCode,
           'Unexpected error' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH

-- Same shape the chat UI already reads for the other two thread kinds.
SELECT
    UPPER(msg.id)                                                    AS id,
    'text'                                                           AS type,
    msg.MessageContent                                               AS text,
    CONVERT(UNIQUEIDENTIFIER, '00000000-0000-0000-0000-000000000000') AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)  AS createdAt,
    UPPER(h.PublicHasherId)                                          AS authorId,
    h.DisplayName                                                    AS authorFirstName,
    h.Photo                                                          AS authorImageUrl,
    msg.MessageSequenceCount                                         AS sequenceCount
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.id = @messageId;
GO
