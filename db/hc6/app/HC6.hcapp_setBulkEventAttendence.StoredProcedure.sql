CREATE OR ALTER PROCEDURE [HC6].[hcapp_setBulkEventAttendence]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @eventId                     UNIQUEIDENTIFIER,
    @hasherIds                   NVARCHAR(MAX),
    @attendenceState             SMALLINT,
    @hasherEventMapUpdatedAfter  NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setBulkEventAttendence
-- Description: Sets attendance for multiple hashers at once. @hasherIds
--   is a comma-separated list of UNIQUEIDENTIFIER strings. Existing HEM
--   rows are updated; new ones are inserted with RsvpState = 3. Only
--   attendance states >= 20 (on trail or On Inn) are accepted — bulk
--   un-attend is not supported. Run counts are recalculated for all
--   affected users after the write.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @eventId                     - Event to update
--   @hasherIds                   - Comma-separated UNIQUEIDENTIFIER strings
--   @attendenceState             - Must be 20–40
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, serverMessage }
--   On success (rowset 2+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_setBulkEventAttendence
-- Breaking Changes:
--   @hasherIds widened VARCHAR(8000) → NVARCHAR(MAX).
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   Delegation target updated to HC6.hcapp_syncEventAdminData.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
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
    @spNumber     = 25,
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

-- ---------------------------------------------------------------
-- Parameter validation
-- ---------------------------------------------------------------
IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1225; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId',
            'A null or empty eventId was passed to ' + @procName, @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@attendenceState IS NULL OR @attendenceState < 20 OR @attendenceState > 40)
BEGIN
    SET @errorCode = 1225; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid attendance state',
            'Bulk attendance state must be 20–40', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid attendance state' AS errorTitle,
           'Bulk attendance state must be at least 20 (on trail).' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@hasherIds IS NULL)
BEGIN
    SET @errorCode = 1225; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null hasherIds',
            '@hasherIds is required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing hasher list' AS errorTitle,
           'At least one hasher must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        DECLARE @queryStart DATETIME = DATEADD(SECOND, -1, GETDATE());

        DECLARE @kennelId UNIQUEIDENTIFIER;
        SELECT @kennelId = evt.KennelId FROM HC.Event evt WHERE evt.id = @eventId;

        -- Authorization: feature "Manage attendance" (see /hc-authorizations).
        -- Run-scoped: a hare for THIS event may set attendance for it.
        DECLARE @bulkAttAllowed SMALLINT;
        DECLARE @bulkIsHare SMALLINT = CASE WHEN EXISTS (
                SELECT 1 FROM HC.HasherEventMap
                WHERE UserId = @userId AND EventId = @eventId AND IsHare = 1) THEN 1 ELSE 0 END;
        EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'manageAttendance', @isHareOfEvent = @bulkIsHare, @allowed = @bulkAttAllowed OUTPUT;
        IF (@bulkAttAllowed = 0)
        BEGIN
            SET @errorCode = 1325; SET @errorType = 13; SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, '<unknown>', 'Not authorised for bulk attendance',
                    'Caller does not hold required role for kennel', @procName, @userId);
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
            SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                   'Not authorised' AS errorTitle,
                   'You are not authorised to set bulk attendance for this event.' AS errorUserMessage,
                   @procName AS errorProc;
            RETURN;
        END

        -- Update existing HEM rows
        ;WITH ParsedGuids AS (
            SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
            FROM STRING_SPLIT(@hasherIds, ',')
            WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
        )
        UPDATE hem SET
            hem.AttendenceState = @attendenceState,
            hem.RsvpState       = 3,
            hem.updatedAt       = GETDATE()
        FROM HC.HasherEventMap hem
        INNER JOIN ParsedGuids pg ON pg.UserId = hem.UserId
        WHERE hem.EventId = @eventId;

        DECLARE @updatedRowCount INT = @@ROWCOUNT;

        -- Insert HEM rows for hashers not yet in the event
        ;WITH ParsedGuids AS (
            SELECT TRY_CAST(value AS UNIQUEIDENTIFIER) AS UserId
            FROM STRING_SPLIT(@hasherIds, ',')
            WHERE TRY_CAST(value AS UNIQUEIDENTIFIER) IS NOT NULL
        )
        INSERT INTO HC.HasherEventMap
            ([id], [EventId], [KennelId], [UserId],
             [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
        SELECT
            NEWID(), @eventId, @kennelId, pg.UserId,
            @attendenceState, 3, 0, 0, GETDATE()
        FROM ParsedGuids pg
        LEFT OUTER JOIN HC.HasherEventMap hem ON hem.UserId = pg.UserId AND hem.EventId = @eventId
        WHERE hem.id IS NULL;

        DECLARE @insertedRowCount INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    -- Recalculate run counts for all affected users (outside transaction)
    EXEC HC6.nonApi_updateRunCountsForAllUsers @updatedSince = @queryStart;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        1 AS adHocDataId,
        CAST(@updatedRowCount AS NVARCHAR(10)) + ' records updated, '
        + CAST(@insertedRowCount AS NVARCHAR(10)) + ' records inserted' AS serverMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1925; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- ---------------------------------------------------------------
-- Delegate to syncEventAdminData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');

EXEC HC6.hcapp_syncEventAdminData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @eventId                     = @eventId,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = 'ignore',
    @paymentsUpdatedAfter        = 'ignore',
    @kennelCreditsUpdatedAfter   = 'ignore',
    @receiptsUpdatedAfter        = 'ignore',
    @procName                    = @procName,
    @param                       = NULL;
