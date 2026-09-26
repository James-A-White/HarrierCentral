CREATE OR ALTER PROCEDURE [HC6].[hcapp_updateDownDown]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER,
    @eventId     UNIQUEIDENTIFIER,
    @downDownId  UNIQUEIDENTIFIER,
    @chargeText      NVARCHAR(MAX),
    @songChoice      NVARCHAR(500)    = NULL,
    @songId          UNIQUEIDENTIFIER = NULL,
    @chargePhotoUrl  NVARCHAR(MAX)    = NULL,
    -- Who is charged (2026-09-26, James). NULL = leave as it is, so older
    -- apps that do not send these keep working. Sent together by the app's
    -- edit page; either one alone replaces only its own half.
    @hasherIds       NVARCHAR(MAX)    = NULL,  -- pipe-delimited UUIDs; '' = none
    @externalNames   NVARCHAR(MAX)    = NULL   -- JSON array of names; '[]' = none

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updateDownDown
-- Description: Updates the charge text on an existing DownDown. Only
--   the original creator or a GM/RA for the kennel may edit.
--   The operation is scoped to @eventId + @kennelId for safety.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns the event (auth scope)
--   @eventId     - Event the DownDown belongs to (validation scope)
--   @downDownId  - DownDown to update
--   @chargeText  - New charge text
--   @hasherIds / @externalNames - optional; the people charged, same formats
--                  as hcapp_addDownDown. NULL = unchanged. A change that would
--                  leave nobody charged is refused (1236).
-- Returns:
--   On success (rowset 0): { success=1, errorCode=NULL, errorType=NULL }
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
-- HC5 Source: None — new feature
-- Changes:
--   2026-09-26: edit who is charged — app hashers (HC.DownDownHashers) and
--     typed names for people not in the app (DownDowns.ExternalNames).
--     James: "I need to be able to edit a charge including the name of the
--     person charged if they were added as a text record."
--     Update and people change in one transaction.
-- =====================================================================
-- Emoji-safe blank test. The database collates SQL_Latin1_General_CP1_CI_AS,
-- in which a surrogate pair has NO sort weight, so N'<emoji>' = '' is TRUE
-- and NULLIF(LTRIM(RTRIM(x)), '') threw away any value made only of emoji.
-- LEN() counts code units, so emoji survive while a string of spaces still
-- measures 0. (2026-09-19, after a room message of one wave was refused.)

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
    @spNumber     = 58,
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

IF (@kennelId   IS NULL OR @kennelId   = '00000000-0000-0000-0000-000000000000'
 OR @eventId    IS NULL OR @eventId    = '00000000-0000-0000-0000-000000000000'
 OR @downDownId IS NULL OR @downDownId = '00000000-0000-0000-0000-000000000000'
 OR LEN(LTRIM(RTRIM(ISNULL(@chargeText, '')))) = 0)
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing parameter',
            '@kennelId, @eventId, @downDownId and @chargeText are all required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Auth: caller must be the original creator, or hold GM (0x02) | RA (0x08) for the kennel.
DECLARE @createdByUserId UNIQUEIDENTIFIER;
SELECT @createdByUserId = CreatedByUserId
FROM HC.DownDowns
WHERE id       = @downDownId
  AND EventId  = @eventId
  AND KennelId = @kennelId;

IF (@createdByUserId IS NULL)
BEGIN
    SET @errorCode = 4041; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'DownDown not found',
            'No DownDown matched @downDownId + @eventId + @kennelId', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Charge not found' AS errorTitle,
           'The charge could not be found. It may have been removed.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@createdByUserId <> @userId)
BEGIN
    -- Authorization: feature "Manage Down Downs" (see /hc-authorizations).
    DECLARE @ddAllowed SMALLINT;
    EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'manageDownDowns', @allowed = @ddAllowed OUTPUT;

    IF (@ddAllowed = 0)
    BEGIN
        SET @errorCode = 1337; SET @errorType = 3; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised',
                'Caller is not the creator and lacks GM or RA role', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Not authorised' AS errorTitle,
               'You can only edit charges you created.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

