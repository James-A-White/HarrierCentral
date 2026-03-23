CREATE OR ALTER PROCEDURE [HC6].[hcportal_editSong]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @songId         UNIQUEIDENTIFIER = NULL,
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
-- Procedure: HC6.hcportal_editSong
-- Description: Updates an existing song record in HC.Song.
--              Only users who hold either the super-admin permission
--              (AppAccessFlags & 0x40000000) or the song-management
--              permission (AppAccessFlags & 0x00000040) for the kennel
--              that originally added the song may call this procedure.
--              Users not associated with that kennel are rejected.
--              Service accounts (callerType 1 or 2) are explicitly
--              rejected — they may not edit songs.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (auth routing — the caller's kennel context)
--             @songId         (required — song to update)
--             @songName       (required — trimmed)
--             @tuneOf         (optional — stored as NULL if blank)
--             @lyrics         (optional — stored as '' if null; Lyrics is NOT NULL)
--             @notes          (optional — stored as NULL if blank)
--             @actions        (optional — stored as NULL if blank)
--             @variants       (optional — stored as NULL if blank)
--             @tags           (optional — stored as NULL if blank)
--             @bawdyRating    (required — must be 0, 1, 2 or 3)
-- Returns: SuccessResult rowset (resultCode, result) or
--          error envelope (Success, ErrorMessage)
-- Author: Harrier Central
-- Created: 2026-03-22
-- HC5 Source: None — new SP with no HC5 equivalent
-- Breaking Changes: N/A (new SP)
-- Permission bits (AppAccessFlags in HC.HasherKennelMap):
--   0x40000000 = authIsSuperAdmin
--   0x00000040 = authCanManageSongs
--   Service accounts (callerType != 0) are always rejected.
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

    -- Validation: songId
    IF @songId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Null or invalid songId' AS ErrorMessage;
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

    -- Look up the song and the kennel that originally added it
    DECLARE @songKennelId UNIQUEIDENTIFIER;
    SELECT @songKennelId = s.AddedBy_KennelId
    FROM HC.Song s
    WHERE s.id = @songId AND s.Removed = 0;

    IF @songKennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Song not found' AS ErrorMessage;
        RETURN;
    END

    -- Service accounts are not permitted to edit songs
    IF @callerType != 0
    BEGIN
        SELECT 0 AS Success, 'Service accounts may not edit songs' AS ErrorMessage;
        RETURN;
    END

    -- Permission check: caller must hold authIsSuperAdmin (0x40000000) OR
    -- authCanManageSongs (0x00000040) for the kennel that originally added the song.
    DECLARE @appAccessFlags INT;
    SELECT @appAccessFlags = hkm.AppAccessFlags
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @hasherId AND hkm.KennelId = @songKennelId;

    IF @appAccessFlags IS NULL OR (@appAccessFlags & 0x40000040) = 0
    BEGIN
        SELECT 0 AS Success,
            'You do not have permission to edit this song' AS ErrorMessage;
        RETURN;
    END

    -- Update the song
    BEGIN TRANSACTION;

    UPDATE HC.Song
    SET
        SongName    = LTRIM(RTRIM(@songName)),
        TuneOf      = NULLIF(LTRIM(RTRIM(@tuneOf)), ''),
        BawdyRating = @bawdyRating,
        Notes       = NULLIF(LTRIM(RTRIM(@notes)), ''),
        Actions     = NULLIF(LTRIM(RTRIM(@actions)), ''),
        Variants    = NULLIF(LTRIM(RTRIM(@variants)), ''),
        Lyrics      = COALESCE(LTRIM(RTRIM(@lyrics)), ''),
        Tags        = NULLIF(LTRIM(RTRIM(@tags)), ''),
        updatedAt   = CONVERT(datetimeoffset(7), sysutcdatetime(), 0)
    WHERE id = @songId AND Removed = 0;

    COMMIT TRANSACTION;

    SELECT
        CAST(1 AS INT) AS resultCode,
        'Success'      AS result

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
