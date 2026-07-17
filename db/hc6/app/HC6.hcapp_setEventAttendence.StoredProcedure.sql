CREATE OR ALTER PROCEDURE [HC6].[hcapp_setEventAttendence]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @eventId                     UNIQUEIDENTIFIER,
    @hasherId                    UNIQUEIDENTIFIER,
    @attendenceState             SMALLINT,
    @isHare                      SMALLINT         = NULL,
    @hasherEventMapUpdatedAfter  NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50),
    @returnUserRecords           SMALLINT         = 0,
    @qrScanText                  NVARCHAR(250),
    @hemId                       UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setEventAttendence
-- Description: Records or updates a hasher's attendance at an event.
--   Supports two lookup modes: direct by @hasherId, or QR code scan
--   via @qrScanText (resolves to hasherId via HC.Hasher.QR_code).
--   If @hemId is supplied, the hasher is resolved from the HEM row
--   (used for visitor/virgin rows that share the KennelId as UserId).
--   Guards against removing attendance when a payment exists.
--   Updates the Event.Hares aggregate when @isHare changes.
--   Returns a richer response in scan mode (payment/member status).
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @eventId                     - Event to update (may be PublicEventId)
--   @hasherId                    - Target hasher (NULL = caller; resolved from QR if scan)
--   @attendenceState             - New attendance state (0–40)
--   @isHare                      - 1 = is hare; -1 / NULL = keep existing
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
--   @returnUserRecords           - 1 = delegate to syncUserData; 0 = syncEventAdminData
--   @qrScanText                  - QR code from hasher's app (mutually exclusive with @hasherId)
--   @hemId                       - If provided, lookup is by HEM id (visitor/virgin support)
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, ... } — two column sets based on scan mode
--   On success (rowset 2+): sync SP rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_setEventAttendence
-- Breaking Changes:
--   @qrScanText widened NVARCHAR(50) → NVARCHAR(250) to match QR_code column.
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   nonApi_updateRunCountsByUser called after transaction commit.
--   Delegation targets updated to HC6 SPs.
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
    @spNumber     = 24,
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
-- Normalise sentinels
-- ---------------------------------------------------------------
IF (@isHare = -1) SET @isHare = NULL;

-- ---------------------------------------------------------------
-- If @hemId provided, validate it matches @eventId and resolve @hasherId
-- ---------------------------------------------------------------
IF (@hemId IS NOT NULL)
BEGIN
    DECLARE @hemEventId UNIQUEIDENTIFIER;

    SELECT @hasherId = hem.UserId, @hemEventId = hem.EventId
    FROM HC.HasherEventMap hem WHERE hem.id = @hemId;

    IF (@eventId != @hemEventId)
    BEGIN
        SET @errorCode = 1224; SET @errorType = 12; SET @errorId = NEWID();
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
-- Validate @attendenceState
-- ---------------------------------------------------------------
IF (@attendenceState IS NULL OR @attendenceState < 0 OR @attendenceState > 40)
BEGIN
    SET @errorCode = 1224; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid attendance state',
            'attendenceState must be 0–40', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid attendance state' AS errorTitle,
           'An invalid attendance state was provided.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Resolve @eventId from PublicEventId (if QR scan mode)
-- ---------------------------------------------------------------
IF (@qrScanText IS NOT NULL)
BEGIN
    SELECT @eventId = COALESCE(evt.id, @eventId)
    FROM HC.Event evt WHERE evt.PublicEventId = @eventId;
END

-- ---------------------------------------------------------------
-- Resolve @hasherId from caller or QR scan
-- ---------------------------------------------------------------
IF (@hasherId IS NULL AND @qrScanText IS NULL)
BEGIN
    SET @hasherId = @userId;
END
ELSE IF (@qrScanText IS NOT NULL)
BEGIN
    SELECT @hasherId = h.id FROM HC.Hasher h WHERE h.QR_code = @qrScanText;
END

IF (@hasherId IS NULL)
BEGIN
    SET @errorCode = 1324; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unknown user',
            'Could not resolve hasher from QR or hasherId', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unknown user' AS errorTitle,
           'This QR code was not recognised.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Load current HEM state
-- ---------------------------------------------------------------
DECLARE @currentAttendenceState SMALLINT;
DECLARE @currentHareStatus      SMALLINT = 0;
DECLARE @virginVisitorState     SMALLINT = 0;
DECLARE @hasherName             NVARCHAR(120);

IF (@hemId IS NULL)
BEGIN
    SELECT
        @hemId                  = hem.id,
        @currentAttendenceState = hem.AttendenceState,
        @currentHareStatus      = hem.IsHare,
        @virginVisitorState     = hem.VirginVisitorType
    FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId AND hem.UserId = @hasherId;
END
ELSE
BEGIN
    SELECT
        @currentAttendenceState = hem.AttendenceState,
        @currentHareStatus      = hem.IsHare,
        @virginVisitorState     = hem.VirginVisitorType
    FROM HC.HasherEventMap hem WHERE hem.id = @hemId;
