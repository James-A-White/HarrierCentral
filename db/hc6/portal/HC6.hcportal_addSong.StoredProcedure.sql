CREATE OR ALTER PROCEDURE [HC6].[hcportal_addSong]

    -- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @songName       NVARCHAR(120)    = NULL,
    @tuneOf         NVARCHAR(500)    = NULL,
    @lyrics         NVARCHAR(MAX)    = NULL,
    @notes          NVARCHAR(MAX)    = NULL,
    @actions        NVARCHAR(MAX)    = NULL,
    @variants       NVARCHAR(MAX)    = NULL,
    @tags           NVARCHAR(MAX)    = NULL,
    @bawdyRating    SMALLINT         = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_addSong
-- Description: Creates a new song record in HC.Song and immediately
--              links it to the requesting kennel via HC.KennelSongMap.
--              Both inserts are wrapped in a single transaction.
--              The authenticated hasher is recorded as AddedBy_UserId
--              and the resolved kennel as AddedBy_KennelId.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing — resolved to internal kennelId)
--             @songName      (required; trimmed)
--             @tuneOf        (optional; NULL if blank)
--             @lyrics        (optional; stored as '' if null)
--             @notes         (optional; NULL if blank)
--             @actions       (optional; NULL if blank)
--             @variants      (optional; NULL if blank)
--             @tags          (optional; NULL if blank)
--             @bawdyRating   (required; must be 0, 1, 2 or 3)
-- Returns: SuccessResult rowset (resultCode, result, newSongId) or
--          error envelope (Success, ErrorMessage)
-- Author: Harrier Central
-- Created: 2026-03-20
-- HC5 Source: None — new SP with no HC5 equivalent
-- Breaking Changes: N/A (new SP)
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
    DECLARE @authError  NVARCHAR(255);
    DECLARE @hasherId   UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
    EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Validation: songName
    IF @songName IS NULL OR LEN(LTRIM(RTRIM(@songName))) = 0
    BEGIN
        SELECT 0 AS Success, 'Song name is required' AS ErrorMessage;
        RETURN;
    END

    -- Validation: bawdyRating
    IF @bawdyRating IS NULL OR @bawdyRating NOT IN (0, 1, 2, 3)
    BEGIN
        SELECT 0 AS Success, 'bawdyRating must be 0, 1, 2, or 3' AS ErrorMessage;
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

    -- Insert song and link to kennel in a single transaction
    DECLARE @newSongId UNIQUEIDENTIFIER = NEWID();

    BEGIN TRANSACTION;

    INSERT INTO HC.Song (
        id,
        SongName,
        TuneOf,
        BawdyRating,
        Notes,
        Actions,
        Variants,
        ImageUrl,
        AudioUrl,
        AutoAddToKennel,
        Rank,
        AddedBy_KennelId,
        AddedBy_UserId,
        Lyrics,
        Tags,
        Removed
    )
    VALUES (
        @newSongId,
        LTRIM(RTRIM(@songName)),
        NULLIF(LTRIM(RTRIM(@tuneOf)), ''),
        @bawdyRating,
        NULLIF(LTRIM(RTRIM(@notes)), ''),
        NULLIF(LTRIM(RTRIM(@actions)), ''),
        NULLIF(LTRIM(RTRIM(@variants)), ''),
        NULL,                                           -- ImageUrl: set separately (not at creation time)
        NULL,                                           -- AudioUrl: set separately (not at creation time)
        0,                                              -- AutoAddToKennel: default off
        0,                                              -- Rank: default 0
        @kennelId,
        @hasherId,
        COALESCE(LTRIM(RTRIM(@lyrics)), ''),            -- Lyrics is NOT NULL; store '' if omitted
        NULLIF(LTRIM(RTRIM(@tags)), ''),
        0
    );

    -- Link the new song to the kennel that created it
    INSERT INTO HC.KennelSongMap (id, KennelId, SongId, Removed)
    VALUES (NEWID(), @kennelId, @newSongId, 0);

    COMMIT TRANSACTION;

    -- Return the new song's ID so the caller can reference it
    SELECT
        CAST(1 AS INT)  AS resultCode,
        'Success'       AS result,
        @newSongId      AS newSongId

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
