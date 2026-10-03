CREATE OR ALTER PROCEDURE [HC6].[nonApi_checkReminders]
AS
-- =====================================================================
-- Procedure: HC6.nonApi_checkReminders
-- Description: Checks for events that are within the check-in reminder
--   window (±11 minutes from start) or RSVP reminder window (±3 days
--   from start) and have not yet had their reminder sent. Returns two
--   rowsets consumed by RunCheckInNotification to dispatch FCM pushes:
--     Rowset 0 — event message details (one row per qualifying event).
--     Rowset 1 — recipients to push (FCM token + EventId).
--   Then stamps CheckInReminderSent / RsvpReminderSent on HC.Event so
--   reminders are not re-sent on the next timer tick.
--   Called by the RunCheckInNotification timer trigger (every 1 minute).
-- Parameters: None. The @apiKey guard from HC5 is removed — the timer
--   trigger runs inside Azure Functions and is not publicly accessible.
-- Returns:
--   Rowset 0: { MessageId, EventId, PublicEventId, UserId,
--               UserDisplayName, UserPhoto, MessageTitle, MessageContent,
--               MessageRelesabilityFlags (typo preserved for C# compat),
--               EventChatMessageCount (obsolete, kept for compat),
--               MessageType }
--   Rowset 1: { UserId, FcmToken, EventId, MessageId }
--   Returns empty rowsets (no rows) when no reminders are due.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC5.hcinternalapi_checkReminders
-- Breaking Changes vs HC5:
--   @apiKey parameter and hardcoded-key guard removed (internal trigger).
--   LOG.GeneralLog startup write removed (noise; timer runs every minute).
--   UPDATE HC.Event wrapped in TRY/CATCH to prevent reminder stampings
--   from aborting on transient errors.
--   Temp tables dropped in CATCH to prevent session leaks on retry.
--   2026-09-25: recipients skip deleted hashers (Hasher.Removed = 1) and
--     removed kennel links (HasherKennelMap.removed = 1), as the chat SPs do.
--   2026-10-03 (E5.F1.S10, James): MessageType 3 "get PackTrack ready" —
--     at the check-in moment, a hasher who said RSVP Yes or is already
--     checked in gets THIS instead of the generic check-in reminder. Its
--     tap opens Live Run, arms auto start, and checks them in if they are
--     at the start. Only devices on build >= @minBuildPreRun get it: older
--     apps read an unknown MessageType as chat. Recipients carry MessageId
--     and the API matches on it, because one run now has two messages.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @checkInWindowMinutes INT = 10;
DECLARE @rsvpWindowMinutes    INT = 4320; -- 3 days
DECLARE @radiusKm             INT = 100;
DECLARE @minBuildPreRun       INT = 1439; -- first app build that handles MessageType 3

-- -----------------------------------------------------------------------
-- Step 1: Collect events within their reminder windows that haven't had
--         a reminder sent yet. MessageType 1 = check-in, 2 = RSVP.
-- -----------------------------------------------------------------------
SELECT
    DATEDIFF(minute, GETDATE(),
             evt.EventStartDateTimeGmt)
                            AS minutesToEvent,
    ken.KennelName,
    ken.id                  AS KennelId,
    evt.PublicEventId,
    evt.id                  AS EventId,
    evt.SyncLatitude        AS lat,
    evt.SyncLongitude       AS lon,
    evt.EventName,
    1                       AS MessageType,
    'checkin'               AS action
INTO #events
FROM HC.Event evt
JOIN HC.Kennel ken         ON ken.id  = evt.KennelId
JOIN HC.City c             ON c.id    = ken.CityId
JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
WHERE evt.EventStartDateTimeGmt
      BETWEEN DATEADD(minute, -(@checkInWindowMinutes + 1), GETDATE())
          AND DATEADD(minute,  (@checkInWindowMinutes + 1), GETDATE())
  AND evt.IsVisible           = 1
  AND evt.deleted              = 0
  AND evt.removed              = 0
  AND evt.CheckInReminderSent IS NULL

UNION ALL

SELECT
    DATEDIFF(minute, GETDATE(),
             evt.EventStartDateTimeGmt),
    ken.KennelName,
    ken.id,
    evt.PublicEventId,
    evt.id,
    evt.SyncLatitude,
    evt.SyncLongitude,
    evt.EventName,
    2,
    'rsvp'
FROM HC.Event evt
JOIN HC.Kennel ken         ON ken.id  = evt.KennelId
JOIN HC.City c             ON c.id    = ken.CityId
JOIN DomainValues.Timezone tz ON tz.id = c.TimezoneId
WHERE evt.EventStartDateTimeGmt
      BETWEEN DATEADD(minute, -(@rsvpWindowMinutes + 1), GETDATE())
          AND DATEADD(minute,  (@rsvpWindowMinutes + 1), GETDATE())
  AND evt.RsvpReminderSent IS NULL
  AND evt.IsVisible        = 1
  AND evt.deleted          = 0
  AND evt.removed          = 0
  AND evt.removed           = 0;

-- -----------------------------------------------------------------------
-- Step 2: Build the message payload for each qualifying event.
--         Only forward-facing events (minutesToEvent > 0) get a push.
-- -----------------------------------------------------------------------
SELECT
    NEWID()                 AS id,
    e.EventId,
    e.PublicEventId,
    '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
                            AS UserId, -- HC system user
    'B6BAFD0D-5D2E-41CD-8495-811D551F01D0'
                            AS PublicHasherId,
    CASE e.MessageType
        WHEN 1 THEN 'Time to check in'
        WHEN 2 THEN 'Time to RSVP'
        ELSE        'Unknown message type'
    END                     AS MessageTitle,
    CASE e.MessageType
        WHEN 1 THEN
            '"' + e.EventName + '" is about to start. If you will be joining the run today, tap this notification to open Harrier Central to check yourself in.'
        WHEN 2 THEN
            '"' + e.EventName + '" will start in ' +
            CASE
                WHEN e.minutesToEvent <   60 THEN CAST(e.minutesToEvent       AS NVARCHAR(50)) + ' minutes. '
                WHEN e.minutesToEvent <  120 THEN '1 hour. '
                WHEN e.minutesToEvent < 1440 THEN CAST(e.minutesToEvent / 60  AS NVARCHAR(50)) + ' hours. '
                WHEN e.minutesToEvent < 2880 THEN '1 day. '
                ELSE                              CAST(e.minutesToEvent / 1440 AS NVARCHAR(50)) + ' days. '
            END +
            'If you will be joining the run, tap this notification to RSVP so the Hares know how much beer to bring.'
        ELSE 'Unknown message type'
    END                     AS MessageContent,
    65535                   AS MessageReleasabilityFlags,
    e.MessageType,
    e.KennelId,
    e.lat,
    e.lon
INTO #messages
FROM #events e
WHERE e.minutesToEvent > 0;

-- The pre-run "get PackTrack ready" message (MessageType 3), one per run in
-- the check-in window, for the hashers who said Yes or are checked in.
INSERT #messages (id, EventId, PublicEventId, UserId, PublicHasherId, MessageTitle,
                  MessageContent, MessageReleasabilityFlags, MessageType, KennelId, lat, lon)
