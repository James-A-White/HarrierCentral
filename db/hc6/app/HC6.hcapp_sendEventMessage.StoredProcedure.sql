CREATE OR ALTER PROCEDURE [HC6].[hcapp_sendEventMessage]

    @deviceId                    UNIQUEIDENTIFIER = NULL,
    @accessToken                 NVARCHAR(1000)   = NULL,
    @eventId                     UNIQUEIDENTIFIER = NULL,
    @messageId                   UNIQUEIDENTIFIER = NULL,
    @messageTitle                NVARCHAR(250)    = NULL,
    @messageContent              NVARCHAR(MAX)    = NULL,
    @messageReleasabilityFlags   INT              = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_sendEventMessage
-- Description: Inserts a new event message and returns three rowsets
--   used by the API shim to send push and in-app notifications:
--     Rowset 1 — the inserted message detail (for the caller)
--     Rowset 2 — full push notification recipients (FCM tokens for
--       hashers whose notification preference and releasability allow
--       a full push within the 6-hour event window)
--     Rowset 3 — in-app notification recipients (FCM tokens for
--       hashers following the kennel who didn't qualify for rowset 2)
--   The caller's badge count is updated to exclude the message they
--   just sent (sender never sees their own message as unread).
--   Token is compound: DeviceSecret + eventId string.
--
--   @messageReleasabilityFlags bitmask:
--     0x0001 = mismanagement, 0x0002 = members, 0x0004 = followers
--     0x0008 = RSVPs,         0x0010 = hares,   0x0020 = everyone
-- Parameters:
--   @deviceId                  - Registered device UUID
--   @accessToken               - Compound token: DeviceSecret + eventId (as NVARCHAR)
--   @eventId                   - Event the message belongs to
--   @messageId                 - Client-generated message UUID (idempotency)
--   @messageTitle              - Optional message title (defaults to event name)
--   @messageContent            - Message body (required)
--   @messageReleasabilityFlags - Bitmask controlling who receives notifications
-- Returns:
--   Read SP (no envelope — data-driven by rowset count).
--   Rowset 0: standard error detail (on error only)
--   Rowset 0: message detail (on success)
--   Rowset 1: full-push FCM recipient rows { UserId, FcmToken }
--   Rowset 2: in-app FCM recipient rows { UserId, FcmToken }
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_sendEventMessage
-- Breaking Changes:
--   @eventId changed NVARCHAR(250) → UNIQUEIDENTIFIER.
--   DATALENGTH checks replaced with NULL/LEN checks.
--   HC5's @isError flag pattern replaced with early RETURN on each error.
--   INSERT + MERGE wrapped in explicit transaction with TRY/CATCH.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 61,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Parameter validation
-- ---------------------------------------------------------------
IF (@messageId IS NULL)
BEGIN
    SET @errorCode = 1261; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Null messageId', 'messageId is required', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing message ID' AS errorTitle, 'A message ID must be provided.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@eventId IS NULL)
BEGIN
    SET @errorCode = 1261; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Null eventId', 'eventId is required', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (LEN(COALESCE(@messageContent, '')) = 0
    OR @messageReleasabilityFlags IS NULL
    OR (@messageReleasabilityFlags & 0x0000003F) = 0)
BEGIN
    SET @errorCode = 1261; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing required message fields',
            'messageContent or messageReleasabilityFlags missing', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing message fields' AS errorTitle,
           'Message content and a valid releasability flag are required.' AS errorUserMessage,
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
    SET @errorCode = 1264; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Message too long',
            CONCAT('eventId=', CAST(@eventId AS VARCHAR(40)), ' contentLen=', LEN(@messageContent)),
            @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Message too long' AS errorTitle,
           CONCAT('Messages can be up to 4,000 characters; this one is ', LEN(@messageContent),
                  '. Please shorten it and send again.') AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Load event and sender context
-- ---------------------------------------------------------------
DECLARE @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;

DECLARE @publicEventId          UNIQUEIDENTIFIER;
DECLARE @kennelId               UNIQUEIDENTIFIER;
DECLARE @eventStartDateTimeUtc  DATETIMEOFFSET(7);
DECLARE @timeLimitHours         SMALLINT = 6;

SELECT
    @publicEventId         = evt.PublicEventId,
    @kennelId              = evt.KennelId,
    @messageTitle          = COALESCE(@messageTitle, evt.EventName),
    @eventStartDateTimeUtc = (CAST(evt.EventStartDatetime AS DATETIME) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC'
FROM HC.Event evt
INNER JOIN HC.Kennel k     ON k.id  = evt.KennelId
INNER JOIN HC.City c       ON c.id  = k.CityId
INNER JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
WHERE evt.id = @eventId;

DECLARE @isWithinWindow SMALLINT =
    CASE WHEN ABS(DATEDIFF(MINUTE, GETDATE(), @eventStartDateTimeUtc)) <= (@timeLimitHours * 60) THEN 1 ELSE 0 END;

-- ---------------------------------------------------------------
-- Authorization: the sender must belong to this kennel (follows it) or be an
-- attendee/RSVP of this event. Previously any authenticated user could post to
-- any event chat (see /hc-authorizations). Mirrors sendKennelMessage's
-- membership gate, widened to include event attendees.
-- ---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap WHERE UserId = @userId AND KennelId = @kennelId AND removed = 0)
   AND NOT EXISTS (SELECT 1 FROM HC.HasherEventMap WHERE UserId = @userId AND EventId = @eventId)
BEGIN
    SET @errorCode = 1263; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised to post',
            'Sender is not a member or attendee of this event', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You must be a member of this kennel or attending this run to post a message.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Write path: INSERT + badge MERGE wrapped in a transaction so
