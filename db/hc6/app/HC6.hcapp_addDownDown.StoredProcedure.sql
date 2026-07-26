CREATE OR ALTER PROCEDURE [HC6].[hcapp_addDownDown]

    @deviceId        UNIQUEIDENTIFIER,
    @accessToken     NVARCHAR(1000),
    @kennelId        UNIQUEIDENTIFIER,
    @eventId         UNIQUEIDENTIFIER,
    @hasherIds       NVARCHAR(MAX),
    @chargeText      NVARCHAR(MAX),
    @songChoice      NVARCHAR(500) = NULL,
    @songId          UNIQUEIDENTIFIER = NULL,
    @chargePhotoUrl  NVARCHAR(MAX) = NULL,
    @externalNames   NVARCHAR(MAX) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_addDownDown
-- Description: Records a DownDown charge against one or more people.
--   Any run attendee (AttendenceState >= 20 on the event) may submit.
--   A charge may target registered hashers, people not in the app, or a
--   mix of both. @hasherIds is a pipe-delimited list of UUID strings;
--   @externalNames is a JSON array of names for people not in the app,
--   e.g. ["Dizzy Lizzy","Two-Buck Chuck"]. At least one of the two is
--   required. Creates one HC.DownDowns row (holding the external names)
--   and one HC.DownDownHashers row per hasher. Returns the new ID.
-- Parameters:
--   @deviceId       - Registered device UUID
--   @accessToken    - Token validated against DeviceSecret
--   @kennelId       - Kennel that owns the event
--   @eventId        - Event the charge belongs to
--   @hasherIds      - Pipe-delimited hasher UUIDs to charge (may be empty)
--   @chargeText     - Description of the charge
--   @chargePhotoUrl - Optional blob URL of an attached charge photo
--   @externalNames  - Optional JSON array of names for people not in the app
-- Returns:
--   On success (rowset 0): { downDownId }
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
-- HC5 Source: None — new feature
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 55,
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
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Count valid targets: registered hashers (valid UUIDs) and external names.
DECLARE @hasherCount INT = (
    SELECT COUNT(*) FROM STRING_SPLIT(ISNULL(@hasherIds, ''), '|')
    WHERE TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) IS NOT NULL
);
DECLARE @externalCount INT = 0;
IF (@externalNames IS NOT NULL AND ISJSON(@externalNames) = 1)
    SET @externalCount = (
        SELECT COUNT(*) FROM OPENJSON(@externalNames)
        WHERE LEN(LTRIM(RTRIM([value]))) > 0
    );

-- A charge needs a description and at least one target (hasher or external name).
IF (@kennelId  IS NULL OR @kennelId  = '00000000-0000-0000-0000-000000000000'
 OR @eventId   IS NULL OR @eventId   = '00000000-0000-0000-0000-000000000000'
 OR (@hasherCount = 0 AND @externalCount = 0)
 OR LEN(LTRIM(RTRIM(ISNULL(@chargeText, '')))) = 0)
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing parameter',
            '@kennelId, @eventId, @chargeText and at least one target (hasher or external name) are required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Verify caller attended this run (AttendenceState >= 20)
IF NOT EXISTS (
    SELECT 1 FROM HC.HasherEventMap
    WHERE UserId         = @userId
      AND EventId        = @eventId
      AND AttendenceState >= 20
)
BEGIN
    SET @errorCode = 1335; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Not authorised',
            'Caller did not attend this run', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'Only run attendees can submit DownDowns.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @newId UNIQUEIDENTIFIER = NEWID();

    -- Only persist external names when there is at least one; store NULL otherwise.
    DECLARE @externalNamesToStore NVARCHAR(MAX) =
        CASE WHEN @externalCount > 0 THEN @externalNames ELSE NULL END;

    INSERT INTO HC.DownDowns (id, EventId, KennelId, ChargeText, SongChoice, SongId, IsDone, CreatedByUserId, ChargePhotoUrl, ExternalNames)
    VALUES (@newId, @eventId, @kennelId, @chargeText, NULLIF(LTRIM(RTRIM(@songChoice)), ''), @songId, 0, @userId,
            NULLIF(LTRIM(RTRIM(@chargePhotoUrl)), ''), @externalNamesToStore);

    INSERT INTO HC.DownDownHashers (DownDownId, HasherId)
    SELECT @newId, TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER)
    FROM STRING_SPLIT(@hasherIds, '|')
    WHERE TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT @newId AS downDownId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