SELECT NEWID(), e.EventId, e.PublicEventId,
       '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC', 'B6BAFD0D-5D2E-41CD-8495-811D551F01D0',
       N'Get PackTrack ready',
       N'"' + e.EventName + N'" starts in ' + CAST(e.minutesToEvent AS NVARCHAR(10))
         + N' minutes. Tap to arm auto start: your trail starts by itself when you set off.',
       65535, 3, e.KennelId, e.lat, e.lon
FROM #events e
WHERE e.minutesToEvent > 0 AND e.MessageType = 1;

-- -----------------------------------------------------------------------
-- Step 3: Rowset 0 — message details for FCM payload construction.
--         MessageRelesabilityFlags column name preserves the HC5 typo
--         so the C# EventMessage deserialiser continues to work.
-- -----------------------------------------------------------------------
SELECT
    msg.id                              AS MessageId,
    msg.EventId,
    msg.PublicEventId,
    h.PublicHasherId                    AS UserId,
    h.DisplayName                       AS UserDisplayName,
    h.Photo                             AS UserPhoto,
    msg.MessageTitle,
    msg.MessageContent,
    msg.MessageReleasabilityFlags       AS MessageRelesabilityFlags,
    0                                   AS EventChatMessageCount, -- obsolete since 2.1.3
    msg.MessageType
FROM #messages msg
JOIN HC.Hasher h ON h.id = msg.UserId;

-- -----------------------------------------------------------------------
-- Step 4: Rowset 1 — recipients who should receive the push.
--         Check-in (type 1): only within @radiusKm of the event and
--         not already checked in. RSVP (type 2): any token holder who
--         hasn't RSVPd, no geo-fence applied.
-- -----------------------------------------------------------------------
DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());

SELECT hkm.UserId, d.FcmToken, msg.EventId, msg.id AS MessageId
FROM #messages msg
JOIN HC.HasherKennelMap hkm ON hkm.KennelId = msg.KennelId
JOIN HC.Hasher hs           ON hs.id         = hkm.UserId
JOIN HC.Device d            ON d.UserId      = hkm.UserId
LEFT JOIN HC.HasherEventMap hem
                             ON hem.UserId   = hkm.UserId
                            AND hem.EventId  = msg.EventId