-- both succeed or both roll back atomically.
-- ---------------------------------------------------------------
DECLARE @messageSequenceCount INT;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO HC.EventMessage
        ([id], [EventId], [PublicEventId], [UserId], [PublicHasherId],
         [MessageTitle], [MessageContent], [MessageReleasabilityFlags])
    VALUES
        (@messageId, @eventId, @publicEventId, @userId, @publicHasherId,
         @messageTitle, @messageContent, @messageReleasabilityFlags);

    SELECT @messageSequenceCount = em.MessageSequenceCount FROM HC.EventMessage em WHERE em.id = @messageId;

    -- Update sender's own badge count (sender never sees their own message as unread)
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @eventId, @messageSequenceCount)) AS Source (UserId, EventId, LastSequenceCount)
    ON (Target.UserId = Source.UserId AND Target.EventId = Source.EventId)
    WHEN MATCHED THEN
        UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, EventId, LastSequenceCount)
        VALUES (Source.UserId, Source.EventId, Source.LastSequenceCount);

    COMMIT TRANSACTION;

-- ---------------------------------------------------------------
-- Rowset 0: message detail
-- ---------------------------------------------------------------
DECLARE @sendToMismanagement SMALLINT = @messageReleasabilityFlags & 0x0001;
DECLARE @sendToMembers       SMALLINT = @messageReleasabilityFlags & 0x0002;
DECLARE @sendToFollowers     SMALLINT = @messageReleasabilityFlags & 0x0004;
DECLARE @sendToRsvps         SMALLINT = @messageReleasabilityFlags & 0x0008;
DECLARE @sendToHares         SMALLINT = @messageReleasabilityFlags & 0x0010;
DECLARE @sendToEveryone      SMALLINT = @messageReleasabilityFlags & 0x0020;

SELECT
    msg.id                                                 AS MessageId,
    msg.EventId                                            AS EventId,
    msg.PublicEventId                                      AS PublicEventId,
    h.PublicHasherId                                       AS UserId,
    h.DisplayName                                          AS UserDisplayName,
    h.Photo                                                AS UserPhoto,
    h.DisplayName + ' - ' + msg.MessageTitle               AS MessageTitle,
    msg.MessageContent                                     AS MessageContent,
    msg.MessageReleasabilityFlags                          AS MessageReleasabilityFlags,
    0                                                      AS EventChatMessageCount,
    msg.MessageType                                        AS MessageType
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.id = @messageId AND msg.removed = 0 AND h.Removed = 0;

-- ---------------------------------------------------------------
-- Push recipients (rewritten 2026-09-17 — James: "they are going to way
-- too many people").
--
-- WHO. Only a hasher who actually CHOSE a notification setting. The
-- effective preference is the event override, else the kennel setting.
-- 0 means "never touched it" and is NOT consent — it is not even a choice
-- the bell offers. This is the same gate nonApi_checkReminders has always
-- used (`IN (1, 3, 4)`); chat was the outlier, treating 0 as yes and so
-- pushing the whole kennel roster for every message.
--     1 on              -> visible push
--     4 on before run   -> visible inside the run window, silent outside
--     3 on but muted    -> silent push, so the badge still moves
--     0 never set, 2 off-> nothing at all
--
-- WHERE. One push per DEVICE, not per device row. A hasher accumulates
-- device rows (re-authorisation mints a new one whenever the keychain
-- entry is lost), and every row kept its own live token: one hasher was
-- getting 43 copies of a single message. So DISTINCT on the token, skip
-- retired rows, and skip devices that have not signed in for 180 days
-- (James's cut-off; the next sign-in re-arms them automatically).
-- ---------------------------------------------------------------
DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());

SELECT DISTINCT
    hkm.UserId,
    device.FcmToken,
    COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference, 0) AS Pref
INTO #pushAudience
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Hasher h      ON h.id          = hkm.UserId
INNER JOIN HC.Device device ON device.UserId = hkm.UserId
LEFT OUTER JOIN HC.HasherEventMap hem ON hem.EventId = @eventId AND hem.UserId = hkm.UserId
WHERE hkm.KennelId = @kennelId
  AND hkm.removed  = 0
  AND h.Removed    = 0
  AND device.FcmToken IS NOT NULL
  AND device.removed   = 0
  AND device.LastLogin >= @idleCutoff
  AND COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference, 0) IN (1, 3, 4)
  AND (
      @sendToEveryone      != 0
   OR (@sendToMismanagement != 0 AND hkm.MismanagementRoles  != 0)
   OR (@sendToMembers       != 0 AND hkm.MembershipExpirationDate > GETDATE())
   OR (@sendToFollowers     != 0 AND hkm.Following = 1)
   OR (@sendToRsvps         != 0 AND hem.RsvpState >= 2)
   OR (@sendToHares         != 0 AND hem.IsHare    != 0)
  );

-- ---------------------------------------------------------------
-- Rowset 1: visible push notification recipients
-- ---------------------------------------------------------------
SELECT DISTINCT UserId, FcmToken
FROM #pushAudience
WHERE Pref = 1
   OR (Pref = 4 AND @isWithinWindow = 1);

-- ---------------------------------------------------------------
-- Rowset 2: silent (data-only) recipients — badge moves, nothing buzzes.
-- "On but muted", and "on before the run" while the run is still far off.
-- ---------------------------------------------------------------
SELECT DISTINCT UserId, FcmToken
FROM #pushAudience
WHERE Pref = 3
   OR (Pref = 4 AND @isWithinWindow = 0);

DROP TABLE #pushAudience;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID(); SET @errorType = 5; SET @errorCode = 9999;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Runtime error in hcapp_sendEventMessage', ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Message send failed' AS errorTitle,
           'Your message could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
