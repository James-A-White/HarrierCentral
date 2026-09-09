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
--   Rowset 1 Devices:  deviceId, os, hcVersion, lastLogin, sessions,
--                      sessionsWithMetrics
--   Rowset 2 Sessions: loggedAt, deviceId, hcVersion, summary (text after
--                      the last '[METRICS] '), peaks (text after
--                      '[METRICS:PEAKS]'), ring (the [METRICS:RING] block,
--                      latest session per device only, else NULL),
--                      appError (HC6.ClientLogAppError), errorLines
--                      Newest first, TOP 60.
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

	-- =============================================
	-- Rowset 1: the user's devices
	-- =============================================
	SELECT
		d.id AS deviceId,
		ISNULL(d.OperatingSystem, 'Android') AS os,
		d.Version + '+' + d.BuildNumber AS hcVersion,
		d.LastLogin AS lastLogin,
		(SELECT COUNT(*) FROM HC.ClientErrorLog c WITH (NOLOCK)
		 WHERE c.DeviceId = d.id AND c.LoggedAt > @cutoff) AS sessions,
		(SELECT COUNT(*) FROM HC.ClientErrorLog c WITH (NOLOCK)
		 WHERE c.DeviceId = d.id AND c.LoggedAt > @cutoff
		   AND c.ErrorLog LIKE '%[[]METRICS]%') AS sessionsWithMetrics
	FROM HC.Device d WITH (NOLOCK)
	WHERE d.UserId = @userId AND d.removed = 0
	ORDER BY d.LastLogin DESC;

	-- =============================================
	-- Rowset 2: sessions with metrics, newest first
	-- =============================================
	;WITH S AS (
		SELECT
			c.Id, c.LoggedAt, c.DeviceId, c.ErrorLog,
			COALESCE(c.AppVersion + '+' + c.BuildNumber, d.Version + '+' + d.BuildNumber, '') AS hcVersion,
			ROW_NUMBER() OVER (PARTITION BY c.DeviceId ORDER BY c.LoggedAt DESC) AS rn
		FROM HC.ClientErrorLog c WITH (NOLOCK)
		INNER JOIN HC.Device d WITH (NOLOCK) ON d.id = c.DeviceId
		WHERE d.UserId = @userId
			AND c.LoggedAt > @cutoff
			AND c.ErrorLog LIKE '%[[]METRICS%'
	)
	SELECT TOP 60
		S.LoggedAt AS loggedAt,
		S.DeviceId AS deviceId,
		S.hcVersion,
		-- the LAST '[METRICS] ' line: the session's cumulative summary
		CASE WHEN p.lastTag > 0
			THEN SUBSTRING(S.ErrorLog, p.lastTag + LEN('[METRICS] '),
			     CHARINDEX(CHAR(10), S.ErrorLog + CHAR(10), p.lastTag) - p.lastTag - LEN('[METRICS] '))
			ELSE NULL END AS summary,
		CASE WHEN p.peaksPos > 0
			THEN LTRIM(SUBSTRING(S.ErrorLog, p.peaksPos + LEN('[METRICS:PEAKS]'),
			     CHARINDEX(CHAR(10), S.ErrorLog + CHAR(10), p.peaksPos) - p.peaksPos - LEN('[METRICS:PEAKS]')))
			ELSE NULL END AS peaks,
		-- ring block for the latest session per device only (it is ~6 KB)
		CASE WHEN S.rn = 1 AND p.ringPos > 0
			THEN SUBSTRING(S.ErrorLog, p.ringPos,
			     CASE WHEN p.peaksPos > p.ringPos THEN p.peaksPos ELSE p.logLen + 1 END - p.ringPos)
			ELSE NULL END AS ring,
		HC6.ClientLogAppError(S.ErrorLog) AS appError,
		(LEN(S.ErrorLog) - LEN(REPLACE(S.ErrorLog, '[ERROR]', ''))) / LEN('[ERROR]') AS errorLines
	FROM S
	CROSS APPLY (
		SELECT
			-- LEN(x + 'x') - 1 counts trailing whitespace, which LEN alone
			-- drops and REVERSE keeps; the two must agree for the arithmetic.
			LEN(S.ErrorLog + 'x') - 1 AS logLen,
			CHARINDEX('[METRICS:PEAKS]', S.ErrorLog) AS peaksPos,
			CHARINDEX('[METRICS:RING]', S.ErrorLog) AS ringPos,
			CHARINDEX(REVERSE('[METRICS] '), REVERSE(S.ErrorLog)) AS revTag
	) q
	CROSS APPLY (
		SELECT
			q.logLen, q.peaksPos, q.ringPos,
			CASE WHEN q.revTag > 0
				THEN q.logLen - q.revTag - LEN('[METRICS] ') + 2
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
