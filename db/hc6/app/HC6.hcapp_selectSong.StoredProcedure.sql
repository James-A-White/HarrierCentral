CREATE OR ALTER PROCEDURE [HC6].[hcapp_selectSong]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @eventId     UNIQUEIDENTIFIER,
    @songId      UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_selectSong
-- Description: Records the current song selection for an event (interactive
--   songbook). Any authenticated user who is RSVP'd to the event may call
--   this. Replaces the previous selection for display purposes; all
--   selections are retained for history. Returns the song title and
--   selected-by name (for the caller's snackbar) plus the FCM tokens of
--   all RSVP'd attendees (for the Azure Function to fan out a silent push).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against device secret
--   @eventId     - Event the song is being selected for
--   @songId      - Song being selected (FK → HC.Song.id)
-- Returns:
--   rowset 0 — success envelope { success, errorCode, errorType }
--   rowset 1 — adHocData { adHocDataId, songTitle, selectedByName }
--   rowset 2 — FCM recipients [{ FcmToken, UserId }] for Azure Function fan-out
--   On error (rowsets 0+1): standard HC6 error detail
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
    @spNumber     = 76,
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
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1281; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null eventId', 'eventId is required', @procName_self, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

IF (@songId IS NULL OR @songId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1282; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null songId', 'songId is required', @procName_self, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing song' AS errorTitle, 'A song must be specified.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

-- Verify caller is RSVP'd to this event (rsvpState >= 2 = Maybe or Going)
IF NOT EXISTS (
    SELECT 1 FROM HC.HasherEventMap hem
    WHERE hem.UserId = @userId AND hem.EventId = @eventId AND hem.RsvpState >= 2 AND hem.Removed = 0
)
BEGIN
    SET @errorCode = 1283; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not RSVP''d to event', 'User must be RSVP''d to select a song', @procName_self, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not RSVP''d' AS errorTitle, 'You must be RSVP''d to this event to share a song.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

-- Verify song exists
DECLARE @songTitle NVARCHAR(120);
SELECT @songTitle = s.SongName FROM HC.Song s WHERE s.id = @songId AND s.Removed = 0;

IF (@songTitle IS NULL)
BEGIN
    SET @errorCode = 1284; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Song not found', 'No active song found with given songId', @procName_self, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Song not found' AS errorTitle, 'The selected song could not be found.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

-- Resolve display name for the songmeister
DECLARE @selectedByName NVARCHAR(200);
SELECT @selectedByName = COALESCE(
    NULLIF(h.HashName, ''),
    NULLIF(h.DisplayName, ''),
    NULLIF(h.FirstName, ''),
    'Someone'
)
FROM HC.Hasher h WHERE h.id = @userId;

-- Insert the song session record
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO HC.SongSession (EventId, SongId, SelectedByUserId, SelectedAt)
    VALUES (@eventId, @songId, @userId, SYSUTCDATETIME());

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorCode = 1285; SET @errorType = 5; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Insert failed', ERROR_MESSAGE(), @procName_self, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Save failed' AS errorTitle, 'Your song selection could not be saved.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END CATCH

-- rowset 0: success envelope
SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

-- rowset 1: adHocData — song details for Flutter caller + Azure Function
SELECT
    1                                             AS adHocDataId,
    @songTitle                                    AS songTitle,
    @selectedByName                               AS selectedByName,
    LOWER(CAST(@eventId AS NVARCHAR(40)))         AS eventId,
    LOWER(CAST(@songId  AS NVARCHAR(40)))         AS songId;

-- rowset 2: FCM recipients — consumed by Azure Function; not parsed by Flutter.
-- Includes RSVP'd (rsvpState >= 2) and checked-in (attendenceState >= 3) users.
-- showNotification = 1 when they have event or kennel notifications enabled.
SELECT DISTINCT
    d.FcmToken,
    LOWER(CAST(d.UserId AS NVARCHAR(40)))         AS UserId,
    CASE WHEN COALESCE(hem.EventNotificationPreference, 0) > 0
              OR COALESCE(hkm.KennelNotificationPreference, 0) > 0
         THEN 1 ELSE 0 END                        AS showNotification
FROM HC.HasherEventMap hem
INNER JOIN HC.Device d ON d.UserId = hem.UserId
LEFT  JOIN HC.HasherKennelMap hkm
      ON hkm.UserId = hem.UserId AND hkm.KennelId = @kennelId
WHERE hem.EventId  = @eventId
  AND (hem.RsvpState >= 2 OR hem.AttendenceState >= 3)
  AND hem.Removed   = 0
  AND d.FcmToken IS NOT NULL
  AND d.FcmToken != '';
