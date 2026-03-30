CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getSongs]
    @publicKennelId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getSongs
-- Description: Returns all non-removed songs assigned to a kennel via
--              HC.KennelSongMap, for public display on the kennel
--              website songs page.
-- Parameters:  @publicKennelId  UNIQUEIDENTIFIER — the kennel's public
--                               GUID; used to resolve the internal
--                               kennelId for the KennelSongMap join.
-- Returns:     Rowset 0: song rows ordered by Rank ASC, SongName ASC.
--              Empty rowset when the kennel is not found / inactive.
--              On validation or runtime error: single-row error envelope
--                        (Success = 0, ErrorMessage = ...).
-- Author:      Harrier Central
-- Created:     2026-03-29
-- HC5 Source:  None — new for HC6 public web (derived from
--              HC6.hcportal_getSongs but unauthenticated / kennel-scoped)
-- Breaking Changes: None — new SP.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Input validation
    IF @publicKennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'publicKennelId is required.' AS ErrorMessage;
        RETURN;
    END;

    -- Resolve internal kennelId from the public GUID
    DECLARE @kennelId UNIQUEIDENTIFIER;
    SELECT @kennelId = k.id
    FROM HC.Kennel k
    WHERE k.PublicKennelId = @publicKennelId
      AND k.deleted = 0
      AND k.removed = 0;

    IF @kennelId IS NULL
    BEGIN
        -- Return empty rowset — shim will treat as 404
        SELECT
            CAST(NULL AS UNIQUEIDENTIFIER) AS id,
            CAST(NULL AS NVARCHAR(120))    AS SongName,
            CAST(NULL AS NVARCHAR(500))    AS TuneOf,
            CAST(NULL AS SMALLINT)         AS BawdyRating,
            CAST(NULL AS NVARCHAR(MAX))    AS Lyrics,
            CAST(NULL AS NVARCHAR(MAX))    AS Notes,
            CAST(NULL AS NVARCHAR(MAX))    AS Actions,
            CAST(NULL AS NVARCHAR(MAX))    AS Variants,
            CAST(NULL AS NVARCHAR(500))    AS ImageUrl,
            CAST(NULL AS NVARCHAR(500))    AS AudioUrl,
            CAST(NULL AS SMALLINT)         AS Rank,
            CAST(NULL AS NVARCHAR(MAX))    AS Tags
        WHERE 1 = 0;
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
    WHERE s.Removed = 0
    ORDER BY s.Rank ASC, s.SongName ASC;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
