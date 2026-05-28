CREATE OR ALTER PROCEDURE [HC6].[hcapp_batchUpdatePhotoStatus]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId   UNIQUEIDENTIFIER,
    @updates    NVARCHAR(MAX)
    -- @updates: JSON array  [{"photoId":"<uuid>","action":<1-6>}, ...]
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
--   @updates     - JSON array: [{"photoId":"...","action":N}, ...]
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
DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId;

IF (@mmRoleFlags & 0x0000102E = 0)
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
  AND j.action BETWEEN 1 AND 6;

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

    -- 2. Status changes (actions 2–6): clear DeletedAt, set new Status
    UPDATE kp
    SET kp.Status    = CASE u.action
                           WHEN 2 THEN 0
                           WHEN 3 THEN 2
                           WHEN 4 THEN 3
                           WHEN 5 THEN 4
                           WHEN 6 THEN 5
                       END,
        kp.DeletedAt = NULL,
        kp.UpdatedAt = GETUTCDATE()
    FROM HC.KennelPhotos kp
    INNER JOIN #Updates u ON u.photoId = kp.id AND u.action BETWEEN 2 AND 6
    WHERE kp.KennelId = @kennelId;

    -- 3. Event cover (action = 6): propagate BlobUrl to HC.Event
    UPDATE e
    SET e.EventCoverPhotoUrl = kp.BlobUrl
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
