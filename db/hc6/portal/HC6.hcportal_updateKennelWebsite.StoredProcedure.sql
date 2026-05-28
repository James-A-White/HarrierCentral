CREATE OR ALTER PROCEDURE [HC6].[hcportal_updateKennelWebsite]

	-- required parameters (accept nulls so SQL can trap errors rather than execution failure)
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL,

	-- optional parameters — all use COALESCE so omitted params preserve existing values
	@enabled BIT = NULL,
	@themeMode NVARCHAR(10) = NULL,
	@primaryColor NVARCHAR(25) = NULL,
	@accentColor NVARCHAR(25) = NULL,
	@scrollBlur SMALLINT = NULL,
	@customDomain NVARCHAR(250) = NULL,
	@urlShortcode NVARCHAR(50) = NULL,
	@bannerImage NVARCHAR(500) = NULL,
	@ogImageUrl NVARCHAR(500) = NULL,
	@backgroundImage NVARCHAR(500) = NULL,
	@titleTextColor NVARCHAR(25) = NULL,
	@bodyTextColor NVARCHAR(25) = NULL,
	@textMutedColor NVARCHAR(9) = NULL,
	@cardBackgroundColor NVARCHAR(9) = NULL,
	@buttonPrimaryColor NVARCHAR(9) = NULL,
	@buttonCancelColor NVARCHAR(9) = NULL,
	@buttonSecondaryColor NVARCHAR(9) = NULL,
	@runCardColor NVARCHAR(9) = NULL,
	@backgroundColor NVARCHAR(25) = NULL,
	@menuBackgroundColor NVARCHAR(25) = NULL,
	@menuTextColor NVARCHAR(25) = NULL,
	@titleFont NVARCHAR(100) = NULL,
	@bodyFont NVARCHAR(100) = NULL,
	@titleText NVARCHAR(500) = NULL,
	@tagline NVARCHAR(250) = NULL,
	@welcomeText NVARCHAR(4000) = NULL,
	@seoTitle NVARCHAR(60) = NULL,
	@seoDescription NVARCHAR(155) = NULL,
	@seoStructuredDataJson NVARCHAR(MAX) = NULL,
	@mismanagementDescription NVARCHAR(4000) = NULL,
	@mismanagementJson NVARCHAR(4000) = NULL,
	@extraMenusJson NVARCHAR(4000) = NULL,
	@contactDetailsJson NVARCHAR(4000) = NULL,
	@controlFlags INT = NULL,
	@pageFeaturesJson NVARCHAR(4000) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_updateKennelWebsite
