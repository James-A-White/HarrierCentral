CREATE OR ALTER PROCEDURE [HC6].[hcapp_batchUpdatePhotoStatus]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId   UNIQUEIDENTIFIER,
    @updates    NVARCHAR(MAX)
    -- @updates: JSON array  [{"photoId":"<uuid>","action":<1-7>}, ...]
    -- Actions: 1=soft-delete  2=private(0)  3=share(2)  4=gallery(3)
    --          5=home_gallery(4)  6=event_cover(5)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_batchUpdatePhotoStatus
-- Description: Applies a batch of photo-status changes in a single
--   round-trip. Accepts a JSON array of {photoId, action} pairs.
--   Auth is checked once at kennel level (Hash Flash / GM / VGM / RA).
--   Set-based UPDATEs are used throughout — no cursor/loop.
--   Partial failures (photo not found / wrong kennel) are counted and
--   reported; successful items are always committed regardless.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns all photos in the batch
--   @updates     - JSON array: [{"photoId":"...","action":N}, ...] (1-7)
-- Returns:
--   On success (rowset 0): { success, successCount, failureCount }
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-23
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

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
    @spNumber     = 37,
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

-- Auth: caller must hold Hash Flash / GM / VGM / RA / WebMeister for this kennel
-- Authorization: feature "Batch / view all photos" (see /hc-authorizations).
DECLARE @photoAllowed SMALLINT;
EXEC HC6.CheckKennelPermission @userId, @kennelId, 0x0000102E, 0x00000100, @photoAllowed OUTPUT;

IF (@photoAllowed = 0)
BEGIN
    SET @errorCode = 1334; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised',
            'Caller lacks Hash Flash / GM / VGM / RA / WebMeister role', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to review photos for this kennel.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Parse JSON into a working table
-- Rows with unrecognised actions are excluded via WHERE.
CREATE TABLE #Updates (
    photoId  UNIQUEIDENTIFIER NOT NULL,
    action   TINYINT          NOT NULL
);

INSERT INTO #Updates (photoId, action)
SELECT  TRY_CAST(j.photoId AS UNIQUEIDENTIFIER),
        TRY_CAST(j.action  AS TINYINT)
FROM OPENJSON(@updates)
WITH (
    photoId NVARCHAR(36) '$.photoId',
    action  TINYINT      '$.action'
) j
WHERE TRY_CAST(j.photoId AS UNIQUEIDENTIFIER) IS NOT NULL
  AND j.action BETWEEN 1 AND 7;

DECLARE @submitted INT = (SELECT COUNT(*) FROM #Updates);

IF (@submitted = 0)
BEGIN
    SELECT 1 AS success, 0 AS successCount, 0 AS failureCount;
    RETURN;
END

-- Count items that don't belong to this kennel (partial-failure detection)
DECLARE @failureCount INT = (
    SELECT COUNT(*)
    FROM #Updates u
    LEFT JOIN HC.KennelPhotos kp
        ON kp.id = u.photoId AND kp.KennelId = @kennelId
    WHERE kp.id IS NULL
);

DECLARE @successCount INT = @submitted - @failureCount;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Soft-delete (action = 1)
    UPDATE kp
    SET kp.DeletedAt  = GETUTCDATE(),
        kp.UpdatedAt  = GETUTCDATE()
    FROM HC.KennelPhotos kp
    INNER JOIN #Updates u ON u.photoId = kp.id AND u.action = 1
    WHERE kp.KennelId = @kennelId;

    -- 2. Audience changes (actions 2,3,4,6): clear DeletedAt, set new Status
    --    (audience model: 0=Private, 2=Members, 3=Public, 5=Cover)
    UPDATE kp
    SET kp.Status    = CASE u.action
                           WHEN 2 THEN 0
                           WHEN 3 THEN 2
                           WHEN 4 THEN 3
                           WHEN 6 THEN 5
                       END,
        kp.DeletedAt = NULL,
        kp.UpdatedAt = GETUTCDATE()
    FROM HC.KennelPhotos kp
    INNER JOIN #Updates u ON u.photoId = kp.id AND u.action IN (2, 3, 4, 6)
    WHERE kp.KennelId = @kennelId;

    -- 2b. Featured toggles (5=feature, 7=unfeature) — orthogonal to audience
    UPDATE kp
    SET kp.Featured  = CASE u.action WHEN 5 THEN 1 ELSE 0 END,
        kp.UpdatedAt = GETUTCDATE()
    FROM HC.KennelPhotos kp
    INNER JOIN #Updates u ON u.photoId = kp.id AND u.action IN (5, 7)
    WHERE kp.KennelId = @kennelId;

    -- 2c. Cover uniqueness: demote previous covers of affected events to Public
    UPDATE prev
    SET prev.Status = 3, prev.UpdatedAt = GETUTCDATE()
    FROM HC.KennelPhotos prev
    WHERE prev.Status = 5 AND prev.KennelId = @kennelId
      AND EXISTS (SELECT 1 FROM HC.KennelPhotos kp
                  INNER JOIN #Updates u ON u.photoId = kp.id AND u.action = 6
                  WHERE kp.EventId = prev.EventId AND kp.id <> prev.id);

    -- 3. Event cover (action = 6): propagate effective URL to HC.Event.
    --    Uses EditedBlobUrl when present (Hash Flash may have cropped the photo)
    --    so the cover reflects the approved edited version.
    UPDATE e
    SET e.EventCoverPhotoUrl = COALESCE(kp.EditedBlobUrl, kp.BlobUrl)
    FROM HC.Event e
    INNER JOIN HC.KennelPhotos kp ON kp.EventId = e.id
    INNER JOIN #Updates u         ON u.photoId  = kp.id AND u.action = 6
    WHERE kp.KennelId = @kennelId;

    COMMIT TRANSACTION;

    SELECT 1 AS success, @successCount AS successCount, @failureCount AS failureCount;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 19 AS errorType;
    SELECT @errorId AS errorId, 19 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH

DROP TABLE IF EXISTS #Updates;
