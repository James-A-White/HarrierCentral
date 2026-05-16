CREATE OR ALTER PROCEDURE [HC6].[hcapp_getEventMessages]

    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getEventMessages
-- Description: Returns all messages for an event, ordered newest first.
--   Author information is returned as flat columns rather than as a
--   nested JSON object (the HC5 v1 approach). The access token is bound
--   to the specific event (compound: DeviceSecret + eventId string) to
--   prevent token replay against a different event's message feed.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Compound token: DeviceSecret + eventId (as NVARCHAR)
--   @eventId     - Event to retrieve messages for
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): { id, type, text, roomId, createdAt,
--                             authorId, authorFirstName, authorImageUrl }
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getEventMessages + HC5.hcapp_getEventMessages2
--   (merged into one flat-column SP)
-- Breaking Changes:
--   HC5 v1 nested JSON author object replaced with flat columns
--     authorId, authorFirstName, authorImageUrl.
--   HC5 v2 separate SP removed — same endpoint now returns both styles
--     in one flat rowset.
--   Token compound param: passes CAST(@eventId AS NVARCHAR(50)) to
--     ValidateAppAuth (unchanged from HC5 token formula).
--   DATALENGTH checks replaced with NULL checks.
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
    @spNumber     = 60,
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

IF (@eventId IS NULL)
BEGIN
    SET @errorCode = 1260; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId', 'eventId is required', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

SELECT
    UPPER(msg.id)                                                               AS id,
    'text'                                                                      AS type,
    msg.MessageContent                                                          AS text,
    msg.PublicEventId                                                           AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)            AS createdAt,
    UPPER(h.PublicHasherId)                                                     AS authorId,
    h.DisplayName                                                               AS authorFirstName,
    h.Photo                                                                     AS authorImageUrl
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.EventId = @eventId
ORDER BY msg.createdAt DESC;
