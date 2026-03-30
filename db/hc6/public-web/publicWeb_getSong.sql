CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getSong]
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @songId         UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getSong
-- Description: Returns a single song for the song detail page.
--              The KennelSongMap join ensures only songs belonging to
--              this kennel are accessible — cannot be used to read
--              another kennel's private songs.
-- Parameters:  @publicKennelId  UNIQUEIDENTIFIER — kennel public GUID
--              @songId          UNIQUEIDENTIFIER — HC.Song.id
-- Returns:     Rowset 0: single song row, or empty if not found /
--                        not assigned to this kennel.
--              On validation or runtime error: error envelope
--                        (Success = 0, ErrorMessage = ...).
-- Author:      Harrier Central
-- Created:     2026-03-29
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None — new SP.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    IF @publicKennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'publicKennelId is required.' AS ErrorMessage;
        RETURN;
    END;

    IF @songId IS NULL
    BEGIN
        SELECT 0 AS Success, 'songId is required.' AS ErrorMessage;
        RETURN;
    END;

    -- Resolve internal kennelId
    DECLARE @kennelId UNIQUEIDENTIFIER;
    SELECT @kennelId = k.id
    FROM HC.Kennel k
    WHERE k.PublicKennelId = @publicKennelId
      AND k.deleted = 0
      AND k.removed = 0;

    IF @kennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Kennel not found.' AS ErrorMessage;
        RETURN;
    END;

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
    FROM HC.Song s WITH (NOLOCK)
    INNER JOIN HC.KennelSongMap ksm WITH (NOLOCK)
        ON ksm.SongId    = s.id
        AND ksm.KennelId = @kennelId
        AND ksm.Removed  = 0
    WHERE s.id      = @songId
      AND s.Removed = 0;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
