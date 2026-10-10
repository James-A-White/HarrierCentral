CREATE OR ALTER PROCEDURE [HC6].[hcportal_kennelDraftLookup]
    @deviceId        UNIQUEIDENTIFIER = NULL,
    @accessToken     NVARCHAR(1000)   = NULL,
    @websiteUrl      NVARCHAR(MAX)    = NULL,
    @kennelName      NVARCHAR(MAX)    = NULL,
    @kennelShortName NVARCHAR(MAX)    = NULL,
    @country         NVARCHAR(MAX)    = NULL,
    @region          NVARCHAR(MAX)    = NULL,
    @city            NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_kennelDraftLookup
-- Description: "New kennel from a website" (E12.F1.S10, James 2026-10-10)
--   asks the database two things about a draft the AI read from a club's
--   website. Reads only; also the gate the KennelFromWebsite API checks
--   before it fetches a page or calls the AI.
--     1. Is this club already here? Live kennels — and open requests — with
--        the same website (host and path, ignoring http/https, www. and a
--        trailing slash), the same name, or the same short name.
--     2. Which of OUR cities is it in? The city the site names, matched by
--        name or accent-free name, within the country (and region) when
--        given. The city row carries the map point; the country the
--        currency — so the city is all the draft needs (James).
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth); the draft's website, names
--   and place names — any may be NULL.
-- Returns:
--   rowset 0 — { Success, ErrorMessage }
--   rowset 1 — possible duplicates { kind ('kennel'|'request'), name, slug,
--              website, reason ('website'|'name'|'short name') }
--   rowset 2 — city candidates, best first (at most 8) { cityId, cityName,
--              regionId, regionName, countryId, countryName, score (100 =
--              exact in the given region and country) }
--   rowset 3 — the country alone when it matched { countryId, countryName }
-- Author: Harrier Central
-- Created: 2026-10-10
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

