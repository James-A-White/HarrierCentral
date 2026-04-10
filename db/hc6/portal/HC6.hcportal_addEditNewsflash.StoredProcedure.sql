CREATE OR ALTER PROCEDURE [HC6].[hcportal_addEditNewsflash]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL,
    @newsflashId    UNIQUEIDENTIFIER = NULL,    -- NULL = add new; provided = edit existing
    @title          NVARCHAR(250) = NULL,
    @bodyText       NVARCHAR(MAX) = NULL,
    @imageUrl       NVARCHAR(500) = NULL,       -- NULL or empty = no image / clear existing image
    @startDate      DATE = NULL,
    @endDate        DATE = NULL,                -- NULL = no expiry
    @kennelId       UNIQUEIDENTIFIER = NULL     -- NULL = all kennels; provided = kennel-targeted

AS
-- =====================================================================
-- Procedure: HC6.hcportal_addEditNewsflash
-- Description: Creates or updates a portal newsflash. When @newsflashId
--              is NULL a new row is inserted; otherwise the existing row
--              is updated. Image upload to blob storage is handled by the
--              Flutter portal before calling this SP — @imageUrl receives
--              the resulting blob filename/URL.
-- Parameters: @deviceId, @accessToken (auth)
--             @newsflashId   — NULL to add, existing GUID to edit
--             @title         — required; max 250 chars
--             @bodyText      — required
--             @imageUrl      — optional; NULL/empty clears any existing image
--             @startDate     — required; defaults to today in the portal UI
--             @endDate       — optional; must be >= @startDate if provided
--             @kennelId      — optional; NULL = platform-wide newsflash
-- Returns: Standard success envelope
-- Author: Harrier Central
-- Created: 2026-04-10
-- HC5 Source: n/a — new feature
-- Breaking Changes: n/a
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Validate required fields (fast-fail before auth round-trip)
    IF LEN(LTRIM(RTRIM(COALESCE(@title, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'Title is required' AS ErrorMessage;
        RETURN;
    END

    IF LEN(LTRIM(RTRIM(COALESCE(@bodyText, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'Body text is required' AS ErrorMessage;
        RETURN;
    END

    IF @startDate IS NULL
    BEGIN
        SELECT 0 AS Success, 'Start date is required' AS ErrorMessage;
        RETURN;
    END

    IF @endDate IS NOT NULL AND @endDate < @startDate
    BEGIN
        SELECT 0 AS Success, 'End date must be on or after start date' AS ErrorMessage;
        RETURN;
    END

    -- Auth
    DECLARE @authError  NVARCHAR(255);
    DECLARE @hasherId   UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);

    EXEC HC6.ValidatePortalAuth
        @deviceId, @accessToken, @procName, NULL,
        @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Validate kennelId if provided
    IF @kennelId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HC.Kennel WHERE id = @kennelId)
    BEGIN
        SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
        RETURN;
    END

    -- Normalise imageUrl: treat empty string as NULL
    DECLARE @resolvedImageUrl NVARCHAR(500) = NULLIF(LTRIM(RTRIM(COALESCE(@imageUrl, ''))), '');

    BEGIN TRANSACTION;

    IF @newsflashId IS NULL
    BEGIN
        -- Add new newsflash
        INSERT INTO HC.PortalNewsflash
            (Title, BodyText, ImageUrl, StartDate, EndDate, KennelId,
             IsDeleted, CreatedByHasherId, CreatedAt, UpdatedAt)
        VALUES
            (LTRIM(RTRIM(@title)), LTRIM(RTRIM(@bodyText)), @resolvedImageUrl,
             @startDate, @endDate, @kennelId,
             0, @hasherId, GETUTCDATE(), GETUTCDATE());
    END
    ELSE
    BEGIN
        -- Edit existing newsflash
        IF NOT EXISTS (
            SELECT 1 FROM HC.PortalNewsflash
            WHERE NewsflashId = @newsflashId AND IsDeleted = 0
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Success, 'Newsflash not found' AS ErrorMessage;
            RETURN;
        END

        UPDATE HC.PortalNewsflash
        SET Title     = LTRIM(RTRIM(@title)),
            BodyText  = LTRIM(RTRIM(@bodyText)),
            ImageUrl  = @resolvedImageUrl,
            StartDate = @startDate,
            EndDate   = @endDate,
            KennelId  = @kennelId,
            UpdatedAt = GETUTCDATE()
        WHERE NewsflashId = @newsflashId
          AND IsDeleted = 0;
    END

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
