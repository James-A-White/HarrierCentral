CREATE OR ALTER PROCEDURE [HC6].[hcportal_getRunAllPhotos]

    @deviceId        UNIQUEIDENTIFIER = NULL,
    @accessToken     NVARCHAR(1000)   = NULL,
    @publicKennelId  UNIQUEIDENTIFIER = NULL,
    @eventId         UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getRunAllPhotos
-- Description: Returns every photo for a specific event regardless of
--   status — pending, approved at any level, private, and soft-deleted.
--   Used to power the portal photo review screen.
--   Caller must hold authIsAdmin (0x0001), authCanManageRuns (0x0004),
--   or authIsSuperAdmin (0x40000000) in
--   HC.HasherKennelMap.AppAccessFlags for the kennel.
-- Parameters:
--   @deviceId        - Registered portal device UUID
--   @accessToken     - Short-lived token validated against device secret
--   @publicKennelId  - Public-facing kennel UUID (resolved to internal id)
--   @eventId         - Event to fetch photos for
-- Returns:
--   On error   (rowset 0): { Success=0, ErrorMessage }
--   On success (rowset 0): photo rows ordered newest-first
-- Author: Harrier Central
-- Created: 2026-05-28
-- HC5 Source: None — new for HC6 KennelPhotos
-- App equivalent: HC6.hcapp_getRunAllPhotos
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

    IF @eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SELECT 0 AS Success, 'eventId is required' AS ErrorMessage;
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

    SELECT
        kp.id                 AS photoId,
        kp.EventId,
        kp.Status,
        kp.DeletedAt,
        kp.BlobUrl,
        kp.Title,
        kp.Description,
        kp.CreatedAt,
        h.DisplayName         AS uploaderDisplayName,
        e.EventName           AS eventName,
        e.AbsoluteEventNumber AS eventNumber
    FROM HC.KennelPhotos kp
    INNER JOIN HC.Hasher h ON h.id = kp.UserId
    INNER JOIN HC.Event  e ON e.id = kp.EventId
    WHERE kp.KennelId = @kennelId
      AND kp.EventId  = @eventId
    ORDER BY kp.CreatedAt DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
