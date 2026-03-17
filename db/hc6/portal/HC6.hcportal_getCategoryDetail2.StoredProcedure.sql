CREATE OR ALTER PROCEDURE [HC6].[hcportal_getCategoryDetail2]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@categoryId SMALLINT = NULL,
	@days SMALLINT = 7,

	-- optional parameters
	@hcVersion NVARCHAR(100) = NULL,
	@hcBuild NVARCHAR(100) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getCategoryDetail2
-- Description: Retrieves activity feed data for the HC admin portal
--              dashboard. Returns raw data columns for one of 10
--              categories: 0=New Hashers, 1=Event RSVPs, 2=New Events,
--              3=New Kennels, 4=App Logins, 5=Payments, 6=Portal Access,
--              7=Errors, 8=HashRuns.Org Traffic, 100=Version Adoption.
--              Each category returns typed columns specific to its data.
--              Portal is responsible for all presentation formatting.
-- Parameters: @deviceId, @accessToken (auth)
--             @categoryId (which category), @days (lookback window)
--             @hcVersion, @hcBuild (category 100 only)
-- Returns: Single rowset with raw typed columns per category
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getCategoryDetail2
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH(@publicHasherId) != 16 replaced with @publicHasherId IS NULL
--   - Added SET XACT_ABORT ON
--   - Added TRY/CATCH error handling
--   - Fixed LOG.GeneralLog LogSource: was 'hcportal_getCategoryDetail'
--     (wrong), now 'hcportal_getCategoryDetail2' (correct)
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog/GeneralLog inserts (logging moved to API shim)
--   - All categories now return raw data columns instead of formatted message strings
--   - Removed header metadata rowset (was rowset 1 with col1-col6 labels)
--   - Portal must implement time-ago formatting and string concatenation
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Allow dirty reads for reporting queries

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

	-- Validation: categoryId
	IF @categoryId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null categoryId' AS ErrorMessage;
		RETURN;
	END

	-- Performance optimization: Calculate datetime values once
	DECLARE @now datetime2 = GETDATE()
	DECLARE @minutes int = 60
	IF (@days != 0) SET @minutes = (@days * 24 * 60)
	DECLARE @cutoffDate datetime2 = DATEADD(minute, -@minutes, @now)

	-- =============================================
	-- CATEGORY 0: New Hashers
	-- =============================================
	IF (@categoryId = 0)
	BEGIN
		;WITH cte AS (
			SELECT
				h.id AS hasherId,
				h.createdAt,
				h.displayName,
				h.HomeKennelId,
				c.CityFullName
			FROM HC.Hasher h WITH (NOLOCK)
			OUTER APPLY (
				SELECT TOP 1 c.CityFullName
				FROM HC.City c WITH (NOLOCK)
				WHERE h.HomeLatitude != 51.503300000
				ORDER BY h.HomeGeolocation.STDistance(c.CityGeolocation) ASC
			) c
			WHERE h.createdAt > @cutoffDate
		)
		SELECT
			cte.createdAt,
			cte.displayName,
			NULL AS homeKennelName,
			cte.CityFullName AS cityFullName
		FROM cte
		WHERE cte.HomeKennelId IS NULL

		UNION ALL

		SELECT
			cte.createdAt,
			cte.displayName,
			k.KennelName AS homeKennelName,
			cte.CityFullName AS cityFullName
		FROM cte
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON cte.HomeKennelId = k.id

		ORDER BY createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 1: Event RSVPs
	-- =============================================
	IF (@categoryId = 1)
	BEGIN
		SELECT
			hem.updatedAt,
			ken.KennelName AS kennelName,
			evt.EventNumber AS eventNumber,
			CASE
				WHEN hem.VirginVisitorType = 0 THEN h.DisplayName
				ELSE hem.DisplayName
			END AS displayName,
			hem.VirginVisitorType AS virginVisitorType,
			hem.RsvpState AS rsvpState,
			hem.AttendenceState AS attendenceState,
			COALESCE(hem.TotalRunsThisKennel, 0) AS totalRunsThisKennel,
			COALESCE(hem.TotalHaringThisKennel, 0) AS totalHaringThisKennel
		FROM HC.HasherEventMap hem WITH (NOLOCK)
		INNER JOIN HC.Event evt WITH (NOLOCK) ON hem.EventId = evt.id
		INNER JOIN HC.Kennel ken WITH (NOLOCK) ON ken.id = hem.KennelId
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON h.id = hem.UserId
		WHERE hem.updatedAt > @cutoffDate
		ORDER BY hem.updatedAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 2: New Events
	-- =============================================
	IF (@categoryId = 2)
	BEGIN
		SELECT
			evt.createdAt,
			evt.InboundIntegrationId AS inboundIntegrationId,
			ken.KennelName AS kennelName,
			evt.EventNumber AS eventNumber,
			evt.EventStartDatetimeIndexed AS eventStartDatetime,
			evt.EventName AS eventName
		FROM HC.Event evt WITH (NOLOCK)
		INNER JOIN HC.Kennel ken WITH (NOLOCK) ON evt.KennelId = ken.id
		WHERE evt.createdAt > @cutoffDate
		ORDER BY evt.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 3: New Kennels
	-- =============================================
	IF (@categoryId = 3)
	BEGIN
		SELECT
			ken.createdAt,
			ken.KennelName AS kennelName,
			COALESCE(c.CityFullName, c.cityCountryName, c.cityName) AS cityFullName
		FROM HC.Kennel ken WITH (NOLOCK)
		INNER JOIN HC.City c WITH (NOLOCK) ON ken.CityId = c.id
		WHERE ken.createdAt > @cutoffDate
		ORDER BY ken.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 4: App Logins
	-- =============================================
	IF (@categoryId = 4)
	BEGIN
		SELECT
			ll.LoginDate AS loginDate,
			h.displayName,
			ll.DeviceName AS deviceName,
			ll.Manufacturer AS manufacturer,
			ll.DeviceType AS deviceType,
			ll.SystemName AS systemName,
			ll.SystemVersion AS systemVersion,
			c.CityFullName AS cityFullName
		FROM HC.LaunchAndLogin ll WITH (NOLOCK)
		LEFT OUTER JOIN HC.Hasher h WITH (NOLOCK) ON ll.UserId = h.id
		LEFT OUTER JOIN HC.City c WITH (NOLOCK) ON c.id = ll.CityId
		WHERE ll.LoginDate > @cutoffDate
			AND ll.UserId <> '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
			AND ll.UserId <> 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A'
		ORDER BY ll.LoginDate DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 5: Payments
	-- =============================================
	IF (@categoryId = 5)
	BEGIN
		SELECT
			p.createdAt,
			k.KennelName AS kennelName,
			evt.EventNumber AS eventNumber,
			CASE
				WHEN hem.VirginVisitorType = 0 THEN h1.DisplayName
				ELSE hem.DisplayName
			END AS displayName,
			hem.VirginVisitorType AS virginVisitorType,
			h2.DisplayName AS processedByDisplayName,
			h3.DisplayName AS cancelledByDisplayName,
			p.CreditAmount AS creditAmount,
			p.DebitAmount AS debitAmount,
			p.PaymentType AS paymentType,
			p.PaymentProvider AS paymentProvider,
			p.CreditAvailable AS creditAvailable,
			p.DoPayForExtras AS doPayForExtras,
			evt.ExtrasDescription AS extrasDescription,
			COALESCE(k.CurrencySymbol, c.CurrencySymbol) AS currencySymbol
		FROM HC.Payment p WITH (NOLOCK)
		INNER JOIN HC.HasherEventMap hem WITH (NOLOCK) ON p.HasherEventMapId = hem.id
		INNER JOIN HC.Hasher h1 WITH (NOLOCK) ON p.UserId = h1.id
		INNER JOIN HC.Hasher h2 WITH (NOLOCK) ON p.PaymentProcessedBy_userId = h2.id
		LEFT OUTER JOIN HC.Hasher h3 WITH (NOLOCK) ON p.CancelledBy_UserId = h3.id
		INNER JOIN HC.Event evt WITH (NOLOCK) ON evt.id = p.EventId
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON evt.KennelId = k.id
		INNER JOIN HC.Country c WITH (NOLOCK) ON k.CountryId = c.id
		WHERE p.createdAt > @cutoffDate
		ORDER BY p.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 6: Portal Access
	-- =============================================
	IF (@categoryId = 6)
	BEGIN
		SELECT
			pa.accessDate,
			h.DisplayName AS displayName,
			k.KennelName AS kennelName
		FROM HC.PortalAccess pa WITH (NOLOCK)
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON pa.hasherId = h.id
		LEFT OUTER JOIN HC.Kennel k WITH (NOLOCK) ON h.HomeKennelId = k.id
		WHERE pa.accessDate > @cutoffDate
			AND pa.hasherId <> '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
			AND pa.hasherId <> 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A'
		ORDER BY pa.accessDate DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 7: Errors
	-- =============================================
	IF (@categoryId = 7)
	BEGIN
		SELECT
			er.updatedAt,
			er.ErrorDescription AS errorDescription,
			h.displayName,
			er.userId,
			er.ProcName AS procName
		FROM HC.ErrorLog er WITH (NOLOCK)
		LEFT OUTER JOIN HC.Hasher h WITH (NOLOCK) ON er.userId = h.id
		WHERE er.updatedAt > @cutoffDate
		ORDER BY er.updatedAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 8: HashRuns.Org Traffic
	-- =============================================
	IF (@categoryId = 8)
	BEGIN
		SELECT
			gl.Timestamp AS [timestamp],
			JSON_VALUE(gl.data, '$.city') AS city,
			JSON_VALUE(gl.data, '$.region') AS region,
			JSON_VALUE(gl.data, '$.country') AS country,
			gl.message AS logMessage,
			ken.KennelName AS kennelName,
			evt.EventName AS eventName
		FROM LOG.GeneralLog gl WITH (NOLOCK)
		LEFT OUTER JOIN HC.Event evt WITH (NOLOCK) ON evt.PublicEventId = gl.StrParam1
		LEFT OUTER JOIN HC.Kennel ken WITH (NOLOCK) ON ken.id = evt.KennelId
		WHERE (gl.LogSource = 'HashRuns.Org Event List' OR gl.LogSource = 'HashRuns.Org Single Event')
			AND gl.Timestamp > @cutoffDate
		ORDER BY gl.Timestamp DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 100: Version Adoption
	-- =============================================
	IF (@categoryId = 100)
	BEGIN
		;WITH cte AS (
			SELECT
				MAX(ll.LoginDate) AS updatedAt,
				ll.UserId,
				MAX(ll.idx) AS idx,
				COUNT(CASE WHEN ll.HcVersion LIKE '%' + @hcVersion + '%' AND ll.HcVersion LIKE '%' + @hcBuild + '%' THEN 1 ELSE NULL END) AS thisVersionCnt,
				COUNT(*) AS twoWeekCnt
			FROM HC.LaunchAndLogin ll WITH (NOLOCK)
			WHERE ll.LoginDate > @cutoffDate
			GROUP BY ll.UserId
		)
		SELECT
			cte.updatedAt,
			h.DisplayName AS displayName,
			ll.HcVersion AS hcVersion,
			ll.SystemName AS systemName,
			cte.twoWeekCnt AS twoWeekCount,
			cte.thisVersionCnt AS thisVersionCount
		FROM cte
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON cte.UserId = h.id
		INNER JOIN HC.LaunchAndLogin ll WITH (NOLOCK) ON ll.idx = cte.idx
		WHERE ll.HcVersion LIKE '%' + @hcVersion + '%'
			AND ll.HcVersion LIKE '%' + @hcBuild + '%'
		GROUP BY h.DisplayName, ll.HcVersion, cte.updatedAt, cte.thisVersionCnt, cte.twoWeekCnt, ll.SystemName
		ORDER BY cte.twoWeekCnt DESC
		OPTION (RECOMPILE)
	END

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
