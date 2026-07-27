CREATE OR ALTER PROCEDURE [HC6].[hcapp_syncEventAdminData]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @eventId                     UNIQUEIDENTIFIER,
    @hashersUpdatedAfter         NVARCHAR(50)      = 'ignore',
    @hasherEventMapUpdatedAfter  NVARCHAR(50)      = 'ignore',
    @hasherKennelMapUpdatedAfter NVARCHAR(50)      = 'ignore',
    @narrowEventsUpdatedAfter    NVARCHAR(50)      = 'ignore',
    @paymentsUpdatedAfter        NVARCHAR(50)      = 'ignore',
    @receiptsUpdatedAfter        NVARCHAR(50)      = 'ignore',
    @kennelCreditsUpdatedAfter   NVARCHAR(50)      = 'ignore',
    @usePaging                   INT               = 0,
    @procName                    NVARCHAR(128)     = NULL,
    @param                       NVARCHAR(500)     = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_syncEventAdminData
-- Description: Incremental sync of event-scoped admin data. Each entity
--   type is gated by a watermark parameter ('ignore' skips that table).
--   Differs from syncUserData in that HasherEventMap and Payments are
--   scoped to the given event (not the calling user), and HasherKennelMap
--   is scoped to the event's kennel. Used after write SPs that modify
--   event-level data so the admin view is immediately updated.
--
--   Tables returned (when watermark != 'ignore'):
--     Hashers (global), HasherEventMap (event-scoped),
--     HasherKennelMap (kennel-scoped, isMember computed dynamically),
--     Event (single event by @eventId), Payments (event-scoped),
--     Receipts (event-scoped).
--
--   @procName and @param support the write-SP delegation pattern —
--   see syncUserData for full documentation.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token (validated against delegating context or DeviceSecret)
--   @eventId                     - Event to scope the sync to
--   @hashersUpdatedAfter         - Watermark for HC.Hasher (global)
--   @hasherEventMapUpdatedAfter  - Watermark for HC.HasherEventMap (event-scoped)
--   @hasherKennelMapUpdatedAfter - Watermark for HC.HasherKennelMap (kennel-scoped)
--   @narrowEventsUpdatedAfter    - Watermark for the single event row
--   @paymentsUpdatedAfter        - Watermark for HC.Payment (event-scoped)
--   @receiptsUpdatedAfter        - Watermark for HC.Receipt (event-scoped)
--   @kennelCreditsUpdatedAfter   - Reserved (commented out in HC5; kept for caller compat)
--   @usePaging                   - 1 = enforce page limits; 0 = unlimited
--   @procName                    - Delegating SP name (NULL = direct call)
--   @param                       - Delegating SP token suffix (NULL = DeviceSecret only)
-- Returns:
--   Read SP (no success envelope).
--   On error (rowset 0): standard HC6 error detail
--   On success: one rowset per non-ignored watermark, in parameter order
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_syncEventAdminData
-- Breaking Changes:
--   isMember in HasherKennelMap rowset computed dynamically (HC5 already
--     did this in syncEventAdminData — retained as-is).
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @effectiveProcName NVARCHAR(128) = COALESCE(@procName, @procName_self);

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
    @procName     = @effectiveProcName,
    @spNumber     = 71,
    @param        = @param,
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
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @effectiveProcName AS errorProc;
    RETURN;
END

-- Wrap the body so any runtime error is LOGGED to HC.ErrorLog before it reaches
-- the client, then re-raised (THROW) to preserve existing client behaviour.
BEGIN TRY

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1271; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId', 'eventId is required', @effectiveProcName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @effectiveProcName AS errorProc;
    RETURN;
END

-- Admin guard: when called directly (not delegated), verify caller has admin rights for event's kennel.
-- Delegated calls from write SPs skip this check — the write SP already verified auth.
DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = e.KennelId FROM HC.Event e WHERE e.id = @eventId;

