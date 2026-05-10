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
--   On success (rowset 0): { BadgeCount, PublicEventId }
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
-- Mode 1: reset all badge counts
-- ---------------------------------------------------------------
IF (@resetAllBadgeCounts != 0)
BEGIN
    UPDATE embc SET
        embc.LastSequenceCount = (
            SELECT MAX(em.MessageSequenceCount)
            FROM HC.EventMessage em WHERE em.EventId = embc.EventId
        )
    FROM HC.EventMessageBadgeCounts embc
    WHERE embc.UserId = @userId;

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

    SELECT
        @messageSequenceCount = MAX(em.MessageSequenceCount),
        @eventId              = em.EventId
    FROM HC.EventMessage em
    WHERE em.PublicEventId = @publicEventId
    GROUP BY em.EventId;

    IF (@resetBadgeCount != 0)
    BEGIN
        MERGE INTO HC.EventMessageBadgeCounts AS Target
        USING (VALUES (@userId, @eventId, @messageSequenceCount)) AS Source (UserId, EventId, LastSequenceCount)
        ON (Target.UserId = Source.UserId AND Target.EventId = Source.EventId)
        WHEN MATCHED THEN
            UPDATE SET Target.LastSequenceCount = Source.LastSequenceCount
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (UserId, EventId, LastSequenceCount)
            VALUES (Source.UserId, Source.EventId, Source.LastSequenceCount);
    END

    SELECT
        COALESCE(@messageSequenceCount, 0) - embc.LastSequenceCount AS BadgeCount,
        @publicEventId                                               AS PublicEventId
    FROM HC.EventMessageBadgeCounts embc
    WHERE embc.EventId = @eventId AND embc.UserId = @userId;

    RETURN;
END

-- ---------------------------------------------------------------
-- Mode 3: all events (no specific event, no reset)
-- ---------------------------------------------------------------
SELECT
    MAX(em.MessageSequenceCount) - embc.LastSequenceCount AS BadgeCount,
    em.PublicEventId
FROM HC.EventMessageBadgeCounts embc
INNER JOIN HC.EventMessage em ON em.EventId = embc.EventId
WHERE embc.UserId = @userId
GROUP BY embc.LastSequenceCount, em.PublicEventId;
