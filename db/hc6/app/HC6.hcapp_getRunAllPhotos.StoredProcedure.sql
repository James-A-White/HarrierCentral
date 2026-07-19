CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunAllPhotos]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId   UNIQUEIDENTIFIER,
    @eventId    UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunAllPhotos
-- Description: Returns every photo for a specific event regardless of
--   status — pending, approved at any level, private, and soft-deleted.
--   Used to power the photo review screen (both Pending and Reviewed tabs)
--   and the persistent status-count header. Caller must hold one of the
--   following roles: Hash Flash (0x20), GM (0x02), VGM (0x04), or RA (0x08).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel the event belongs to (used for auth check)
--   @eventId     - Event to fetch photos for
-- Returns:
--   On success (rowset 0): all photo rows ordered newest-first
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-23
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
    @spNumber     = 36,
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
    SET @errorCode = 1234; SET @errorType = 12; SET @errorId = NEWID();
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

-- Verify caller holds an approval role for this kennel:
-- Hash Flash (0x0020) | GM (0x0002) | VGM (0x0004) | RA (0x0008) | WebMeister (0x1000) = 0x102E
-- Authorization: feature "Batch / view all photos" (see /hc-authorizations).
DECLARE @photoAllowed SMALLINT;
EXEC HC6.CheckKennelPermission @userId, @kennelId, 0x0000102E, 0x00000100, @photoAllowed OUTPUT;

IF (@photoAllowed = 0)
BEGIN
    SET @errorCode = 1334; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised to review photos',
            'Caller does not hold Hash Flash, GM, VGM, RA or WebMeister role for this kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to review photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY

SELECT
    kp.id                   AS photoId,
    kp.EventId,
    kp.Status,
    kp.Featured,
    kp.DeletedAt,
    kp.BlobUrl,
    kp.EditedBlobUrl,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    h.DisplayName           AS uploaderDisplayName,
    e.EventName             AS eventName,
    e.AbsoluteEventNumber   AS eventNumber
FROM HC.KennelPhotos kp
INNER JOIN HC.Hasher h ON h.id  = kp.UserId
INNER JOIN HC.Event  e ON e.id  = kp.EventId
WHERE kp.KennelId = @kennelId
  AND kp.EventId  = @eventId
ORDER BY kp.CreatedAt DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcapp_getRunAllPhotos',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
