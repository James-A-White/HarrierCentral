CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendRoomMessage]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @roomType       INT              = NULL,
    @messageId      UNIQUEIDENTIFIER = NULL,
    @messageContent NVARCHAR(MAX)    = NULL
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
-- Returns:
--   Rowset 0: the message, in the same shape the chat UI already reads for
--     kennel and event threads. UNCHANGED — clients parse this one.
--   Rowset 1: push detail for the API shim { MessageId, RoomType, RoomName,
--     UserId, UserDisplayName, UserPhoto, MessageTitle, MessageContent }
--   Rowset 2: visible push recipients { UserId, FcmToken }
--   Rowset 3: silent (data-only) recipients { UserId, FcmToken }
--
--   Rowsets 1-3 were added 2026-09-18 (E9.F1.S10). A room computed no
--   audience at all before that, so the shim had nothing to deliver and a
--   room message never reached a phone.
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

-- LEN(), not a comparison against '' — and this is not a style point.
-- The database collates SQL_Latin1_General_CP1_CI_AS, in which a surrogate
-- pair carries NO sort weight, so N'<emoji>' = '' is TRUE and the old
-- NULLIF(LTRIM(RTRIM(...)), '') returned NULL for a message made only of
-- emoji. A hasher who sent a single wave got "The message could not be
-- sent" for a message that was never empty (Kilty, 2026-09-19, room 1 on
-- 3.1.0+1388; the request body in the client log carried the emoji).
-- LEN() counts the code units (2) so emoji pass, and still returns 0 for a
-- string of only spaces, which is what the guard is actually for.
-- hcapp_sendKennelMessage already does it this way; this is now the same.
IF (@roomType IS NULL
    OR @messageId IS NULL
    OR LEN(COALESCE(@messageContent, N'')) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            CONCAT('roomType=', ISNULL(CAST(@roomType AS VARCHAR(12)), 'NULL'),
                   ' messageId=', CASE WHEN @messageId IS NULL THEN 'NULL' ELSE 'set' END,
                   ' contentLen=', LEN(COALESCE(@messageContent, N''))),
            @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1941 AS errorCode,
           'Missing fields' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- The column is NVARCHAR(4000) since 2026-09-23 and this parameter is MAX so
-- that an over-long message is REFUSED, not cut: an NVARCHAR(500) parameter
-- silently truncated the first admin-room announcement at exactly 500
-- characters, with no error and no log (James, 2026-09-23). LEN counts
-- UTF-16 code units, the same measure the column enforces.
IF (LEN(@messageContent) > 4000)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Message too long',
            CONCAT('roomType=', ISNULL(CAST(@roomType AS VARCHAR(12)), 'NULL'),
                   ' contentLen=', LEN(@messageContent)),
            @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1942 AS errorCode,
           'Message too long' AS errorTitle,
           CONCAT('Messages can be up to 4,000 characters; this one is ', LEN(@messageContent),
                  '. Please shorten it and send again.') AS errorUserMessage,
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

-- The message is COMMITTED by this point. Everything below is push
-- plumbing, so a failure here must not fail the send: it is logged and
-- swallowed, never re-thrown. Re-throwing would break the client's parse of
-- a rowset it has already been given, to report a message that did in fact
-- arrive.
BEGIN TRY

-- ---------------------------------------------------------------
-- Rowset 1: push detail.
-- Deliberately a SEPARATE rowset rather than extra columns on rowset 0:
-- rowset 0 is the flutter_chat_core shape that two clients already parse,
-- and it stays exactly as it was.
-- ---------------------------------------------------------------
SELECT
    msg.id                                   AS MessageId,
    msg.MessageType                          AS RoomType,
    c.RoomName                               AS RoomName,
    h.PublicHasherId                         AS UserId,
    h.DisplayName                            AS UserDisplayName,
    h.Photo                                  AS UserPhoto,
    c.RoomName + ' — ' + h.DisplayName       AS MessageTitle,
    msg.MessageContent                       AS MessageContent
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
LEFT JOIN HC6.ChatRoomCatalog() c ON c.RoomType = msg.MessageType
WHERE msg.id = @messageId;

-- ---------------------------------------------------------------
-- Push recipients. A room does NOT use the kennel notification preference:
-- membership is by role and the room's own opt-out lives on
-- HC.EventMessageBadgeCounts.ParticipationState —
--   0 participate with push (the default, and no row means the default)
--   1 participate, badges only
--   2 opted out, and the room is not even listed
-- so 0 is consent here, unlike the kennel and event prefs where 0 means
-- "never touched". That difference is deliberate: a hasher only has a room
-- at all because they hold the role.
--
-- The rest mirrors hcapp_sendEventMessage: one push per DEVICE TOKEN, not
-- per device row, nothing retired, and nothing to a device that has not
-- signed in for 180 days (the next sign-in re-arms it).
--
-- The sender IS included, deliberately, exactly as the event and kennel
-- audiences include theirs. The echo of your own message is what drives the
-- delivered tick: the chat page's FCM listener calls
-- _upgradeOwnMessagesToDelivered() for any push on the thread it is showing,
-- so suppressing the sender's copy would leave their own messages on a single
-- tick for ever (James, 2026-09-18). It looked like a fan-out bug and is not.
--
-- HC6.UserMayEnterChatRoom is the gate, the same one the list and the read
-- SPs use, so a room can never push to someone it would refuse to show.
-- ---------------------------------------------------------------
DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());
-- Builds that cannot route a push with no event are left out entirely.
-- One place owns the number: HC6.MinBuildForChatPush.
DECLARE @minPushBuild INT = HC6.MinBuildForChatPush();

SELECT DISTINCT
    h.id           AS UserId,
    device.FcmToken,
    ISNULL(b.ParticipationState, 0) AS Pref
INTO #roomAudience
FROM HC.Hasher h
INNER JOIN HC.Device device ON device.UserId = h.id
LEFT JOIN HC.EventMessageBadgeCounts b
       ON b.UserId       = h.id
      AND b.EventId      IS NULL
      AND b.KennelId     IS NULL
      AND b.ThreadId     IS NULL
      AND b.MessageType  = @roomType
WHERE h.Removed = 0
  AND device.FcmToken  IS NOT NULL
  AND device.removed   = 0
  AND device.LastLogin >= @idleCutoff
  -- BuildNumber is NVARCHAR and can be '<unknown>': TRY_CAST yields NULL,
  -- the comparison is UNKNOWN, and the device is excluded. Fail closed.
  AND TRY_CAST(device.BuildNumber AS INT) >= @minPushBuild
  AND ISNULL(b.ParticipationState, 0) <> 2
  AND HC6.UserMayEnterChatRoom(h.id, @roomType) = 1;

-- Rowset 2: visible push recipients
SELECT DISTINCT UserId, FcmToken FROM #roomAudience WHERE Pref = 0;

-- Rowset 3: silent (data-only) recipients — the badge moves, nothing buzzes
SELECT DISTINCT UserId, FcmToken FROM #roomAudience WHERE Pref = 1;

DROP TABLE #roomAudience;

END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId),
            'Push audience failed in sendRoomMessage', ERROR_MESSAGE(), @procName, @userId);
    -- Swallowed on purpose. See the note above the TRY.
END CATCH
GO
