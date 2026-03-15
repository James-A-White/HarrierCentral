CREATE OR ALTER PROCEDURE [HC6].[hcportal_test]

	-- required parameters
	@publicKennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_test
-- Description: Test/debug SP that retrieves the top 5 event names for a
--              given kennel, ordered by event start date descending.
--              No authentication — intentionally lightweight for testing.
-- Parameters: @publicKennelId (kennel to query)
-- Returns: Single rowset: EventName (top 5)
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_test
-- Breaking Changes:
--   - Removed dead input parameters: @publicHasherId, @accessToken,
--     @ipAddress, @ipGeoDetails (none were used in HC5 body)
--   - Removed commented-out debug EXEC statement
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	SELECT TOP 5 evt.EventName FROM HC.Event evt
	INNER JOIN HC.Kennel k ON evt.KennelId = k.id
	WHERE k.PublicKennelId = @publicKennelId
	ORDER BY EventStartDatetime DESC

END TRY
BEGIN CATCH
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
