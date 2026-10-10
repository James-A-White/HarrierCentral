CREATE OR ALTER PROCEDURE [HC6].[hcportal_updateKennelRequest]
    @deviceId          UNIQUEIDENTIFIER = NULL,
    @accessToken       NVARCHAR(1000)   = NULL,
    @kennelImportId    UNIQUEIDENTIFIER,
    @firstName         NVARCHAR(MAX)    = NULL,
    @lastName          NVARCHAR(MAX)    = NULL,
    @hashName          NVARCHAR(MAX)    = NULL,
    @emailAddress      NVARCHAR(MAX)    = NULL,
    @kennelName        NVARCHAR(MAX)    = NULL,
    @kennelShortName   NVARCHAR(MAX)    = NULL,
    @kennelDescription NVARCHAR(MAX)    = NULL,
    @kennelUrl         NVARCHAR(MAX)    = NULL,
    @kennelFacebookUrl NVARCHAR(MAX)    = NULL,
    @countryId         UNIQUEIDENTIFIER = NULL,
    @regionId          UNIQUEIDENTIFIER = NULL,
    @cityId            UNIQUEIDENTIFIER = NULL,
    @hashCash          NVARCHAR(MAX)    = NULL,
    @nonMemberPrice    NVARCHAR(MAX)    = NULL,
    @reviewNote        NVARCHAR(MAX)    = NULL,
    -- E12.F1.S10 (2026-10-10): what a website read adds. Text so that ''
    -- can clear a value (NULL keeps it), as for the fields above.
    @logoUrl           NVARCHAR(MAX)    = NULL,
    @foundedOn         NVARCHAR(MAX)    = NULL,
    @runDayOfWeek      NVARCHAR(MAX)    = NULL,
    @runStartTime      NVARCHAR(MAX)    = NULL,
    @runsPageUrl       NVARCHAR(MAX)    = NULL,
    @socialLinksJson   NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_updateKennelRequest
-- Description: A reviewer corrects a kennel request before approving it
--   (E12.F1.S5): the requester's details, the kennel's names and links,
--   the price, and — most often — the location, picked from the
--   database's own countries, regions and cities. Only an open request
--   (awaiting email or new) can be edited; an approved one already made
--   its kennel, and that kennel is edited in the kennel page instead.
--   Every parameter left NULL keeps the stored value; an empty string
--   clears an optional field. Replaces the UPDATE branch of the INSTEAD OF
--   trigger on EXT.vwOfficeForms_KennelImport (HC3W).
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth); @kennelImportId; the fields.
--   User text arrives as NVARCHAR(MAX) and is checked against the column
--   widths with LEN, so nothing is truncated silently.
-- Returns: rowset 0 — { Success, ErrorMessage }.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces trgVwOfficeForms_KennelImport UPDATE, HC3W)
-- Breaking Changes: none (new)
-- 2026-10-10 (E12.F1.S10): @logoUrl, @foundedOn ('yyyy'|'yyyy-mm'|
--   'yyyy-mm-dd'), @runDayOfWeek (1 Mon … 7 Sun), @runStartTime ('HH:mm'),
--   @runsPageUrl and @socialLinksJson (checked by HC6.SocialLinksProblem);
--   approval copies them onto the kennel.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError  NVARCHAR(255);
DECLARE @callerId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;

EXEC HC6.ValidatePortalAuth
    @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @callerId OUTPUT, @callerType OUTPUT;

IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanEditKennel = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanEditKennel required' AS ErrorMessage;
    RETURN;
END

-- Trim once; the checks and the UPDATE read the trimmed values.
SET @firstName         = TRIM(@firstName);
SET @lastName          = TRIM(@lastName);
SET @hashName          = TRIM(@hashName);
SET @emailAddress      = LOWER(TRIM(@emailAddress));
SET @kennelName        = TRIM(@kennelName);
SET @kennelShortName   = TRIM(@kennelShortName);
SET @kennelDescription = TRIM(@kennelDescription);
SET @kennelUrl         = TRIM(@kennelUrl);
SET @kennelFacebookUrl = TRIM(@kennelFacebookUrl);
SET @hashCash          = TRIM(@hashCash);
SET @nonMemberPrice    = TRIM(@nonMemberPrice);
SET @reviewNote        = TRIM(@reviewNote);
SET @logoUrl           = TRIM(@logoUrl);
SET @foundedOn         = TRIM(@foundedOn);
SET @runDayOfWeek      = TRIM(@runDayOfWeek);
SET @runStartTime      = TRIM(@runStartTime);
SET @runsPageUrl       = TRIM(@runsPageUrl);
SET @socialLinksJson   = TRIM(@socialLinksJson);