END

IF (@virginVisitorState = 0 OR @hemId IS NULL)
    SELECT @hasherName = COALESCE(h.DisplayName, 'Hasher') FROM HC.Hasher h WHERE h.id = @hasherId;
ELSE
    SELECT @hasherName = COALESCE(hem.DisplayName, 'Hasher') FROM HC.HasherEventMap hem WHERE hem.id = @hemId;

-- ---------------------------------------------------------------
-- Guard: cannot un-attend if payment registered
-- ---------------------------------------------------------------
DECLARE @payCount INT = 0;
SELECT @payCount = COUNT(*) FROM HC.Payment pay
WHERE pay.HasherEventMapId = @hemId AND pay.CancelledBy_UserId IS NULL;

IF (@currentAttendenceState >= 20 AND @attendenceState < 20 AND @payCount > 0)
BEGIN
    SELECT 0 AS success, 1524 AS errorCode, 5 AS errorType;
    SELECT NEWID() AS errorId, 5 AS errorType, 1524 AS errorCode,
           'Payment registered' AS errorTitle,
           'You tried to mark ' + @hasherName + ' as not at the Hash, but a payment has been '
           + 'registered. Please cancel the payment first.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Admin guard (H13): when setting attendance for a different user,
-- caller must hold attendance-management or admin rights for this event's kennel.
-- Self-attendance never requires an extra check.
-- ---------------------------------------------------------------
IF (@hasherId != @userId)
BEGIN
    DECLARE @setAttKennelId UNIQUEIDENTIFIER;
    SELECT @setAttKennelId = KennelId FROM HC.Event WHERE id = @eventId;

    DECLARE @setAttMmRoles    INT = 0;
    DECLARE @setAttAccessFlags INT = 0;
    SELECT
        @setAttMmRoles     = ISNULL(hkm.MismanagementRoles, 0),
        @setAttAccessFlags = ISNULL(hkm.AppAccessFlags, 0)
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @userId AND hkm.KennelId = @setAttKennelId;

    IF (@setAttMmRoles & 0x2E) = 0 AND (@setAttAccessFlags & 0x40000081) = 0
    BEGIN
        SET @errorCode = 1324; SET @errorType = 13; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Not authorised to set attendance for other user',
                'Caller does not hold required role for kennel', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Not authorised' AS errorTitle,
               'You are not authorised to set attendance for other members.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

-- ---------------------------------------------------------------
-- Load event info
-- ---------------------------------------------------------------
DECLARE @kennelId  UNIQUEIDENTIFIER;
DECLARE @eventName NVARCHAR(250);

SELECT
    @kennelId  = evt.KennelId,
    @eventName = CASE WHEN evt.UseFbRunDetails = 0 THEN evt.EventName ELSE evt.FbEventName END
FROM HC.Event evt WHERE evt.id = @eventId;

