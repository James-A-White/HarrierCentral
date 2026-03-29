CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getLandingPageData]
    @kennelUniqueShortName NVARCHAR(50)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getLandingPageData
-- Description: Returns kennel identity and website configuration needed
--              to render a public-web landing page, including HC6
--              theming from HC.KennelWebsite where configured.
--              Looked up by URL slug (KennelUniqueShortName).
--              Style columns fall back to the FILTH kennel's
--              KennelWebsite row when the requested kennel has no value.
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
--                           FILTH kennel (5029DE3A-D231-47AA-BE72-
--                           ECE9BCCD55D1) added as platform-level style
--                           defaults (kwf). HC.Kennel Website* column
--                           fallbacks removed — no kennel has data in
--                           those columns for the HC6 public web.
--             2026-03-27 — Added hardcoded content fallbacks for Tagline,
--                           WelcomeText, and TitleText (falls back to
--                           KennelName). Applies when the kennel has no
--                           KennelWebsite row or the column is NULL.
--             2026-03-28 — Added k.PublicKennelId so the frontend can pass
--                           it to subsequent public-web SPs (e.g.
--                           publicWeb_getEvents) that take a GUID key
--                           instead of the URL slug.
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None — PublicKennelId is a new column addition only.
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

    -- FILTH kennel — platform-level style defaults. Style columns COALESCE:
    --   kennel value (kw) → FILTH default (kwf) → hardcoded literal (ThemeMode/ScrollBlur only)
    -- HC.Kennel Website* columns are NOT used as fallbacks — no kennel has
    -- data in those columns for the HC6 public web.
    DECLARE @filthKennelId UNIQUEIDENTIFIER = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1';

    -- kw  = the requested kennel's KennelWebsite row (NULL if not yet configured)
    -- kwf = the FILTH kennel's KennelWebsite row    (NULL if FILTH not configured)
    -- Empty rowset (0 rows) = kennel not found or not publicly visible → 404.
    SELECT
        -- ── Core identity (from HC.Kennel) ───────────────────────────────────
        k.PublicKennelId,
        k.KennelName,
        k.KennelShortName,
        k.KennelUniqueShortName,
        k.KennelDescription,

        -- ── Branding — kennel → FILTH ────────────────────────────────────────
        COALESCE(kw.LogoUrl,         kwf.LogoUrl)         AS KennelLogo,
        COALESCE(kw.FaviconUrl,      kwf.FaviconUrl)      AS FaviconUrl,
        COALESCE(kw.BannerImage,     kwf.BannerImage)     AS BannerImage,
        COALESCE(kw.BackgroundImage, kwf.BackgroundImage) AS WebsiteBackgroundImage,

        -- ── HC6 theming — kennel → FILTH → literal last resort ───────────────
        COALESCE(kw.ThemeMode,    kwf.ThemeMode,    'dark') AS ThemeMode,
        COALESCE(kw.PrimaryColor, kwf.PrimaryColor)         AS PrimaryColor,
        COALESCE(kw.AccentColor,  kwf.AccentColor)          AS AccentColor,
        COALESCE(kw.ScrollBlur,   kwf.ScrollBlur,   0)      AS ScrollBlur,
        COALESCE(kw.OgImageUrl,   kwf.OgImageUrl)           AS OgImageUrl,

        -- ── Kennel-specific content — kennel → hardcoded platform default ──────
        COALESCE(kw.TitleText, k.KennelName)                                   AS WebsiteTitleText,
        COALESCE(kw.Tagline,   N'A Drinking Club with a Running Problem')       AS Tagline,
        COALESCE(kw.WelcomeText, N'The Hash House Harriers — or simply "the Hash" — is a worldwide social running group that combines a casual cross-country run with good company and a post-run celebration. Founded in Kuala Lumpur in 1938 by a group of British expatriates looking for a fun way to stay fit, the Hash has since grown to thousands of chapters across the globe. Each week, a volunteer "hare" lays a trail of chalk marks, flour, or paper, and the group — the "pack" — follows the clues to find the finish. No experience needed, no fitness level required. Walkers, joggers, and seasoned runners are all equally welcome. The only rule? Have fun.') AS WelcomeText,

        -- ── SEO (no FILTH default) ───────────────────────────────────────────
        kw.SeoTitle,
        kw.SeoDescription,
        kw.SeoStructuredDataJson,

        -- ── Routing ──────────────────────────────────────────────────────────
        kw.CustomDomain,
        kw.Enabled AS WebsiteEnabled,

        -- ── HC5 legacy colours — kennel → FILTH ──────────────────────────────
        COALESCE(kw.BackgroundColor,     kwf.BackgroundColor)     AS WebsiteBackgroundColor,
        COALESCE(kw.MenuBackgroundColor, kwf.MenuBackgroundColor) AS MenuBackgroundColor,
        COALESCE(kw.MenuTextColor,       kwf.MenuTextColor)       AS MenuTextColor,
        COALESCE(kw.BodyTextColor,       kwf.BodyTextColor)       AS BodyTextColor,
        COALESCE(kw.TitleTextColor,      kwf.TitleTextColor)      AS TitleTextColor

    FROM HC.Kennel k
    LEFT JOIN HC.KennelWebsite kw  ON kw.KennelId  = k.id
    LEFT JOIN HC.KennelWebsite kwf ON kwf.KennelId = @filthKennelId
    WHERE k.KennelUniqueShortName = @kennelUniqueShortName
      AND k.deleted = 0
      AND k.removed = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
