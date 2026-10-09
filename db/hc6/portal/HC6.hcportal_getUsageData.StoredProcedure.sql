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
--              Login, Payment, Portal, Error, Push, App Error, PackTrack, Email,
--              AI Tokens, Azure Cost [pence] — the last two added 2026-10-05), recent login details,
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
--   - 2026-09-20: highlightHcVersion (rowset 4) re-based on the release
--     train. Same 0..3 scale, but the old rules named 1.x/2.x only, so every
--     3.x build scored 3 (red) and 2.1.2 scored 0 (green) — backwards on the
--     hasher cards. 0 = 3.1/3.2, 1 = 3.0, 3 = 2.x, 9 = unrecognised.
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

	-- Get future run count
	DECLARE @futureRunCount INT;
	SELECT @futureRunCount = COUNT(*)
	FROM HC.Event WITH (NOLOCK)
	WHERE EventStartLocal > GETDATE();

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
		SUBSTRING(HcVersion, 1, PATINDEX('%-%', HcVersion) - 1) AS versionNum,
		SUBSTRING(HcVersion, PATINDEX('%-%', HcVersion) + 1, 1000) AS buildNum,
		isiPhone,
		isNotiPhone
	FROM VersionStats
	ORDER BY SUBSTRING(HcVersion, PATINDEX('%-%', HcVersion) + 1, 1000) DESC;

	-- Result Set 2: Integration job data
	-- The AI runs-page reader (integration 6) took the Facebook tile's place
	-- (James, 2026-10-05; Facebook has been off since 2023). It is listed
	-- even before its first job, because the portal hides every tile when
	-- fewer than three come back. For 6 only: newRuns14d / updatedRuns14d
	-- sum the '<inserted>|<updated>' that HC6.nonApi_recordRunsPageJob
	-- writes into RecordsSuccessInfo, and kennelsUsing counts kennels whose
	-- Inbound Integration is set to it. NULL on every other tile.
	DECLARE @rpNew INT, @rpUpdated INT, @rpKennels INT;
	SELECT @rpNew = COALESCE(SUM(TRY_CAST(LEFT(ij.RecordsSuccessInfo, CHARINDEX('|', ij.RecordsSuccessInfo) - 1) AS INT)), 0),
	       @rpUpdated = COALESCE(SUM(TRY_CAST(SUBSTRING(ij.RecordsSuccessInfo, CHARINDEX('|', ij.RecordsSuccessInfo) + 1, 20) AS INT)), 0)
	FROM HC.IntegrationJob ij WITH (NOLOCK)
	WHERE ij.IntegrationId = 6 AND ij.endedAt >= DATEADD(DAY, -14, SYSDATETIMEOFFSET())
	  AND CHARINDEX('|', ij.RecordsSuccessInfo) > 1;
	SELECT @rpKennels = COUNT(*) FROM HC.Kennel WITH (NOLOCK)
	WHERE InboundIntegrationId = 6 AND deleted = 0;

	;WITH LatestJobs AS (
		SELECT
			intg.IntegrationId,
			intg.IntegrationAbbreviation,
			MAX(ij.IntegrationJobId) AS IntegrationJobId,
			intg.Enabled AS integrationEnabled,
			intg.Interval
		FROM HC.Integration intg WITH (NOLOCK)
		LEFT JOIN HC.IntegrationJob ij WITH (NOLOCK)
			ON ij.IntegrationId = intg.IntegrationId AND ij.endedAt IS NOT NULL
		WHERE intg.IntegrationId <> 1
		GROUP BY intg.IntegrationId, intg.IntegrationAbbreviation, intg.Enabled, intg.Interval
		HAVING MAX(ij.IntegrationJobId) IS NOT NULL OR intg.IntegrationId = 6
	)
	SELECT TOP 10
		lj.IntegrationAbbreviation AS integrationAbbreviation,
		lj.integrationEnabled AS integrationEnabled,
		lj.Interval AS interval,
		lj.IntegrationId AS integrationId,
		COALESCE(ij.RecordsRead, 0) AS recordsRead,
		COALESCE(ij.RecordsWritten, 0) AS recordsWritten,
		COALESCE(ij.RecordsFailedInfo, '') AS recordsFailedInfo,
		COALESCE(ij.ErrorCount, 0) AS errorCount,
		COALESCE(ij.ErrorInfo, '') AS errorInfo,
		-- A tile with no job yet reads as "never run": an old date.
		COALESCE(ij.endedAt, CAST('2000-01-01T00:00:00+00:00' AS DATETIMEOFFSET(7))) AS endedAt,
		COALESCE(DATEDIFF(MINUTE, ij.endedAt, GETDATE()), 999999) AS minutesAgo,
		COALESCE(ij.KennelsSucceeded, 0) AS kennelsSucceeded,
		COALESCE(ij.KennelsSucceededInfo, '') AS kennelsSucceededInfo,
		COALESCE(ij.KennelsFailed, 0) AS kennelsFailed,
		COALESCE(ij.KennelsFailedInfo, '') AS kennelsFailedInfo,
		@futureRunCount AS futureRunCount,
		CASE WHEN lj.IntegrationId = 6 THEN @rpNew END AS newRuns14d,
		CASE WHEN lj.IntegrationId = 6 THEN @rpUpdated END AS updatedRuns14d,
		CASE WHEN lj.IntegrationId = 6 THEN @rpKennels END AS kennelsUsing
	FROM LatestJobs lj
	LEFT JOIN HC.IntegrationJob ij WITH (NOLOCK) ON lj.IntegrationJobId = ij.IntegrationJobId
	ORDER BY lj.IntegrationAbbreviation;

	-- Azure Cost windows (row 12). Cost arrives per UTC day and keeps
	-- settling for about a day, so the row compares COMPLETE days only — a
	-- day read 2+ days after it began. Comparing a half-filled yesterday with
	-- a full day before would show a false green every morning.
	-- Shown INCLUDING VAT: Azure reports pre-tax cost (2026-10-05).
	DECLARE @vat DECIMAL(6,4) = HC6.AzureVatMultiplier();
	DECLARE @costDay DATE = (SELECT MAX(CostDate) FROM LOG.AzureDailyCost
	                         WHERE RetrievedAt >= DATEADD(DAY, 2, CAST(CostDate AS DATETIME2(0))));

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

		UNION ALL

		-- PackTrack: individual tracks captured — one per runner per run, so a
		-- run twelve people tracked counts twelve (James, 2026-09-13). Dated by
		-- the track's FIRST POINT, which is when it was actually captured;
		-- updatedAt would date it by the nightly archive instead, bunching
		-- every one of a day's tracks into the small hours of the next.
		SELECT
			'PackTrack' AS dataType,
			10 AS id,
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.hr2 AND hem.TrackFirstPointAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.d2 AND hem.TrackFirstPointAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.w2 AND hem.TrackFirstPointAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN hem.TrackFirstPointAt >= b.m2 AND hem.TrackFirstPointAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.HasherEventMap hem WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE hem.removed = 0
			AND hem.TrackPointCount > 0
			AND hem.TrackFirstPointAt >= b.m2

		UNION ALL

		-- Push: notifications a PERSON actually saw.
		--
		-- IsVisible = 1 is the whole filter, and it is exact: every
		-- badge-maintenance push is data-only by construction. It removes
		-- markEventChatRead (the read-sync that clears a badge on your other
		-- devices, 2,388 of the 5,767 rows in the 30 days to 2026-09-18) and
		-- the silent copies of a chat message sent to someone who has the
		-- thread muted. Neither ever appears on a phone, so counting them
		-- made the row answer "how much FCM traffic" when the question is
		-- "how many people were interrupted" (James, 2026-09-18).
		--
		-- The join to HC.Device was removed with it. It existed to say
		-- "mobile only", but it matched on a LIVE FcmToken, so a push whose
		-- token was later cleared — by the duplicate-token dedupe, or by
		-- DeleteFcmToken after Firebase rejected it — silently vanished from
		-- the count. That was losing 55% of all rows, and the portal dedupe
		-- added on 2026-09-18 would have made it worse. Expect this row to
		-- step UP when this deploys; the old number was wrong, not the new
		-- one.
		SELECT
			'Push' AS dataType,
			8 AS id,
			SUM(CASE WHEN pl.SentAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.hr2 AND pl.SentAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.d2 AND pl.SentAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.w2 AND pl.SentAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN pl.SentAt >= b.m2 AND pl.SentAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.PushLog pl WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE pl.SentAt >= b.m2
			AND pl.IsVisible = 1

		UNION ALL

		-- Email: people a run email reached — one GeneralLog row per send
		-- (nonApi_recordRunEmailSent), its JSON Data carrying the recipient
		-- count; previews and the launch announcement are not run emails.
		-- Rows written before 2026-10-09 are plain text and count 0 — ISJSON
		-- keeps JSON_VALUE from throwing on them.
		SELECT
			'Email' AS dataType,
			13 AS id,
			SUM(CASE WHEN g.[Timestamp] >= b.hr1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.hr2 AND g.[Timestamp] < b.hr1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.d1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.d2 AND g.[Timestamp] < b.d1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.w1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.w2 AND g.[Timestamp] < b.w1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.m1 THEN g.n ELSE 0 END),
			SUM(CASE WHEN g.[Timestamp] >= b.m2 AND g.[Timestamp] < b.m1 THEN g.n ELSE 0 END)
		FROM (SELECT gl.[Timestamp],
		             CASE WHEN ISJSON(gl.Data) = 1 THEN TRY_CAST(JSON_VALUE(gl.Data, '$.recipients') AS INT) ELSE 0 END AS n
		      FROM LOG.GeneralLog gl WITH (NOLOCK)
		      WHERE gl.LogSource = 'RunEmail' AND gl.Message = 'Run email sent') g
		CROSS JOIN DateBounds b
		WHERE g.[Timestamp] >= b.m2

		UNION ALL

		-- App Error: client sessions whose uploaded log holds an app error as
		-- defined by HC6.ClientLogAppError (uncaught Dart exception, Flutter
		-- framework error, or a MetricKit crash/hang). HTTP timeouts and
		-- expired-avatar 404s are deliberately NOT counted — they are the
		-- network, not the app. The 'Error' row above is server-side
		-- (HC.ErrorLog); this one is the phone's side of the same story.
		-- The LIKE prefilter keeps the function off rows that cannot qualify.
		SELECT
			'App Error' AS dataType,
			9 AS id,
			SUM(CASE WHEN c.LoggedAt >= b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.hr2 AND c.LoggedAt < b.hr1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.d2 AND c.LoggedAt < b.d1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.w2 AND c.LoggedAt < b.w1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.m1 THEN 1 ELSE 0 END),
			SUM(CASE WHEN c.LoggedAt >= b.m2 AND c.LoggedAt < b.m1 THEN 1 ELSE 0 END)
		FROM HC.ClientErrorLog c WITH (NOLOCK)
		CROSS JOIN DateBounds b
		WHERE c.LoggedAt >= b.m2
			AND (c.ErrorLog LIKE '%[[]ERROR][[]%' OR c.ErrorLog LIKE '[[]METRICKIT]%')
			AND HC6.ClientLogAppError(c.ErrorLog) IS NOT NULL

		UNION ALL

		-- AI Tokens: tokens billed by AI model calls (LOG.AiUsage — the runs
		-- page reader today). Fewer is better, so the portal colours it like
		-- Error: green when lower (James, 2026-10-05). Cost per call is in
		-- the drill-down.
		SELECT
			'AI Tokens' AS dataType,
			11 AS id,
			SUM(CASE WHEN a.CalledAt >= b.hr1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.hr2 AND a.CalledAt < b.hr1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.d1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.d2 AND a.CalledAt < b.d1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.w1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.w2 AND a.CalledAt < b.w1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.m1 THEN a.TotalTokens ELSE 0 END),
			SUM(CASE WHEN a.CalledAt >= b.m2 AND a.CalledAt < b.m1 THEN a.TotalTokens ELSE 0 END)
		FROM DateBounds b
		LEFT JOIN LOG.AiUsage a WITH (NOLOCK) ON a.CalledAt >= b.m2

		UNION ALL

		-- Azure Cost, in PENCE INCLUDING VAT (@vat) (the grid is whole numbers; the portal shows
		-- £). Day = the latest complete day vs the day before; Week = the 7
		-- complete days ending then vs the 7 before; Month = 30 vs 30. No
		-- hourly figure exists, so Hour is 0/0 (neutral). Lower is green.
		SELECT
			'Azure Cost' AS dataType,
			12 AS id,
			0,
			0,
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate = @costDay THEN c.Cost ELSE 0 END), 0) AS INT),
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate = DATEADD(DAY, -1, @costDay) THEN c.Cost ELSE 0 END), 0) AS INT),
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate > DATEADD(DAY, -7, @costDay) THEN c.Cost ELSE 0 END), 0) AS INT),
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate <= DATEADD(DAY, -7, @costDay) AND c.CostDate > DATEADD(DAY, -14, @costDay) THEN c.Cost ELSE 0 END), 0) AS INT),
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate > DATEADD(DAY, -30, @costDay) THEN c.Cost ELSE 0 END), 0) AS INT),
			CAST(ROUND(100 * @vat * SUM(CASE WHEN c.CostDate <= DATEADD(DAY, -30, @costDay) THEN c.Cost ELSE 0 END), 0) AS INT)
		FROM (SELECT 1 AS one) x
		LEFT JOIN LOG.AzureDailyCost c WITH (NOLOCK)
			ON c.CostDate <= @costDay AND c.CostDate > DATEADD(DAY, -60, @costDay)
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
		LEFT(ll.HcVersion, NULLIF(CHARINDEX(',', ll.HcVersion), 0) - 1) AS hcVersion,
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
		-- Release train the hasher's app build belongs to, on the existing
		-- 0 = best .. 3 = worst scale the phone-version column already uses.
		-- The rules it replaced still spoke of 1.x and 2.x, so every 3.x build
		-- fell through to ELSE 3 and the newest app on the estate showed red.
		--   0 = current   3.1.x / 3.2.x
		--   1 = previous  3.0.x
		--   3 = legacy    2.x.y
		--   9 = anything else (a version this SP has not been told about)
		CASE
			WHEN v.hcVersionNum LIKE '3.1.%' OR v.hcVersionNum = '3.1'
			  OR v.hcVersionNum LIKE '3.2.%' OR v.hcVersionNum = '3.2' THEN 0
			WHEN v.hcVersionNum LIKE '3.0.%' OR v.hcVersionNum = '3.0' THEN 1
			WHEN v.hcVersionNum LIKE '2.%' THEN 3
			ELSE 9
		END AS highlightHcVersion
	FROM HC.LaunchAndLogin ll WITH (NOLOCK)
	INNER JOIN HC.Hasher h WITH (NOLOCK) ON h.id = ll.UserId
	LEFT OUTER JOIN HC.Kennel k WITH (NOLOCK) ON h.HomeKennelId = k.id
	-- 'HC Ver: 3.1.0, Bld: 1394' -> '3.1.0', parsed once so the CASE above
	-- reads as version rules rather than string surgery.
	CROSS APPLY (VALUES (
		LTRIM(REPLACE(LEFT(ll.HcVersion, NULLIF(CHARINDEX(',', ll.HcVersion), 0) - 1), 'HC Ver:', ''))
	)) AS v(hcVersionNum)
	WHERE ll.LoginDate > DATEADD(DAY, -1, GETDATE())
		AND ll.HcVersion LIKE 'HC Ver%'
	GROUP BY
		h.DisplayName,
		ll.UserId,
		h.FirstName + ' ' + h.LastName,
		LEFT(ll.HcVersion, NULLIF(CHARINDEX(',', ll.HcVersion), 0) - 1),
		v.hcVersionNum,
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
		WHERE evt.EventStartLocal > DATEADD(MINUTE, -2880, GETDATE())
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
		WHERE evt.EventStartLocal > DATEADD(MINUTE, -2880, GETDATE())
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
