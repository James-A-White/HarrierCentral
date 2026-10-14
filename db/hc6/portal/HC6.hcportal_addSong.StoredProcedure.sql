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
    @bawdyRating    SMALLINT         = NULL,
    -- 2026-10-14 (idempotency audit P6): the new song's id, minted by the
    -- portal ONCE per add form. NULL = the old behaviour (NEWID()).
    @newSongId      UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_addSong
-- Idempotency: client-id — @newSongId minted once per add form; a repeat returns it, nothing inserted.
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
--             @newSongId     (optional; the client-minted id, see below)
-- Idempotent writes ("creates a row", 2026-10-14, idempotency audit P6):
--   the portal mints @newSongId once per add form and resends it on every
--   attempt. It is checked WITH (UPDLOCK, HOLDLOCK) inside the transaction:
--   unknown => inserted under it; already added by this kennel => a repeat
--   after a lost reply: the same success row, no second song, and the
--   kennel's KennelSongMap row is created only if it has none at all (a row
--   the admin has since switched off is left off); added by another
--   kennel => refused. The CATCH now logs to HC.ErrorLog.
-- Returns: SuccessResult rowset (resultCode, result, newSongId) or
--          error envelope (Success, ErrorMessage)
-- Author: Harrier Central
-- Created: 2026-03-20
-- HC5 Source: None — new SP with no HC5 equivalent
-- Breaking Changes: N/A (new SP)
-- Permission bits (AppAccessFlags in HC.HasherKennelMap):
--   0x40000000 = authIsSuperAdmin
--   0x00000040 = authCanManageSongs
--   Service accounts (callerType != 0) are always rejected.
-- =====================================================================

-- Emoji-safe blank test. The database collates SQL_Latin1_General_CP1_CI_AS,
-- in which a surrogate pair has NO sort weight, so N'<emoji>' = '' is TRUE
-- and NULLIF(LTRIM(RTRIM(x)), '') threw away any value made only of emoji.
-- LEN() counts code units, so emoji survive while a string of spaces still
-- measures 0. (2026-09-19, after a room message of one wave was refused.)

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

    -- Service accounts are not permitted to add songs
    IF @callerType != 0
    BEGIN
        SELECT 0 AS Success, 'Service accounts may not add songs' AS ErrorMessage;
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

    -- Permission check: caller must hold authIsSuperAdmin (0x40000000) OR
    -- authCanManageSongs (0x00000040) for the requesting kennel.
    DECLARE @addSongFlags INT;
    SELECT @addSongFlags = hkm.AppAccessFlags
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId;

    IF @addSongFlags IS NULL OR (@addSongFlags & 0x40000040) = 0
    BEGIN
        SELECT 0 AS Success, 'You do not have permission to add songs' AS ErrorMessage;
        RETURN;
    END

    -- Insert song and link to kennel in a single transaction
    DECLARE @songId UNIQUEIDENTIFIER = COALESCE(@newSongId, NEWID());

    BEGIN TRANSACTION;

    IF (@newSongId IS NOT NULL)
    BEGIN
        DECLARE @found SMALLINT = 0;
        DECLARE @existingKennelId UNIQUEIDENTIFIER;
        SELECT @found = 1, @existingKennelId = s.AddedBy_KennelId
        FROM HC.Song s WITH (UPDLOCK, HOLDLOCK)
        WHERE s.id = @songId;

        IF (@found = 1)
        BEGIN
            IF (@existingKennelId IS NULL OR @existingKennelId <> @kennelId)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS Success, 'That song id is already in use' AS ErrorMessage;
                RETURN;
            END

            -- A repeat: the song is there. Its kennel link exists once.
            IF NOT EXISTS (SELECT 1 FROM HC.KennelSongMap ksm WITH (UPDLOCK, HOLDLOCK)
                           WHERE ksm.KennelId = @kennelId AND ksm.SongId = @songId)
                INSERT INTO HC.KennelSongMap (id, KennelId, SongId, Removed)
                VALUES (NEWID(), @kennelId, @songId, 0);

            COMMIT TRANSACTION;
            SELECT
                CAST(1 AS INT)  AS resultCode,
                'Success'       AS result,
                @songId         AS newSongId;
            RETURN;
        END
    END

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
        @songId,
        LTRIM(RTRIM(@songName)),
        CASE WHEN LEN(COALESCE(@tuneOf, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@tuneOf)) END,
        @bawdyRating,
        CASE WHEN LEN(COALESCE(@notes, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@notes)) END,
        CASE WHEN LEN(COALESCE(@actions, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@actions)) END,
        CASE WHEN LEN(COALESCE(@variants, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@variants)) END,
        NULL,                                           -- ImageUrl: set separately (not at creation time)
        NULL,                                           -- AudioUrl: set separately (not at creation time)
        0,                                              -- AutoAddToKennel: default off
        0,                                              -- Rank: default 0
        @kennelId,
        @hasherId,
        COALESCE(LTRIM(RTRIM(@lyrics)), ''),            -- Lyrics is NOT NULL; store '' if omitted
        CASE WHEN LEN(COALESCE(@tags, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@tags)) END,
        0
    );

    -- Link the new song to the kennel that created it
    INSERT INTO HC.KennelSongMap (id, KennelId, SongId, Removed)
    VALUES (NEWID(), @kennelId, @songId, 0);

    COMMIT TRANSACTION;

    -- Return the new song's ID so the caller can reference it
    SELECT
        CAST(1 AS INT)  AS resultCode,
        'Success'       AS result,
        @songId         AS newSongId

END TRY
BEGIN CATCH
    -- Roll back FIRST, then log: a log row written inside the transaction
    -- would be erased by the rollback.
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_addSong',
            ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