-- ---------------------------------------------------------------
-- Write HEM (transacted)
-- ---------------------------------------------------------------
DECLARE @recalculateRunNumbers SMALLINT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

        IF (@hemId IS NOT NULL AND @attendenceState < 20)
        BEGIN
            UPDATE HC.HasherEventMap SET
                AttendenceState = @attendenceState,
                updatedAt       = GETDATE()
            WHERE id = @hemId;

            IF (@currentAttendenceState >= 20) SET @recalculateRunNumbers = 1;
        END
        ELSE IF (@hemId IS NOT NULL AND @attendenceState >= 20)
        BEGIN
            UPDATE HC.HasherEventMap SET
                AttendenceState = @attendenceState,
                RsvpState       = 3,
                IsHare          = COALESCE(@isHare, IsHare),
                updatedAt       = GETDATE()
            WHERE id = @hemId;

            IF (@currentAttendenceState < 20) SET @recalculateRunNumbers = 1;
        END
        ELSE IF (@hemId IS NULL)
        BEGIN
            SET @hemId = NEWID();

            INSERT INTO HC.HasherEventMap
                ([id], [EventId], [KennelId], [UserId],
                 [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
            VALUES
                (@hemId, @eventId, @kennelId, @hasherId,
                 @attendenceState, 3, 0, 0, GETDATE());

            SET @recalculateRunNumbers = 1;
        END

        -- Update Event.Hares aggregate if isHare flag changed
        IF (@isHare IS NOT NULL)
        BEGIN
            DECLARE @haresStr NVARCHAR(2500);
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

    SET @errorCode = 1924; SET @errorType = 19; SET @errorId = NEWID();
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
-- Post-write: update run counts, re-read final state
-- ---------------------------------------------------------------
IF (@recalculateRunNumbers = 1)
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @hasherId;

SELECT @attendenceState = hem.AttendenceState
FROM HC.HasherEventMap hem WHERE hem.UserId = @hasherId AND hem.EventId = @eventId;

-- Final per-event run/haring counts to return. The recompute now counts a
-- check-in whose run starts within 6 hours (or has started), so this reflects
-- today's run in real time rather than waiting for the overnight batch.
DECLARE @totalRunsThisKennel   INT;
DECLARE @totalHaringThisKennel INT;
SELECT @totalRunsThisKennel   = hem.TotalRunsThisKennel,
       @totalHaringThisKennel = hem.TotalHaringThisKennel
FROM HC.HasherEventMap hem WHERE hem.id = @hemId;

DECLARE @isMember    SMALLINT;
DECLARE @eventPrice  SMALLMONEY;

SELECT
    @isMember   = CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE() THEN 1 ELSE 0 END,
    @eventPrice = CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE()
                    THEN COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers,    0)
                    ELSE COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
                  END
FROM HC.Event e
INNER JOIN HC.Kennel k ON k.id = e.KennelId
LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = e.KennelId AND hkm.UserId = @hasherId
WHERE e.id = @eventId;

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

-- ---------------------------------------------------------------
-- Return ad hoc result — two formats based on scan vs. manual
-- ---------------------------------------------------------------
DECLARE @alreadyText NVARCHAR(20) = CASE WHEN @attendenceState >= 20 AND @attendenceState <= @currentAttendenceState THEN 'already ' ELSE '' END;
DECLARE @hasherNameText NVARCHAR(120) = CASE WHEN @hasherId = @userId THEN 'You are ' ELSE @hasherName + ' is ' END;

DECLARE @serverMessage NVARCHAR(500) =
    @hasherNameText + COALESCE(@alreadyText, '') + 'recorded as ' +
    CASE
        WHEN @attendenceState >= 20 AND @attendenceState < 30 THEN 'on the Hash trail at "' + COALESCE(@eventName, 'the Hash') + '"'
        WHEN @attendenceState >= 30 THEN 'On Inn'
        ELSE 'not at the run'
    END;

IF (@attendenceState >= 20 AND COALESCE(@eventPrice, 0) != 0)
BEGIN
    IF (@payCount = 0)
        SET @serverMessage = @serverMessage + '. Don''t forget to pay for the Hash';
    ELSE IF (@attendenceState = 20)
        SET @serverMessage = @serverMessage + ' and paid. Enjoy your run!';
    ELSE IF (@attendenceState = 30)
        SET @serverMessage = @serverMessage + ' and paid. Enjoy your beer!';
END

IF (@qrScanText IS NULL)
BEGIN
    SELECT
        1                      AS adHocDataId,
        @serverMessage         AS serverMessage,
        @hemId                 AS hasherEventMapId,
        @hasherId              AS hasherId,
        @attendenceState       AS attendenceState,
        @totalRunsThisKennel   AS totalRunsThisKennel,
        @totalHaringThisKennel AS totalHaringThisKennel;
END
ELSE
BEGIN
    SELECT
        1                                                               AS adHocDataId,
        @serverMessage                                                  AS userMessage,
        COALESCE(@payCount, 0)                                          AS isPaid,
        @isMember                                                       AS isMember,
        @hemId                                                          AS hasherEventMapId,
        @hasherId                                                       AS hasherId,
        COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference) AS notificationPreference,
        COALESCE(hem.EventEmailAlertPreference,   hkm.KennelEmailAlertPreference)   AS emailAlertPreference,
        COALESCE(hkm.CurrentHaringCount, -1)                            AS currentHaringCount,
        COALESCE(hkm.CurrentPackRunCount, -1)                           AS currentPackRunCount,
        @totalRunsThisKennel                                            AS totalRunsThisKennel,
        @totalHaringThisKennel                                          AS totalHaringThisKennel,
        COALESCE(hem.RsvpState, -1)                                     AS rsvpState,
        COALESCE(hem.IsHare, 0)                                         AS willHareState,
        COALESCE(evt.Hares, '')                                         AS hares,
        COALESCE(hkm.DiscountAmount, 0)                                 AS discountAmount,
        COALESCE(hkm.DiscountPercent, 0)                                AS discountPercent,
        COALESCE(hkm.DiscountDescription, '')                           AS discountDescription
    FROM HC.HasherEventMap hem
    INNER JOIN HC.Event evt ON hem.EventId = evt.id
    LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = @kennelId AND hkm.UserId = hem.UserId
    WHERE hem.id = @hemId;
END

-- ---------------------------------------------------------------
-- Delegate to sync SP (outside TRY — runs after all writes)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');

IF (@returnUserRecords = 0)
BEGIN
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
END
ELSE
BEGIN
    EXEC HC6.hcapp_syncUserData
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @hashersUpdatedAfter         = 'ignore',
        @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
        @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
        @narrowEventsUpdatedAfter    = 'ignore',
        @usePaging                   = 0,
        @procName                    = @procName,
        @param                       = NULL;
END
