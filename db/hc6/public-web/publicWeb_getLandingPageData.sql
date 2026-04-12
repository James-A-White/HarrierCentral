CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getLandingPageData]
    @kennelUniqueShortName NVARCHAR(50)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getLandingPageData
-- Description: Returns kennel identity and website configuration needed
--              to render a public-web landing page, including HC6
--              theming from HC.KennelWebsite where configured.
--              Looked up by URL slug (KennelUniqueShortName).
-- Parameters:  @kennelUniqueShortName  NVARCHAR(50) — URL slug;
--                                      maps to Kennel.KennelUniqueShortName
-- Returns:     Rowset 0: single KennelLandingPage row, or empty if the
--                        kennel is not found / inactive / deleted.
--              Empty rowset = 404 at the shim layer.
--              On validation or runtime error: single-row error envelope
--                        (Success = 0, ErrorMessage = ...).
-- Author:      Harrier Central
-- Created:     2026-03-26
-- Updated:     2026-03-27 — Added HC.KennelWebsite join; HC6 theming,
--                           OgImage, SEO, and scroll effect columns.
--             2026-03-27 — Added hardcoded content fallbacks for Tagline,
--                           WelcomeText, and TitleText.
--             2026-04-06 — BackgroundImage no longer inherited from FILTH;
--                           returns NULL when kennel has none.
--             2026-03-28 — Added k.PublicKennelId.
--             2026-04-12 — Removed FILTH kennel fallback join (kwf).
--                           Style defaults that were sourced from FILTH's
--                           KennelWebsite row are now hardcoded literals
--                           so FILTH kennel changes cannot affect other
--                           kennels. Logo and favicon now read from
--                           HC.Kennel.KennelLogo / KennelFavicon directly;
--                           LogoUrl and FaviconUrl removed from
--                           HC.KennelWebsite.
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None
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

    -- kw = the requested kennel's KennelWebsite row (NULL columns if not yet configured).
    -- Empty rowset (0 rows) = kennel not found or not publicly visible → 404.
    SELECT
        -- ── Core identity (from HC.Kennel) ───────────────────────────────────
        k.PublicKennelId,
        k.KennelName,
        k.KennelShortName,
        k.KennelUniqueShortName,
        k.KennelDescription,

        -- ── Branding — logo/favicon always from HC.Kennel ────────────────────
        k.KennelLogo                                                AS KennelLogo,
        k.KennelFavicon                                             AS FaviconUrl,
        kw.BannerImage                                              AS BannerImage,

        -- BackgroundImage is kennel-specific — NULL means frontend uses the platform default tile.
        kw.BackgroundImage                                          AS WebsiteBackgroundImage,

        -- ── HC6 theming — kennel value or hardcoded platform default ─────────
        COALESCE(kw.ThemeMode,  'dark')                             AS ThemeMode,
        kw.PrimaryColor                                             AS PrimaryColor,
        kw.AccentColor                                              AS AccentColor,
        COALESCE(kw.ScrollBlur, 0)                                  AS ScrollBlur,
        kw.OgImageUrl                                               AS OgImageUrl,

        -- ── Kennel-specific content ───────────────────────────────────────────
        COALESCE(kw.TitleText, k.KennelName)                        AS WebsiteTitleText,
        COALESCE(kw.Tagline,   N'A Drinking Club with a Running Problem') AS Tagline,
        COALESCE(kw.WelcomeText, N'The Hash House Harriers — or simply "the Hash" — is a worldwide social running group that combines a casual cross-country run with good company and a post-run celebration. Founded in Kuala Lumpur in 1938 by a group of British expatriates looking for a fun way to stay fit, the Hash has since grown to thousands of chapters across the globe. Each week, a volunteer "hare" lays a trail of chalk marks, flour, or paper, and the group — the "pack" — follows the clues to find the finish. No experience needed, no fitness level required. Walkers, joggers, and seasoned runners are all equally welcome. The only rule? Have fun.') AS WelcomeText,

        -- ── SEO (no platform default) ─────────────────────────────────────────
        kw.SeoTitle,
        kw.SeoDescription,
        kw.SeoStructuredDataJson,

        -- ── Routing ───────────────────────────────────────────────────────────
        kw.CustomDomain,
        kw.Enabled                                                  AS WebsiteEnabled,

        -- ── HC5 legacy colours ────────────────────────────────────────────────
        kw.BackgroundColor                                          AS WebsiteBackgroundColor,
        kw.MenuBackgroundColor,
        kw.MenuTextColor,
        kw.BodyTextColor,
        kw.TitleTextColor

    FROM HC.Kennel k
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE k.KennelUniqueShortName = @kennelUniqueShortName
      AND k.deleted = 0
      AND k.removed = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
