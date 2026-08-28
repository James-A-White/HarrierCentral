CREATE OR ALTER PROCEDURE [HC6].[hcapp_getEventBadgeCount]

    @deviceId            UNIQUEIDENTIFIER,
    @accessToken         NVARCHAR(1000),
    @publicEventId       UNIQUEIDENTIFIER = NULL,
    @resetBadgeCount     INT              = 0,
    @resetAllBadgeCounts INT              = 0

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getEventBadgeCount
-- Description: Returns the badge count (unread message count) for one
--   event or all events. Optionally resets the count by updating the
--   LastSequenceCount watermark in HC.EventMessageBadgeCounts.
--
--   Modes:
--     @resetAllBadgeCounts != 0  → reset all events to current max,
--       return { 0, '00000000-...' }
--     @publicEventId provided     → query/reset a specific event's count
--     Neither provided            → return counts for all events where
--       the user has a badge count row
--
--   @resetBadgeCount only applies when @publicEventId is provided.
-- Parameters:
--   @deviceId            - Registered device UUID
--   @accessToken         - Token validated against DeviceSecret
--   @publicEventId       - Public event UUID to query/reset (optional)
--   @resetBadgeCount     - 1 = update LastSequenceCount for this event
--   @resetAllBadgeCounts - 1 = reset ALL event badge counts to current max
-- Returns:
--   Read SP (no success envelope — always returns a count row).
--   Modes 1 & 2 (rowset 0): { BadgeCount, PublicEventId }
--   Mode 3 all-events (rowset 0): one row per run thread the user can see
--     that has ANY messages, PLUS one row per followed kennel thread that
--     has ANY messages —
--     { BadgeCount, PublicEventId, EventId, EventName, EventNumber,
--       EventStartDatetimeGmt, EventImage, KennelId, PublicKennelId,
--       KennelShortName, KennelLogo, MessageCount }. Extra columns let the
--     app render the Unseen Chats list for events that aren't locally
--     synced. First two columns unchanged. Rows may carry BadgeCount = 0
--     (fully read, or notifications set to ignore for that thread) —
--     MessageCount tells the run/kennel card whether the thread has content
--     at all (2026-08-28).
--   Unread rules (both thread kinds, 2026-08-28):
--     * A thread surfaces as unread BEFORE the user first opens it — no
--       badge row ⇒ every message is unread.
--     * BadgeCount is forced to 0 when the user's effective notification
--       preference for the thread is ignore (2). Effective preference uses
--       the same NULLIF/COALESCE rule as the push-dispatch SPs:
--       COALESCE(NULLIF(hem.EventNotificationPreference, 0),
--                hkm.KennelNotificationPreference, 0). Silver Bell (mute=3)
--       still badges — in-app only is exactly what a badge is.
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getEventBadgeCount
-- Breaking Changes:
--   Token standardised to DeviceSecret only (HC5 had dead code for
--     event-bound compound token that was commented out).
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
    @spNumber     = 63,
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

IF (@publicEventId = '00000000-0000-0000-0000-000000000000') SET @publicEventId = NULL;

-- Wrap the body so any runtime error (timeout, deadlock, transient) is LOGGED to
-- HC.ErrorLog before it reaches the client. This SP previously had no TRY/CATCH,
-- so the HTTP 500s seen in the client log harvest left NO server-side record and
-- were undiagnosable. The CATCH re-raises (THROW) rather than returning an error
-- envelope on purpose: the caller (NotificationService background badge poll)
-- passes no errorCallback, so an envelope would trigger sendHttpPost's automatic
-- "Close" alert on a background poll. Re-raising preserves today's behaviour
-- (silent retry, no dialog, badges untouched) while giving us the error text.
BEGIN TRY

