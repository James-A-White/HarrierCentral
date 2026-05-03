CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennelWebsite]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennelWebsite
-- Description: Retrieves the HC6 public website configuration row for a
--              single kennel. If no row exists yet, inserts a default row
--              so the Edit Website form always has something to load.
--              Returns all columns from HC.KennelWebsite.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing)
-- Returns: Single rowset with all KennelWebsite columns, or error envelope
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

	-- Resolve kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER;
	SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId;

	-- Validation: kennel exists
	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
		RETURN;
	END

	-- Upsert: create a default row if this kennel has no website config yet.
	-- This ensures the Edit Website form always has a row to load.
	IF NOT EXISTS (SELECT 1 FROM HC.KennelWebsite WHERE KennelId = @kennelId)
	BEGIN
		INSERT INTO HC.KennelWebsite (KennelId, Enabled, ThemeMode, ScrollBlur)
		VALUES (@kennelId, 0, 'dark', 0);
	END

	-- Return the row
	SELECT
		  kw.[KennelId]                 AS kennelId
		, kw.[CustomDomain]             AS customDomain
		, kw.[UrlShortcode]             AS urlShortcode
		, kw.[Enabled]                  AS enabled
		, kw.[ThemeMode]                AS themeMode
		, kw.[PrimaryColor]             AS primaryColor
		, kw.[AccentColor]              AS accentColor
		, kw.[ScrollBlur]               AS scrollBlur
		, kw.[BannerImage]              AS bannerImage
		, kw.[OgImageUrl]               AS ogImageUrl
		, kw.[BackgroundImage]          AS backgroundImage
		, kw.[TitleTextColor]           AS titleTextColor
		, kw.[BodyTextColor]            AS bodyTextColor
		, kw.[TextMutedColor]           AS textMutedColor
		, kw.[CardBackgroundColor]      AS cardBackgroundColor
		, kw.[BackgroundColor]          AS backgroundColor
		, kw.[MenuBackgroundColor]      AS menuBackgroundColor
		, kw.[MenuTextColor]            AS menuTextColor
		, kw.[TitleFont]                AS titleFont
		, kw.[BodyFont]                 AS bodyFont
		, kw.[TitleText]                AS titleText
		, kw.[Tagline]                  AS tagline
		, kw.[WelcomeText]              AS welcomeText
		, kw.[SeoTitle]                 AS seoTitle
		, kw.[SeoDescription]           AS seoDescription
		, kw.[SeoStructuredDataJson]    AS seoStructuredDataJson
		, kw.[MismanagementDescription] AS mismanagementDescription
		, kw.[MismanagementJson]        AS mismanagementJson
		, kw.[ExtraMenusJson]           AS extraMenusJson
		, kw.[ContactDetailsJson]       AS contactDetailsJson
		, kw.[ControlFlags]             AS controlFlags
	FROM HC.KennelWebsite kw
	WHERE kw.KennelId = @kennelId;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
