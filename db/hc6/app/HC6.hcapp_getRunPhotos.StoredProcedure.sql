CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunPhotos]

    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @eventId        UNIQUEIDENTIFIER,
    @afterUpdatedAt DATETIME2        = NULL
    -- NULL = return all matching records (initial load).
    -- Non-null = return only records updated after this timestamp (incremental).
    -- Applies to others' public photos only; own photos are always fully returned.

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunPhotos
-- Description: Returns photos for a run. Returns two rowsets:
--   Rowset 1 — own photos (all statuses, always fully returned).
--   Rowset 2 — others' public photos (status=2 only, filtered by
--              @afterUpdatedAt for incremental updates).
--   Call on-demand when the map or photo UI is active; do not poll.
-- Parameters:
--   @deviceId       - Registered device UUID
--   @accessToken    - Token validated against DeviceSecret
--   @eventId        - The run to fetch photos for
--   @afterUpdatedAt - Incremental watermark for others' public photos
-- Returns:
--   On success (rowset 1): own photo rows (see columns below)
--   On success (rowset 2): others' public photo rows (see columns below)
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
    @spNumber     = 32,
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

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1232; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing eventId',
            '@eventId is required for hcapp_getRunPhotos', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY

-- Rowset 1: own photos (all statuses — always fully returned, no watermark).
-- Includes AssetId so the app can load the photo from device storage first
-- and only fall back to BlobUrl if the asset is missing or stale.
SELECT
    kp.id           AS photoId,
    kp.EventId,
    kp.KennelId,
    kp.UserId,
    kp.BlobUrl,
    kp.EditedBlobUrl,
    kp.AssetId,
    kp.Latitude,
    kp.Longitude,
    kp.Status,
    kp.Featured,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    kp.UpdatedAt
FROM HC.KennelPhotos kp
WHERE kp.EventId = @eventId
  AND kp.UserId  = @userId;

-- Rowset 2: others' public photos (status=2, incremental by @afterUpdatedAt)
SELECT
    kp.id           AS photoId,
    kp.EventId,
    kp.KennelId,
    kp.UserId,
    kp.BlobUrl,
    kp.EditedBlobUrl,
    kp.Latitude,
    kp.Longitude,
    kp.Status,
    kp.Featured,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    kp.UpdatedAt,
    h.DisplayName   AS uploaderDisplayName
FROM HC.KennelPhotos kp
INNER JOIN HC.Hasher h ON h.id = kp.UserId
WHERE kp.EventId  = @eventId
  AND kp.UserId  <> @userId
  AND kp.DeletedAt IS NULL
  -- Audience model: Public(3+) for everyone; Members(2) only for member-tier
  -- viewers of the photo's kennel (HC.KennelAccessTier = the single oracle).
  AND ( kp.Status >= 3
        OR (kp.Status = 2 AND EXISTS (
              SELECT 1 FROM HC.KennelAccessTier(@userId, kp.KennelId) t
              WHERE t.Tier >= 10)) )
  AND (@afterUpdatedAt IS NULL OR kp.UpdatedAt > @afterUpdatedAt);

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcapp_getRunPhotos',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
