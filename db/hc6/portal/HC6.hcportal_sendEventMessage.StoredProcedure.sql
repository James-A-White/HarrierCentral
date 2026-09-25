CREATE OR ALTER PROCEDURE [HC6].[hcportal_sendEventMessage]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicEventId uniqueidentifier = NULL,
@messageId uniqueidentifier = NULL,
@messageTitle nvarchar(250) = NULL,
@messageContent nvarchar(MAX) = NULL,
@messageReleasabilityFlags int = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_sendEventMessage
-- Description: Sends a message to event participants based on
--   releasability flags (admins, members, followers, RSVPs, hares,
--   everyone). Inserts into HC.EventMessage and returns the message
--   details along with FCM tokens for users who should receive full
--   push notifications (rowset 1) and in-app-only notifications
--   (rowset 2). Notification preferences and a 6-hour event proximity
--   window gate full push delivery.
-- Parameters: @deviceId, @accessToken, @publicEventId,
--   @messageId, @messageTitle, @messageContent,
--   @messageReleasabilityFlags
-- Returns: On error: HC6 standard envelope (Success, ErrorMessage).
--   On success: MessageDetails rowset, FullPushNotificationRecipients
--   rowset, InAppOnlyNotificationRecipients rowset.
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_sendEventMessage
-- Breaking Changes:
--   Removed EventChatMessageCount from MessageDetails rowset (obsolete).
--   Fixed LOG.GeneralLog LogSource from 'hcportal_getKennelHashers' to
--   'hcportal_sendEventMessage'. Validation now short-circuits on first
--   error. Added XACT_ABORT, TRY/CATCH, and transaction around
--   EventMessage INSERT. Removed commented-out debug code.
--   Auth validated via HC6.ValidatePortalAuth helper SP.
--   Removed @ipAddress, @ipGeoDetails (logging moved to API shim).
--   Removed ErrorLog/GeneralLog inserts (logging moved to API shim).
--   All error returns now use HC6 standard envelope (Success, ErrorMessage).
--   @publicHasherId replaced by @deviceId (device-bound auth via HC.Device lookup)
-- Bug Fixes (post-migration):
--   PublicHasherId was hardcoded NULL in INSERT — now resolved from HC.Hasher.
--   Added NULL guard on @eventId after event lookup (event not found now
--     returns a clean error instead of a constraint violation).
--   Service accounts now rejected unconditionally (@callerType check added).
--   Releasability flag mask in error-detail builder corrected from 0x0f to
--     0x3f to match the outer validation check.
--   Removed redundant second @messageTitle fallback (COALESCE in event SELECT
--     already handles it; second query was dead code).
--   Removed redundant WHERE evt.id = @eventId in temp table query (already
--     enforced by the INNER JOIN condition).
--   Sender excluded from Rowset 1 (full push) — sender should not receive
--     a visible banner for their own message. Sender now falls into Rowset 2
--     (silent data-only FCM) so the portal can use the echo to confirm
--     double-tick delivery.
--   2026-09-25: push audience brought in line with hcapp_sendEventMessage
--     (the 2026-09-17 fan-out fix never reached this SP). Preference 0 no
--     longer counts as "on"; one push per device token; retired and
--     180-day-idle devices skipped; deleted hashers (Hasher.Removed = 1)
--     and removed kennel links skipped. Rowsets 1 and 2 keep their columns
--     (UserId, DisplayName, FcmToken). The CATCH now logs to HC.ErrorLog.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

-- Auth validation
DECLARE @authError NVARCHAR(255);
DECLARE @hasherId UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
-- Compound callerParamString binds the token to the specific event AND message,
-- preventing a captured token from being replayed for a different message.
-- Flutter caller must use paramString: '$deviceSecret:$publicEventId:$messageId'.
DECLARE @msgCallerParam NVARCHAR(73) =
    CAST(@publicEventId AS NVARCHAR(36)) + ':' + CAST(@messageId AS NVARCHAR(36));
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName,
    @msgCallerParam,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

-- Reject service accounts
IF @callerType != 0
BEGIN
    SELECT 0 AS Success, 'Service accounts may not send event messages' AS ErrorMessage;
    RETURN;
END

-- Validate publicEventId
IF (@publicEventId IS NULL)
BEGIN
        SELECT 0 AS Success, 'publicEventId is required' AS ErrorMessage;
        RETURN;
