CREATE OR ALTER PROCEDURE [HC6].[hcapp_getEventMessageCounts]

    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getEventMessageCounts
-- Description: Returns the number of unread messages per event for the
--   calling user, calculated as the difference between the maximum
--   MessageSequenceCount in HC.EventMessage and the user's
--   LastSequenceCount in HC.EventMessageBadgeCounts. Only returns rows
--   for events where the user has sent at least one message (this
--   mirrors the HC5 behaviour; the join path limits scope to events
--   where the current user has message rows).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): { id (EventId), PublicEventId, EventChatMessageCount }
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getEventMessageCounts
-- Breaking Changes:
--   DATALENGTH checks replaced with NULL checks.
--   HC5 query behaviour retained unchanged — note that the join via
--     HC.EventMessage filters to events where the user sent messages,
--     not all events with unread messages for the user. This is a
--     known limitation carried forward from HC5.
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
    @spNumber     = 62,
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

DECLARE @publicHasherId UNIQUEIDENTIFIER;
SELECT @publicHasherId = h.PublicHasherId FROM HC.Hasher h WHERE h.id = @userId;

SELECT
    em.EventId                                              AS id,
    em.PublicEventId,
    MAX(em.MessageSequenceCount) - embc.LastSequenceCount   AS EventChatMessageCount
FROM HC.EventMessage em
INNER JOIN HC.Hasher h     ON em.UserId   = h.id
INNER JOIN HC.EventMessageBadgeCounts embc
                           ON embc.EventId = em.EventId AND embc.UserId = h.id
WHERE h.PublicHasherId = @publicHasherId
GROUP BY em.EventId, em.PublicEventId, embc.LastSequenceCount;