-- ---------------------------------------------------------------
-- Mode 1: reset all badge counts (event AND kennel threads)
-- ---------------------------------------------------------------
IF (@resetAllBadgeCounts != 0)
BEGIN
    -- Advance every EXISTING badge row to the current max sequence for its
    -- thread. Event rows key on EventId; kennel-thread rows have EventId IS NULL
    -- and key on KennelId, so the max must be resolved from the matching scope.
    -- COALESCE(..., embc.LastSequenceCount) guards the NOT NULL column against
    -- threads with no (remaining) messages — a bare subquery returns NULL there
    -- and previously threw a constraint violation for kennel-thread rows.
    UPDATE embc SET
        embc.LastSequenceCount = COALESCE(
            CASE
                WHEN embc.EventId IS NOT NULL THEN
                    (SELECT MAX(em.MessageSequenceCount)
                     FROM HC.EventMessage em
                     WHERE em.EventId = embc.EventId AND em.Removed = 0)
                ELSE
                    (SELECT MAX(em.MessageSequenceCount)
                     FROM HC.EventMessage em
                     WHERE em.KennelId = embc.KennelId
                       AND em.EventId IS NULL AND em.Removed = 0)
            END,
            embc.LastSequenceCount)
    FROM HC.EventMessageBadgeCounts embc
    WHERE embc.UserId = @userId;

    -- Kennel threads surface as unread with NO badge row (Mode 3 LEFT JOINs
    -- them in), so the UPDATE above can't clear them. Create a caught-up row for
    -- every followed kennel thread that has unseen messages but no row yet, so
    -- "clear all" actually sticks across the next server fetch.
    INSERT HC.EventMessageBadgeCounts (UserId, KennelId, LastSequenceCount, LastReadAt)
    SELECT @userId, t.KennelId, t.MaxSeq, GETUTCDATE()
    FROM (
        SELECT em.KennelId, MAX(em.MessageSequenceCount) AS MaxSeq
        FROM HC.EventMessage em
        WHERE em.KennelId IS NOT NULL AND em.EventId IS NULL AND em.Removed = 0
        GROUP BY em.KennelId
    ) AS t
    -- EXISTS (not JOIN) so a duplicate HasherKennelMap row can't fan out into
    -- duplicate badge inserts for the same kennel.
    WHERE EXISTS (
        SELECT 1 FROM HC.HasherKennelMap hkm
        WHERE hkm.KennelId = t.KennelId AND hkm.UserId = @userId)
      AND NOT EXISTS (
        SELECT 1 FROM HC.EventMessageBadgeCounts embc
        WHERE embc.UserId = @userId
          AND embc.KennelId = t.KennelId
          AND embc.EventId IS NULL);

    -- Run threads surface unread before first read too (since 2026-08-28), so
    -- the same caught-up-row insert is needed for every run thread in the
    -- Mode 3 scope (kennel followed / attendance row, start >= -90 days) that
    -- has messages but no badge row yet.
    INSERT HC.EventMessageBadgeCounts (UserId, EventId, LastSequenceCount, LastReadAt)
    SELECT @userId, t.EventId, t.MaxSeq, GETUTCDATE()
    FROM (
        SELECT em.EventId, MAX(em.MessageSequenceCount) AS MaxSeq
        FROM HC.EventMessage em
        WHERE em.EventId IS NOT NULL AND em.Removed = 0
        GROUP BY em.EventId
    ) AS t
    INNER JOIN HC.Event e ON e.id = t.EventId
    WHERE e.EventStartDatetimeGmt >= DATEADD(DAY, -90, SYSUTCDATETIME())
      AND (
            EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
                    WHERE hkm.KennelId = e.KennelId AND hkm.UserId = @userId)
            OR EXISTS (SELECT 1 FROM HC.HasherEventMap hem
                       WHERE hem.EventId = e.id AND hem.UserId = @userId)
          )
      AND NOT EXISTS (
        SELECT 1 FROM HC.EventMessageBadgeCounts embc
        WHERE embc.UserId = @userId AND embc.EventId = t.EventId);

    SELECT 0 AS BadgeCount, '00000000-0000-0000-0000-000000000000' AS PublicEventId;
    RETURN;