-- Description: Updates a kennel's HC6 public website configuration in
--              HC.KennelWebsite. Update-only (row created on kennel insert
--              via TR_Kennel_AfterInsert_CreateKennelWebsite trigger).
--              Uses COALESCE so only supplied parameters are written.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing)
--             ~30 optional website settings via COALESCE pattern
-- Returns: SuccessResult rowset (result, resultCode) or error envelope
-- Author: Harrier Central
-- Created: 2026-05-03
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Validation: themeMode must be 'light' or 'dark' if supplied
	IF @themeMode IS NOT NULL AND @themeMode NOT IN ('light', 'dark')
	BEGIN
		SELECT 0 AS Success, 'Invalid themeMode — must be ''light'' or ''dark''' AS ErrorMessage;
		RETURN;
	END

	-- Validation: scrollBlur must be 0–100 if supplied
	IF @scrollBlur IS NOT NULL AND (@scrollBlur < 0 OR @scrollBlur > 100)
	BEGIN
		SELECT 0 AS Success, 'Invalid scrollBlur — must be between 0 and 100' AS ErrorMessage;
		RETURN;
	END

	-- Resolve kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER;
	SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId;

	-- Validation: kennel exists
	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
		RETURN;
	END

	-- Validation: KennelWebsite row exists (should always exist due to trigger, but be safe)
	IF NOT EXISTS (SELECT 1 FROM HC.KennelWebsite WHERE KennelId = @kennelId)
	BEGIN
		SELECT 0 AS Success, 'KennelWebsite record not found for this kennel' AS ErrorMessage;
		RETURN;
	END

	-- Privilege check: caller must have admin rights for this kennel (H12 fix).
	-- AppAccessFlags 0x40000081 = superAdmin | authIsAdmin; either is sufficient.
	DECLARE @appAccessFlags INT = 0;
	SELECT @appAccessFlags = ISNULL(hkm.AppAccessFlags, 0)
	FROM HC.HasherKennelMap hkm
	WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId;

	IF (@appAccessFlags & 0x40000081) = 0
	BEGIN
		SELECT 0 AS Success, 'You are not authorised to update this kennel''s website.' AS ErrorMessage;
		RETURN;
	END

	-- Main update (wrapped in transaction)
	BEGIN TRANSACTION;

	-- Empty string ('') is the sentinel for "clear this field to NULL".
	-- Non-string fields (BIT, INT) use plain COALESCE — they are never cleared.
	-- Nullable NVARCHAR fields use CASE WHEN to honour the sentinel.
	UPDATE HC.KennelWebsite
	SET
		  [Enabled]                  = COALESCE(@enabled, [Enabled])
		, [ThemeMode]                = COALESCE(@themeMode, [ThemeMode])
		, [ScrollBlur]               = COALESCE(@scrollBlur, [ScrollBlur])
		, [PrimaryColor]             = CASE WHEN @primaryColor             = '' THEN NULL ELSE COALESCE(@primaryColor,             [PrimaryColor])             END
		, [AccentColor]              = CASE WHEN @accentColor              = '' THEN NULL ELSE COALESCE(@accentColor,              [AccentColor])              END
		, [CustomDomain]             = CASE WHEN @customDomain             = '' THEN NULL ELSE COALESCE(@customDomain,             [CustomDomain])             END
		, [UrlShortcode]             = CASE WHEN @urlShortcode             = '' THEN NULL ELSE COALESCE(@urlShortcode,             [UrlShortcode])             END
		, [BannerImage]              = CASE WHEN @bannerImage              = '' THEN NULL ELSE COALESCE(@bannerImage,              [BannerImage])              END
		, [OgImageUrl]               = CASE WHEN @ogImageUrl               = '' THEN NULL ELSE COALESCE(@ogImageUrl,               [OgImageUrl])               END
		, [BackgroundImage]          = CASE WHEN @backgroundImage          = '' THEN NULL ELSE COALESCE(@backgroundImage,          [BackgroundImage])          END
		, [TitleTextColor]           = CASE WHEN @titleTextColor           = '' THEN NULL ELSE COALESCE(@titleTextColor,           [TitleTextColor])           END
		, [BodyTextColor]            = CASE WHEN @bodyTextColor            = '' THEN NULL ELSE COALESCE(@bodyTextColor,            [BodyTextColor])            END
		, [TextMutedColor]           = CASE WHEN @textMutedColor           = '' THEN NULL ELSE COALESCE(@textMutedColor,           [TextMutedColor])           END
		, [CardBackgroundColor]      = CASE WHEN @cardBackgroundColor      = '' THEN NULL ELSE COALESCE(@cardBackgroundColor,      [CardBackgroundColor])      END
		, [ButtonPrimaryColor]        = CASE WHEN @buttonPrimaryColor        = '' THEN NULL ELSE COALESCE(@buttonPrimaryColor,        [ButtonPrimaryColor])        END
		, [ButtonCancelColor]         = CASE WHEN @buttonCancelColor         = '' THEN NULL ELSE COALESCE(@buttonCancelColor,         [ButtonCancelColor])         END
		, [ButtonSecondaryColor]      = CASE WHEN @buttonSecondaryColor      = '' THEN NULL ELSE COALESCE(@buttonSecondaryColor,      [ButtonSecondaryColor])      END
		, [RunCardColor]             = CASE WHEN @runCardColor             = '' THEN NULL ELSE COALESCE(@runCardColor,             [RunCardColor])             END
		, [BackgroundColor]          = CASE WHEN @backgroundColor          = '' THEN NULL ELSE COALESCE(@backgroundColor,          [BackgroundColor])          END
		, [MenuBackgroundColor]      = CASE WHEN @menuBackgroundColor      = '' THEN NULL ELSE COALESCE(@menuBackgroundColor,      [MenuBackgroundColor])      END
		, [MenuTextColor]            = CASE WHEN @menuTextColor            = '' THEN NULL ELSE COALESCE(@menuTextColor,            [MenuTextColor])            END
		, [TitleFont]                = CASE WHEN @titleFont                = '' THEN NULL ELSE COALESCE(@titleFont,                [TitleFont])                END
		, [BodyFont]                 = CASE WHEN @bodyFont                 = '' THEN NULL ELSE COALESCE(@bodyFont,                [BodyFont])                 END
		, [TitleText]                = CASE WHEN @titleText                = '' THEN NULL ELSE COALESCE(@titleText,                [TitleText])                END
		, [Tagline]                  = CASE WHEN @tagline                  = '' THEN NULL ELSE COALESCE(@tagline,                  [Tagline])                  END
		, [WelcomeText]              = CASE WHEN @welcomeText              = '' THEN NULL ELSE COALESCE(@welcomeText,              [WelcomeText])              END
		, [SeoTitle]                 = CASE WHEN @seoTitle                 = '' THEN NULL ELSE COALESCE(@seoTitle,                 [SeoTitle])                 END
		, [SeoDescription]           = CASE WHEN @seoDescription           = '' THEN NULL ELSE COALESCE(@seoDescription,           [SeoDescription])           END
		, [SeoStructuredDataJson]    = CASE WHEN @seoStructuredDataJson    = '' THEN NULL ELSE COALESCE(@seoStructuredDataJson,    [SeoStructuredDataJson])    END
		, [MismanagementDescription] = CASE WHEN @mismanagementDescription = '' THEN NULL ELSE COALESCE(@mismanagementDescription, [MismanagementDescription]) END
		, [MismanagementJson]        = CASE WHEN @mismanagementJson        = '' THEN NULL ELSE COALESCE(@mismanagementJson,        [MismanagementJson])        END
		, [ExtraMenusJson]           = CASE WHEN @extraMenusJson           = '' THEN NULL ELSE COALESCE(@extraMenusJson,           [ExtraMenusJson])           END
		, [ContactDetailsJson]       = CASE WHEN @contactDetailsJson       = '' THEN NULL ELSE COALESCE(@contactDetailsJson,       [ContactDetailsJson])       END
		, [ControlFlags]             = CASE WHEN @controlFlags             IS NULL THEN [ControlFlags] ELSE @controlFlags             END
		, [PageFeaturesJson]         = CASE WHEN @pageFeaturesJson         = '' THEN NULL ELSE COALESCE(@pageFeaturesJson,         [PageFeaturesJson])         END
	WHERE KennelId = @kennelId;

	COMMIT TRANSACTION;

	SELECT 'Website settings updated successfully' AS result, 1 AS resultCode;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