IF (@procName IS NULL)
BEGIN
    -- Authorization: event-admin data read (attendees/payments/receipts). Broad —
    -- serves run admin (attendance) AND hash cash; original roles kept, with
    -- HashCash|HashBank added so role-based hash-cash people can load run admin
    -- data, plus ManageRuns|ManageHashCash flags as overrides. (see /hc-authorizations)
    DECLARE @syncEvtAllowed SMALLINT;
    EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'enterRunAdmin', @allowed = @syncEvtAllowed OUTPUT;
    -- Run-scoped: a designated hare of THIS event may load its admin data so
    -- they can run their own run (edit details, receipts, check-in, take payment).
    IF (@syncEvtAllowed = 0 AND EXISTS (
            SELECT 1 FROM HC.HasherEventMap
            WHERE UserId = @userId AND EventId = @eventId AND IsHare = 1))
        SET @syncEvtAllowed = 1;
    IF (@syncEvtAllowed = 0)
    BEGIN
        SET @errorCode = 1371; SET @errorType = 13; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Not authorised for event admin sync',
                'Caller does not hold required role for kennel', @effectiveProcName, @userId);
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Not authorised' AS errorTitle,
               'You are not authorised to sync admin data for this event.' AS errorUserMessage,
               @effectiveProcName AS errorProc;
        RETURN;
    END
END

-- ---------------------------------------------------------------
-- Paging limits
-- ---------------------------------------------------------------
DECLARE @paging2500 INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 2500 END;
DECLARE @paging250  INT = CASE WHEN COALESCE(@usePaging, 0) = 0 THEN 1000000 ELSE 250  END;

-- ---------------------------------------------------------------
-- Normalise watermarks
-- ---------------------------------------------------------------
IF (@hashersUpdatedAfter            IS NULL OR @hashersUpdatedAfter            <= '2000-01-01') SET @hashersUpdatedAfter            = 'ignore';
IF (@hasherEventMapUpdatedAfter     IS NULL OR @hasherEventMapUpdatedAfter     <= '2000-01-01') SET @hasherEventMapUpdatedAfter     = 'ignore';
IF (@hasherKennelMapUpdatedAfter    IS NULL OR @hasherKennelMapUpdatedAfter    <= '2000-01-01') SET @hasherKennelMapUpdatedAfter    = 'ignore';
IF (@narrowEventsUpdatedAfter       IS NULL OR @narrowEventsUpdatedAfter       <= '2000-01-01') SET @narrowEventsUpdatedAfter       = 'ignore';
IF (@paymentsUpdatedAfter           IS NULL OR @paymentsUpdatedAfter           <= '2000-01-01') SET @paymentsUpdatedAfter           = 'ignore';
IF (@receiptsUpdatedAfter           IS NULL OR @receiptsUpdatedAfter           <= '2000-01-01') SET @receiptsUpdatedAfter           = 'ignore';

-- @kennelId already resolved above for the admin guard.

DECLARE @ua DATETIMEOFFSET(7);

-- ---------------------------------------------------------------
-- HASHERS (global — all updated since watermark)
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
-- HASHER–EVENT MAP (event-scoped)
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
        hem.Email                                                           AS email,
        hem.PhoneNumber                                                     AS phoneNumber,
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

