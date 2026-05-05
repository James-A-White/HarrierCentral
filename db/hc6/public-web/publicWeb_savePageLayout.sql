CREATE OR ALTER PROCEDURE [HC6].[publicWeb_savePageLayout]
    @KennelSlug     NVARCHAR(100),
    @PageLayoutJson NVARCHAR(MAX)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_savePageLayout
-- Description: Saves (inserts or updates) the Puck page layout JSON
--              for a kennel. Called by the Next.js admin layout editor
--              via the PublicWebAdminApi POST endpoint.
-- Parameters:  @KennelSlug     NVARCHAR(100) — HC.Kennel.KennelUniqueShortName
--              @PageLayoutJson NVARCHAR(MAX) — Puck Data JSON
-- Returns:     { Success INT, ErrorMessage NVARCHAR(MAX) }
-- Author:      Harrier Central
-- Created:     2026-05-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    DECLARE @KennelId UNIQUEIDENTIFIER;

    SELECT @KennelId = k.id
    FROM   HC.Kennel k
    WHERE  k.KennelUniqueShortName = @KennelSlug
      AND  k.deleted = 0
      AND  k.removed = 0;

    IF @KennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Kennel not found.' AS ErrorMessage;
        RETURN;
    END;

    IF ISJSON(@PageLayoutJson) = 0
    BEGIN
        SELECT 0 AS Success, 'PageLayoutJson is not valid JSON.' AS ErrorMessage;
        RETURN;
    END;

    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM HC.KennelWebsite WHERE KennelId = @KennelId)
    BEGIN
        UPDATE HC.KennelWebsite
        SET    PageLayoutJson = @PageLayoutJson,
               updatedAt      = SYSDATETIMEOFFSET()
        WHERE  KennelId = @KennelId;
    END
    ELSE
    BEGIN
        -- No KennelWebsite row yet — create minimal one.
        -- Enabled defaults to 0 so saving a layout does not auto-publish
        -- the website; the kennel must be explicitly enabled separately.
        INSERT INTO HC.KennelWebsite (KennelId, PageLayoutJson)
        VALUES (@KennelId, @PageLayoutJson);
    END

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
