CREATE OR ALTER PROCEDURE [HC6].[hcportal_addEditNewsflash]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL,
    @newsflashId    UNIQUEIDENTIFIER = NULL,    -- NULL = add new; provided = edit existing
    @title          NVARCHAR(250) = NULL,
    @bodyText       NVARCHAR(MAX) = NULL,
    @imageUrl       NVARCHAR(500) = NULL,       -- NULL or empty = no image / clear existing image
    @startDate      DATE = NULL,
    @endDate        DATE = NULL,                -- NULL = no expiry
    @kennelId       UNIQUEIDENTIFIER = NULL,    -- NULL = all kennels; provided = kennel-targeted
    @newNewsflashId UNIQUEIDENTIFIER = NULL     -- a NEW newsflash's id, minted once per dialog (E14.G2.R5)

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
--             @newNewsflashId — optional (2026-10-14, E14.G2.R5): the id the
--                              portal minted for a new newsflash, sent on
--                              every attempt. Already there = a repeat after
--                              a lost reply: success, nothing inserted.
--                              Idempotent writes pattern: creates a row.
-- Returns: Standard success envelope
-- Idempotency: client-id — @newNewsflashId minted once per dialog; already there (UPDLOCK, HOLDLOCK) = success, nothing inserted. Edits are set-state.
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

    -- Platform admins with the newsflash right only (2026-10-13), as the
    -- portal's Newsflash screen already requires. Until now any signed-in
    -- portal user could create, change or delete platform newsflashes.
    DECLARE @mayNewsflash SMALLINT = 0;
    EXEC HC6.nonApi_portalKennelAccess @hasherId = @hasherId, @callerType = @callerType,
         @platformCap = 'CanManageNewsflash', @allowed = @mayNewsflash OUTPUT;
    IF (@mayNewsflash = 0)
    BEGIN
        SELECT 0 AS Success, 'Not authorised to manage newsflashes' AS ErrorMessage;
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
        -- Add new newsflash. With @newNewsflashId the portal's own id is the
        -- key, and a repeat (the first attempt committed, its reply was lost)
        -- finds it under lock and inserts nothing.
        IF (@newNewsflashId IS NULL OR NOT EXISTS (
                SELECT 1 FROM HC.PortalNewsflash WITH (UPDLOCK, HOLDLOCK)
                WHERE NewsflashId = @newNewsflashId))
            INSERT INTO HC.PortalNewsflash
                (NewsflashId, Title, BodyText, ImageUrl, StartDate, EndDate, KennelId,
                 IsDeleted, CreatedByHasherId, CreatedAt, UpdatedAt)
            VALUES
                (COALESCE(@newNewsflashId, NEWID()), LTRIM(RTRIM(@title)), LTRIM(RTRIM(@bodyText)), @resolvedImageUrl,
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