END

-- ---------------------------------------------------------------
-- Mode 2: specific event
-- ---------------------------------------------------------------
IF (@publicEventId IS NOT NULL)
BEGIN
    DECLARE @messageSequenceCount INT;
    DECLARE @eventId              UNIQUEIDENTIFIER;

    -- Resolve eventId from HC.Event directly (robust even when no messages
    -- exist yet — resolving from HC.EventMessage leaves @eventId NULL for
    -- empty chats, causing the NOT NULL constraint to fire on INSERT).
    SELECT @eventId = id FROM HC.Event WHERE PublicEventId = @publicEventId;

    IF @eventId IS NULL
    BEGIN
        SELECT 0 AS BadgeCount, @publicEventId AS PublicEventId;
        RETURN;
    END

    SELECT @messageSequenceCount = MAX(em.MessageSequenceCount)
    FROM HC.EventMessage em
    WHERE em.EventId = @eventId;

    IF (@resetBadgeCount != 0)
    BEGIN
        MERGE INTO HC.EventMessageBadgeCounts AS Target
        USING (VALUES (@userId, @eventId, COALESCE(@messageSequenceCount, 0))) AS Source (UserId, EventId, LastSequenceCount)
        ON (Target.UserId = Source.UserId AND Target.EventId = Source.EventId)
        WHEN MATCHED THEN
            UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (id, UserId, EventId, LastSequenceCount)
            VALUES (NEWID(), Source.UserId, Source.EventId, Source.LastSequenceCount);
    END

    SELECT
        COALESCE(@messageSequenceCount, 0) - COALESCE(embc.LastSequenceCount, 0) AS BadgeCount,
        @publicEventId                                                             AS PublicEventId
    FROM HC.EventMessageBadgeCounts embc
    WHERE embc.EventId = @eventId AND embc.UserId = @userId;

    RETURN;
END

-- ---------------------------------------------------------------
-- Mode 3: all threads (no specific event, no reset)
-- Returns one row per RUN thread with messages that the user can plausibly
-- see on a run card, and one row per followed KENNEL thread with messages,
-- with enough event/kennel display fields for the app to render the
-- "Unseen Chats" list WITHOUT the event being locally synced. The app
-- filters that list on BadgeCount > 0 itself; rows with BadgeCount = 0 are
-- there so the cards can draw a solid "has chats" bubble vs an outline
-- "no chats yet" bubble. BadgeCount/PublicEventId stay first for
-- back-compat with callers that only read those two columns.
-- ---------------------------------------------------------------

-- Run threads. Scope: any event the user holds a badge row for (has posted
-- or read — not time-bounded), OR an event in a kennel they follow / have an
-- attendance row for, starting within the last 90 days or in the future.
-- No badge row ⇒ every message is unread (surfaces before first read, same
-- as kennel threads). BadgeCount is forced to 0 when the effective
-- notification preference for the run is ignore (2) — see header.
SELECT
    CASE WHEN COALESCE(NULLIF(hem.EventNotificationPreference, 0),
                       hkm.KennelNotificationPreference, 0) <> 2
         THEN t.MaxSeq - COALESCE(embc.LastSequenceCount, 0)
         ELSE 0 END          AS BadgeCount,
    e.PublicEventId,
    e.id                    AS EventId,
    e.EventName,
    e.EventNumber,
    e.EventStartDatetimeGmt,
    e.EventImage,
    e.KennelId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS PublicKennelId,   -- run threads: no kennel-thread identity
    k.KennelShortName,
    k.KennelLogo,
    t.MsgCount              AS MessageCount
