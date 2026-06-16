CREATE OR ALTER PROCEDURE [HC6].[hcportal_batchUpdatePhotoStatus]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @updates        NVARCHAR(MAX)    = NULL
    -- @updates: JSON array  [{"photoId":"<uuid>","action":<1-6>}, ...]
    -- Actions: 1=soft-delete  2=private(0)  3=share(2)  4=gallery(3)
    --          5=home_gallery(4)  6=event_cover(5)

AS
-- =====================================================================
-- Procedure: HC6.hcportal_batchUpdatePhotoStatus
-- Description: Applies a batch of photo-status changes in a single
--   round-trip. Accepts a JSON array of {photoId, action} pairs.
--   Auth is checked once at kennel level via AppAccessFlags.
--   Set-based UPDATEs are used throughout — no cursor/loop.
--   Partial failures (photo not found / wrong kennel) are counted and
--   reported; successful items are always committed regardless.
--   Caller must hold authIsAdmin (0x0001), authCanManageRuns (0x0004),
--   or authIsSuperAdmin (0x40000000) in
--   HC.HasherKennelMap.AppAccessFlags for the kennel.
-- Parameters:
--   @deviceId       - Registered portal device UUID
--   @accessToken    - Short-lived token validated against device secret
--   @publicKennelId - Public-facing kennel UUID (resolved to internal id)
--   @updates        - JSON array: [{"photoId":"...","action":N}, ...]
-- Returns:
--   On error   (rowset 0): { Success=0, ErrorMessage }
--   On success (rowset 0): { Success=1, successCount, failureCount }
-- Author: Harrier Central
-- Created: 2026-05-28
-- HC5 Source: None — new for HC6 KennelPhotos
-- App equivalent: HC6.hcapp_batchUpdatePhotoStatus
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    DECLARE @authError  NVARCHAR(255);
    DECLARE @hasherId   UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
    DECLARE @kennelId   UNIQUEIDENTIFIER;

    EXEC HC6.ValidatePortalAuth
        @deviceId, @accessToken, @procName, NULL,
        @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    IF @publicKennelId IS NULL OR @publicKennelId = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SELECT 0 AS Success, 'publicKennelId is required' AS ErrorMessage;
        RETURN;
    END

    SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId;

    IF @kennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Kennel not found.' AS ErrorMessage;
        RETURN;
    END

    IF @updates IS NULL OR LEN(LTRIM(RTRIM(@updates))) = 0
    BEGIN
        SELECT 0 AS Success, 'updates is required' AS ErrorMessage;
        RETURN;
    END

    -- Permission: authIsAdmin (0x0001) | authCanManagePublicWebContent (0x0080) | authIsSuperAdmin (0x40000000)
    DECLARE @appAccessFlags INT = 0;
    SELECT @appAccessFlags = ISNULL(hkm.AppAccessFlags, 0)
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId;

    IF (@appAccessFlags & 0x40000081) = 0
    BEGIN
        SELECT 0 AS Success,
               'You are not authorised to review photos for this kennel.' AS ErrorMessage;
        RETURN;
    END

    -- Parse JSON into a working table
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
        SELECT 1 AS Success, 0 AS successCount, 0 AS failureCount;
        DROP TABLE IF EXISTS #Updates;
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

        -- 3. Event cover (action = 6): propagate best available URL to HC.Event
        --    Prefer EditedBlobUrl so the cover shows the cropped/edited version.
        UPDATE e
        SET e.EventCoverPhotoUrl = COALESCE(kp.EditedBlobUrl, kp.BlobUrl)
        FROM HC.Event e
        INNER JOIN HC.KennelPhotos kp ON kp.EventId = e.id
        INNER JOIN #Updates u         ON u.photoId  = kp.id AND u.action = 6
        WHERE kp.KennelId = @kennelId;

    COMMIT TRANSACTION;

    SELECT 1 AS Success, @successCount AS successCount, @failureCount AS failureCount;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH

DROP TABLE IF EXISTS #Updates;
