CREATE OR ALTER PROCEDURE [HC6].[hcportal_toggleKennelSong]

	-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
	@deviceId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL,
	@songId UNIQUEIDENTIFIER = NULL,
	@isInKennel SMALLINT = NULL   -- 1 = add to kennel, 0 = remove from kennel

AS
-- =====================================================================
-- Procedure: HC6.hcportal_toggleKennelSong
-- Idempotency: set-state — sends the target (@isInKennel), never a flip; the add's existence check is locked (UPDLOCK, HOLDLOCK) so concurrent adds make one map row.
-- Description: Toggles whether a song is associated with a kennel.
--              If adding (@isInKennel=1), either creates a new
--              KennelSongMap record or un-soft-deletes an existing one.
--              If removing (@isInKennel=0), soft-deletes the mapping.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId, @songId (routing)
--             @isInKennel (toggle flag: 0 or 1)
-- Returns: SuccessResult rowset (resultCode, result) or error envelope
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_toggleKennelSong
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for GUIDs
--   - Removed dead input parameters @hcVersion, @hcBuild
--   - INSERT/UPDATE wrapped in transaction
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- Bug Fixes (vs original HC5):
--   - All KennelSongMap operations now use resolved internal @kennelId
--     instead of @publicKennelId directly (HC5 bug: EXISTS/UPDATE/INSERT
--     all matched zero rows, songs were never actually toggled)
--   - 2026-10-14 (idempotency audit P9; Idempotent writes: sets a state):
--     the add path's existence check takes WITH (UPDLOCK, HOLDLOCK), so two
--     concurrent adds cannot insert two KennelSongMap rows. No unique index
--     on (KennelId, SongId) was added; that is James's call.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	DECLARE @now DATETIME2 = GETDATE()

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	DECLARE @hasherId UNIQUEIDENTIFIER;
	DECLARE @callerType INT;
	DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @songId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Validation: songId
	IF @songId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid songId' AS ErrorMessage;
		RETURN;
	END

	-- Validation: isInKennel
	IF @isInKennel IS NULL OR @isInKennel NOT IN (0, 1)
	BEGIN
		SELECT 0 AS Success, 'isInKennel must be 0 or 1' AS ErrorMessage;
		RETURN;
	END

	-- Resolve internal kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER;
	SELECT @kennelId = ken.id FROM HC.Kennel ken WHERE ken.PublicKennelId = @publicKennelId;

	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
		RETURN;
	END

	-- Permission (2026-10-13): a kennel's songbook is its managers' --
	-- Admin/SuperAdmin or Manage songs (0x40), or manageSongs. Until now any
	-- signed-in portal user could change any kennel's songbook.
	DECLARE @maySongs SMALLINT = 0;
	EXEC HC6.nonApi_portalKennelAccess @hasherId = @hasherId, @callerType = @callerType,
	     @kennelId = @kennelId, @flagMask = 0x000000C1, @functionKey = 'manageSongs',
	     @allowed = @maySongs OUTPUT;
	IF (@maySongs = 0)
	BEGIN
		SELECT 0 AS Success, 'Not authorised to change this kennel''s songs' AS ErrorMessage;
		RETURN;
	END

	-- =============================================
	-- Add or remove song from kennel
	-- =============================================
	BEGIN TRANSACTION;

	IF @isInKennel = 1
	BEGIN
		-- Adding song to kennel: check if a row already exists
		-- Locked (idempotency audit P9, 2026-10-14): two concurrent adds
		-- cannot both see "no row" and insert two map rows; the second waits
		-- and then un-removes the first one's row.
		IF EXISTS (SELECT 1 FROM HC.KennelSongMap WITH (UPDLOCK, HOLDLOCK) WHERE SongId = @songId AND KennelId = @kennelId)
		BEGIN
			-- Row exists -> un-remove it
			UPDATE HC.KennelSongMap
			SET Removed = 0, updatedAt = @now
			WHERE SongId = @songId AND KennelId = @kennelId
		END
		ELSE
		BEGIN
			-- No row -> insert a new mapping
			INSERT INTO HC.KennelSongMap (id, SongId, KennelId, Removed, CreatedAt)
			VALUES (NEWID(), @songId, @kennelId, 0, @now)
		END
	END
	ELSE
	BEGIN
		-- Removing song from kennel: soft-delete by setting Removed = 1
		UPDATE HC.KennelSongMap
		SET Removed = 1, updatedAt = @now
		WHERE SongId = @songId AND KennelId = @kennelId AND Removed = 0
	END

	COMMIT TRANSACTION;

	-- Return success
	SELECT
		CAST(1 AS INT) as resultCode,
		'Success' as result

END TRY
BEGIN CATCH
	-- Roll back FIRST, then log (2026-10-14: this CATCH did not log).
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
	VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_toggleKennelSong',
	        ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
