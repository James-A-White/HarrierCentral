CREATE OR ALTER PROCEDURE [HC6].[hcapp_getDownDowns]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER,
    @eventId     UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getDownDowns
-- Description: Returns all DownDown charges for a run, with each
--   charge's list of named hashers. Returns two rowsets:
--     Rowset 0 — one row per DownDown (id, chargeText, isDone,
--                createdByDisplayName, createdAt)
--     Rowset 1 — one row per DownDownHasher (downDownId, hasherId,
--                displayName) so the app can group by downDownId
--   Auth: GM (0x02) or RA (0x08).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns the event
--   @eventId     - Event to fetch DownDowns for
-- Returns:
--   On success (rowset 0): DownDown rows ordered by createdAt ASC
--   On success (rowset 1): DownDownHasher rows
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
-- HC5 Source: None — new feature
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
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
    @spNumber     = 56,
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
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000'
 OR @eventId  IS NULL OR @eventId  = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing parameter',
            '@kennelId and @eventId are both required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Auth: GM (0x02) | RA (0x08) = 0x000A
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId;

IF (@mmRoleFlags & 0x0000000A = 0)
BEGIN
    SET @errorCode = 1336; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised',
            'Caller lacks GM or RA role', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'Only the GM and RAs can view DownDowns.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Rowset 0: DownDown charges
SELECT
    dd.id              AS downDownId,
    dd.ChargeText      AS chargeText,
    dd.IsDone          AS isDone,
    dd.IsCancelled     AS isCancelled,
    dd.SongChoice      AS songChoice,
    h.DisplayName      AS createdByDisplayName,
    h.Photo            AS createdByPhoto,
    dd.CreatedAt       AS createdAt
FROM HC.DownDowns dd
INNER JOIN HC.Hasher h ON h.id = dd.CreatedByUserId
WHERE dd.EventId  = @eventId
  AND dd.KennelId = @kennelId
ORDER BY dd.CreatedAt ASC;

-- Rowset 1: Charged hashers per DownDown
SELECT
    ddh.DownDownId AS downDownId,
    ddh.HasherId   AS hasherId,
    h.DisplayName  AS displayName
FROM HC.DownDownHashers ddh
INNER JOIN HC.Hasher h ON h.id = ddh.HasherId
INNER JOIN HC.DownDowns dd ON dd.id = ddh.DownDownId
WHERE dd.EventId  = @eventId
  AND dd.KennelId = @kennelId;