END

-- Validate messageId
IF (@messageId IS NULL)
BEGIN
        SELECT 0 AS Success, 'messageId is required' AS ErrorMessage;
        RETURN;
END

-- Validate message content and releasability flags
IF (
        @messageContent IS NULL
        OR LEN(@messageContent) = 0
        OR @messageReleasabilityFlags IS NULL
        OR (@messageReleasabilityFlags & 0x0000003f) = 0)
BEGIN
        DECLARE @errorDetail nvarchar(1000);
        SET @errorDetail = '';
        IF (@messageContent IS NULL OR LEN(@messageContent) = 0) SET @errorDetail = 'Message Content ';
        IF (@messageReleasabilityFlags IS NULL OR (@messageReleasabilityFlags & 0x0000003f) = 0) SET @errorDetail = @errorDetail + 'Message Releasability Flags ';

        SET @errorDetail = REPLACE(TRIM(@errorDetail), ' ', ', ');

        SELECT 0 AS Success, 'Missing or empty fields: ' + @errorDetail AS ErrorMessage;
        RETURN;
END

-- The column is NVARCHAR(4000) since 2026-09-23 and this parameter is MAX so
-- that an over-long message is REFUSED, not cut: an NVARCHAR(500) parameter
-- silently truncated the first admin-room announcement at exactly 500
-- characters, with no error and no log (James, 2026-09-23). LEN counts
-- UTF-16 code units, the same measure the column enforces.
IF (LEN(@messageContent) > 4000)
BEGIN
        SELECT 0 AS Success,
               CONCAT('Messages can be up to 4,000 characters; this one is ', LEN(@messageContent),
                      '. Please shorten it and send again.') AS ErrorMessage;
        RETURN;