FROM (
    SELECT em.EventId,
           MAX(em.MessageSequenceCount) AS MaxSeq,
           COUNT(*)                     AS MsgCount
    FROM HC.EventMessage em
    WHERE em.EventId IS NOT NULL AND em.Removed = 0
    GROUP BY em.EventId
) AS t
INNER JOIN HC.Event  e ON e.id = t.EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId
-- OUTER APPLY + TOP 1 everywhere below: none of HasherKennelMap,
-- HasherEventMap or EventMessageBadgeCounts is guaranteed unique per
-- (user, thread), so a plain LEFT JOIN could fan out into duplicate rows.
-- `Found` is the existence flag — HasherEventMap.EventNotificationPreference
-- is nullable, so the preference column itself can't stand in for "row
-- exists".
OUTER APPLY (
    SELECT TOP 1 1 AS Found, h.KennelNotificationPreference
    FROM HC.HasherKennelMap h
    WHERE h.KennelId = e.KennelId AND h.UserId = @userId
) AS hkm
OUTER APPLY (
    SELECT TOP 1 1 AS Found, h.EventNotificationPreference
    FROM HC.HasherEventMap h
    WHERE h.EventId = e.id AND h.UserId = @userId
) AS hem
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount
    FROM HC.EventMessageBadgeCounts b
    WHERE b.EventId = t.EventId AND b.UserId = @userId
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc
WHERE e.deleted = 0
  AND e.IsVisible <> 0
  AND (
        embc.LastSequenceCount IS NOT NULL
        OR (
            e.EventStartDatetimeGmt >= DATEADD(DAY, -90, SYSUTCDATETIME())
            AND (hkm.Found = 1 OR hem.Found = 1)
        )
      )

UNION ALL

-- Kennel-level chat threads the user follows that have ANY messages. A user
-- with NO badge row yet sees the full thread count as unread. Fully-read
-- threads are returned too (BadgeCount = 0) so the kennel card can draw a
-- solid "has chats" icon vs an outline "no chats yet" icon — the app's
-- Unseen Chats list filters on BadgeCount > 0 itself. BadgeCount is forced
-- to 0 when the kennel notification preference is ignore (2).
SELECT
    CASE WHEN hkm.KennelNotificationPreference <> 2
         THEN t.MaxSeq - COALESCE(embc.LastSequenceCount, 0)
         ELSE 0 END                                AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    k.KennelName                                   AS EventName,
    0                                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    k.id                                           AS KennelId,
    k.PublicKennelId                               AS PublicKennelId,
    k.KennelShortName,
    k.KennelLogo,
    t.MsgCount                                     AS MessageCount
FROM (
    SELECT em.KennelId,
           MAX(em.MessageSequenceCount) AS MaxSeq,
           COUNT(*)                     AS MsgCount
    FROM HC.EventMessage em
    WHERE em.KennelId IS NOT NULL AND em.EventId IS NULL AND em.Removed = 0
    GROUP BY em.KennelId
) AS t
INNER JOIN HC.Kennel k ON k.id = t.KennelId
-- CROSS APPLY + TOP 1 (not JOIN) so a duplicate HasherKennelMap row can't
-- fan out into duplicate rows for the same kennel thread; it also filters
-- to followed kennels (no HKM row ⇒ no row).
CROSS APPLY (
    SELECT TOP 1 h.KennelNotificationPreference
    FROM HC.HasherKennelMap h
    WHERE h.KennelId = t.KennelId AND h.UserId = @userId
) AS hkm
OUTER APPLY (
    SELECT TOP 1 b.LastSequenceCount
    FROM HC.EventMessageBadgeCounts b
    WHERE b.KennelId = t.KennelId AND b.UserId = @userId AND b.EventId IS NULL
    ORDER BY b.Removed, b.LastSequenceCount DESC
) AS embc;

END TRY
BEGIN CATCH
    -- Log the real failure so the next occurrence is diagnosable, then re-raise
    -- to preserve the client's existing silent-retry behaviour (see note above).
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getEventBadgeCount',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