WHERE COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference, 0) IN (1, 3, 4)
  -- One reminder per DEVICE, not per device row: a hasher accumulates rows
  -- and each kept a live token. Retired rows and devices that have not
  -- signed in for 180 days are skipped; the next sign-in re-arms them
  -- (James, 2026-09-17). UNION below also de-duplicates the token.
  -- Deleted hashers and removed kennel links get no reminders
  -- (2026-09-25): gdprDelete used to leave their tokens live.
  AND hs.Removed    = 0
  AND hkm.removed   = 0
  AND d.FcmToken   IS NOT NULL
  AND d.removed     = 0
  AND d.LastLogin  >= @idleCutoff
  AND msg.lat      IS NOT NULL
  AND d.Latitude   IS NOT NULL
  AND COALESCE(hem.AttendenceState, 0) < 20
  AND msg.MessageType = 1
  AND d.GeoPoint.STDistance(GEOGRAPHY::Point(msg.lat, msg.lon, 4326)) <= (@radiusKm * 1000)
  -- Said Yes on a build that understands MessageType 3: they get that instead.
  AND NOT (COALESCE(hem.RsvpState, 0) = 3 AND TRY_CAST(d.BuildNumber AS INT) >= @minBuildPreRun)

UNION

-- MessageType 3: everyone who said RSVP Yes (3) or is checked in (>= 20),
-- unless they switched this run or kennel OFF (2). Unlike the generic
-- reminder an unset bell (0) is no bar — they told us they are coming —
-- and there is no 100 km fence: a "get ready" nudge is about THEIR run.
SELECT hkm.UserId, d.FcmToken, msg.EventId, msg.id
FROM #messages msg
JOIN HC.HasherKennelMap hkm ON hkm.KennelId = msg.KennelId
JOIN HC.Hasher hs           ON hs.id         = hkm.UserId
JOIN HC.Device d            ON d.UserId      = hkm.UserId
JOIN HC.HasherEventMap hem  ON hem.UserId    = hkm.UserId
                           AND hem.EventId   = msg.EventId
WHERE msg.MessageType = 3
  AND (hem.RsvpState = 3 OR hem.AttendenceState >= 20)
  AND ISNULL(hem.removed, 0) = 0
  AND COALESCE(NULLIF(hem.EventNotificationPreference, 0), hkm.KennelNotificationPreference, 0) <> 2
  AND hs.Removed  = 0
  AND hkm.removed = 0
  AND d.FcmToken IS NOT NULL
  AND d.removed    = 0
  AND d.LastLogin >= @idleCutoff
  AND TRY_CAST(d.BuildNumber AS INT) >= @minBuildPreRun

UNION

SELECT hkm.UserId, d.FcmToken, msg.EventId, msg.id
FROM #messages msg
JOIN HC.HasherKennelMap hkm ON hkm.KennelId = msg.KennelId
JOIN HC.Hasher hs           ON hs.id         = hkm.UserId
JOIN HC.Device d            ON d.UserId      = hkm.UserId
LEFT JOIN HC.HasherEventMap hem
                             ON hem.UserId   = hkm.UserId
                            AND hem.EventId  = msg.EventId
WHERE COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference, 0) IN (1, 3, 4)
  AND COALESCE(hem.RsvpState, 0) < 1
  AND msg.MessageType = 2
  AND hs.Removed  = 0
  AND hkm.removed = 0
  AND d.FcmToken IS NOT NULL
  AND d.removed    = 0
  AND d.LastLogin >= @idleCutoff;

-- -----------------------------------------------------------------------
-- Step 5: Stamp reminder-sent timestamps on HC.Event so these events
--         are not re-processed on the next timer tick.
-- -----------------------------------------------------------------------
BEGIN TRY
    UPDATE evt
    SET
        evt.CheckInReminderSent = CASE WHEN e.MessageType = 1 THEN GETDATE() ELSE evt.CheckInReminderSent END,
        evt.RsvpReminderSent    = CASE WHEN e.MessageType = 2 THEN GETDATE() ELSE evt.RsvpReminderSent    END
    FROM HC.Event evt
    JOIN #events e ON e.EventId = evt.id;
END TRY
BEGIN CATCH
    -- Log the stamp failure but do not abort — the rowsets have already
    -- been returned and pushes will fire. A missed stamp causes a
    -- duplicate reminder on the next tick, which is preferable to
    -- swallowing the error silently and blocking the entire timer run.
    INSERT INTO HC.ErrorLog
        (HcVersion, ErrorName, ErrorDescription, ProcName)
    VALUES
        ('HC6', 'nonApi_checkReminders stamp failed',
         ERROR_MESSAGE(), 'HC6.nonApi_checkReminders');
END CATCH;

DROP TABLE IF EXISTS #messages;
DROP TABLE IF EXISTS #events;
