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
-- Updated:     2026-03-27 — LEFT JOIN HC.KennelWebsite added; HC6
--                           theming, OgImage, SEO, and scroll effect
--                           columns added. Overlapping columns COALESCE
--                           from KennelWebsite first, falling back to
--                           HC.Kennel values during data migration.
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: Adds new nullable columns to rowset. No removals.
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

    -- Return kennel identity and website config.
    -- HC.KennelWebsite columns are NULL until the data migration from
    -- HC.Kennel runs. Overlapping legacy columns COALESCE KennelWebsite
    -- first so the migration cutover is seamless with no SP redeploy.
    -- Empty rowset (0 rows) = kennel not found or not publicly visible → 404.
    SELECT
        -- ── Core identity (always from HC.Kennel) ────────────────────
        k.KennelName,
        k.KennelShortName,
        k.KennelUniqueShortName,
        k.KennelDescription,

        -- ── Branding — KennelWebsite preferred, HC.Kennel fallback ───
        COALESCE(kw.LogoUrl,         k.KennelLogo)             AS KennelLogo,
        COALESCE(kw.FaviconUrl,      k.KennelFavicon)          AS FaviconUrl,
        COALESCE(kw.BannerImage,     k.WebsiteBannerImage)     AS BannerImage,
        COALESCE(kw.BackgroundImage, k.WebsiteBackgroundImage) AS WebsiteBackgroundImage,
        COALESCE(kw.TitleText,       k.WebsiteTitleText)       AS WebsiteTitleText,

        -- ── HC6 theming (NULL until data migration) ──────────────────
        kw.ThemeMode,
        kw.PrimaryColor,
        kw.AccentColor,
        kw.ScrollBlur,
        kw.Tagline,
        kw.WelcomeText,
        kw.OgImageUrl,

        -- ── SEO — KennelWebsite preferred, HC.Kennel fallback ────────
        COALESCE(kw.SeoTitle,       k.KennelSeoTitle)       AS SeoTitle,
        COALESCE(kw.SeoDescription, k.KennelSeoDescription) AS SeoDescription,
        kw.SeoStructuredDataJson,

        -- ── Routing ──────────────────────────────────────────────────
        kw.CustomDomain,
        kw.Enabled AS WebsiteEnabled,

        -- ── HC5 legacy colours — KennelWebsite preferred, fallback ───
        COALESCE(kw.BackgroundColor,     k.WebsiteBackgroundColor)     AS WebsiteBackgroundColor,
        COALESCE(kw.MenuBackgroundColor, k.WebsiteMenuBackgroundColor) AS MenuBackgroundColor,
        COALESCE(kw.MenuTextColor,       k.WebsiteMenuTextColor)       AS MenuTextColor,
        COALESCE(kw.BodyTextColor,       k.WebsiteBodyTextColor)       AS BodyTextColor,
        COALESCE(kw.TitleTextColor,      k.WebsiteTitleTextColor)      AS TitleTextColor

    FROM HC.Kennel k
    LEFT JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE k.KennelUniqueShortName = @kennelUniqueShortName
      AND k.deleted = 0
      AND k.removed = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
