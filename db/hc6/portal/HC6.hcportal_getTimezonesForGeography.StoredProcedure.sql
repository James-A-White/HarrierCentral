CREATE OR ALTER PROCEDURE [HC6].[hcportal_getTimezonesForGeography]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	-- filters
	@countryId UNIQUEIDENTIFIER = NULL,
	@regionId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getTimezonesForGeography
-- Description: Returns the distinct timezones actually used by cities in a
--              given country (optionally narrowed to a region). Powers the
--              manual timezone dropdown shown when a run's location is
--              entered as free text ("Other" region/city) and therefore has
--              no structured city to derive a timezone from.
-- Parameters: @deviceId, @accessToken (auth); @countryId (required filter);
--             @regionId (optional — narrows to one region's cities)
-- Returns: Single rowset: id (DomainValues.Timezone.id), displayName,
--          ianaTimeZone, utcOffset (standard-time offset, formatted)
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

	DECLARE @yr INT = YEAR(SYSUTCDATETIME());

	-- Distinct zones used by cities in the country (optionally one region).
	;WITH zones AS (
		SELECT DISTINCT
			t.id,
			t.FullTimezone,
			t.IanaTimeZone,
			t.Timezone AS windowsTz
		FROM HC.City c
		JOIN HC.Region r ON r.id = c.RegionId
		JOIN DomainValues.Timezone t ON t.id = c.TimezoneId
		WHERE r.CountryId = @countryId
		  AND (@regionId IS NULL OR c.RegionId = @regionId)
		  AND c.Removed = 0
	)
	SELECT
		z.id,
		z.FullTimezone AS displayName,
		z.IanaTimeZone AS ianaTimeZone,
		-- Standard-time offset (smaller of midwinter/midsummer) as a hint.
		'UTC'
			+ CASE WHEN o.stdOff < 0 THEN '-' ELSE '+' END
			+ RIGHT('00' + CAST(ABS(o.stdOff) / 60 AS VARCHAR(2)), 2)
			+ ':'
			+ RIGHT('00' + CAST(ABS(o.stdOff) % 60 AS VARCHAR(2)), 2) AS utcOffset
	FROM zones z
	CROSS APPLY (
		SELECT stdOff = CASE
			WHEN DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 1, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE z.windowsTz)
			   <= DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 7, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE z.windowsTz)
			THEN DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 1, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE z.windowsTz)
			ELSE DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 7, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE z.windowsTz)
		END
	) o
	ORDER BY displayName;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
