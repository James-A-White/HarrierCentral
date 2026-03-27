-- =====================================================================
-- Table: HC.KennelWebsite
-- Description: Per-kennel HC6 public website configuration. One row per
--              kennel. Absence of a row means the kennel has no HC6
--              public website configured yet.
--
-- Relationship: 1:1 optional with HC.Kennel (KennelId is PK and FK).
--              Slug is NOT stored here — join to HC.Kennel.KennelUniqueShortName.
--
-- Migration notes:
--   Website* columns migrated from HC.Kennel. HC5-era colour columns
--   (BackgroundColor, MenuTextColor, BodyTextColor, TitleTextColor,
--   MenuBackgroundColor) are preserved for migration completeness but are
--   likely superseded by PrimaryColor + AccentColor + ThemeMode in HC6.
--   Review before populating new kennels.
--
-- Author: Harrier Central
-- Created: 2026-03-27
-- =====================================================================

CREATE TABLE [HC].[KennelWebsite]
(
    -- ── Identity & routing ─────────────────────────────────────────────
    -- Slug lives on HC.Kennel.KennelUniqueShortName — join to resolve.
    [KennelId]                  UNIQUEIDENTIFIER    NOT NULL,
    [CustomDomain]              NVARCHAR(250)       NULL,       -- tier 3 custom domain (e.g. lh3.com); NULL = subdomain only
    [UrlShortcode]              NVARCHAR(50)        NULL,       -- HC5: WebsiteUrlShortcode; review vs KennelUniqueShortName at migration
    [Enabled]                   BIT                 NOT NULL    CONSTRAINT [DF_KennelWebsite_Enabled] DEFAULT (0),

    -- ── HC6 theming ────────────────────────────────────────────────────
    [ThemeMode]                 NVARCHAR(10)        NOT NULL    CONSTRAINT [DF_KennelWebsite_ThemeMode] DEFAULT ('dark'),  -- 'light' | 'dark'
    [PrimaryColor]              NVARCHAR(25)        NULL,       -- CSS hex; injected as --color-primary
    [AccentColor]               NVARCHAR(25)        NULL,       -- CSS hex; injected as --color-accent; falls back to PrimaryColor if NULL

    -- ── HC6 scroll effect ──────────────────────────────────────────────
    [ScrollBlur]                SMALLINT            NOT NULL    CONSTRAINT [DF_KennelWebsite_ScrollBlur] DEFAULT (0),     -- 0 = no blur, 100 = full blur on hero scroll; frontend maps to backdrop-filter intensity

    -- ── Branding & imagery ─────────────────────────────────────────────
    [LogoUrl]                   NVARCHAR(500)       NULL,       -- HC.Kennel: KennelLogo
    [FaviconUrl]                NVARCHAR(250)       NULL,       -- HC.Kennel: KennelFavicon
    [BannerImage]               NVARCHAR(500)       NULL,       -- HC5: WebsiteBannerImage; hero/header image
    [OgImageUrl]                NVARCHAR(500)       NULL,       -- Open Graph image (1200×630px recommended); used when page is shared on social/messaging; falls back to BannerImage if NULL
    [BackgroundImage]           NVARCHAR(500)       NULL,       -- HC5: WebsiteBackgroundImage

    -- ── HC5 colours (legacy) ───────────────────────────────────────────
    -- These were individually managed in HC5. In HC6, PrimaryColor +
    -- AccentColor + ThemeMode cover most use cases. Retained for migration
    -- completeness; evaluate before using in new HC6 templates.
    [BackgroundColor]           NVARCHAR(25)        NULL,       -- HC5: WebsiteBackgroundColor
    [MenuBackgroundColor]       NVARCHAR(25)        NULL,       -- HC5: WebsiteMenuBackgroundColor
    [MenuTextColor]             NVARCHAR(25)        NULL,       -- HC5: WebsiteMenuTextColor
    [BodyTextColor]             NVARCHAR(25)        NULL,       -- HC5: WebsiteBodyTextColor
    [TitleTextColor]            NVARCHAR(25)        NULL,       -- HC5: WebsiteTitleTextColor

    -- ── HC5 fonts (legacy) ─────────────────────────────────────────────
    [TitleFont]                 NVARCHAR(100)       NULL,       -- HC5: WebsiteTitleFont
    [BodyFont]                  NVARCHAR(100)       NULL,       -- HC5: WebsiteBodyFont

    -- ── Content ────────────────────────────────────────────────────────
    [TitleText]                 NVARCHAR(500)       NULL,       -- HC5: WebsiteTitleText; custom display name shown in hero (distinct from KennelName)
    [Tagline]                   NVARCHAR(250)       NULL,       -- short strapline shown under logo/title
    [WelcomeText]               NVARCHAR(4000)      NULL,       -- HC5: WebsiteWelcomeText; homepage welcome/intro copy

    -- ── SEO ────────────────────────────────────────────────────────────
    [SeoTitle]                  NVARCHAR(60)        NULL,       -- per-tenant <title> tag; HC.Kennel: KennelSeoTitle
    [SeoDescription]            NVARCHAR(155)       NULL,       -- per-tenant <meta description>; HC.Kennel: KennelSeoDescription
    [SeoStructuredDataJson]     NVARCHAR(MAX)       NULL,       -- JSON-LD override for Organization/SportsClub schema; SP generates a default from HC.Kennel data (name, city, country, logo, founded date); this field overrides per-kennel when needed

    -- ── Structured content (JSON) ──────────────────────────────────────
    [MismanagementDescription]  NVARCHAR(4000)      NULL,       -- HC5: WebsiteMismanagementDescription
    [MismanagementJson]         NVARCHAR(4000)      NULL,       -- HC5: WebsiteMismanagementJson; committee contacts
    [ExtraMenusJson]            NVARCHAR(4000)      NULL,       -- HC5: WebsiteExtraMenusJson; custom nav items
    [ContactDetailsJson]        NVARCHAR(4000)      NULL,       -- HC5: WebsiteContactDetailsJson

    -- ── System ─────────────────────────────────────────────────────────
    [ControlFlags]              INT                 NULL,       -- HC5: WebsiteControlFlags; bit flags for feature toggles
    [createdAt]                 DATETIMEOFFSET(7)   NOT NULL    CONSTRAINT [DF_KennelWebsite_createdAt] DEFAULT (SYSDATETIMEOFFSET()),
    [updatedAt]                 DATETIMEOFFSET(7)   NOT NULL    CONSTRAINT [DF_KennelWebsite_updatedAt] DEFAULT (SYSDATETIMEOFFSET()),

    -- ── Constraints ────────────────────────────────────────────────────
    CONSTRAINT [PK_KennelWebsite]
        PRIMARY KEY CLUSTERED ([KennelId]),

    CONSTRAINT [FK_KennelWebsite_Kennel]
        FOREIGN KEY ([KennelId]) REFERENCES [HC].[Kennel] ([id]),

    CONSTRAINT [CK_KennelWebsite_ThemeMode]
        CHECK ([ThemeMode] IN ('light', 'dark')),

    CONSTRAINT [CK_KennelWebsite_ScrollBlur]
        CHECK ([ScrollBlur] BETWEEN 0 AND 100)
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- Custom domain lookup — used by middleware for tier 3 tenants; filtered index excludes NULLs
-- (a standard unique index on a nullable column would block all but one NULL row)
CREATE UNIQUE NONCLUSTERED INDEX [UQ_KennelWebsite_CustomDomain]
    ON [HC].[KennelWebsite] ([CustomDomain])
    WHERE [CustomDomain] IS NOT NULL
GO
