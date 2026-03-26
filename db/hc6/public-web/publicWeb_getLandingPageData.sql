CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getLandingPageData]
    @kennelUniqueShortName NVARCHAR(50)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getLandingPageData
-- Description: Returns the minimum kennel identity data needed to render
--              a public-web landing page. Looked up by the unique short
--              name, which maps directly to the kennel's URL slug
--              (e.g. "lh3" → lh3.harriercentral.com).
-- Parameters:  @kennelUniqueShortName  NVARCHAR(50) — URL slug;
--                                      maps to Kennel.KennelUniqueShortName
-- Returns:     Rowset 0: single KennelLandingPage row, or empty if the
--                        kennel is not found / inactive / deleted.
--              On validation or runtime error: single-row error envelope
--                        (Success = 0, ErrorMessage = ...).
-- Author:      Harrier Central
-- Created:     2026-03-26
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: N/A (new SP)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Input validation
    IF LEN(LTRIM(RTRIM(ISNULL(@kennelUniqueShortName, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'KennelUniqueShortName is required.' AS ErrorMessage;
        RETURN;
    END;

    IF LEN(@kennelUniqueShortName) > 50
    BEGIN
        SELECT 0 AS Success, 'KennelUniqueShortName exceeds maximum length.' AS ErrorMessage;
        RETURN;
    END;

    -- Return kennel identity data.
    -- Empty rowset (0 rows) means the kennel does not exist or is not
    -- publicly visible — the caller should treat this as a 404.
    SELECT
        k.KennelLogo,
        k.KennelDescription,
        k.KennelShortName,
        k.KennelUniqueShortName,
        k.KennelName,
        k.WebsiteBackgroundImage,
        k.WebsiteBackgroundColor,
        k.WebsiteTitleText
    FROM HC.Kennel k
    WHERE k.KennelUniqueShortName = @kennelUniqueShortName
      AND k.deleted  = 0
      AND k.removed  = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