END

    DECLARE @timeLimitForNotificationsInHours smallint = 6;

    DECLARE @eventId uniqueidentifier,
            @kennelId uniqueidentifier,
            @eventStartDateTimeInUtc datetimeoffset(7),
            @isEventWithinTimeLimitForNotifications smallint = 0;

    SELECT
        @eventId = evt.id,
        @kennelId = evt.KennelId,
        @messageTitle = COALESCE(@messageTitle, evt.EventName),
        @eventStartDateTimeInUtc = (CAST(evt.EventStartDatetime AS datetime) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC'
    FROM HC.Event evt
    INNER JOIN HC.Kennel k ON k.id = evt.KennelId
    INNER JOIN HC.City c ON k.CityId = c.id
    INNER JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
    WHERE PublicEventId = @publicEventId;

    -- Guard: event must exist
    IF @eventId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Event not found' AS ErrorMessage;
        RETURN;
    END

    IF (ABS(DATEDIFF(minute, GETDATE(), @eventStartDateTimeInUtc)) <= (@timeLimitForNotificationsInHours * 60))
    BEGIN
        SET @isEventWithinTimeLimitForNotifications = 1;
    END

    -- Resolve the caller's public hasher ID
    DECLARE @publicHasherId UNIQUEIDENTIFIER;
    SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @hasherId;

    -- Insert the message inside a transaction
    BEGIN TRANSACTION;

    INSERT INTO [HC].[EventMessage]
                  (
                    [id]
                  , [EventId]
                  , [PublicEventId]
                  , [UserId]
                  , [PublicHasherId]
                  , [MessageTitle]
                  , [MessageContent]
                  , [MessageReleasabilityFlags]
                  )
          VALUES
                  (
                    @messageId
                  , @eventId
                  , @publicEventId
                  , @hasherId
                  , @publicHasherId
                  , @messageTitle
                  , @messageContent
                  , @messageReleasabilityFlags
                  );

    COMMIT TRANSACTION;

    -- Decode releasability bit flags
    DECLARE @sendToHares smallint = @messageReleasabilityFlags & 0x0010,
            @sendToEveryone smallint = @messageReleasabilityFlags & 0x0020,
            @sendToMismanagement smallint  = @messageReleasabilityFlags & 0x0001,
            @sendToMembers smallint  = @messageReleasabilityFlags & 0x0002,
            @sendToFollowers smallint = @messageReleasabilityFlags & 0x0004,
            @sendToRsvps smallint = @messageReleasabilityFlags & 0x0008;

    -- Rowset 0: MessageDetails
    SELECT
          msg.[id] as MessageId
        , [EventId] as EventId
        , [PublicEventId] as PublicEventId
        , h.PublicHasherId as UserId
        , h.DisplayName as UserDisplayName
        , h.Photo as UserPhoto
        , h.DisplayName + ' - ' + [MessageTitle] as MessageTitle
        , [MessageContent] as MessageContent
        , [MessageReleasabilityFlags] as MessageRelesabilityFlags
        , msg.[MessageType] as MessageType
    FROM HC.EventMessage msg
    INNER JOIN HC.Hasher h ON msg.UserId = h.id
    WHERE msg.id = @messageId AND msg.removed = 0 AND h.Removed = 0;

    -- ---------------------------------------------------------------
    -- Push audience — the same rules as HC6.hcapp_sendEventMessage, which
    -- this SP had drifted from (brought back in line 2026-09-25):
    --
    -- Preference. Effective = event-level override when non-zero, else
    -- the kennel preference (NULLIF: event 0 means "no override").
    --     1 on               -> visible push
    --     4 on before run    -> visible inside the 6-hour window, silent outside
    --     3 on but muted     -> silent push, so the badge still moves
    --     0 never set, 2 off -> nothing
    -- This SP used to treat 0 as "on", and 0 is what every follower who
    -- never touched the bell has, so each portal message pushed the whole
    -- roster. The app SPs stopped doing that on 2026-09-17.
    --
    -- WHERE. One push per DEVICE (DISTINCT on the token) rather than per
    -- device row — a hasher accumulates rows and each kept a live token,
    -- one hasher got 43 copies of one message — skipping retired rows and
    -- devices idle 180 days. Deleted hashers (Hasher.Removed = 1) and
    -- removed kennel links are left out: gdprDelete left their tokens live.
    --
    -- The sender never gets a visible banner for their own message. Their
    -- devices get the silent echo that confirms delivery whenever they follow
    -- or belong to the kennel and have not switched it off — as before.
    -- ---------------------------------------------------------------
    DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());

    SELECT DISTINCT
        hkm.UserId,
        h.DisplayName,
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
      AND (
          (    COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference, 0) IN (1, 3, 4)
           AND (
               @sendToEveryone      != 0
            OR (@sendToMismanagement != 0 AND hkm.MismanagementRoles  != 0)
            OR (@sendToMembers       != 0 AND hkm.MembershipExpirationDate > GETDATE())
            OR (@sendToFollowers     != 0 AND hkm.Following = 1)
            OR (@sendToRsvps         != 0 AND hem.RsvpState >= 2)
            OR (@sendToHares         != 0 AND hem.IsHare    != 0)
           ))
          -- The sender's own devices, for the silent delivery echo, unless
          -- they switched this kennel off (the old rule, kept).
       OR (    hkm.UserId = @hasherId
           AND COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference, 0) != 2
           AND (hkm.Following != 0 OR hkm.MembershipExpirationDate > GETDATE()))
      );

    -- Rowset 1: FullPushNotificationRecipients — visible banner.
    SELECT DISTINCT UserId, DisplayName, FcmToken
    FROM #pushAudience
    WHERE UserId != @hasherId
      AND (Pref = 1 OR (Pref = 4 AND @isEventWithinTimeLimitForNotifications = 1));

    -- Rowset 2: InAppOnlyNotificationRecipients — silent, the badge moves.
    -- A token already in rowset 1 is not sent a second, silent copy.
    SELECT DISTINCT a.UserId, a.DisplayName, a.FcmToken
    FROM #pushAudience a
    WHERE (a.UserId = @hasherId
           OR a.Pref = 3
           OR (a.Pref = 4 AND @isEventWithinTimeLimitForNotifications = 0))
      AND NOT EXISTS (
          SELECT 1 FROM #pushAudience v
          WHERE v.FcmToken = a.FcmToken
            AND v.UserId  != @hasherId
            AND (v.Pref = 1 OR (v.Pref = 4 AND @isEventWithinTimeLimitForNotifications = 1)));

    DROP TABLE #pushAudience;

END TRY
BEGIN CATCH
    -- Roll back FIRST, then log: a log row written inside the transaction
    -- would be erased by the rollback.
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_sendEventMessage',
            ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
