CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelPendingPhotos]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId   UNIQUEIDENTIFIER,
    @eventId    UNIQUEIDENTIFIER = NULL  -- optional: restrict to a single event

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getKennelPendingPhotos
-- Description: Returns all photos with Status=1 (pending_review) for
--   a kennel, for the photo review screen. Caller must hold one of the
--   following roles: Hash Flash (0x20), GM (0x02), VGM (0x04), or RA (0x08).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel to fetch pending photos for
--   @eventId     - (optional) Restrict results to a single event
-- Returns:
--   On success (rowset 0): pending photo rows ordered newest-first
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-20
-- HC5 Source: None — new for HC6 KennelPhotos
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
    @spNumber     = 34,
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

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1234; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing kennelId',
            '@kennelId is required for hcapp_getKennelPendingPhotos', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Verify caller is Hash Flash for this kennel (0x00000020)
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId;

-- Hash Flash (0x20) OR GM (0x02) OR VGM (0x04) OR RA (0x08) = 0x2E
IF (@mmRoleFlags & 0x0000002E = 0)
BEGIN
    SET @errorCode = 1334; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised to review photos',
            'Caller does not hold Hash Flash, GM, VGM or RA role for this kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to review photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

SELECT
    kp.id                   AS photoId,
    kp.EventId,
    kp.UserId,
    kp.BlobUrl,
    kp.Latitude,
    kp.Longitude,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    kp.UpdatedAt,
    h.DisplayName           AS uploaderDisplayName,
    e.EventName             AS eventName,
    e.AbsoluteEventNumber   AS eventNumber
FROM HC.KennelPhotos kp
INNER JOIN HC.Hasher h ON h.id  = kp.UserId
INNER JOIN HC.Event  e ON e.id  = kp.EventId
WHERE kp.KennelId = @kennelId
  AND kp.Status   = 1
  AND (@eventId IS NULL OR kp.EventId = @eventId)
ORDER BY kp.CreatedAt DESC;
