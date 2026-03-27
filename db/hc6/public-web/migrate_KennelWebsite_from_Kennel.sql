-- =====================================================================
-- Migration: Populate HC.KennelWebsite from HC.Kennel
--
-- Purpose:  Back-fills one KennelWebsite row per Kennel for all
--           kennels that pre-date the
--           TR_Kennel_AfterInsert_CreateKennelWebsite trigger.
--           Kennels created after that trigger was deployed already
--           have a stub row and are excluded by the LEFT JOIN filter.
--
-- Enabled:  All migrated rows are set to Enabled = 0. Review and
--           flip to 1 per kennel once you are happy with the config.
--
-- HC6 columns with no HC5 equivalent are left NULL:
--   CustomDomain, ThemeMode (defaults 'dark'), PrimaryColor,
--   AccentColor, ScrollBlur (defaults 0), OgImageUrl, Tagline,
--   SeoStructuredDataJson
--
-- Run once. Safe to re-run — the LEFT JOIN / WHERE filters are
-- idempotent and will insert nothing if all rows already exist.
-- =====================================================================

INSERT INTO [HC].[KennelWebsite]
(
    -- Identity
    [KennelId],
    [UrlShortcode],
    [Enabled],

    -- HC6 theming (no HC5 source — defaults applied)
    [ThemeMode],
    [ScrollBlur],

    -- Branding
    [LogoUrl],
    [FaviconUrl],
    [BannerImage],
    [BackgroundImage],

    -- HC5 colours
    [BackgroundColor],
    [MenuBackgroundColor],
    [MenuTextColor],
    [BodyTextColor],
    [TitleTextColor],

    -- HC5 fonts
    [TitleFont],
    [BodyFont],

    -- Content
    [TitleText],
    [WelcomeText],

    -- SEO
    [SeoTitle],
    [SeoDescription],

    -- Structured content
    [MismanagementDescription],
    [MismanagementJson],
    [ExtraMenusJson],
    [ContactDetailsJson],

    -- System flags
    [ControlFlags]

    -- createdAt / updatedAt intentionally omitted — column DEFAULTs
    -- and the updatedAt trigger handle these automatically
)
SELECT
    -- Identity
    ken.[id],
    ken.[WebsiteUrlShortcode],
    CASE WHEN ken.[WebsiteBackgroundColor] IS NOT NULL
              OR ken.[WebsiteBackgroundImage]  IS NOT NULL
         THEN 1 ELSE 0 END,             -- Enabled = 1 if any background config exists

    -- HC6 theming (column DEFAULTs will apply for ThemeMode / ScrollBlur
    -- since we are omitting them here, but explicit values make intent clear)
    'dark',                                 -- ThemeMode default; update per kennel
    0,                                      -- ScrollBlur default

    -- Branding
    ken.[KennelLogo],
    ken.[KennelFavicon],
    ken.[WebsiteBannerImage],
    ken.[WebsiteBackgroundImage],

    -- HC5 colours
    ken.[WebsiteBackgroundColor],
    ken.[WebsiteMenuBackgroundColor],
    ken.[WebsiteMenuTextColor],
    ken.[WebsiteBodyTextColor],
    ken.[WebsiteTitleTextColor],

    -- HC5 fonts
    ken.[WebsiteTitleFont],
    ken.[WebsiteBodyFont],

    -- Content
    ken.[WebsiteTitleText],
    ken.[WebsiteWelcomeText],

    -- SEO
    ken.[KennelSeoTitle],
    ken.[KennelSeoDescription],

    -- Structured content
    ken.[WebsiteMismanagementDescription],
    ken.[WebsiteMismanagementJson],
    ken.[WebsiteExtraMenusJson],
    ken.[WebsiteContactDetailsJson],

    -- System flags
    ken.[WebsiteControlFlags]

FROM [HC].[Kennel] ken
LEFT OUTER JOIN [HC].[KennelWebsite] kws ON ken.[id] = kws.[KennelId]
WHERE kws.[KennelId] IS NULL       -- only kennels with no KennelWebsite row yet
  AND ken.[deleted]  = 0
  AND ken.[removed]  = 0;