DECLARE @invalid NVARCHAR(500) = CASE
    WHEN @kennelImportId IS NULL                    THEN 'kennelImportId is required'
    WHEN LEN(@firstName) > 250 OR LEN(@lastName) > 250 OR LEN(@hashName) > 250
                                                    THEN 'Names may be at most 250 characters'
    WHEN LEN(@emailAddress) > 250                   THEN 'The email address may be at most 250 characters'
    WHEN @emailAddress IS NOT NULL AND @emailAddress NOT LIKE '%_@_%._%'
                                                    THEN 'That is not a valid email address'
    WHEN LEN(@kennelName) > 250                     THEN 'The kennel name may be at most 250 characters'
    WHEN @kennelName IS NOT NULL AND LEN(@kennelName) = 0
                                                    THEN 'The kennel name cannot be empty'
    WHEN LEN(@kennelShortName) > 20                 THEN 'The short name may be at most 20 characters'
    WHEN @kennelShortName IS NOT NULL AND LEN(@kennelShortName) = 0
                                                    THEN 'The short name cannot be empty'
    WHEN @kennelShortName COLLATE Latin1_General_BIN LIKE '%[^A-Za-z0-9]%'
                                                    THEN 'The short name may only hold letters and digits (it becomes the web address)'
    WHEN LEN(@kennelDescription) > 4000             THEN 'The description may be at most 4000 characters'
    WHEN LEN(@kennelUrl) > 250 OR LEN(@kennelFacebookUrl) > 250
                                                    THEN 'Links may be at most 250 characters'
    WHEN LEN(@hashCash) > 50 OR LEN(@nonMemberPrice) > 50
                                                    THEN 'The price may be at most 50 characters'
    WHEN LEN(@reviewNote) > 1000                    THEN 'The review note may be at most 1000 characters'
    WHEN LEN(@logoUrl) > 1000 OR LEN(@runsPageUrl) > 1000
                                                    THEN 'An address may be at most 1000 characters'
    WHEN LEN(@logoUrl) > 0 AND @logoUrl NOT LIKE N'https://%'
                                                    THEN 'The logo must be an https address'
    WHEN LEN(@runsPageUrl) > 0 AND @runsPageUrl NOT LIKE N'http%://%'
                                                    THEN 'The runs page must be a web address'
    WHEN LEN(@foundedOn) > 0 AND NOT (
            (LEN(@foundedOn) = 4  AND @foundedOn LIKE N'[12][0-9][0-9][0-9]')
         OR (LEN(@foundedOn) = 7  AND TRY_CAST(@foundedOn + N'-01' AS DATE) IS NOT NULL)
         OR (LEN(@foundedOn) = 10 AND TRY_CAST(@foundedOn AS DATE) IS NOT NULL))
                                                    THEN 'Founded must be a year (1984), a month (1984-06) or a date (1984-06-30)'
    WHEN LEN(@runDayOfWeek) > 0 AND ISNULL(TRY_CAST(@runDayOfWeek AS SMALLINT), 0) NOT BETWEEN 1 AND 7
                                                    THEN 'The run day must be 1 (Monday) to 7 (Sunday)'
    WHEN LEN(@runStartTime) > 0 AND TRY_CAST(@runStartTime AS TIME(0)) IS NULL
                                                    THEN 'The start time must be HH:mm, e.g. 18:30'
    WHEN LEN(@socialLinksJson) > 0 AND HC6.SocialLinksProblem(@socialLinksJson) IS NOT NULL
                                                    THEN HC6.SocialLinksProblem(@socialLinksJson)
    WHEN @regionId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM HC.Region r WHERE r.id = @regionId
              AND r.CountryId = COALESCE(@countryId,
                    (SELECT ki.CountryId FROM EXT.OfficeForms_KennelImport ki WHERE ki.KennelImportId = @kennelImportId)))
                                                    THEN 'That region is not in the chosen country'
    WHEN @cityId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM HC.City c WHERE c.id = @cityId
              AND c.RegionId = COALESCE(@regionId,
                    (SELECT ki.RegionId FROM EXT.OfficeForms_KennelImport ki WHERE ki.KennelImportId = @kennelImportId)))
                                                    THEN 'That city is not in the chosen region'
    ELSE NULL END;

