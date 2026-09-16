CREATE OR ALTER PROCEDURE [HC6].[publicWeb_searchKennels]
    @q NVARCHAR(100) = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_searchKennels
-- Description: Kennel directory search for the web's Kennels tab
--              (E9.F7.S9): name, short name, slug, city, region, country
--              AND the four *SearchTags columns — "Scotland" is neither a
--              Region nor a Country row, and a kennel in Edinburgh is only
--              findable by that word through KennelSearchTags
--              (reference_search_tags_columns). Public read; no auth.
-- Parameters:  @q - the words typed; NULL/empty returns the 50 most
--              recently active kennels.
-- Returns:     Rowset 0: up to 50 kennels.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @term NVARCHAR(102) = '%' + LTRIM(RTRIM(COALESCE(@q, ''))) + '%';
    SELECT TOP 50
        k.PublicKennelId,
        k.KennelUniqueShortName                                  AS KennelSlug,
        k.KennelShortName,
        k.KennelName,
        k.KennelLogo,
        k.KennelStatus,
        c.CityName                                               AS City,
        rgn.RegionName                                           AS Region,
        ctr.CountryName                                          AS Country,
        (SELECT MAX(e.EventStartDateTimeGmt) FROM HC.Event e
          WHERE e.KennelId = k.id AND e.IsVisible = 1 AND e.deleted = 0 AND e.removed = 0) AS LastRunGmt
    FROM HC.Kennel k
    LEFT JOIN HC.City    c   ON c.id   = k.CityId
    LEFT JOIN HC.Region  rgn ON rgn.id = k.ProvinceStateId
    LEFT JOIN HC.Country ctr ON ctr.id = k.CountryId
    WHERE k.deleted = 0 AND k.removed = 0
      AND k.KennelStatus IN (1, 2)
      AND (
            @term = '%%'
         OR k.KennelName            LIKE @term
         OR k.KennelShortName       LIKE @term
         OR k.KennelUniqueShortName LIKE @term
         OR c.CityName              LIKE @term
         OR rgn.RegionName          LIKE @term
         OR ctr.CountryName         LIKE @term
         OR REPLACE(COALESCE(k.KennelSearchTags,   ''), ',', ' ') LIKE @term
         OR REPLACE(COALESCE(c.CitySearchTags,      ''), ',', ' ') LIKE @term
         OR REPLACE(COALESCE(rgn.RegionSearchTags,  ''), ',', ' ') LIKE @term
         OR REPLACE(COALESCE(ctr.CountrySearchTags, ''), ',', ' ') LIKE @term
          )
    ORDER BY LastRunGmt DESC, k.KennelShortName;
END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_searchKennels', ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
