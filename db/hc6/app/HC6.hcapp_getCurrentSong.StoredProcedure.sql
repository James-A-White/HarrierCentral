CREATE OR ALTER PROCEDURE [HC6].[hcapp_getCurrentSong]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @eventId     UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getCurrentSong
-- Description: Pull-on-open endpoint for the interactive songbook. Returns
--   the most recently selected song for the given event if it was selected
--   within the last 2 minutes AND the calling user is RSVP'd to the event.
--   Returns an empty rowset when no active song exists.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against device secret
--   @eventId     - Event to check for an active song
-- Returns:
--   On error (rowset 0): standard HC6 error detail
--   On success: single rowset — 0 or 1 rows:
--     { songId, songName, tuneOf, lyrics, bawdyRating,
--       imageUrl, audioUrl, tags, selectedByName, selectedAt }
-- Author: Harrier Central
-- Created: 2026-06-02
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);

DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName_self,
    @spNumber     = 77,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1291; SET @errorType = 2; SET @errorId = NEWID();
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

-- Caller must be RSVP'd to the event
IF NOT EXISTS (
    SELECT 1 FROM HC.HasherEventMap hem
    WHERE hem.UserId = @userId AND hem.EventId = @eventId AND hem.RsvpState >= 2 AND hem.Removed = 0
)
BEGIN
    -- Return empty rowset silently — not an error, user simply isn't RSVP'd
    SELECT
        CAST(NULL AS NVARCHAR(40))  AS songId,
        CAST(NULL AS NVARCHAR(120)) AS songName,
        CAST(NULL AS NVARCHAR(500)) AS tuneOf,
        CAST(NULL AS NVARCHAR(MAX)) AS lyrics,
        CAST(NULL AS SMALLINT)      AS bawdyRating,
        CAST(NULL AS NVARCHAR(500)) AS imageUrl,
        CAST(NULL AS NVARCHAR(500)) AS audioUrl,
        CAST(NULL AS NVARCHAR(MAX)) AS tags,
        CAST(NULL AS NVARCHAR(200)) AS selectedByName,
        CAST(NULL AS NVARCHAR(50))  AS selectedAt
    WHERE 1 = 0;
    RETURN;
END

-- Return the most recent song selected within the last 2 minutes
SELECT TOP 1
    LOWER(CAST(s.id        AS NVARCHAR(40)))  AS songId,
    s.SongName                                AS songName,
    s.TuneOf                                  AS tuneOf,
    s.Lyrics                                  AS lyrics,
    s.BawdyRating                             AS bawdyRating,
    s.ImageUrl                                AS imageUrl,
    s.AudioUrl                                AS audioUrl,
    s.Tags                                    AS tags,
    COALESCE(
        NULLIF(h.HashName, ''),
        NULLIF(h.DisplayName, ''),
        NULLIF(h.FirstName, ''),
        'Someone'
    )                                         AS selectedByName,
    CONVERT(NVARCHAR(50), CAST(ss.SelectedAt AS DATETIME2)) AS selectedAt
FROM HC.SongSession ss
INNER JOIN HC.Song   s ON s.id  = ss.SongId
INNER JOIN HC.Hasher h ON h.id  = ss.SelectedByUserId
WHERE ss.EventId  = @eventId
  AND ss.Removed  = 0
  AND ss.SelectedAt > DATEADD(MINUTE, -2, SYSUTCDATETIME())
ORDER BY ss.SelectedAt DESC;
