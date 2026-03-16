CREATE OR ALTER PROCEDURE [HC6].[hcportal_getUsageData]
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getUsageData
-- Description: Returns comprehensive platform usage statistics for the
--              HC admin portal dashboard. Includes app version
--              distribution, integration job status, usage metrics
--              across data types (Account, Activity, Event, Kennel,
--              Login, Payment, Portal, Error), recent login details,
--              and recently updated/active events.
-- Parameters: @deviceId, @accessToken (auth)
-- Returns: Rowset 1: VersionData (iOS vs Android)
--          Rowset 2: IntegrationJobData
--          Rowset 3: UsageStatistics
--          Rowset 4: LoginInformation
--          Rowset 5: RecentEvents
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getUsageData
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error with RETURN
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Fixed LOG.GeneralLog LogSource: was 'hcportal_getKennelHashers',
--     now correctly says 'hcportal_getUsageData'
--   - Fixed DATALENGTH(ll.SystemName) > 4 to LEN(ll.SystemName) > 2
--     (DATALENGTH returns byte count for NVARCHAR, so >4 bytes = >2 chars)
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, OBJECT_NAME(@@PROCID), NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Get future run count
	DECLARE @futureRunCount INT;
	SELECT @futureRunCount = COUNT(*)
	FROM HC.Event WITH (NOLOCK)
	WHERE EventStartDatetimeIndexed > GETDATE();

	-- Result Set 1: Version data (iOS vs Android usage)
	;WITH LatestLogins AS (
		SELECT
			ll.UserId,
			MAX(ll.idx) AS idx,
			MAX(ll.LoginDate) AS loginDate
		FROM HC.LaunchAndLogin ll WITH (NOLOCK)
		WHERE ll.LoginDate > DATEADD(DAY, -14, GETDATE())
			AND LEN(ll.SystemName) > 2
			AND ll.HcVersion LIKE 'HC Ver:%'
		GROUP BY ll.UserId
	),
	VersionStats AS (
		SELECT
			REPLACE(REPLACE(ll2.HcVersion, 'HC Ver: ', ''), ', Bld: ', '-') AS HcVersion,
			SUM(CASE WHEN ll2.SystemName = 'iOS' THEN 1 ELSE 0 END) AS isiPhone,
			SUM(CASE WHEN ll2.SystemName != 'iOS' THEN 1 ELSE 0 END) AS isNotiPhone
		FROM LatestLogins cte
		INNER JOIN HC.LaunchAndLogin ll2 WITH (NOLOCK) ON cte.idx = ll2.idx
		GROUP BY ll2.HcVersion
	)
	SELECT
		SUBSTRING(HcVersion, 1, PATINDEX('%--%', HcVersion) - 1) AS versionNum,
		SUBSTRING(HcVersion, PATINDEX('%--%', HcVersion) + 1, 1000) AS buildNum,
		isiPhone,
		isNotiPhone
	FROM VersionStats
	ORDER BY SUBSTRING(HcVersion, PATINDEX('%--%', HcVersion) + 1, 1000) DESC;

	-- Result Set 2: Integration job data
	;WITH LatestJobs AS (
		SELECT
			intg.IntegrationAbbreviation,
			MAX(ij.IntegrationJobId) AS IntegrationJobId,
			intg.Enabled AS integrationEnabled,
			intg.Interval
		FROM HC.IntegrationJob ij WITH (NOLOCK)
		INNER JOIN HC.Integration intg WITH (NOLOCK) ON ij.IntegrationId = intg.IntegrationId
		WHERE ij.endedAt IS NOT NULL
		GROUP BY intg.IntegrationAbbreviation, intg.Enabled, intg.Interval
	)
	SELECT TOP 10
		lj.IntegrationAbbreviation AS integrationAbbreviation,
		lj.integrationEnabled AS integrationEnabled,
		lj.Interval AS interval,
		ij.IntegrationId AS integrationId,
		ij.RecordsRead AS recordsRead,
		ij.RecordsWritten AS recordsWritten,
		ij.RecordsFailedInfo AS recordsFailedInfo,
		ij.ErrorCount AS errorCount,
		ij.ErrorInfo AS errorInfo,
		ij.endedAt AS endedAt,
		DATEDIFF(MINUTE, ij.endedAt, GETDATE()) AS minutesAgo,
		ij.KennelsSucceeded AS kennelsSucceeded,
		ij.KennelsSucceededInfo AS kennelsSucceededInfo,
		ij.KennelsFailed AS kennelsFailed,
		ij.KennelsFailedInfo AS kennelsFailedInfo,
		@futureRunCount AS futureRunCount
	FROM LatestJobs lj
	INNER JOIN HC.IntegrationJob ij WITH (NOLOCK) ON lj.IntegrationJobId = ij.IntegrationJobId
	ORDER BY lj.IntegrationAbbreviation;

	-- Result Set 3: Usage statistics across different data types
	;WITH DateBounds AS (
		SELECT
			nowUtc = SYSUTCDATETIME(),
			hr1 = DATEADD(HOUR, -1, SYSUTCDATETIME()),
			hr2 = DATEADD(HOUR, -2, SYSUTCDATETIME()),
			d1  = DATEADD(DAY, -1, SYSUTCDATETIME()),
			d2  = DATEADD(DAY, -2, SYSUTCDATETIME()),
			w1  = DATEADD(WEEK, -1, SYSUTCDATETIME()),
			w2  = DATEADD(WEEK, -2, SYSUTCDATETIME()),
			m1  = DATEADD(MONTH, -1, SYSUTCDATETIME()),
			m2  = DATEADD(MONTH, -2, SYSUTCDATETIME())
	),
	ExcludedUsers AS (
		SELECT '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC' AS UserId
		UNION ALL
		SELECT 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A'
	)
	SELECT *
	FROM (
		-- Account
		SELECT
			'Account' AS dataType,
			0 AS id,
			SUM(CASE WHEN h.createdAt >= b.hr1 THEN 1 ELSE 0 END) AS lastHour,
			SUM(CASE WHEN h.createdAt >= b.hr2 AND h.createdAt < b.hr1 THEN 1 ELSE 0 END) AS lastHourComp,
			SUM(CASE WHEN h.createdAt >= b.d1 THEN 1 ELSE 0 END) AS lastDay,
			SUM(CASE WHEN h.createdAt >= b.d2 AND h.createdAt < b.d1 THEN 1 ELSE 0 END) AS lastDayComp,
			SUM(CASE WHEN h.createdAt >= b.w1 THEN 1 ELSE 0 END) AS lastWeek,
			SUM(CASE WHEN h.createdAt >= b.w2 AND h.createdAt < b.w1 THEN 1 ELSE 0 END) AS lastWeekComp,
			SUM(CASE WHEN h.createdAt >= b.m1 THEN 1 ELSE 0 END) AS lastMonth,
			SUM(CASE WHEN h.createdAt >= b.m2 AND h.createdAt < b.m1 THEN 1 ELSE 0 END) AS lastMonthComp
		FROM HC.Hasher h WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE h.createdAt >= b.m2

		UNION ALL

		-- Activity
		SELECT
			'Activity' AS dataType,
			1 AS id,
			SUM(CASE WHEN m.updatedAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.hr2 AND m.updatedAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.d2 AND m.updatedAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.w2 AND m.updatedAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN m.updatedAt >= b.m2 AND m.updatedAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.HasherEventMap m WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE m.updatedAt >= b.m2
			AND NOT EXISTS (SELECT 1 FROM ExcludedUsers eu WHERE eu.UserId = m.userId)

		UNION ALL

		-- Event
		SELECT
			'Event' AS dataType,
			2 AS id,
			SUM(CASE WHEN e.createdAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.hr2 AND e.createdAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.d2 AND e.createdAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.w2 AND e.createdAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN e.createdAt >= b.m2 AND e.createdAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.Event e WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE e.createdAt >= b.m2

		UNION ALL

		-- Kennel
		SELECT
			'Kennel' AS dataType,
			3 AS id,
			SUM(CASE WHEN k.createdAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.hr2 AND k.createdAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.d2 AND k.createdAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.w2 AND k.createdAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN k.createdAt >= b.m2 AND k.createdAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.Kennel k WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE k.createdAt >= b.m2

		UNION ALL

		-- Login
		SELECT
			'Login' AS dataType,
			4 AS id,
			SUM(CASE WHEN l.LoginDate >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.hr2 AND l.LoginDate < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.d2 AND l.LoginDate < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.w2 AND l.LoginDate < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN l.LoginDate >= b.m2 AND l.LoginDate < b.m1 THEN 1 ELSE 0 END)
		FROM HC.LaunchAndLogin l WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE l.LoginDate >= b.m2
			AND NOT EXISTS (SELECT 1 FROM ExcludedUsers eu WHERE eu.UserId = l.userId)

		UNION ALL

		-- Payment
		SELECT
			'Payment' AS dataType,
			5 AS id,
			SUM(CASE WHEN p.createdAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.hr2 AND p.createdAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.d2 AND p.createdAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.w2 AND p.createdAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN p.createdAt >= b.m2 AND p.createdAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.Payment p WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE p.createdAt >= b.m2

		UNION ALL

		-- Portal
		SELECT
			'Portal' AS dataType,
			6 AS id,
			SUM(CASE WHEN pa.accessDate >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.hr2 AND pa.accessDate < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.d2 AND pa.accessDate < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.w2 AND pa.accessDate < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pa.accessDate >= b.m2 AND pa.accessDate < b.m1 THEN 1 ELSE 0 END)
		FROM HC.PortalAccess pa WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE pa.accessDate >= b.m2
			AND NOT EXISTS (SELECT 1 FROM ExcludedUsers eu WHERE eu.UserId = pa.hasherId)

		UNION ALL

		-- Error
		SELECT
			'Error' AS dataType,
			7 AS id,
			SUM(CASE WHEN el.updatedAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.hr2 AND el.updatedAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.d2 AND el.updatedAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.w2 AND el.updatedAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN el.updatedAt >= b.m2 AND el.updatedAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.ErrorLog el WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE el.updatedAt >= b.m2
	) d
	ORDER BY d.id;

	-- Result Set 4: Login information for last day
	SELECT
		h.DisplayName AS userName,
		ll.UserId AS userId,
		h.FirstName + ' ' + h.LastName AS realName,
		h.Photo AS photo,
		CASE
			WHEN ll.DeviceType = 'iPhone' THEN 1
			WHEN ll.DeviceType IS NULL THEN -1
			ELSE 0
		END AS isIphone,
		COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') AS systemVersion,
		COUNT(ll.UserName) AS loginCount,
		MAX(ll.LoginDate) AS lastLoginDate,
		DATEDIFF(MINUTE, MAX(ll.LoginDate), GETDATE()) AS minutesSinceLastLogin,
		COALESCE(k.KennelName, '') AS kennelName,
		COALESCE(k.kennelShortName, '') AS kennelShortName,
		LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) AS hcVersion,
		CASE
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '26.%' THEN 0
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '18.%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '17.%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '16.%' THEN 2
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '15.%' THEN 2
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '14.%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '13.%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '12.%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '11.%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '10.%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '37%' THEN 0
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '36%' THEN 0
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '35%' THEN 0
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '34%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '33%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '32%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '31%' THEN 1
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '30%' THEN 2
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '29%' THEN 2
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '28%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '27%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '26%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '25%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '24%' THEN 3
			WHEN COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), '') LIKE '23%' THEN 3
			ELSE 3
		END AS highlightPhoneVersion,
		CASE
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%2.1%' THEN 0
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%2.0%' THEN 0
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%1.6%' THEN 1
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%1.5%' THEN 2
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%1.2%' THEN 3
			WHEN LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1) LIKE '%1.1.%' THEN 3
			ELSE 3
		END AS highlightHcVersion
	FROM HC.LaunchAndLogin ll WITH (NOLOCK)
	INNER JOIN HC.Hasher h WITH (NOLOCK) ON h.id = ll.UserId
	LEFT OUTER JOIN HC.Kennel k WITH (NOLOCK) ON h.HomeKennelId = k.id
	WHERE ll.LoginDate > DATEADD(DAY, -1, GETDATE())
		AND ll.HcVersion LIKE 'HC Ver%'
	GROUP BY
		h.DisplayName,
		ll.UserId,
		h.FirstName + ' ' + h.LastName,
		LEFT(ll.HcVersion, CHARINDEX(',', ll.HcVersion) - 1),
		COALESCE(REPLACE(LEFT(ll.SystemVersion, 5), '/', ''), ''),
		CASE
			WHEN ll.DeviceType = 'iPhone' THEN 1
			WHEN ll.DeviceType IS NULL THEN -1
			ELSE 0
		END,
		h.Photo,
		COALESCE(k.KennelName, ''),
		COALESCE(k.kennelShortName, '')
	ORDER BY MAX(ll.LoginDate) DESC;

	-- Result Set 5: Recent events (last 20 updated or active)
	;WITH RecentlyUpdated AS (
		SELECT TOP 20
			k.KennelName AS kennelName,
			k.KennelShortName AS kennelShortName,
			k.KennelLogo AS kennelLogo,
			CASE WHEN evt.UseFbRunDetails != 0 THEN evt.FbEventName ELSE evt.EventName END AS eventName,
			DATEDIFF(MINUTE, evt.updatedAt, GETDATE()) AS minutesAgoUpdated,
			DATEDIFF(MINUTE, evt.createdAt, GETDATE()) AS minutesAgoCreated,
			DATEDIFF(MINUTE, GETDATE(), evt.EventStartDatetime) AS minutesUntilRun,
			(SELECT COUNT(*)
			  FROM HC.HasherEventMap hem WITH (NOLOCK)
			  WHERE hem.EventId = evt.id
				AND hem.updatedAt >= DATEADD(DAY, -1, GETDATE())) AS activityLastDay,
			evt.PublicEventId AS publicEventId
		FROM HC.Event evt WITH (NOLOCK)
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON evt.KennelId = k.id
		WHERE evt.EventStartDatetimeIndexed > DATEADD(MINUTE, -2880, GETDATE())
			AND evt.IsVisible = 1
		ORDER BY evt.updatedAt DESC
	),
	MostActive AS (
		SELECT TOP 20
			k.KennelName AS kennelName,
			k.KennelShortName AS kennelShortName,
			k.KennelLogo AS kennelLogo,
			CASE WHEN evt.UseFbRunDetails != 0 THEN evt.FbEventName ELSE evt.EventName END AS eventName,
			DATEDIFF(MINUTE, evt.updatedAt, GETDATE()) AS minutesAgoUpdated,
			DATEDIFF(MINUTE, evt.createdAt, GETDATE()) AS minutesAgoCreated,
			DATEDIFF(MINUTE, GETDATE(), evt.EventStartDatetime) AS minutesUntilRun,
			(SELECT COUNT(*)
			  FROM HC.HasherEventMap hem WITH (NOLOCK)
			  WHERE hem.EventId = evt.id
				AND hem.updatedAt >= DATEADD(DAY, -1, GETDATE())) AS activityLastDay,
			evt.PublicEventId AS publicEventId
		FROM HC.Event evt WITH (NOLOCK)
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON evt.KennelId = k.id
		WHERE evt.EventStartDatetimeIndexed > DATEADD(MINUTE, -2880, GETDATE())
			AND evt.IsVisible = 1
			AND EXISTS (
				SELECT 1
				FROM HC.HasherEventMap hem WITH (NOLOCK)
				WHERE hem.EventId = evt.id
					AND hem.updatedAt >= DATEADD(DAY, -1, GETDATE())
			)
		ORDER BY activityLastDay DESC
	)
	SELECT DISTINCT *
	FROM (
		SELECT * FROM RecentlyUpdated
		UNION
		SELECT * FROM MostActive
	) combined
	ORDER BY minutesAgoUpdated;

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
