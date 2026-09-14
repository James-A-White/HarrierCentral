CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendAdminMessage]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @messageId      UNIQUEIDENTIFIER = NULL,
    @messageContent NVARCHAR(500)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendAdminMessage
-- Description: Sends a message to the platform-wide Harrier Central admin
--   channel — one room, not scoped to any kennel or run.
--
--   NO NEW TABLE AND NO NEW COLUMN. HC.EventMessage already carries two
--   kinds of message and tells them apart by which key is set: event chat
--   has EventId, kennel chat has KennelId, and BOTH columns are nullable.
--   The admin channel is simply the third kind — both keys NULL, with
--   MessageType = 1 saying which it is. MessageType already exists and is
--   0 on all 1,227 existing rows, so nothing already stored changes
--   meaning (James, 2026-09-13).
--
-- Authorization: SuperAdmin (AppAccessFlags & 0x40000000) on ANY kennel.
--   Deliberately the narrowest of the three audiences considered: 290
--   people rather than the 414 holding admin somewhere. A room of 414 is a
--   town square, and widening later is a one-line change to this test
--   whereas narrowing it after 400 people have been talking is not.
--
--   Note this is NOT HC6.CheckKennelPermission: that answers "may this
--   user do X in kennel K", and this channel belongs to no kennel. The
--   SuperAdmin bit is checked directly, which is the same bit
--   CheckKennelPermission itself treats as the all-features bypass.
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

IF (@messageId IS NULL
    OR NULLIF(LTRIM(RTRIM(ISNULL(@messageContent, ''))), '') IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            'messageId or messageContent was empty', @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1941 AS errorCode,
           'Missing fields' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Authorization. ValidateAppAuth proved WHO, not what they may do.
IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
               WHERE hkm.UserId = @userId AND hkm.removed = 0
                 AND hkm.AppAccessFlags & 0x40000000 <> 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not an admin',
            'Sender holds SuperAdmin on no kennel', @procName, @userId);
    SELECT @errorId AS errorId, 13 AS errorType, 1942 AS errorCode,
           'Not authorised' AS errorTitle,
           'The admin channel is for Harrier Central administrators.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- The global room this SP speaks for. Role rooms (RAs, Hash Flashes) take
-- 2, 3, ... and DMs will carry a ThreadId alongside. See
-- db/hc6/app/archive/2026-09-14_chat_thread_keys.sql for the whole key.
DECLARE @roomType INT = 1;

DECLARE @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;

BEGIN TRY
    BEGIN TRANSACTION;

    -- EventId and KennelId both NULL; MessageType 1 is what says "admin".
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
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_sendAdminMessage',
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
