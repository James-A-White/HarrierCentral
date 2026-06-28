CREATE OR ALTER PROCEDURE [HC6].[hcportal_getCities]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	-- filter
	@regionId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getCities
-- Description: Returns the cities for a given region from HC.City,
--              ordered alphabetically by CityName. Used to populate the
--              cascading Country -> Region -> City selector in the run
--              editor.
-- Parameters: @deviceId, @accessToken (auth); @regionId (filter)
-- Returns: Single rowset: id, CityName
-- Author: Harrier Central
-- Created: 2026-06-28
-- HC5 Source: none (new in HC6)
-- Breaking Changes: none
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Main query
	SELECT c.id, c.CityName
	FROM HC.City c
	WHERE c.RegionId = @regionId
	  AND c.Removed = 0
	ORDER BY c.CityName

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