-- ---------------------------------------------------------------
-- HASHER–KENNEL MAP (kennel-scoped; isMember computed dynamically)
-- ---------------------------------------------------------------
IF (@hasherKennelMapUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@hasherKennelMapUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        hkm.id                                                              AS hkmId,
        hkm.UserId                                                          AS userId,
        hkm.KennelId                                                        AS kennelId,
        hkm.Following                                                       AS following,
        CASE WHEN COALESCE(hkm.MembershipExpirationDate, '2000-01-01') > GETDATE() THEN 1 ELSE 0 END AS isMember,
        hkm.IsHomeKennel                                                    AS isHomeKennel,
        hkm.IsKennelFollowing                                               AS isKennelFollowing,
        hkm.KennelNotificationPreference                                    AS kennelNotificationPreference,
        hkm.KennelEmailAlertPreference                                      AS kennelEmailAlertPreference,
        hkm.MismanagementRoles                                              AS mismanagementRoles,
        hkm.UserRoleFlags                                                   AS userRoleFlags,
        hkm.AppAccessFlags                                                  AS appAccessFlags,
        hkm.HcTotalRunCount                                                 AS hcTotalRunCount,
        hkm.HcHaringCount                                                   AS hcHaringCount,
        hkm.HistoricalHaringCount                                           AS historicalHaringCount,
        hkm.HistoricalTotalRunCount                                         AS historicalTotalRunCount,
        hkm.HistoricalCountIsEstimate                                       AS historicalCountIsEstimate,
        hkm.KennelCredit                                                    AS kennelCredit,
        hkm.DiscountAmount                                                  AS discountAmount,
        hkm.DiscountPercent                                                 AS discountPercent,
        hkm.DiscountDescription                                             AS discountDescription,
        hkm.MembershipExpirationDate                                        AS membershipExpirationDate,
        ''                                                                  AS authorizedDeviceList,
        0                                                                   AS authorizedDeviceCount,
        hkm.MemberSince                                                     AS memberSince,
        hkm.DateOfLastRun                                                   AS dateOfLastRun,
        hkm.KennelUserPhoto                                                 AS kennelUserPhoto,
        hkm.KennelHashName                                                  AS kennelHashName,
        hkm.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(hkm.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.HasherKennelMap hkm WITH (INDEX(IX_KennelSyncHasherKennelMap))
    WHERE hkm.KennelId = @kennelId AND hkm.updatedAt > @ua
    ORDER BY hkm.updatedAt ASC, hkm.id ASC
    OFFSET 0 ROWS FETCH NEXT @paging250 ROWS ONLY;
END

-- ---------------------------------------------------------------
-- EVENT (single row — the event being synced)
-- ---------------------------------------------------------------
IF (@narrowEventsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@narrowEventsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        evt.id                                                              AS eventId,
        evt.PublicEventId                                                   AS publicEventId,
        evt.KennelId                                                        AS kennelId,
        evt.IsVisible                                                       AS isVisible,
        evt.IsCountedRun                                                    AS isCountedRun,
        evt.EventGeographicScope                                            AS eventGeographicScope,
        evt.InboundIntegrationId                                            AS eventInboundIntegrationId,
        evt.IsPromotedEvent                                                 AS isPromotedEvent,
        evt.EventNumber                                                     AS eventNumber,
        evt.EventPriceForMembers                                            AS eventPriceForMembers,
        evt.EventPriceForNonMembers                                         AS eventPriceForNonMembers,
        evt.EventPriceForExtras                                             AS eventPriceForExtras,
        evt.ExtrasDescription                                               AS extrasDescription,
        evt.DoTrackHashCash                                                 AS doTrackHashCash,
        evt.EventFacebookId                                                 AS eventFacebookId,
        evt.AbsoluteEventNumber                                             AS absoluteEventNumber,
        evt.CanEditRunAttendence                                            AS canEditRunAttendence,
        evt.Hares                                                           AS hares,
        evt.EventPaymentScheme                                              AS eventPaymentScheme,
        evt.EventPaymentUrl                                                 AS eventPaymentUrl,
        evt.EventPaymentUrlExpires                                          AS eventPaymentUrlExpires,
        evt.UnconfirmedBankXferCount                                        AS unconfirmedBankXferCount,
        evt.Tags1                                                           AS tags1,
        evt.Tags2                                                           AS tags2,
        evt.Tags3                                                           AS tags3,
        CASE WHEN evt.UseFbImage      = 1 THEN evt.FbEventImage         ELSE evt.EventImage         END AS eventImage,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName          ELSE evt.EventName          END AS eventName,
        CONVERT(DATETIME2, evt.EventStartDatetime) AS eventStartDatetime,
        COALESCE(evt.EventStartDatetimeGmt, evt.EventStartDatetime)        AS eventStartDatetimeGmt,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventDescription   ELSE evt.EventDescription   END AS eventDescription,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc,
        evt.EventUrl                                                        AS eventUrl,
        CASE WHEN evt.UseFbLatLon = 1 AND evt.FbLatitude IS NOT NULL AND evt.FbLatitude >= -90.0 AND evt.FbLongitude >= -180.0
             THEN evt.FbLatitude  ELSE COALESCE(evt.Latitude,  ken.Latitude)  END AS narrowEventLatitude,
        CASE WHEN evt.UseFbLatLon = 1 AND evt.FbLongitude IS NOT NULL AND evt.FbLatitude >= -90.0 AND evt.FbLongitude >= -180.0
             THEN evt.FbLongitude ELSE COALESCE(evt.Longitude, ken.Longitude) END AS narrowEventLongitude,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationPostCode   ELSE evt.LocationPostCode   END AS locationPostCode,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCity       ELSE evt.LocationCity       END AS locationCity,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationStreet     ELSE evt.LocationStreet     END AS locationStreet,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCountry    ELSE evt.LocationCountry    END AS locationCountry,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationRegion     ELSE evt.LocationRegion     END AS locationRegion,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationSubRegion  ELSE evt.LocationSubRegion  END AS locationSubRegion,
        evt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(evt.updatedAt AS DATETIME2))             AS updatedAt,
        evt.UseFbLocation                                                   AS useFbLocation,
        evt.UseFbLatLon                                                     AS useFbLatLon,
        evt.UseFbRunDetails                                                 AS useFbRunDetails,
        evt.UseFbImage                                                      AS useFbImage,
        evt.Latitude                                                        AS hcLatitude,
        evt.Longitude                                                       AS hcLongitude,
        evt.CountryId                                                       AS countryId,
        COALESCE(evt.w3wLatitude,  evt.FbLatitude)                          AS fbLatitude,
        COALESCE(evt.w3wLongitude, evt.FbLongitude)                         AS fbLongitude
    FROM HC.Event evt WITH (INDEX(PK_Event))
    INNER JOIN HC.Kennel ken ON evt.KennelId = ken.id
    WHERE evt.id = @eventId AND evt.updatedAt > @ua;
END

-- ---------------------------------------------------------------
-- PAYMENTS (event-scoped)
-- ---------------------------------------------------------------
IF (@paymentsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@paymentsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        pmt.id                                                              AS paymentId,
        pmt.KennelId                                                        AS kennelId,
        pmt.UserId                                                          AS paidBy,
        pmt.HasherEventMapId                                                AS hemId,
        pmt.EventId                                                         AS eventId,
        pmt.PaymentProcessedBy_userId                                       AS paidTo,
        pmt.CreditAmount                                                    AS creditAmount,
        pmt.DebitAmount                                                     AS debitAmount,
        pmt.CreditAvailable                                                 AS creditAvailable,
        CAST(pmt.PaidDate AS DATETIME)                                      AS paidDate,
        pmt.PaymentType                                                     AS paymentType,
        pmt.ProductType                                                     AS productType,
        CAST(pmt.CancelledDate AS DATETIME)                                 AS cancelledDate,
        pmt.CancelledBy_UserId                                              AS cancelledBy,
        CAST(pmt.ConfirmedDate AS DATETIME)                                 AS confirmedDate,
        pmt.ConfirmedBy_UserId                                              AS confirmedBy,
        pmt.PaymentReference                                                AS paymentReference,
        pmt.DiscountAmount                                                  AS discountAmount,
        pmt.DiscountPercent                                                 AS discountPercent,
        pmt.DiscountDescription                                             AS discountDescription,
        pmt.SpecialRunPriceReason                                           AS specialRunPriceReason,
        pmt.Notes                                                           AS notes,
        pmt.DoPayForExtras                                                  AS doPayForExtras,
        pmt.Surcharge                                                       AS surcharge,
        pmt.PaymentProvider                                                 AS paymentProvider,
        pmt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(pmt.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.Payment pmt
    WHERE pmt.EventId = @eventId AND pmt.updatedAt > @ua;
END

-- ---------------------------------------------------------------
-- RECEIPTS (event-scoped)
-- ---------------------------------------------------------------
IF (@receiptsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@receiptsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        rec.id                                                              AS receiptId,
        rec.EventId                                                         AS eventId,
        rec.UserId                                                          AS userId,
        rec.ReceiptAmount                                                   AS receiptAmount,
        rec.CostCategory                                                    AS costCategory,
        rec.DateUploaded                                                    AS dateUploaded,
        rec.ImageUrl                                                        AS imageUrl,
        rec.ReceiptShortDesc                                                AS receiptShortDesc,
        rec.Notes                                                           AS notes,
        rec.ReimbursedBy                                                    AS reimbursedBy,
        rec.ReimbursedOn                                                    AS reimbursedOn,
        rec.ReimbursedAmount                                                AS reimbursedAmount,
        rec.ReimbursedNotes                                                 AS reimbursedNotes,
        rec.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(rec.updatedAt AS DATETIME2))             AS updatedAt
    FROM HC.Receipt rec
    WHERE rec.EventId = @eventId AND rec.updatedAt > @ua;
END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in syncEventAdminData',
            ERROR_MESSAGE(), @effectiveProcName, @userId);
    THROW;
END CATCH
