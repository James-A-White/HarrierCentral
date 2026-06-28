CREATE OR ALTER PROCEDURE [HC6].[hcapp_getEventRsvps]

    @deviceId                   UNIQUEIDENTIFIER,
    @accessToken                NVARCHAR(1000),
    @eventId                    UNIQUEIDENTIFIER,
    @hashersUpdatedAfter        NVARCHAR(50) = 'ignore',
    @hasherEventMapUpdatedAfter NVARCHAR(50) = 'ignore',
    @usePaging                  INT          = 0

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getEventRsvps
-- Description: Returns RSVP attendance data for a specific event,
--   accessible by any authenticated app user (no admin role required).
--   Returns the same Hashers and HasherEventMap column shapes as
--   hcapp_syncEventAdminData so the client can reuse the same sync
--   infrastructure, but deliberately omits contact info (email,
--   phoneNumber) and does not return HasherKennelMap, Payments, or
--   Receipts rowsets — those remain admin-only.
-- Parameters:
--   @deviceId                   - Registered device UUID
--   @accessToken                - Token validated against device secret
--   @eventId                    - Event to fetch RSVPs for
--   @hashersUpdatedAfter        - Watermark for HC.Hasher (global)
--   @hasherEventMapUpdatedAfter - Watermark for HC.HasherEventMap (event-scoped)
--   @usePaging                  - 1 = enforce page limits; 0 = unlimited
-- Returns:
--   On error (rowset 0): standard HC6 error detail
--   On success: Hashers rowset (if watermark != 'ignore'),
--               HasherEventMap rowset (if watermark != 'ignore')
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
    @spNumber     = 75,
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
    SET @errorCode = 1272; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId', 'eventId is required', @procName_self, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Paging limits
-- ---------------------------------------------------------------
DECLARE @paging2500 INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 2500 END;
DECLARE @paging250  INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 250  END;

-- ---------------------------------------------------------------
-- Normalise watermarks
-- ---------------------------------------------------------------
IF (@hashersUpdatedAfter        IS NULL OR @hashersUpdatedAfter        <= '2000-01-01') SET @hashersUpdatedAfter        = 'ignore';
IF (@hasherEventMapUpdatedAfter IS NULL OR @hasherEventMapUpdatedAfter <= '2000-01-01') SET @hasherEventMapUpdatedAfter = 'ignore';

DECLARE @ua DATETIMEOFFSET(7);

-- ---------------------------------------------------------------
-- HASHERS (global — same shape as syncEventAdminData)
-- ---------------------------------------------------------------
IF (@hashersUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hashersUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        h.id                                                                AS hasherId,
        COALESCE(h.FirstName, '')                                           AS firstName,
        COALESCE(h.LastName, '')                                            AS lastName,
        COALESCE(h.DisplayName, '')                                         AS dispName,
        COALESCE(h.HashName, '')                                            AS hashName,
        COALESCE(h.Photo, '')                                               AS photo,
        COALESCE(h.NameDisplayPreference, 0)                                AS dispPref,
        COALESCE(h.IncludeInGlobalHashDirectory, 0)                         AS includeInGlobalHashDirectory,
        CONVERT(NVARCHAR(50), CAST(COALESCE(h.updatedAt, GETDATE()) AS DATETIME2)) AS updatedAt,
        COALESCE(h.Removed, 0)                                              AS removed
    FROM HC.Hasher h WITH (INDEX(IX_AllSyncHashers))
    WHERE h.updatedAt > @ua
    ORDER BY h.updatedAt ASC, h.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging2500 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- HASHER–EVENT MAP (event-scoped; contact info omitted)
-- Same column shape as syncEventAdminData — email and phoneNumber
-- are returned as NULL so non-admins cannot access contact details.
-- ---------------------------------------------------------------
IF (@hasherEventMapUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hasherEventMapUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        hem.id                                                              AS hemId,
        hem.UserId                                                          AS userId,
        hem.EventId                                                         AS eventId,
        hem.HasherOwnEventId                                                AS hasherOwnEventId,
        hem.UserStartEvent                                                  AS userStartEvent,
        hem.UserEndEvent                                                    AS userEndEvent,
        hem.RsvpState                                                       AS rsvpState,
        hem.AttendenceState                                                 AS attendenceState,
        hem.IsHare                                                          AS isHare,
        hem.EventNotificationPreference                                     AS eventNotificationPreference,
        hem.EventEmailAlertPreference                                       AS eventEmailAlertPreference,
        hem.EventCountOverride                                              AS eventCountOverride,
        hem.VirginVisitorType                                               AS virginVisitorType,
        hem.TotalHaring                                                     AS totalHaring,
        hem.TotalHaringThisKennel                                           AS totalHaringThisKennel,
        hem.TotalRuns                                                       AS totalRuns,
        hem.TotalRunsThisKennel                                             AS totalRunsThisKennel,
        hem.DisplayName                                                     AS displayName,
        NULL                                                                AS email,
        NULL                                                                AS phoneNumber,
        evt.EventNumber                                                     AS hemEventNumber,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName  ELSE evt.EventName  END AS hemEventName,
        CONVERT(DATETIME2, evt.EventStartDatetime) AS hemEventStartDatetime,
        COALESCE(evt.EventStartDatetimeGmt, evt.EventStartDatetime)        AS hemEventStartDatetimeGmt,
        evt.CanEditRunAttendence                                            AS hemCanEditRunAttendence,
        CASE WHEN evt.IsCountedRun != 0 AND evt.IsVisible != 0 THEN 1 ELSE 0 END AS hemEventIsCountedAndVisible,
        evt.KennelId                                                        AS hemEventKennelId,
        hkm.KennelUserPhoto                                                 AS hemKennelUserPhoto,
        hkm.KennelHashName                                                  AS hemKennelHashName,
        hem.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(hem.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.HasherEventMap hem WITH (INDEX(IX_EventSyncHasherEventMap))
    INNER JOIN HC.Event evt ON evt.id = hem.EventId
    LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = hem.UserId AND hkm.KennelId = hem.KennelId
    WHERE hem.EventId = @eventId AND hem.updatedAt > @ua
    ORDER BY hem.updatedAt ASC, hem.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END
