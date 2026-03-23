CREATE OR ALTER PROCEDURE [HC6].[hcportal_getEventMessages]

	-- required parameters
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicEventId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getEventMessages
-- Description: Retrieves all non-deleted event messages for a specific
--              event, returning message content with author information
--              formatted for a chat-like interface. Messages are
--              ordered by creation time descending (newest first).
-- Parameters: @deviceId, @accessToken (auth),
--             @publicEventId (event filter)
-- Returns: Single rowset: id, type, text, roomId, createdAt, author
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getEventMessages
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Fixed LOG.GeneralLog LogSource: was 'hcportal_getKennelHashers',
--     now correctly says 'hcportal_getEventMessages'
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- Bug Fixes (post-migration):
--   - Auth now validated before parameter checks (consistent with other HC6 SPs)
--   - Added NULL guard on @eventId: unknown event returns clean error
--     instead of silently returning zero rows
--   - Added msg.removed = 0 and h.Removed = 0 filters: soft-deleted
--     messages and messages from removed hashers are now excluded
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation (before parameter checks, consistent with HC6 standard)
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicEventId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicEventId
	IF @publicEventId IS NULL
	BEGIN
		SELECT 0 AS Success, 'publicEventId is required' AS ErrorMessage;
		RETURN;
	END

	-- Resolve event ID
	DECLARE @eventId UNIQUEIDENTIFIER;
	SELECT @eventId = id FROM HC.Event WHERE PublicEventId = @publicEventId;

	-- Guard: event must exist
	IF @eventId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Event not found' AS ErrorMessage;
		RETURN;
	END

	-- Main query: Event Messages (excluding soft-deleted messages and removed hashers)
	SELECT
		msg.id AS [id],
		'text' AS [type],
		msg.MessageContent AS [text],
		@publicEventId AS roomId,
		DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt) AS [createdAt],

		JSON_QUERY(
			CASE
				WHEN h.id IS NOT NULL
				THEN (
					SELECT
						h.PublicHasherId AS [id],
						h.DisplayName AS [firstName],
						h.Photo AS [imageUrl]
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				ELSE NULL
			END
		) AS [author]

	FROM HC.EventMessage msg
	INNER JOIN HC.Hasher h ON msg.UserId = h.id
	WHERE msg.EventId = @eventId
	  AND msg.removed = 0
	  AND h.Removed = 0
	ORDER BY createdAt DESC

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