IF (@invalid IS NOT NULL)
BEGIN
    SELECT 0 AS Success, @invalid AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @currentStatus SMALLINT;
    SELECT @currentStatus = ki.RequestStatus
    FROM EXT.OfficeForms_KennelImport ki WITH (UPDLOCK, HOLDLOCK)
    WHERE ki.KennelImportId = @kennelImportId;

    IF (@currentStatus IS NULL OR @currentStatus NOT IN (0, 1))
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success,
               CASE WHEN @currentStatus IS NULL THEN 'Request not found'
                    ELSE 'Only an open request can be edited' END AS ErrorMessage;
        RETURN;
    END

    -- A country change without a region clears the region and city below
    -- it, so the three can never disagree; the same for a region change.
    UPDATE ki SET
        FirstName         = COALESCE(@firstName, ki.FirstName),
        LastName          = COALESCE(@lastName, ki.LastName),
        HashName          = COALESCE(@hashName, ki.HashName),
        EmailAddress      = COALESCE(@emailAddress, ki.EmailAddress),
        KennelName        = COALESCE(@kennelName, ki.KennelName),
        KennelShortName   = COALESCE(@kennelShortName, ki.KennelShortName),
        KennelDescription = COALESCE(@kennelDescription, ki.KennelDescription),
        KennelUrl         = CASE WHEN @kennelUrl IS NULL THEN ki.KennelUrl ELSE NULLIF(@kennelUrl, N'') END,
        KennelFacebookUrl = CASE WHEN @kennelFacebookUrl IS NULL THEN ki.KennelFacebookUrl ELSE NULLIF(@kennelFacebookUrl, N'') END,
        HashCash          = COALESCE(@hashCash, ki.HashCash),
        NonMemberPrice    = CASE WHEN @nonMemberPrice IS NULL THEN ki.NonMemberPrice ELSE NULLIF(@nonMemberPrice, N'') END,
        ReviewNote        = CASE WHEN @reviewNote IS NULL THEN ki.ReviewNote ELSE NULLIF(@reviewNote, N'') END,
        LogoUrl           = CASE WHEN @logoUrl IS NULL THEN ki.LogoUrl ELSE NULLIF(@logoUrl, N'') END,
        FoundedOn         = CASE WHEN @foundedOn IS NULL THEN ki.FoundedOn ELSE NULLIF(@foundedOn, N'') END,
        RunDayOfWeek      = CASE WHEN @runDayOfWeek IS NULL THEN ki.RunDayOfWeek ELSE TRY_CAST(NULLIF(@runDayOfWeek, N'') AS SMALLINT) END,
        RunStartTime      = CASE WHEN @runStartTime IS NULL THEN ki.RunStartTime ELSE TRY_CAST(NULLIF(@runStartTime, N'') AS TIME(0)) END,
        RunsPageUrl       = CASE WHEN @runsPageUrl IS NULL THEN ki.RunsPageUrl ELSE NULLIF(@runsPageUrl, N'') END,
        SocialLinksJson   = CASE WHEN @socialLinksJson IS NULL THEN ki.SocialLinksJson ELSE NULLIF(@socialLinksJson, N'') END,
        CountryId         = COALESCE(@countryId, ki.CountryId),
        RegionId          = CASE WHEN @regionId IS NOT NULL THEN @regionId
                                 WHEN @countryId IS NOT NULL AND @countryId <> COALESCE(ki.CountryId, '00000000-0000-0000-0000-000000000000') THEN NULL
                                 ELSE ki.RegionId END,
        CityId            = CASE WHEN @cityId IS NOT NULL THEN @cityId
                                 WHEN @regionId IS NOT NULL AND @regionId <> COALESCE(ki.RegionId, '00000000-0000-0000-0000-000000000000') THEN NULL
                                 WHEN @countryId IS NOT NULL AND @countryId <> COALESCE(ki.CountryId, '00000000-0000-0000-0000-000000000000') THEN NULL
                                 ELSE ki.CityId END,
        updatedAt         = GETDATE()
    FROM EXT.OfficeForms_KennelImport ki
    WHERE ki.KennelImportId = @kennelImportId;

    -- Keep the text columns in step with the ids, so the history reads the
    -- names the kennel was created with.
    UPDATE ki SET
        Country = COALESCE(LEFT(co.CountryName, 50), ki.Country),
        Region  = COALESCE(LEFT(re.RegionName, 50), ki.Region),
        City    = COALESCE(LEFT(ci.CityName, 50), ki.City)
    FROM EXT.OfficeForms_KennelImport ki
    LEFT JOIN HC.Country co ON co.id = ki.CountryId
    LEFT JOIN HC.Region  re ON re.id = ki.RegionId
    LEFT JOIN HC.City    ci ON ci.id = ki.CityId
    WHERE ki.KennelImportId = @kennelImportId;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_updateKennelRequest',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