-- ── Who is charged, when the caller sent it ─────────────────────────
DECLARE @changePeople BIT = CASE WHEN @hasherIds IS NOT NULL OR @externalNames IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @newHashers TABLE (HasherId UNIQUEIDENTIFIER PRIMARY KEY);
DECLARE @newExternalNames NVARCHAR(MAX);

IF (@changePeople = 1)
BEGIN
    -- Hashers: the list sent, or the current ones when only names were sent.
    -- Only real hashers (the FK would refuse anything else mid-transaction).
    IF (@hasherIds IS NOT NULL)
        INSERT @newHashers (HasherId)
        SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(v.value)) AS UNIQUEIDENTIFIER)
        FROM STRING_SPLIT(@hasherIds, '|') v
        WHERE TRY_CAST(LTRIM(RTRIM(v.value)) AS UNIQUEIDENTIFIER) IS NOT NULL
          AND EXISTS (SELECT 1 FROM HC.Hasher h
                      WHERE h.id = TRY_CAST(LTRIM(RTRIM(v.value)) AS UNIQUEIDENTIFIER));
    ELSE
        INSERT @newHashers (HasherId)
        SELECT DISTINCT HasherId FROM HC.DownDownHashers WHERE DownDownId = @downDownId;

    -- Names: the array sent (blanks dropped), or the current value.
    IF (@externalNames IS NOT NULL)
    BEGIN
        IF (ISJSON(@externalNames) = 1)
            SET @newExternalNames = (
                SELECT LTRIM(RTRIM(j.[value])) AS [value]
                FROM OPENJSON(@externalNames) j
                WHERE LEN(LTRIM(RTRIM(j.[value]))) > 0
                FOR JSON PATH);
        -- FOR JSON PATH gives [{"value":"x"}]; store the plain array the app reads.
        IF (@newExternalNames IS NOT NULL)
            SET @newExternalNames = (
                SELECT '[' + STRING_AGG('"' + STRING_ESCAPE(v.value, 'json') + '"', ',') + ']'
                FROM OPENJSON(@newExternalNames) WITH (value NVARCHAR(4000) '$.value') v);
    END
    ELSE
        SELECT @newExternalNames = ExternalNames FROM HC.DownDowns WHERE id = @downDownId;

    IF (NOT EXISTS (SELECT 1 FROM @newHashers)
        AND (@newExternalNames IS NULL OR ISJSON(@newExternalNames) = 0
             OR NOT EXISTS (SELECT 1 FROM OPENJSON(@newExternalNames))))
    BEGIN
        SET @errorCode = 1236; SET @errorType = 2; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Nobody charged',
                'An edit would leave the charge with no hasher and no name', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Nobody charged' AS errorTitle,
               'A charge needs at least one person — a hasher or a name.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE HC.DownDowns
    SET ChargeText     = @chargeText,
        SongChoice     = CASE WHEN LEN(COALESCE(@songChoice, N'')) = 0 THEN NULL ELSE LTRIM(RTRIM(@songChoice)) END,
        SongId         = @songId,
        ChargePhotoUrl = COALESCE(@chargePhotoUrl, ChargePhotoUrl),
        ExternalNames  = CASE WHEN @changePeople = 1 THEN @newExternalNames ELSE ExternalNames END,
        UpdatedAt      = GETUTCDATE()
    WHERE id       = @downDownId
      AND EventId  = @eventId
      AND KennelId = @kennelId;

    IF (@changePeople = 1)
    BEGIN
        DELETE ddh FROM HC.DownDownHashers ddh
        WHERE ddh.DownDownId = @downDownId
          AND NOT EXISTS (SELECT 1 FROM @newHashers n WHERE n.HasherId = ddh.HasherId);

        INSERT HC.DownDownHashers (DownDownId, HasherId)
        SELECT @downDownId, n.HasherId
        FROM @newHashers n
        WHERE NOT EXISTS (SELECT 1 FROM HC.DownDownHashers ddh
                          WHERE ddh.DownDownId = @downDownId AND ddh.HasherId = n.HasherId);
    END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    -- Roll back BEFORE logging, or the rollback erases the log row.
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
