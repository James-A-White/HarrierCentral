CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennelHashers]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennelHashers
-- Description: Retrieves a list of all hashers (members and followers)
--              for a specified kennel, including their membership
--              status, run counts, payment history from recent events,
--              and credit balances. Requires portal access token and
--              appropriate AppAccessFlags (0x40000019 permission).
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing)
-- Returns: Single rowset of hasher details, or error envelope
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getKennelHashers
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - @publicKennelId changed from NVARCHAR(250) to UNIQUEIDENTIFIER
--   - LEN(@publicKennelId) != 36 length check removed (type now enforces validity)
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - @publicHasherId replaced by @deviceId (device-bound auth via HC.Device lookup)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Resolve kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER
	SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId

	-- Validation: kennel exists
	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
		RETURN;
	END

	-- Evaluate "now" once and reuse for every time comparison below.
	DECLARE @now DATETIME = GETDATE();

	-- Authorization: check AppAccessFlags permission bitmask
	-- 0x40000019 = authIsSuperAdmin | authCanManageMembers | authCanManageHashCash | authIsAdmin
	DECLARE @appAccessFlags INT,
			@kennelName NVARCHAR(200)

	SELECT
		@appAccessFlags = hkm.AppAccessFlags,
		@kennelName = k.KennelName
	FROM HC.HasherKennelMap hkm
	INNER JOIN HC.Kennel k on hkm.KennelId = k.id
	WHERE hkm.UserId = @hasherId
	AND k.PublicKennelId = @publicKennelId

	IF @appAccessFlags IS NULL OR (@appAccessFlags & 0x40000019) = 0
	BEGIN
		SELECT 0 AS Success,
			'You are not authorized to access Hasher information for ' + COALESCE(@kennelName, 'this kennel') AS ErrorMessage;
		RETURN;
	END

	-- Get last two events and next event for payment info columns
	DECLARE @lastEventId UNIQUEIDENTIFIER,
			@lastEventNumber NVARCHAR(50),
			@lastEventDate DATETIME,
			@secondLastEventId UNIQUEIDENTIFIER,
			@secondLastEventNumber NVARCHAR(50),
			@secondLastEventDate DATETIME,
			@nextEventDate DATETIME,
			@nextEventNumber NVARCHAR(50)

	SELECT TOP 1
		@lastEventId = evt.id,
		@lastEventNumber = CAST(evt.EventNumber as NVARCHAR(50)),
		@lastEventDate = evt.EventStartDatetime
	FROM HC.Event evt
	WHERE evt.KennelId = @kennelId AND evt.IsCountedRun = 1
	AND evt.EventStartDatetime < @now
	ORDER BY evt.EventStartDatetime DESC

	SELECT TOP 1
		@secondLastEventId = evt.id,
		@secondLastEventNumber = CAST(evt.EventNumber as NVARCHAR(50)),
		@secondLastEventDate = evt.EventStartDatetime
	FROM HC.Event evt
	WHERE evt.KennelId = @kennelId AND evt.IsCountedRun = 1
	AND evt.id != @lastEventId
	AND evt.EventStartDatetime < @now
	ORDER BY evt.EventStartDatetime DESC

	SELECT TOP 1
		@nextEventNumber = CAST(evt.EventNumber as NVARCHAR(50)),
		@nextEventDate = evt.EventStartDatetime
	FROM HC.Event evt
	WHERE evt.KennelId = @kennelId AND evt.IsCountedRun = 1
	AND evt.EventStartDatetime > @lastEventDate
	ORDER BY evt.EventStartDatetime ASC

	-- Main query (read-only, no transaction needed)
	;WITH cte1 AS (
		SELECT
			  h.PublicHasherId as publicHasherId
			, h.id as hasherId
			, @publicKennelId as publicKennelId
			, h.HashName as hashName
			, h.FirstName as firstName
			, h.LastName as lastName
			, h.DisplayName as displayName
			, CASE WHEN hkm.MembershipExpirationDate > @now THEN h.Email ELSE '<hidden>' END as eMail
			, COALESCE(h.Photo, 'bundle://avatar-1') as photo
			, h.LastLoginDateTime as lastLoginDateTime
			, CASE WHEN LastLoginDateTime IS NULL THEN REPLACE(h.ResetCode, 'URC:', '') ELSE '' END as inviteCode
			, CASE WHEN hkm.kennelId = h.HomeKennelId THEN 'Yes' ELSE 'No' END as isHomeKennel
			, CASE WHEN hkm.Following = 1 THEN 'Yes' ELSE 'No' END as isFollowing
			, CASE WHEN hkm.MembershipExpirationDate > @now THEN 'Yes' ELSE 'No' END as isMember
			, CASE WHEN hkm.MembershipExpirationDate > @now THEN 'Member'
				   WHEN hkm.Following = 1 THEN 'Following' ELSE 'None' END as status
			-- Kennel-level preference. 'Auto' (0) is not a valid kennel default
			-- (auto only applies at the event level, falling back to this value),
			-- so legacy 0 and 1 both surface as 'On'. 2=Off, 3=Silver Bell
			-- (silent/in-app only), 4=6 hrs before (push only within the 6-hour
			-- window before the run).
			, CASE WHEN hkm.KennelNotificationPreference = 2 THEN 'Off' WHEN hkm.KennelNotificationPreference = 3 THEN 'Silver Bell' WHEN hkm.KennelNotificationPreference = 4 THEN '6 hrs before' ELSE 'On' END as notifications
			, CASE WHEN hkm.KennelEmailAlertPreference = 0 THEN 'Auto' WHEN hkm.KennelEmailAlertPreference = 1 THEN 'On' WHEN hkm.KennelEmailAlertPreference = 2 THEN 'Off' ELSE 'Unknown' END as emailAlerts
			, COALESCE(hkm.historicalHaringCount, 0) as historicHaring
			, COALESCE(hkm.historicalTotalRunCount, 0) as historicTotalRuns
			, COALESCE(hkm.hcHaringCount, 0) as hcHaringCount
			, COALESCE(hkm.hcTotalRunCount, 0) as hcTotalRunCount
			, CASE WHEN hkm.HistoricalCountIsEstimate = 1 THEN 'Yes' ELSE 'No' END as historicCountsAreEstimates
			, hkm.DateOfLastRun as dateOfLastRun
			, hkm.MembershipExpirationDate as membershipExpirationDate
			, hkm.KennelCredit as kennelCredit
			, hkm.DiscountAmount as discountAmount
			, hkm.DiscountPercent as discountPercent
			, hkm.DiscountDescription as discountDescription
			-- hashCredit now sourced from HasherKennelMap.KennelCredit (kept current
			-- by nonApi_updateKennelCreditByUser). The legacy HC.KennelCredit table
			-- is no longer read here (it is a redundant copy, marked for retirement).
			, COALESCE(hkm.KennelCredit, 0) as hashCredit
		FROM HC.HasherKennelMap hkm
		INNER JOIN HC.Hasher h on hkm.UserId = h.id
		WHERE hkm.KennelId = @kennelId
		AND (hkm.MembershipExpirationDate > @now OR hkm.Following = 1)
	),
	cte2 AS (
		SELECT
			hem.UserId as hasherid,
			@lastEventNumber + '-' + COALESCE(pay.PaymentTypeCode, '?') as atLastEvent,
			@lastEventDate as lastEventDate
		FROM HC.HasherEventMap hem
		LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
		WHERE hem.EventId = @lastEventId
	),
	cte3 AS (
		SELECT
			hem.UserId as hasherid,
			@secondLastEventNumber + '-' + COALESCE(pay.PaymentTypeCode, '?') as atSecondToLastEvent,
			@secondLastEventDate as secondToLastEventDate,
			@nextEventDate as nextEventDate,
			@nextEventNumber as nextEventNumber
		FROM HC.HasherEventMap hem
		LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
		WHERE hem.EventId = @secondLastEventId
	)
	SELECT
		publicHasherId, publicKennelId, hashName, firstName, lastName, displayName,
		eMail, photo, lastLoginDateTime, inviteCode, isHomeKennel, isFollowing,
		isMember, status, notifications, emailAlerts, historicHaring, historicTotalRuns,
		hcHaringCount, hcTotalRunCount, historicCountsAreEstimates, dateOfLastRun,
		membershipExpirationDate, kennelCredit, discountAmount, discountPercent,
		discountDescription, hashCredit, atLastEvent, atSecondToLastEvent,
		secondToLastEventDate, lastEventDate, nextEventDate, nextEventNumber
	FROM cte1
	LEFT OUTER JOIN cte2 on cte1.hasherId = cte2.hasherid
	LEFT OUTER JOIN cte3 on cte1.hasherId = cte3.hasherid
	ORDER BY cte1.displayName

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
