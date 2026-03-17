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

	-- =============================================
	-- Add or remove song from kennel
	-- =============================================
	BEGIN TRANSACTION;

	IF @isInKennel = 1
	BEGIN
		-- Adding song to kennel: check if a row already exists
		IF EXISTS (SELECT 1 FROM HC.KennelSongMap WHERE SongId = @songId AND KennelId = @kennelId)
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
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
