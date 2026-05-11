CREATE OR ALTER PROCEDURE [HC6].[hcapp_setEventRsvp]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @eventId                     UNIQUEIDENTIFIER,
    @hasherId                    UNIQUEIDENTIFIER,
    @isHare                      INT              = -1,
    @rsvpState                   INT              = -1,
    @hasherEventMapUpdatedAfter  NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50),
    @hemId                       UNIQUEIDENTIFIER = NULL,
    @autoSetNotifications        SMALLINT         = 1

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setEventRsvp
-- Description: Updates a hasher's RSVP and/or hare state for an event.
--   Upserts a HasherEventMap row if none exists. Guards against changing
--   RSVP state when the hasher is already marked as attended (only an
--   isHare change is permitted post-attendance). Optionally auto-sets
--   notification preferences when RSVP changes. Updates Event.Hares
--   aggregate when IsHare changes.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @eventId                     - Event UUID
--   @hasherId                    - Target hasher (defaults to caller if NULL)
--   @isHare                      - 1 = is hare; -1 / NULL = keep existing
--   @rsvpState                   - New RSVP state; -1 / NULL = keep existing
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
--   @hemId                       - If provided, lookup is by HEM id
--   @autoSetNotifications        - 1 = set notification prefs based on RSVP change
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, serverMessage, hasherEventMapId, hasherId,
--                             rsvpState, willHareState, hares,
--                             eventNotificationPreference, emailAlertPreference }
--   On success (rowset 2+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_setEventRsvp
-- Breaking Changes:
--   HC5 bug fixed: condition for isHare-change-while-attended used
--     @rsvpState = -1 after sentinel had already been converted to NULL,
--     making the condition always false. Now uses @rsvpState IS NULL.
--   TRY/CATCH and transaction added (HC5 had neither).
--   nonApi_updateRunCountsByUser called after transaction commit.
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
    @spNumber     = 26,
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
-- Validate @hemId / @eventId consistency if hemId provided
-- ---------------------------------------------------------------
IF (@hemId IS NOT NULL)
BEGIN
    DECLARE @hemEventId UNIQUEIDENTIFIER;
    SELECT @hasherId = hem.UserId, @hemEventId = hem.EventId
    FROM HC.HasherEventMap hem WHERE hem.id = @hemId;

    IF (@eventId != @hemEventId)
    BEGIN
        SET @errorCode = 1226; SET @errorType = 12; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Mismatched eventIds',
                'HEM eventId and @eventId do not match', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Mismatched event IDs' AS errorTitle,
               'The event IDs are inconsistent. Please try again.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

-- ---------------------------------------------------------------
-- Normalise sentinels and defaults
-- ---------------------------------------------------------------
IF (@hasherId IS NULL) SET @hasherId = @userId;

-- rsvpState = 1 (not coming) forces isHare = 0
IF (@rsvpState = 1) SET @isHare = 0;

IF (@isHare    = -1) SET @isHare    = NULL;
IF (@rsvpState = -1) SET @rsvpState = NULL;

-- ---------------------------------------------------------------
-- Load event and current HEM state
-- ---------------------------------------------------------------
DECLARE @kennelId            UNIQUEIDENTIFIER;
DECLARE @eventDate           DATETIMEOFFSET(7);
DECLARE @currentAttendenceState SMALLINT;
DECLARE @currentRsvpState    SMALLINT;
DECLARE @currentIsHareState  SMALLINT;
DECLARE @virginVisitorState  SMALLINT = 0;
DECLARE @hasherName          NVARCHAR(120);

SELECT @kennelId = evt.KennelId, @eventDate = evt.EventStartDatetime
FROM HC.Event evt WHERE evt.id = @eventId;

IF (@hemId IS NULL)
BEGIN
    SELECT
        @hemId                  = hem.id,
        @currentAttendenceState = hem.AttendenceState,
        @currentRsvpState       = hem.RsvpState,
        @currentIsHareState     = hem.IsHare,
        @virginVisitorState     = hem.VirginVisitorType
    FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @hasherId;
END
ELSE
BEGIN
    SELECT
        @currentAttendenceState = hem.AttendenceState,
        @currentRsvpState       = hem.RsvpState,
        @currentIsHareState     = hem.IsHare,
        @virginVisitorState     = hem.VirginVisitorType
    FROM HC.HasherEventMap hem WHERE hem.id = @hemId;
END

IF (@virginVisitorState = 0 OR @hemId IS NULL)
    SELECT @hasherName = COALESCE(h.DisplayName, 'Hasher') FROM HC.Hasher h WHERE h.id = @hasherId;
ELSE
    SELECT @hasherName = COALESCE(hem.DisplayName, 'Hasher') FROM HC.HasherEventMap hem WHERE hem.id = @hemId;

-- ---------------------------------------------------------------
-- Determine notification preferences for auto-set
-- ---------------------------------------------------------------
DECLARE @kennelNotificationPreference INT = NULL;
DECLARE @emailAlertPreference         INT = NULL;

IF (@autoSetNotifications = 1)
BEGIN
    IF (@rsvpState = 1)
    BEGIN
        SET @kennelNotificationPreference = 2;
        SET @emailAlertPreference = 2;
    END
    ELSE
    BEGIN
        SELECT
            @kennelNotificationPreference = hkm.KennelNotificationPreference,
            @emailAlertPreference         = hkm.KennelEmailAlertPreference
        FROM HC.HasherKennelMap hkm
        WHERE hkm.KennelId = @kennelId AND hkm.UserId = @userId;
    END
END

-- ---------------------------------------------------------------
-- Write (transacted)
-- ---------------------------------------------------------------
DECLARE @serverMessage NVARCHAR(500) = '';
DECLARE @haresStr      NVARCHAR(2500);

BEGIN TRY
    BEGIN TRANSACTION;

        IF (@hemId IS NOT NULL
            AND (
                -- RSVP or hare changed while not yet attended
                (
                    (@currentRsvpState != COALESCE(@rsvpState, @currentRsvpState)
                     OR @currentIsHareState != COALESCE(@isHare, @currentIsHareState))
                    AND @currentAttendenceState < 20
                )
                OR
                -- Already attended but only hare flag changing (fix: IS NULL instead of = -1)
                (
                    @currentIsHareState != COALESCE(@isHare, @currentIsHareState)
                    AND @currentAttendenceState >= 20
                    AND (@rsvpState IS NULL OR @rsvpState = @currentRsvpState)
                )
            ))
        BEGIN
            UPDATE HC.HasherEventMap SET
                RsvpState                    = COALESCE(@rsvpState, RsvpState),
                IsHare                       = COALESCE(@isHare,    IsHare),
                EventNotificationPreference  = COALESCE(@kennelNotificationPreference, EventNotificationPreference),
                EventEmailAlertPreference    = COALESCE(@emailAlertPreference,         EventEmailAlertPreference),
                updatedAt                    = GETDATE()
            WHERE id = @hemId;
        END
        ELSE IF (@hemId IS NULL)
        BEGIN
            SET @hemId = NEWID();

            INSERT INTO HC.HasherEventMap
                ([id], [EventId], [KennelId], [UserId],
                 [RsvpState], [IsHare], [VirginVisitorType],
                 [EventNotificationPreference], [updatedAt])
            VALUES
                (@hemId, @eventId, @kennelId, @hasherId,
                 @rsvpState,
                 CASE WHEN @isHare > 0 THEN 1 ELSE 0 END,
                 0,
                 @kennelNotificationPreference,
                 GETDATE());
        END
        ELSE IF (@currentAttendenceState >= 20)
        BEGIN
            SET @serverMessage = COALESCE(@hasherName, 'User')
                + ' is already checked in at the Hash. The RSVP can no longer be changed.'
                + '~~To change the RSVP, you must first mark '
                + COALESCE(@hasherName, 'User') + ' as being not at the Hash.';
        END
        ELSE
        BEGIN
            SET @serverMessage = 'The RSVP status has not changed for ' + COALESCE(@hasherName, 'User');
        END

        -- Update Event.Hares aggregate if isHare state changed
        DECLARE @newHareState SMALLINT;
        SELECT @newHareState = hem.IsHare
        FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @hasherId;

        IF (@currentIsHareState != COALESCE(@newHareState, @currentIsHareState))
        BEGIN
            SELECT @haresStr = STRING_AGG(h.DisplayName, ', ') WITHIN GROUP (ORDER BY h.DisplayName ASC)
            FROM HC.HasherEventMap hem
            INNER JOIN HC.Hasher h ON hem.UserId = h.id
            WHERE hem.EventId = @eventId AND hem.IsHare = 1 AND hem.RsvpState = 3;

            UPDATE HC.Event SET Hares = @haresStr, updatedAt = GETDATE()
            WHERE id = @eventId AND COALESCE(Hares, 'x') != COALESCE(@haresStr, 'x');
        END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1926; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- Post-write run count update (outside transaction)
EXEC HC.nonApi_updateRunCountsByUser @userId = @hasherId, @eventDateTime = @eventDate;

-- Re-read final state for response
DECLARE @eventNotificationPreference INT;

SELECT
    @rsvpState                   = hem.RsvpState,
    @isHare                      = hem.IsHare,
    @eventNotificationPreference = hem.EventNotificationPreference,
    @emailAlertPreference        = hem.EventEmailAlertPreference
FROM HC.HasherEventMap hem WHERE hem.UserId = @hasherId AND hem.EventId = @eventId;

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

SELECT
    1                            AS adHocDataId,
    COALESCE(@serverMessage, '') AS serverMessage,
    @hemId                       AS hasherEventMapId,
    @hasherId                    AS hasherId,
    @rsvpState                   AS rsvpState,
    @isHare                      AS willHareState,
    @haresStr                    AS hares,
    @eventNotificationPreference AS eventNotificationPreference,
    @emailAlertPreference        AS emailAlertPreference;

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
