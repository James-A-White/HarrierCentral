CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendKennelMessage]
    @deviceId                    UNIQUEIDENTIFIER = NULL,
    @accessToken                 NVARCHAR(1000)   = NULL,
    @kennelId                    UNIQUEIDENTIFIER = NULL,
    @messageId                   UNIQUEIDENTIFIER = NULL,
    @messageTitle                NVARCHAR(250)    = NULL,
    @messageContent              NVARCHAR(500)    = NULL,
    @messageReleasabilityFlags   INT              = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendKennelMessage
-- Description: Sends a message to a KENNEL-LEVEL chat thread (an
--   EventMessage row with KennelId set and EventId NULL). Mirrors
--   hcapp_sendEventMessage's three-rowset contract so the API shim's
--   push dispatch works unchanged. Preference resolution uses
--   KennelNotificationPreference only (no event-level override exists
--   for a kennel thread); onBeforeRun(4) is treated as a full push.
-- Parameters: mirror hcapp_sendEventMessage with @kennelId in place of
--   @eventId.
-- Returns:
--   Rowset 0: message detail (sender optimistic-UI confirmation)
--   Rowset 1: full push recipients { UserId, FcmToken }
--   Rowset 2: silent in-app recipients { UserId, FcmToken }
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — kennel chat, design of record)
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
    @spNumber = 64, @param = NULL,
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

IF (@messageId IS NULL OR @kennelId IS NULL
    OR LEN(COALESCE(@messageContent, '')) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing required fields',
            'messageId, kennelId and messageContent are required', @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1901 AS errorCode,
           'Missing fields' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Sender must at least follow the kennel
IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
               WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not a follower',
            'Sender has no HKM row for this kennel', @procName, @userId);
    SELECT @errorId AS errorId, 3 AS errorType, 1902 AS errorCode,
           'Not following' AS errorTitle,
           'You must follow this kennel to use its chat.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

DECLARE @publicKennelId UNIQUEIDENTIFIER, @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicKennelId = k.PublicKennelId FROM HC.Kennel k WHERE k.id = @kennelId;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;
SET @messageReleasabilityFlags = COALESCE(@messageReleasabilityFlags, 63);
SET @messageTitle = COALESCE(@messageTitle, '');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO HC.EventMessage
        ([id], [KennelId], [PublicKennelId], [UserId], [PublicHasherId],
         [MessageTitle], [MessageContent], [MessageReleasabilityFlags])
    VALUES
        (@messageId, @kennelId, @publicKennelId, @userId, @publicHasherId,
         @messageTitle, @messageContent, @messageReleasabilityFlags);

    DECLARE @messageSequenceCount INT;
    SELECT @messageSequenceCount = em.MessageSequenceCount
    FROM HC.EventMessage em WHERE em.id = @messageId;

    -- Sender never sees their own message as unread
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @kennelId, @messageSequenceCount)) AS Source (UserId, KennelId, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.KennelId = Source.KennelId)
    WHEN MATCHED THEN
        UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, KennelId, LastSequenceCount)
        VALUES (Source.UserId, Source.KennelId, Source.LastSequenceCount);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'The message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH

-- ---------------------------------------------------------------
-- Rowset 0: message detail
-- ---------------------------------------------------------------
DECLARE @sendToMismanagement SMALLINT = @messageReleasabilityFlags & 0x0001;
DECLARE @sendToMembers       SMALLINT = @messageReleasabilityFlags & 0x0002;
DECLARE @sendToFollowers     SMALLINT = @messageReleasabilityFlags & 0x0004;
DECLARE @sendToEveryone      SMALLINT = @messageReleasabilityFlags & 0x0020;

SELECT
    msg.id                                   AS MessageId,
    msg.KennelId                             AS KennelId,
    msg.PublicKennelId                       AS PublicKennelId,
    h.PublicHasherId                         AS UserId,
    h.DisplayName                            AS UserDisplayName,
    h.Photo                                  AS UserPhoto,
    h.DisplayName + ' - ' + msg.MessageTitle AS MessageTitle,
    msg.MessageContent                       AS MessageContent,
    msg.MessageReleasabilityFlags            AS MessageReleasabilityFlags,
    0                                        AS EventChatMessageCount,
    msg.MessageType                          AS MessageType
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.id = @messageId AND msg.removed = 0 AND h.Removed = 0;

-- ---------------------------------------------------------------
-- Rowset 1: full push recipients. Kennel-level preference only (no event
-- override exists); onBeforeRun(4) has no event window here -> full push.
-- ---------------------------------------------------------------
SELECT
    hkm.UserId,
    device.FcmToken
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Hasher h      ON hkm.UserId    = h.id
INNER JOIN HC.Device device ON device.UserId = h.id
WHERE hkm.KennelId = @kennelId
  AND device.FcmToken IS NOT NULL
  AND hkm.KennelNotificationPreference IN (0, 1, 4)
  AND (
      @sendToEveryone       != 0
   OR (@sendToMismanagement != 0 AND hkm.MismanagementRoles != 0)
   OR (@sendToMembers       != 0 AND hkm.MembershipExpirationDate > GETDATE())
   OR (@sendToFollowers     != 0 AND hkm.Following = 1)
  );

-- ---------------------------------------------------------------
-- Rowset 2: silent in-app recipients (followers/members not in rowset 1,
-- not opted out)
-- ---------------------------------------------------------------
SELECT
    hkm.UserId,
    device.FcmToken
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Device device ON hkm.UserId = device.UserId
WHERE hkm.KennelId = @kennelId
  AND (hkm.Following != 0 OR hkm.MembershipExpirationDate > GETDATE())
  AND device.FcmToken IS NOT NULL
  AND hkm.KennelNotificationPreference != 2
  AND hkm.KennelNotificationPreference NOT IN (0, 1, 4);
