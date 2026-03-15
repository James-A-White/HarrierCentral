CREATE OR ALTER PROCEDURE [HC6].[hcportal_getSongs]

	-- required parameters
	@publicHasherId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getSongs
-- Description: Returns all non-removed songs from HC.Song with a
--              membership flag (isInKennel) indicating whether each song
--              is assigned to the specified kennel via HC.KennelSongMap.
-- Parameters: @publicHasherId, @accessToken (auth)
--             @publicKennelId (kennel to check membership against)
-- Returns: Single rowset: id, SongName, TuneOf, BawdyRating, Notes,
--          Actions, Variants, ImageUrl, AudioUrl, AutoAddToKennel, Rank,
--          AddedBy_KennelId, AddedBy_UserId, Lyrics, Tags, createdAt,
--          isInKennel
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getSongs
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - DATALENGTH checks replaced with IS NULL for UNIQUEIDENTIFIER params
--   - @publicKennelId changed from NVARCHAR(250) to UNIQUEIDENTIFIER
--   - isInKennel return type kept as SMALLINT (matches HC5)
--   - Removed dead variable @now (was declared but never used)
--   - Removed dead input parameters: @hcVersion, @hcBuild
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- Bug Fixes (vs original HC5):
--   - KennelSongMap join now uses resolved internal @kennelId instead of
--     @publicKennelId directly (HC5 bug: join never matched, isInKennel
--     always returned 0)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @publicKennelId, @authError OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Resolve internal kennelId
	DECLARE @kennelId UNIQUEIDENTIFIER;
	SELECT @kennelId = ken.id FROM HC.Kennel ken WHERE ken.PublicKennelId = @publicKennelId;

	-- =============================================
	-- Return all non-removed songs with kennel membership flag
	-- isInKennel = 1 if the song exists in KennelSongMap for this kennel (and not removed), 0 otherwise
	-- =============================================
	SELECT
		s.id,
		s.SongName,
		s.TuneOf,
		s.BawdyRating,
		s.Notes,
		s.Actions,
		s.Variants,
		s.ImageUrl,
		s.AudioUrl,
		s.AutoAddToKennel,
		s.Rank,
		s.AddedBy_KennelId,
		s.AddedBy_UserId,
		s.Lyrics,
		s.Tags,
		s.createdAt,
		CAST(CASE WHEN ksm.id IS NOT NULL THEN 1 ELSE 0 END AS SMALLINT) AS isInKennel
	FROM HC.Song s WITH (NOLOCK)
	LEFT JOIN HC.KennelSongMap ksm WITH (NOLOCK)
		ON ksm.SongId = s.id
		AND ksm.KennelId = @kennelId
		AND ksm.Removed = 0
	WHERE s.Removed = 0
	ORDER BY s.SongName ASC

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
