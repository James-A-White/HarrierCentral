CREATE OR ALTER PROCEDURE [HC6].[hcportal_getCityTimezones]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	-- one of these identifies the zone (cityId takes precedence)
	@cityId UNIQUEIDENTIFIER = NULL,
	@timezoneId INT = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getCityTimezones
-- Description: Returns the relevant timezone(s) for a zone. The zone is
--              identified either by @cityId (HC.City.TimezoneId) or, when a
--              run's location is free-text ('Other'), by a directly-chosen
--              @timezoneId (Event.TimezoneId). @cityId takes precedence.
--              Most zones have two clock representations across the year —
--              Standard and Daylight (DST). This SP derives both offsets
--              from the Windows zone via AT TIME ZONE (which knows the DST
--              rules), returning one row when the zone has no DST and two
--              rows when it does. Used for the read-only timezone display in
--              the run editor.
-- Parameters: @deviceId, @accessToken (auth); @cityId OR @timezoneId
-- Returns: Single rowset (1-2 rows): sortOrder, kind, utcOffset,
--          ianaTimeZone, windowsTimeZone, observesDst
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

	-- Resolve the Windows time zone + IANA name. Prefer the city's zone; fall
	-- back to a directly-supplied @timezoneId (the manual 'Other' case).
	DECLARE @windowsTz NVARCHAR(300);
	DECLARE @iana NVARCHAR(300);

	IF @cityId IS NOT NULL
		SELECT @windowsTz = t.Timezone, @iana = t.IanaTimeZone
		FROM HC.City c
		JOIN DomainValues.Timezone t ON t.id = c.TimezoneId
		WHERE c.id = @cityId;

	IF @windowsTz IS NULL AND @timezoneId IS NOT NULL
		SELECT @windowsTz = t.Timezone, @iana = t.IanaTimeZone
		FROM DomainValues.Timezone t
		WHERE t.id = @timezoneId;

	-- No city / no timezone → return an empty rowset (no error).
	IF @windowsTz IS NULL
	BEGIN
		SELECT TOP 0
			CAST(0 AS INT) AS sortOrder,
			CAST('' AS NVARCHAR(20)) AS kind,
			CAST('' AS NVARCHAR(20)) AS utcOffset,
			CAST('' AS NVARCHAR(300)) AS ianaTimeZone,
			CAST('' AS NVARCHAR(300)) AS windowsTimeZone,
			CAST(0 AS SMALLINT) AS observesDst;
		RETURN;
	END

	-- Probe the offset at midwinter and midsummer of the current year. DST
	-- always shifts the clock forward, so the smaller offset is Standard and
	-- the larger is Daylight — true in both hemispheres. Equal => no DST.
	DECLARE @yr INT = YEAR(SYSUTCDATETIME());
	DECLARE @janOff INT = DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 1, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE @windowsTz);
	DECLARE @julOff INT = DATEPART(TZOFFSET, CAST(DATETIMEFROMPARTS(@yr, 7, 1, 0, 0, 0, 0) AS datetime2) AT TIME ZONE @windowsTz);
	DECLARE @stdOff INT = CASE WHEN @janOff <= @julOff THEN @janOff ELSE @julOff END;
	DECLARE @dstOff INT = CASE WHEN @janOff >= @julOff THEN @janOff ELSE @julOff END;
	DECLARE @observesDst SMALLINT = CASE WHEN @stdOff <> @dstOff THEN 1 ELSE 0 END;

	;WITH offs AS (
		SELECT * FROM (VALUES
			(0, 'Standard', @stdOff),
			(1, 'Daylight', @dstOff)
		) v(sortOrder, kind, offMin)
	)
	SELECT
		o.sortOrder,
		o.kind,
		-- Format the offset minutes as 'UTC±HH:MM'.
		'UTC'
			+ CASE WHEN o.offMin < 0 THEN '-' ELSE '+' END
			+ RIGHT('00' + CAST(ABS(o.offMin) / 60 AS VARCHAR(2)), 2)
			+ ':'
			+ RIGHT('00' + CAST(ABS(o.offMin) % 60 AS VARCHAR(2)), 2) AS utcOffset,
		@iana AS ianaTimeZone,
		@windowsTz AS windowsTimeZone,
		@observesDst AS observesDst
	FROM offs o
	-- Drop the Daylight row when the zone doesn't observe DST.
	WHERE NOT (o.sortOrder = 1 AND @observesDst = 0)
	ORDER BY o.sortOrder;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
