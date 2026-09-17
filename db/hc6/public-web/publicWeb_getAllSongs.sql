-- =====================================================================
-- Procedure: HC6.publicWeb_getAllSongs
-- Description: The app's Songs tab for a web member (E9.F7.S11). The app
--   reads `SELECT * FROM common_songs WHERE removed = 0 ORDER BY songName`
--   — the whole catalogue, ungrouped: a kennel's own songbook is only
--   seen inside that kennel's pages (James, 2026-09-17). Same columns as
--   publicWeb_getSongs so the web renders both with one component.
--   Behind ValidateAppAuth rather than the anonymous shim, because the
--   per-kennel songbook is public one kennel at a time and this is the
--   whole global songbook in a single call.
-- Parameters: @songId — optional; when given, just that one song.
-- Returns: rowset 0 envelope; rowset 1 the songs, by name
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getAllSongs]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @songId      UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 117, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        s.id,
        s.SongName,
        s.TuneOf,
        s.BawdyRating,
        s.Lyrics,
        s.Notes,
        s.Actions,
        s.Variants,
        s.ImageUrl,
        s.AudioUrl,
        s.Rank,
        s.Tags
    FROM HC.Song s
    WHERE s.Removed = 0
      AND (@songId IS NULL OR s.id = @songId)
    ORDER BY s.SongName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getAllSongs', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
GO
