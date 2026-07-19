CREATE OR ALTER PROCEDURE [HC6].[hcapp_copyEventRsvps]

    @deviceId                   UNIQUEIDENTIFIER,
    @accessToken                NVARCHAR(1000),
    @fromEvent                  UNIQUEIDENTIFIER,
    @toEvent                    UNIQUEIDENTIFIER,
    @hasherEventMapUpdatedAfter NVARCHAR(50)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_copyEventRsvps
-- Description: Copies all HasherEventMap RSVP rows from one event to
--   another, skipping any hasher who already has an HEM row for the
--   target event. Only RSVP state (RsvpState, IsHare,
--   VirginVisitorType) is copied — attendance state is not transferred.
--   Used by admins to pre-populate RSVPs for a rescheduled event.
-- Parameters:
--   @deviceId                   - Registered device UUID
--   @accessToken                - Token validated against DeviceSecret
--   @fromEvent                  - Source event UUID
--   @toEvent                    - Target event UUID
--   @hasherEventMapUpdatedAfter - Sync watermark for HasherEventMap
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, serverMessage }
--   On success (rowset 2+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_copyEventRsvps
-- Breaking Changes:
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
    @spNumber     = 21,
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
IF (@fromEvent IS NULL OR @fromEvent = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1221; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty fromEvent',
            'A null or empty fromEvent was passed to ' + @procName, @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing source event' AS errorTitle,
           'A source event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@toEvent IS NULL OR @toEvent = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1221; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty toEvent',
            'A null or empty toEvent was passed to ' + @procName, @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing target event' AS errorTitle,
           'A target event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        -- Admin guard (H13): verify both events belong to the same kennel and
        -- caller has event-admin rights for that kennel.
        DECLARE @fromKennelId UNIQUEIDENTIFIER;
        DECLARE @toKennelId   UNIQUEIDENTIFIER;
        SELECT @fromKennelId = KennelId FROM HC.Event WHERE id = @fromEvent;
        SELECT @toKennelId   = KennelId FROM HC.Event WHERE id = @toEvent;

        IF @fromKennelId IS NULL OR @toKennelId IS NULL OR @fromKennelId != @toKennelId
        BEGIN
            SET @errorCode = 1221; SET @errorType = 12; SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, '<unknown>', 'Cross-kennel RSVP copy attempted',
                    'Source and target events must belong to the same kennel', @procName, @userId);
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
            SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                   'Invalid events' AS errorTitle,
                   'Both events must belong to the same kennel.' AS errorUserMessage, @procName AS errorProc;
            RETURN;
        END

        -- Authorization: feature "Copy RSVPs" (see /hc-authorizations).
        DECLARE @copyAllowed SMALLINT;
        EXEC HC6.CheckKennelPermission @userId, @fromKennelId, 0x00080146, 0x00000004, @copyAllowed OUTPUT;
        IF (@copyAllowed = 0)
        BEGIN
            SET @errorCode = 1321; SET @errorType = 13; SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, '<unknown>', 'Not authorised to copy RSVPs',
                    'Caller does not hold required role for kennel', @procName, @userId);
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
            SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                   'Not authorised' AS errorTitle,
                   'You are not authorised to copy RSVPs for this event.' AS errorUserMessage,
                   @procName AS errorProc;
            RETURN;
        END

        INSERT INTO HC.HasherEventMap
            ([id], [EventId], [KennelId], [UserId],
             [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
        SELECT
            NEWID(),
            @toEvent,
            hemFrom.KennelId,
            hemFrom.UserId,
            hemFrom.RsvpState,
            hemFrom.IsHare,
            hemFrom.VirginVisitorType,
            GETDATE()
        FROM HC.HasherEventMap hemFrom
        LEFT OUTER JOIN HC.HasherEventMap hemTo
            ON hemTo.EventId = @toEvent AND hemTo.UserId = hemFrom.UserId
        WHERE hemFrom.EventId = @fromEvent
          AND hemFrom.removed = 0
          AND hemTo.id IS NULL;

        DECLARE @copiedCount INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        1                                                                    AS adHocDataId,
        'Copied ' + CAST(@copiedCount AS NVARCHAR(10)) + ' RSVPs'           AS serverMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1921; SET @errorType = 19; SET @errorId = NEWID();
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
SET @hasherEventMapUpdatedAfter = COALESCE(@hasherEventMapUpdatedAfter, 'ignore');

EXEC HC6.hcapp_syncEventAdminData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @eventId                     = @toEvent,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @hasherKennelMapUpdatedAfter = 'ignore',
    @narrowEventsUpdatedAfter    = 'ignore',
    @paymentsUpdatedAfter        = 'ignore',
    @kennelCreditsUpdatedAfter   = 'ignore',
    @receiptsUpdatedAfter        = 'ignore',
    @procName                    = @procName,
    @param                       = NULL;
