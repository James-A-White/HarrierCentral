CREATE OR ALTER PROCEDURE [HC6].[hcportal_getLoginHistory]

	-- required parameters
	@publicHasherId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@userId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getLoginHistory
-- Description: Returns login history for a specified user over the last
--              365 days. Includes login timestamps, app versions, device
--              types, and geolocation data ordered most recent first.
-- Parameters: @publicHasherId, @accessToken (auth)
--             @userId (user to query)
-- Returns: Single rowset: loginDate, hcVersion, systemVersion,
--          isIphone, latitude, longitude, locationName
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getLoginHistory
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for UNIQUEIDENTIFIER params
--   - Removed commented-out debug EXEC statement
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @now DATETIME2 = GETDATE()
DECLARE @cutoffDate DATETIME2 = DATEADD(YEAR, -1, @now)

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), NULL, @authError OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: userId
	IF @userId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid userId' AS ErrorMessage;
		RETURN;
	END

	-- =============================================
	-- Return login history for the specified user
	-- Last 365 days, ordered most recent first
	-- =============================================
	SELECT
		ll.LoginDate AS loginDate,
		ll.HcVersion AS hcVersion,
		COALESCE(ll.SystemVersion, '') AS systemVersion,
		CASE WHEN ll.SystemName LIKE '%ios%' THEN 1 ELSE 0 END AS isIphone,
		COALESCE(c.Latitude, 0.0) AS latitude,
		COALESCE(c.Longitude, 0.0) AS longitude,
		COALESCE(c.CityFullName, '') AS locationName
	FROM HC.LaunchAndLogin ll WITH (NOLOCK)
	LEFT OUTER JOIN HC.City c WITH (NOLOCK) ON c.id = ll.CityId
	WHERE ll.UserId = @userId
		AND ll.LoginDate > @cutoffDate
	ORDER BY ll.LoginDate DESC
	OPTION (RECOMPILE)

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
