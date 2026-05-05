CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getPageLayout]
    @KennelSlug NVARCHAR(100)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getPageLayout
-- Description: Returns the saved Puck page layout JSON for a kennel.
--              Used by the public landing page to load a kennel's
--              custom layout (falls back to the hardcoded default when
--              PageLayoutJson IS NULL or the row doesn't exist yet).
-- Parameters:  @KennelSlug NVARCHAR(100) — HC.Kennel.KennelUniqueShortName
-- Returns:     Rowset 0: { PageLayoutJson NVARCHAR(MAX) } — one row.
--              Zero rows = kennel not found → shim returns 404.
--              One row with PageLayoutJson NULL = no layout saved yet.
-- Author:      Harrier Central
-- Created:     2026-05-05
-- =====================================================================
SET NOCOUNT ON;

BEGIN TRY

    -- LEFT JOIN so kennels without a KennelWebsite row still return one
    -- row (PageLayoutJson = NULL), rather than zero rows (which the shim
    -- would misread as a 404).
    SELECT kw.PageLayoutJson
    FROM   HC.Kennel        k
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE  k.KennelUniqueShortName = @KennelSlug
      AND  k.deleted = 0
      AND  k.removed = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
