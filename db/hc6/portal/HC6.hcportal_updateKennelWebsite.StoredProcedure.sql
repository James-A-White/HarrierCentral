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
	@controlFlags INT = NULL

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

	-- Main update (wrapped in transaction)
	BEGIN TRANSACTION;

	UPDATE HC.KennelWebsite
	SET
		  [Enabled]                  = COALESCE(@enabled, [Enabled])
		, [ThemeMode]                = COALESCE(@themeMode, [ThemeMode])
		, [PrimaryColor]             = COALESCE(@primaryColor, [PrimaryColor])
		, [AccentColor]              = COALESCE(@accentColor, [AccentColor])
		, [ScrollBlur]               = COALESCE(@scrollBlur, [ScrollBlur])
		, [CustomDomain]             = COALESCE(@customDomain, [CustomDomain])
		, [UrlShortcode]             = COALESCE(@urlShortcode, [UrlShortcode])
		, [BannerImage]              = COALESCE(@bannerImage, [BannerImage])
		, [OgImageUrl]               = COALESCE(@ogImageUrl, [OgImageUrl])
		, [BackgroundImage]          = COALESCE(@backgroundImage, [BackgroundImage])
		, [TitleTextColor]           = COALESCE(@titleTextColor, [TitleTextColor])
		, [BodyTextColor]            = COALESCE(@bodyTextColor, [BodyTextColor])
		, [TextMutedColor]           = COALESCE(@textMutedColor, [TextMutedColor])
		, [CardBackgroundColor]      = COALESCE(@cardBackgroundColor, [CardBackgroundColor])
		, [BackgroundColor]          = COALESCE(@backgroundColor, [BackgroundColor])
		, [MenuBackgroundColor]      = COALESCE(@menuBackgroundColor, [MenuBackgroundColor])
		, [MenuTextColor]            = COALESCE(@menuTextColor, [MenuTextColor])
		, [TitleFont]                = COALESCE(@titleFont, [TitleFont])
		, [BodyFont]                 = COALESCE(@bodyFont, [BodyFont])
		, [TitleText]                = COALESCE(@titleText, [TitleText])
		, [Tagline]                  = COALESCE(@tagline, [Tagline])
		, [WelcomeText]              = COALESCE(@welcomeText, [WelcomeText])
		, [SeoTitle]                 = COALESCE(@seoTitle, [SeoTitle])
		, [SeoDescription]           = COALESCE(@seoDescription, [SeoDescription])
		, [SeoStructuredDataJson]    = COALESCE(@seoStructuredDataJson, [SeoStructuredDataJson])
		, [MismanagementDescription] = COALESCE(@mismanagementDescription, [MismanagementDescription])
		, [MismanagementJson]        = COALESCE(@mismanagementJson, [MismanagementJson])
		, [ExtraMenusJson]           = COALESCE(@extraMenusJson, [ExtraMenusJson])
		, [ContactDetailsJson]       = COALESCE(@contactDetailsJson, [ContactDetailsJson])
		, [ControlFlags]             = COALESCE(@controlFlags, [ControlFlags])
	WHERE KennelId = @kennelId;

	COMMIT TRANSACTION;

	SELECT 'Website settings updated successfully' AS result, 1 AS resultCode;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