BEGIN TRY
    SET @kennelName      = NULLIF(TRIM(@kennelName), N'');
    SET @kennelShortName = NULLIF(TRIM(@kennelShortName), N'');
    SET @country         = NULLIF(TRIM(@country), N'');
    SET @region          = NULLIF(TRIM(@region), N'');
    SET @city            = NULLIF(TRIM(@city), N'');

    -- A website reduced to host + path: 'sth3.org', 'oh3.info/v1'.
    DECLARE @site NVARCHAR(500) = LOWER(NULLIF(TRIM(@websiteUrl), N''));
    IF (@site IS NOT NULL)
    BEGIN
        SET @site = REPLACE(REPLACE(@site, N'https://', N''), N'http://', N'');
        IF (@site LIKE N'www.%') SET @site = SUBSTRING(@site, 5, 500);
        WHILE (RIGHT(@site, 1) = N'/') SET @site = LEFT(@site, LEN(@site) - 1);
        IF (LEN(@site) < 4) SET @site = NULL;
    END

    SELECT 1 AS Success, NULL AS ErrorMessage;

    ;WITH kennels AS (
        SELECT k.KennelName, k.KennelShortName, k.KennelUniqueShortName,
               k.KennelWebsiteUrl,
               site = CASE WHEN LEN(ISNULL(k.KennelWebsiteUrl, N'')) < 4 THEN NULL ELSE
                    (SELECT CASE WHEN x.s LIKE N'%/' THEN LEFT(x.s, LEN(x.s) - 1) ELSE x.s END
                     FROM (SELECT s = CASE WHEN y.s LIKE N'www.%' THEN SUBSTRING(y.s, 5, 500) ELSE y.s END
                           FROM (SELECT s = REPLACE(REPLACE(LOWER(TRIM(k.KennelWebsiteUrl)), N'https://', N''), N'http://', N'')) y) x) END
        FROM HC.Kennel k
        WHERE k.deleted = 0 AND k.removed = 0
    ), requests AS (
        SELECT ki.KennelName, ki.KennelShortName, ki.KennelUrl,
               site = CASE WHEN LEN(ISNULL(ki.KennelUrl, N'')) < 4 THEN NULL ELSE
                    (SELECT CASE WHEN x.s LIKE N'%/' THEN LEFT(x.s, LEN(x.s) - 1) ELSE x.s END
                     FROM (SELECT s = CASE WHEN y.s LIKE N'www.%' THEN SUBSTRING(y.s, 5, 500) ELSE y.s END
                           FROM (SELECT s = REPLACE(REPLACE(LOWER(TRIM(ki.KennelUrl)), N'https://', N''), N'http://', N'')) y) x) END
        FROM EXT.OfficeForms_KennelImport ki
        WHERE ki.RequestStatus IN (0, 1)
    )
    SELECT TOP 10 d.kind, d.name, d.slug, d.website, d.reason
    FROM (
        SELECT N'kennel' AS kind, k.KennelName AS name, k.KennelUniqueShortName AS slug,
               k.KennelWebsiteUrl AS website,
               CASE WHEN @site IS NOT NULL AND k.site = @site THEN N'website'
                    WHEN @kennelName IS NOT NULL AND k.KennelName = @kennelName THEN N'name'
                    ELSE N'short name' END AS reason,
               CASE WHEN @site IS NOT NULL AND k.site = @site THEN 0 ELSE 1 END AS rank
        FROM kennels k
        WHERE (@site IS NOT NULL AND k.site = @site)
           OR (@kennelName IS NOT NULL AND k.KennelName = @kennelName)
           OR (@kennelShortName IS NOT NULL AND (k.KennelShortName = @kennelShortName
                                                 OR k.KennelUniqueShortName = @kennelShortName))
        UNION ALL
        SELECT N'request', r.KennelName, r.KennelShortName, r.KennelUrl,
               CASE WHEN @site IS NOT NULL AND r.site = @site THEN N'website'
                    WHEN @kennelName IS NOT NULL AND r.KennelName = @kennelName THEN N'name'
                    ELSE N'short name' END,
               2
        FROM requests r
        WHERE (@site IS NOT NULL AND r.site = @site)
           OR (@kennelName IS NOT NULL AND r.KennelName = @kennelName)
           OR (@kennelShortName IS NOT NULL AND r.KennelShortName = @kennelShortName)
    ) d
    ORDER BY d.rank, d.name;

    -- Our country, then cities by name (accent-free too), best first.
    DECLARE @countryId UNIQUEIDENTIFIER =
        (SELECT TOP 1 co.id FROM HC.Country co
         WHERE ISNULL(co.Removed, 0) = 0
           AND (co.CountryName = @country OR co.CountryCode = @country)
         ORDER BY CASE WHEN co.CountryName = @country THEN 0 ELSE 1 END);

    SELECT TOP 8
        LOWER(CAST(ci.id AS NVARCHAR(40)))  AS cityId,     ci.CityName   AS cityName,
        LOWER(CAST(re.id AS NVARCHAR(40)))  AS regionId,   re.RegionName AS regionName,
        LOWER(CAST(co.id AS NVARCHAR(40)))  AS countryId,  co.CountryName AS countryName,
        s.score
    FROM HC.City ci
    JOIN HC.Region re  ON re.id = ci.RegionId
    JOIN HC.Country co ON co.id = re.CountryId
    CROSS APPLY (SELECT
        exact  = CASE WHEN ci.CityName = @city OR ci.City_ASCII = @city THEN 1 ELSE 0 END,
        inReg  = CASE WHEN @region IS NOT NULL AND (re.RegionName = @region OR re.RegionAbbreviation = @region) THEN 1 ELSE 0 END,
        inCtry = CASE WHEN @countryId IS NOT NULL AND co.id = @countryId THEN 1 ELSE 0 END) m
    CROSS APPLY (SELECT score =
        CASE WHEN m.exact = 1 AND m.inCtry = 1 AND m.inReg = 1 THEN 100
             WHEN m.exact = 1 AND m.inCtry = 1                 THEN 90
             WHEN m.exact = 1 AND @countryId IS NULL           THEN 70
             WHEN m.exact = 0 AND m.inCtry = 1                 THEN 50
             ELSE 0 END) s
    WHERE @city IS NOT NULL
      AND ISNULL(ci.Removed, 0) = 0
      AND (ci.CityName = @city OR ci.City_ASCII = @city
           OR (LEN(@city) >= 3 AND (ci.CityName LIKE @city + N'%' OR ci.City_ASCII LIKE @city + N'%')))
      AND s.score > 0
    ORDER BY s.score DESC, ci.CityName;

    SELECT LOWER(CAST(co.id AS NVARCHAR(40))) AS countryId, co.CountryName AS countryName
    FROM HC.Country co WHERE co.id = @countryId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_kennelDraftLookup',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
