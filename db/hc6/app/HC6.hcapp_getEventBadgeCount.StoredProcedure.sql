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
--   Mode 3 all-events (rowset 0): one row per event with unread messages —
--     { BadgeCount, PublicEventId, EventId, EventName, EventNumber,
--       EventStartDatetimeGmt, EventImage, KennelId, KennelShortName,
--       KennelLogo }. Extra columns let the app render the Unseen Chats list
--     for events that aren't locally synced. First two columns unchanged.
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
-- Mode 3: all events (no specific event, no reset)
-- Returns one row per event that has unread messages (BadgeCount > 0),
-- with enough event/kennel display fields for the app to render the
-- "Unseen Chats" list WITHOUT the event being locally synced — so a run
-- with an unread chat always appears even if the user doesn't follow the
-- kennel and hasn't attended. BadgeCount/PublicEventId stay first for
-- back-compat with callers that only read those two columns.
-- ---------------------------------------------------------------
SELECT
    unread.BadgeCount,
    e.PublicEventId,
    e.id                    AS EventId,
    e.EventName,
    e.EventNumber,
    e.EventStartDatetimeGmt,
    e.EventImage,
    e.KennelId,
    CAST(NULL AS UNIQUEIDENTIFIER) AS PublicKennelId,   -- run threads: no kennel-thread identity
    k.KennelShortName,
    k.KennelLogo
FROM (
    SELECT
        embc.EventId                                          AS EventId,
        MAX(em.MessageSequenceCount) - embc.LastSequenceCount AS BadgeCount
    FROM HC.EventMessageBadgeCounts embc
    INNER JOIN HC.EventMessage em ON em.EventId = embc.EventId
    WHERE embc.UserId = @userId AND embc.EventId IS NOT NULL
    GROUP BY embc.EventId, embc.LastSequenceCount
) AS unread
INNER JOIN HC.Event  e ON e.id = unread.EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId
WHERE unread.BadgeCount > 0
  AND e.deleted = 0
  AND e.IsVisible <> 0

UNION ALL

-- Kennel-level chat threads the user follows that have messages they haven't
-- seen. A user with NO badge row yet sees the full thread count (unlike run
-- threads, kennel threads must surface before first read).
SELECT
    t.MaxSeq - COALESCE(embc.LastSequenceCount, 0) AS BadgeCount,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS PublicEventId,
    CAST(NULL AS UNIQUEIDENTIFIER)                 AS EventId,
    k.KennelName                                   AS EventName,
    0                                              AS EventNumber,
    CAST(NULL AS DATETIMEOFFSET(7))                AS EventStartDatetimeGmt,
    CAST(NULL AS NVARCHAR(500))                    AS EventImage,
    k.id                                           AS KennelId,
    k.PublicKennelId                               AS PublicKennelId,
    k.KennelShortName,
    k.KennelLogo
FROM (
    SELECT em.KennelId, MAX(em.MessageSequenceCount) AS MaxSeq
    FROM HC.EventMessage em
    WHERE em.KennelId IS NOT NULL AND em.EventId IS NULL AND em.Removed = 0
    GROUP BY em.KennelId
) AS t
INNER JOIN HC.Kennel k ON k.id = t.KennelId
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = t.KennelId AND hkm.UserId = @userId
LEFT JOIN HC.EventMessageBadgeCounts embc
    ON embc.KennelId = t.KennelId AND embc.UserId = @userId AND embc.EventId IS NULL
WHERE t.MaxSeq - COALESCE(embc.LastSequenceCount, 0) > 0;
