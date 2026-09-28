CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getGeography]
    @countryId UNIQUEIDENTIFIER = NULL,
    @regionId  UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getGeography
-- Description: The cascading Country → Region → City lists for the
--              hashruns.org/add-kennel form (E12.F1.S7), so a request names
--              the database's own places instead of free text for someone
--              to guess at later (the old EXT.ProcessKennelImports matched
--              cities with LIKE '%' + @City + '%'). The same lists the
--              portal's hcportal_getCountries / getRegions / getCities
--              give an authenticated admin; this one is anonymous, and
--              reference data only.
--              One door, three questions:
--                no parameters → every country;
--                @countryId    → that country's regions;
--                @regionId     → that region's cities.
-- Parameters:  @countryId, @regionId (at most one is used; @regionId wins).
-- Returns:     one rowset { id, name }, alphabetical.
-- Author:      Harrier Central
-- Created:     2026-09-28
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    IF (@regionId IS NOT NULL)
        SELECT c.id, c.CityName AS name
        FROM HC.City c
        WHERE c.RegionId = @regionId AND c.Removed = 0
        ORDER BY c.CityName;
    ELSE IF (@countryId IS NOT NULL)
        SELECT r.id, r.RegionName AS name
        FROM HC.Region r
        WHERE r.CountryId = @countryId AND r.Removed = 0
        ORDER BY r.RegionName;
    ELSE
        SELECT c.id, c.CountryName AS name
        FROM HC.Country c
        WHERE c.Removed = 0
        ORDER BY c.CountryName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getGeography',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
