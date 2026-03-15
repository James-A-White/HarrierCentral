CREATE OR ALTER PROCEDURE [HC6].[hcportal_sendEventMessage]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicEventId uniqueidentifier = NULL,
@messageId uniqueidentifier = NULL,
@messageTitle nvarchar(250) = NULL,
@messageContent nvarchar(500) = NULL,
@messageReleasabilityFlags int = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_sendEventMessage
-- Description: Sends a message to event participants based on
--   releasability flags (admins, members, followers, RSVPs, hares,
--   everyone). Inserts into HC.EventMessage and returns the message
--   details along with FCM tokens for users who should receive full
--   push notifications (rowset 1) and in-app-only notifications
--   (rowset 2). Notification preferences and time windows are
--   considered.
-- Parameters: @publicHasherId, @accessToken, @publicEventId,
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
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

-- Auth validation
DECLARE @authError NVARCHAR(255);
EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @publicEventId, @authError OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
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
        IF (@messageReleasabilityFlags IS NULL OR (@messageReleasabilityFlags & 0x0000000f) = 0) SET @errorDetail = @errorDetail + 'Message Releasability Flags ';

        SET @errorDetail = REPLACE(TRIM(@errorDetail), ' ', ', ');

        SELECT 0 AS Success, 'Missing or empty fields: ' + @errorDetail AS ErrorMessage;
        RETURN;
END

DECLARE @hasherId uniqueidentifier;
SELECT @hasherId = id FROM HC.Hasher WHERE PublicHasherId = @publicHasherId;

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

    IF (ABS(DATEDIFF(minute, GETDATE(), @eventStartDateTimeInUtc)) <= (@timeLimitForNotificationsInHours * 60))
    BEGIN
        SET @isEventWithinTimeLimitForNotifications = 1;
    END

    -- Default messageTitle to event name if still NULL
    IF (@messageTitle IS NULL)
    BEGIN
        SELECT @messageTitle = evt.EventName FROM HC.Event evt WHERE evt.id = @eventId;
    END

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

    -- Rowset 1: FullPushNotificationRecipients
    -- Notification preference flags:
    --   1 = Always On
    --   2 = Off
    --   4 = On 6 hours before run
    --   3 = On but muted
    SELECT
        hkm.UserId as UserId,
        device.FcmToken as FcmToken
        INTO #tempMessageOn
    FROM HC.HasherKennelMap hkm
    INNER JOIN HC.Hasher h ON hkm.UserId = h.id
    INNER JOIN HC.Event evt ON evt.id = @eventId
    INNER JOIN HC.Device device ON device.UserId = h.id
    LEFT OUTER JOIN HC.HasherEventMap hem ON hem.EventId = evt.id AND hem.UserId = h.id
    WHERE evt.id = @eventId
    AND
    (
        (COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference) = 1) -- always send notifications
        OR
        (
            -- only send full notifications when within the time window
            (COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference) = 4) AND (@isEventWithinTimeLimitForNotifications = 1)
        )
    )
    AND hkm.KennelId = @kennelId
    AND device.FcmToken IS NOT NULL
        AND
          (@sendToEveryone != 0
              OR (@sendToMismanagement != 0 AND hkm.MismanagementRoles != 0)
              OR (@sendToMembers != 0 AND hkm.MembershipExpirationDate > GETDATE())
              OR (@sendToFollowers != 0 AND hkm.Following = 1)
              OR (@sendToRsvps != 0 AND hem.RsvpState >= 2 AND COALESCE(hem.EventNotificationPreference, 1) != 0)
              OR (@sendToHares != 0 AND hem.IsHare != 0 AND COALESCE(hem.EventNotificationPreference, 1) != 0)
          )

    SELECT * FROM #tempMessageOn;

    -- Rowset 2: InAppOnlyNotificationRecipients
    -- Everyone associated with a Kennel who did not qualify for a full push notification.
    -- They will receive an in-app notification so they can see the chat updating in realtime.
    SELECT
        hkm.UserId,
        device.FcmToken
    FROM HC.HasherKennelMap hkm
    INNER JOIN HC.Device device ON hkm.UserId = device.UserId
    LEFT OUTER JOIN #tempMessageOn t ON hkm.UserId = t.UserId
    WHERE hkm.KennelId = @kennelId AND (hkm.Following != 0 OR hkm.MembershipExpirationDate > GETDATE())
    AND device.FcmToken IS NOT NULL
    AND t.UserId IS NULL;

    DROP TABLE #tempMessageOn;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
