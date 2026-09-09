CREATE OR ALTER PROCEDURE [HC6].[hcportal_getDeviceHealth]
	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@userId UNIQUEIDENTIFIER = NULL,
	-- optional
	@days SMALLINT = 14
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getDeviceHealth
-- Description: Per-device health for one user, for the Usage Data user
--   tile. Pulls the [METRICS] instrumentation (app 3.0.14+) out of the
--   user's uploaded session logs in HC.ClientErrorLog: the LAST [METRICS]
--   line of each session (its cumulative summary), its [METRICS:PEAKS]
--   line, and — for the most recent session per device — the one-minute
--   [METRICS:RING] block. The SP EXTRACTS the lines; the portal parses the
--   key=value pairs, so a new field in the app needs no SP change.
-- Parameters: @deviceId, @accessToken (auth)
--             @userId (user to query), @days (window, default 14)
-- Returns:
--   Rowset 1 Devices:  the user's APP devices (iOS or Android — browser
--                      rows from the portal are excluded) that uploaded at
--                      least one session in the window. deviceId, os,
--                      hcVersion, lastLogin, sessions, sessionsWithMetrics
--   Rowset 2 Sessions: EVERY uploaded session from those devices, newest
--                      first, TOP 100 — one row per app launch that was
--                      harvested, whether or not it carried metrics.
--                      sessionStart (the log's first timestamp, phone
--                      local time), loggedAt (upload), deviceId, os,
--                      hcVersion, summary (text after the last '[METRICS] ',
--                      NULL when the build predates 3.0.14), peaks, ring
--                      (latest session per device only), appError,
--                      errorLines
-- Changes:
--   2026-09-09 - v1.1: device rows limited to app devices with sessions;
--                session rows no longer require metrics; sessionStart added.
--   2026-09-09 - v1.2: ring for every session; summary = last line before
--                the ring block (merged retried uploads no longer leak the
--                next session's start line); errorText added; TOP 60.
-- Author: Harrier Central
-- Created: 2026-09-09
-- HC5 Source: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hasherId UNIQUEIDENTIFIER;
BEGIN TRY
	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @callerType INT;
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END
	IF @userId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid userId' AS ErrorMessage;
		RETURN;
	END
	IF @days IS NULL OR @days < 1 OR @days > 90 SET @days = 14;

	DECLARE @cutoff DATETIMEOFFSET(7) = DATEADD(DAY, -@days, SYSDATETIMEOFFSET());

	-- App devices: the mobile app reports OperatingSystem 'iOS' or nothing
	-- (Android sends no systemName); the portal reports its browser name.
	-- IsMobile is not reliable for this (Safari on a phone sets it).
	DECLARE @appDevices TABLE (id UNIQUEIDENTIFIER PRIMARY KEY, os NVARCHAR(50), hcVersion NVARCHAR(60), lastLogin DATETIMEOFFSET(7));
	INSERT @appDevices (id, os, hcVersion, lastLogin)
	SELECT d.id, ISNULL(d.OperatingSystem, 'Android'), d.Version + '+' + d.BuildNumber, d.LastLogin
	FROM HC.Device d WITH (NOLOCK)
	WHERE d.UserId = @userId AND d.removed = 0
		AND (d.OperatingSystem IS NULL OR d.OperatingSystem = 'iOS')
		AND EXISTS (SELECT 1 FROM HC.ClientErrorLog c WITH (NOLOCK)
		            WHERE c.DeviceId = d.id AND c.LoggedAt > @cutoff);

	-- =============================================
	-- Rowset 1: app devices with sessions in the window
	-- =============================================
	SELECT
		a.id AS deviceId,
		a.os,
		a.hcVersion,
		a.lastLogin,
		-- A session is one app launch's harvested log, uploaded on the next
		-- launch. MetricKit payloads are their own rows and are NOT launches.
		(SELECT COUNT(*) FROM HC.ClientErrorLog c WITH (NOLOCK)
		 WHERE c.DeviceId = a.id AND c.LoggedAt > @cutoff
		   AND c.ErrorLog NOT LIKE '[[]METRICKIT]%') AS sessions,
		(SELECT COUNT(*) FROM HC.ClientErrorLog c WITH (NOLOCK)
		 WHERE c.DeviceId = a.id AND c.LoggedAt > @cutoff
		   AND c.ErrorLog LIKE '%[[]METRICS]%') AS sessionsWithMetrics
	FROM @appDevices a
	ORDER BY a.lastLogin DESC;

	-- =============================================
	-- Rowset 2: every harvested session, newest first
	-- =============================================
	;WITH S AS (
		SELECT
			c.Id, c.LoggedAt, c.DeviceId, c.ErrorLog, a.os,
			COALESCE(c.AppVersion + '+' + c.BuildNumber, a.hcVersion, '') AS hcVersion,
			ROW_NUMBER() OVER (PARTITION BY c.DeviceId ORDER BY c.LoggedAt DESC) AS rn
		FROM HC.ClientErrorLog c WITH (NOLOCK)
		INNER JOIN @appDevices a ON a.id = c.DeviceId
		WHERE c.LoggedAt > @cutoff
		  -- launches, plus a MetricKit row only when it carries a diagnostic
		  -- (crash / hang); routine daily metric payloads are not sessions
		  AND (c.ErrorLog NOT LIKE '[[]METRICKIT]%' OR HC6.ClientLogAppError(c.ErrorLog) IS NOT NULL)
	)
	SELECT TOP 60
		CASE WHEN S.ErrorLog LIKE '[[]METRICKIT]%' THEN 'diagnostic' ELSE 'session' END AS kind,
		-- the log's first entry timestamp: when the session started, phone-local
		CASE WHEN LEFT(S.ErrorLog, 1) = '[' AND CHARINDEX(']', S.ErrorLog) BETWEEN 20 AND 40
			THEN SUBSTRING(S.ErrorLog, 2, CHARINDEX(']', S.ErrorLog) - 2) END AS sessionStart,
		S.LoggedAt AS loggedAt,
		S.DeviceId AS deviceId,
		S.os,
		S.hcVersion,
		-- The session's cumulative summary: the LAST '[METRICS] why=' line
		-- BEFORE the ring block. The ring/peaks are appended at upload, so
		-- anything after them is a later session merged in by a retried
		-- upload — its 'why=start up=0s' line must not masquerade as this
		-- session's summary. (Tag chosen without a trailing space: LEN()
		-- drops trailing spaces, which put the old '[METRICS] ' tag off by one.)
		-- keep the 'why=' pair itself: the text after the 10-char '[METRICS] ' tag
		CASE WHEN p.lastTag > 0
			THEN SUBSTRING(S.ErrorLog, p.lastTag + 10,
			     CHARINDEX(CHAR(10), S.ErrorLog + CHAR(10), p.lastTag) - p.lastTag - 10)
			ELSE NULL END AS summary,
		-- The session's FIRST '[METRICS] why=start' line: battery and memory
		-- at launch, so start and end can be shown side by side.
		CASE WHEN q.startTag > 0
			THEN SUBSTRING(S.ErrorLog, q.startTag + 10,
			     CHARINDEX(CHAR(10), S.ErrorLog + CHAR(10), q.startTag) - q.startTag - 10)
			ELSE NULL END AS summaryStart,
		CASE WHEN p.peaksPos > 0
			THEN LTRIM(SUBSTRING(S.ErrorLog, p.peaksPos + LEN('[METRICS:PEAKS]'),
			     CHARINDEX(CHAR(10), S.ErrorLog + CHAR(10), p.peaksPos) - p.peaksPos - LEN('[METRICS:PEAKS]')))
			ELSE NULL END AS peaks,
		-- ring block for EVERY session (~6 KB each; TOP 60 bounds the payload)
		CASE WHEN p.ringPos > 0
			THEN SUBSTRING(S.ErrorLog, p.ringPos,
			     CASE WHEN p.peaksPos > p.ringPos THEN p.peaksPos ELSE p.logLen + 1 END - p.ringPos)
			ELSE NULL END AS ring,
		HC6.ClientLogAppError(S.ErrorLog) AS appError,
		(LEN(S.ErrorLog) - LEN(REPLACE(S.ErrorLog, '[ERROR]', ''))) / LEN('[ERROR]') AS errorLines,
		-- the [ERROR] lines themselves, in order, newline-separated (first 60)
		(SELECT STRING_AGG(CAST(LEFT(x.value, 400) AS NVARCHAR(MAX)), CHAR(10)) WITHIN GROUP (ORDER BY x.ordinal)
		 FROM (SELECT TOP 60 value, ordinal FROM STRING_SPLIT(S.ErrorLog, CHAR(10), 1)
		       WHERE value LIKE '%[[]ERROR]%' ORDER BY ordinal) x) AS errorText
	FROM S
	CROSS APPLY (
		SELECT
			-- LEN(x + 'x') - 1 counts trailing whitespace, which LEN alone
			-- drops and REVERSE keeps; the two must agree for the arithmetic.
			LEN(S.ErrorLog + 'x') - 1 AS logLen,
			CHARINDEX('[METRICS:PEAKS]', S.ErrorLog) AS peaksPos,
			CHARINDEX('[METRICS:RING]', S.ErrorLog) AS ringPos,
			CHARINDEX('[METRICS] why=start', S.ErrorLog) AS startTag,
			-- search only the part before the ring block (the whole log when
			-- there is none), so a merged later session cannot be picked
			CASE WHEN CHARINDEX('[METRICS:RING]', S.ErrorLog) > 0
				THEN LEFT(S.ErrorLog, CHARINDEX('[METRICS:RING]', S.ErrorLog))
				ELSE S.ErrorLog END AS head
	) q
	CROSS APPLY (
		SELECT
			q.logLen, q.peaksPos, q.ringPos,
			CASE WHEN CHARINDEX(REVERSE('[METRICS] why='), REVERSE(q.head)) > 0
				THEN (LEN(q.head + 'x') - 1) - CHARINDEX(REVERSE('[METRICS] why='), REVERSE(q.head)) - LEN('[METRICS] why=') + 2
				ELSE 0 END AS lastTag
	) p
	ORDER BY S.LoggedAt DESC
	OPTION (RECOMPILE);
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
	VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcportal_getDeviceHealth',
	        ERROR_MESSAGE(), @procName, @hasherId);
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
