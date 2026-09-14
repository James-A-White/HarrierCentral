CREATE OR ALTER PROCEDURE [HC6].[hcapp_getAdminMessages]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @sinceSequenceCount INT              = NULL,
    -- 1 marks everything read up to the newest message returned. The app
    -- sends 1 when the channel is on screen and 0 when it is only counting
    -- the badge, so opening the list is what clears it.
    @markRead           SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getAdminMessages
-- Description: Reads the platform-wide Harrier Central admin channel, and
--   optionally marks it read. The twin of hcapp_sendAdminMessage.
--
--   The thread is the EventMessage rows with EventId AND KennelId both
--   NULL and MessageType = 1. See the send SP's header for why that needed
--   no new table and no new column.
--
-- Authorization: SuperAdmin (AppAccessFlags & 0x40000000) on ANY kennel —
--   the same test as sending. A non-admin gets an error rather than an
--   empty list, so the app never renders the room to someone who cannot be
--   in it.
--
-- Returns:
--   Rowset 0: messages, newest first, in the shape the chat UI already
--             reads for kennel and event threads.
--   Rowset 1: { unreadCount, newestSequenceCount } for the badge.
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
    @spNumber = 105, @param = NULL,
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

IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
               WHERE hkm.UserId = @userId AND hkm.removed = 0
                 AND hkm.AppAccessFlags & 0x40000000 <> 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not an admin',
            'Reader holds SuperAdmin on no kennel', @procName, @userId);
    SELECT @errorId AS errorId, 13 AS errorType, 1944 AS errorCode,
           'Not authorised' AS errorTitle,
           'The admin channel is for Harrier Central administrators.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY

-- The global room this SP speaks for. Role rooms take 2, 3, ...; DMs will
-- carry a ThreadId alongside. Whole key:
-- db/hc6/app/archive/2026-09-14_chat_thread_keys.sql
DECLARE @roomType INT = 1;

DECLARE @newestSeq INT =
    (SELECT MAX(em.MessageSequenceCount) FROM HC.EventMessage em
      WHERE em.EventId IS NULL AND em.KennelId IS NULL
        AND em.MessageType = @roomType AND em.Removed = 0);

-- Same full key as the MERGE below. EventId/KennelId NULL alone would read
-- back whichever global room or DM happened to write last.
DECLARE @lastRead INT =
    ISNULL((SELECT b.LastSequenceCount FROM HC.EventMessageBadgeCounts b
             WHERE b.UserId = @userId
               AND b.EventId IS NULL AND b.KennelId IS NULL
               AND b.ThreadId IS NULL
               AND b.MessageType = @roomType), 0);

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
WHERE msg.EventId IS NULL
  AND msg.KennelId IS NULL
  AND msg.MessageType = @roomType
  AND msg.Removed = 0
  AND h.Removed = 0
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount > @sinceSequenceCount)
ORDER BY msg.createdAt DESC;

-- Badge BEFORE the mark, so the caller learns what it had to clear.
SELECT
    (SELECT COUNT(*) FROM HC.EventMessage em
      WHERE em.EventId IS NULL AND em.KennelId IS NULL
        AND em.MessageType = @roomType AND em.Removed = 0
        AND em.UserId <> @userId
        AND em.MessageSequenceCount > @lastRead)      AS unreadCount,
    ISNULL(@newestSeq, 0)                             AS newestSequenceCount;

IF (@markRead = 1 AND @newestSeq IS NOT NULL)
BEGIN
    -- Same full key as the send SP. Comparing a nullable column to a NULL
    -- value never matches, so the kennel form of this MERGE would add a new
    -- badge row on every read; and without MessageType/ThreadId in the
    -- match, this room would share one badge row with every role room and
    -- every future DM.
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @newestSeq)) AS Source (UserId, LastSequenceCount)
    ON (Target.UserId = Source.UserId
        AND Target.EventId IS NULL
        AND Target.KennelId IS NULL
        AND Target.ThreadId IS NULL
        AND Target.MessageType = @roomType)
    WHEN MATCHED THEN
        UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount,
                   Target.LastReadAt = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, EventId, KennelId, MessageType, LastSequenceCount, LastReadAt)
        VALUES (Source.UserId, NULL, NULL, @roomType, Source.LastSequenceCount, SYSDATETIMEOFFSET());
END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getAdminMessages',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
