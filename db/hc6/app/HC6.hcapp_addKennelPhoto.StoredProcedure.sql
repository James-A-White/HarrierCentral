CREATE OR ALTER PROCEDURE [HC6].[hcapp_addKennelPhoto]

    @deviceId             UNIQUEIDENTIFIER,
    @accessToken          NVARCHAR(1000),
    @photoId              UNIQUEIDENTIFIER,
    @eventId              UNIQUEIDENTIFIER,
    @kennelId             UNIQUEIDENTIFIER,
    @blobUrl              NVARCHAR(500),
    @latitude             DECIMAL(9,6),
    @longitude            DECIMAL(9,6),
    @title                NVARCHAR(250)  = NULL,
    @description          NVARCHAR(MAX)  = NULL,
    @assetId              NVARCHAR(500)  = NULL,
    -- Device-library identifier (iOS PHAsset.localIdentifier / Android MediaStore URI).
    -- NULL when the user had "save to camera roll" disabled or permission denied.
    -- Device-specific — only meaningful on the device that uploaded the photo.
    @perRunSharingOverride INT            = NULL
    -- NULL = resolve from saved per-kennel / global preferences.
    -- 0 = keep private regardless of saved preference.
    -- 1 = share with Hash Flash regardless of saved preference.

AS
-- =====================================================================
-- Procedure: HC6.hcapp_addKennelPhoto
-- Description: Records a kennel photo after the app has uploaded the
--   image blob directly to Azure Storage. Resolves the effective sharing
--   preference (per-run override → per-kennel → global bit) and sets the
--   initial status accordingly: private (0) or pending_review (1).
--   No sync delegation — photos are fetched on-demand via hcapp_getRunPhotos.
-- Parameters:
--   @deviceId             - Registered device UUID
--   @accessToken          - Token validated against DeviceSecret
--   @photoId              - Client-generated GUID (must be unique)
--   @eventId              - Event the photo belongs to
--   @kennelId             - Kennel scope (must match event's kennel)
--   @blobUrl              - Full CDN URL to the uploaded blob
--   @latitude             - Where the photo was taken
--   @longitude            - Where the photo was taken
--   @title                - Optional short title
--   @description          - Optional longer description
--   @assetId              - Optional device-library ID (iOS/Android) for local-first display
--   @perRunSharingOverride - Per-run preference (NULL=use saved, 0=private, 1=share)
-- Returns:
--   On success (rowset 0): { success, errorCode, errorType }
--   On success (rowset 1): { photoId, status }
--   On error  (rowset 0): { success, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-20
-- HC5 Source: None — new for HC6 KennelPhotos
-- Quota: v2 — quota enforcement stub is present but not activated.
--   When paid tiers are designed, replace the NULL stub with a real limit.
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
    @spNumber     = 31,
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

-- Validate required parameters
IF (@photoId IS NULL OR @photoId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1231; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing photoId',
            '@photoId is required for hcapp_addKennelPhoto', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
    OR (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
    OR LEN(ISNULL(@blobUrl, '')) = 0
BEGIN
    SET @errorCode = 1231; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing required fields',
            'eventId, kennelId, and blobUrl are all required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Verify event belongs to the stated kennel
IF NOT EXISTS (
    SELECT 1 FROM HC.Event WHERE id = @eventId AND KennelId = @kennelId
)
BEGIN
    SET @errorCode = 1331; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Event/kennel mismatch',
            'eventId does not belong to the supplied kennelId', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Event not found' AS errorTitle,
           'The run could not be found. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- v2 quota hook: replace NULL with a real limit when paid tiers are designed.
DECLARE @maxPhotosPerUserPerRun INT = NULL; /* v2: enforce when paid tiers exist */
IF (@maxPhotosPerUserPerRun IS NOT NULL)
BEGIN
    DECLARE @existingCount INT = 0;
    SELECT @existingCount = COUNT(*)
    FROM HC.KennelPhotos
    WHERE EventId = @eventId AND UserId = @userId;

    IF (@existingCount >= @maxPhotosPerUserPerRun)
    BEGIN
        SET @errorCode = 1231; SET @errorType = 12; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Photo quota exceeded',
                'User has reached the maximum number of photos for this run', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Photo limit reached' AS errorTitle,
               'You have reached the maximum number of photos for this run.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

-- Resolve effective sharing preference (most specific wins):
-- 1. @perRunSharingOverride (if not NULL)
-- 2. HasherKennelMap.PhotoSharingPreference for this kennel
-- 3. Hasher.Preferences bit 6 (0x00000040) — global photo sharing
DECLARE @effectiveSharingPref TINYINT;

IF (@perRunSharingOverride IS NOT NULL)
BEGIN
    SET @effectiveSharingPref = CAST(@perRunSharingOverride AS TINYINT);
END
ELSE
BEGIN
    DECLARE @kennelSharingPref TINYINT = NULL;
    SELECT @kennelSharingPref = PhotoSharingPreference
    FROM HC.HasherKennelMap
    WHERE UserId = @userId AND KennelId = @kennelId;

    IF (@kennelSharingPref IS NOT NULL AND @kennelSharingPref > 0)
    BEGIN
        SET @effectiveSharingPref = @kennelSharingPref;
    END
    ELSE
    BEGIN
        DECLARE @globalPrefs INT = 0;
        SELECT @globalPrefs = ISNULL(Preferences, 0) FROM HC.Hasher WHERE id = @userId;
        SET @effectiveSharingPref = CASE WHEN (@globalPrefs & 0x00000040) > 0 THEN 1 ELSE 0 END;
    END
END

DECLARE @status TINYINT = CASE WHEN @effectiveSharingPref > 0 THEN 1 ELSE 0 END;
-- status 0 = private, 1 = pending_review

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [HC].[KennelPhotos]
        (id, EventId, KennelId, UserId, BlobUrl, AssetId, Latitude, Longitude, Status, Title, Description)
    VALUES
        (@photoId, @eventId, @kennelId, @userId, @blobUrl,
         @assetId, @latitude, @longitude, @status, @title, @description);

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT @photoId AS photoId, @status AS status;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1931 AS errorCode, 19 AS errorType;
    SELECT @errorId AS errorId, 19 AS errorType, 1931 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
