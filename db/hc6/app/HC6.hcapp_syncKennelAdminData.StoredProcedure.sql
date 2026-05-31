CREATE OR ALTER PROCEDURE [HC6].[hcapp_syncKennelAdminData]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @kennelId                    UNIQUEIDENTIFIER,
    @hashersUpdatedAfter         NVARCHAR(50)      = 'ignore',
    @kennelsUpdatedAfter         NVARCHAR(50)      = 'ignore',
    @hasherKennelMapUpdatedAfter NVARCHAR(50)      = 'ignore',
    @hasherEventMapUpdatedAfter  NVARCHAR(50)      = 'ignore',
    @paymentsUpdatedAfter        NVARCHAR(50)      = 'ignore',
    @targetHasherId              UNIQUEIDENTIFIER  = NULL,
    @usePaging                   INT               = 0,
    @procName                    NVARCHAR(128)     = NULL,
    @param                       NVARCHAR(500)     = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_syncKennelAdminData
-- Description: Incremental sync of kennel-level admin data. Each entity
--   type is gated by a watermark parameter ('ignore' skips that table).
--   HasherKennelMap and Payments are scoped to the given kennel. Used
--   after write SPs that modify kennel-level membership so the admin
--   view is immediately updated.
--
--   Tables returned (when watermark != 'ignore'):
--     Kennels (global watermark), HasherKennelMap (kennel-scoped),
--     Hashers (global), Payments (scoped to @targetHasherId if provided),
--     HasherEventMap (scoped to @targetHasherId if provided).
--
--   @procName and @param support the write-SP delegation pattern —
--   see syncUserData for full documentation.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token (validated against delegating context or DeviceSecret)
--   @kennelId                    - Kennel to scope the sync to
--   @hashersUpdatedAfter         - Watermark for HC.Hasher (global)
--   @kennelsUpdatedAfter         - Watermark for HC.Kennel (global)
--   @hasherKennelMapUpdatedAfter - Watermark for HC.HasherKennelMap (kennel-scoped)
--   @hasherEventMapUpdatedAfter  - Watermark for HC.HasherEventMap (targetHasher-scoped)
--   @paymentsUpdatedAfter        - Watermark for HC.Payment (targetHasher-scoped)
--   @targetHasherId              - Optional: scope HEM and Payment to this hasher
--   @usePaging                   - 1 = enforce page limits; 0 = unlimited
--   @procName                    - Delegating SP name (NULL = direct call)
--   @param                       - Delegating SP token suffix (NULL = DeviceSecret only)
-- Returns:
--   Read SP (no success envelope).
--   On error (rowset 0): standard HC6 error detail
--   On success: one rowset per non-ignored watermark, in parameter order
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_syncKennelAdminData
-- Breaking Changes:
--   isMember in HasherKennelMap rowset computed dynamically (HC5 used
--     stored IsMember column which can be stale).
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
    @spNumber     = 72,
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

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1272; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty kennelId', 'kennelId is required', @effectiveProcName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing kennel' AS errorTitle, 'A kennel must be specified.' AS errorUserMessage, @effectiveProcName AS errorProc;
    RETURN;
END

-- Admin guard (M13): when called directly (not delegated), verify caller has admin rights for @kennelId.
-- Delegated calls from write SPs skip this check — the write SP already verified auth.
-- AppAccessFlags 0x40000081 = superAdmin | authIsAdmin.
IF (@procName IS NULL)
BEGIN
    DECLARE @syncKennelMmRoles    INT = 0;
    DECLARE @syncKennelAccessFlags INT = 0;
    SELECT
        @syncKennelMmRoles     = ISNULL(hkm.MismanagementRoles, 0),
        @syncKennelAccessFlags = ISNULL(hkm.AppAccessFlags, 0)
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId;

    IF (@syncKennelMmRoles & 0x2E) = 0 AND (@syncKennelAccessFlags & 0x40000081) = 0
    BEGIN
        SET @errorCode = 1372; SET @errorType = 13; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Not authorised for kennel admin sync',
                'Caller does not hold required role for kennel', @effectiveProcName, @userId);
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Not authorised' AS errorTitle,
               'You are not authorised to sync admin data for this kennel.' AS errorUserMessage,
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
IF (@kennelsUpdatedAfter            IS NULL OR @kennelsUpdatedAfter            <= '2000-01-01') SET @kennelsUpdatedAfter            = 'ignore';
IF (@hasherKennelMapUpdatedAfter    IS NULL OR @hasherKennelMapUpdatedAfter    <= '2000-01-01') SET @hasherKennelMapUpdatedAfter    = 'ignore';
IF (@hasherEventMapUpdatedAfter     IS NULL OR @hasherEventMapUpdatedAfter     <= '2000-01-01') SET @hasherEventMapUpdatedAfter     = 'ignore';
IF (@paymentsUpdatedAfter           IS NULL OR @paymentsUpdatedAfter           <= '2000-01-01') SET @paymentsUpdatedAfter           = 'ignore';

DECLARE @ua DATETIMEOFFSET(7);

-- ---------------------------------------------------------------
-- KENNELS (global watermark)
-- ---------------------------------------------------------------
IF (@kennelsUpdatedAfter != 'ignore')
BEGIN
    SET @ua = CAST(@kennelsUpdatedAfter AS DATETIMEOFFSET(7));
    SELECT
        k.id                                                                AS kennelId,
        k.PublicKennelId                                                    AS publicKennelId,
        k.CityId                                                            AS cityId,
        k.ProvinceStateId                                                   AS regionId,
        k.CountryId                                                         AS countryId,
        k.KennelName                                                        AS kennelName,
        k.KennelShortName                                                   AS kennelShortName,
        k.KennelUniqueShortName                                             AS kennelUniqueShortName,
        k.KennelDescription                                                 AS kennelDescription,
        k.KennelSearchTags                                                  AS kennelSearchTags,
        k.DisseminateAllowWebLinks                                          AS disseminateAllowWebLinks,
        k.KennelLogo                                                        AS kennelLogo,
        k.KennelPinColor                                                    AS kennelPinColor,
        k.KennelCoverPhoto                                                  AS kennelCoverPhoto,
        k.KennelWebsiteUrl                                                  AS kennelWebsiteUrl,
        COALESCE(k.KennelMismanagementTeam, '')                             AS kennelMismanagementTeam,
        k.DefaultEventCurrencyType                                          AS defaultEventCurrencyType,
        k.IntegrationType                                                   AS integrationType,
        k.KennelEventsUrl                                                   AS kennelEventsUrl,
        k.KennelStatus                                                      AS kennelStatus,
        k.AllowNegativeCredit                                               AS allowNegativeCredit,
        k.AllowSelfPayment                                                  AS allowSelfPayment,
        k.MembershipDurationInMonths                                        AS membershipDurationInMonths,
        k.DistancePreference                                                AS distancePreference,
        k.CanEditRunAttendence                                              AS canEditRunAttendence,
        k.InboundIntegrationId                                              AS kennelInboundIntegrationId,
        COALESCE(k.Latitude,  c.Latitude)                                   AS kennelLatitude,
        COALESCE(k.Longitude, c.Longitude)                                  AS kennelLongitude,
        k.DefaultEventPriceForMembers                                       AS defaultPriceForMembers,
        k.DefaultEventPriceForNonMembers                                    AS defaultPriceForNonMembers,
        k.DefaultRunStartTime                                               AS defaultRunStartTime,
        k.RunCountStartDate                                                 AS runCountStartDate,
        k.CurrencyCode                                                      AS currencyCode,
        k.PrimaryCultureCode                                                AS primaryCultureCode,
        k.CurrencySymbol                                                    AS currencySymbol,
        k.DigitsAfterDecimal                                                AS digitsAfterDecimal,
        k.BankScheme                                                        AS bankScheme,
        k.BankAccountNumber                                                 AS bankAccountNumber,
        k.BankBic                                                           AS bankBic,
        k.BankBeneficiary                                                   AS bankBeneficiary,
        k.KennelPaymentScheme                                               AS kennelPaymentScheme,
        k.KennelPaymentUrl                                                  AS kennelPaymentUrl,
        k.KennelPaymentUrlExpires                                           AS kennelPaymentUrlExpires,
        k.KennelPaymentMemberSurcharge                                      AS kennelPaymentMemberSurcharge,
        k.KennelPaymentNonMemberSurcharge                                   AS kennelPaymentNonMemberSurcharge,
        k.KennelPaymentScheme2                                              AS kennelPaymentScheme2,
        k.KennelPaymentUrl2                                                 AS kennelPaymentUrl2,
        k.KennelPaymentUrlExpires2                                          AS kennelPaymentUrlExpires2,
        k.KennelPaymentMemberSurcharge2                                     AS kennelPaymentMemberSurcharge2,
        k.KennelPaymentNonMemberSurcharge2                                  AS kennelPaymentNonMemberSurcharge2,
        k.KennelPaymentScheme3                                              AS kennelPaymentScheme3,
        k.KennelPaymentUrl3                                                 AS kennelPaymentUrl3,
        k.KennelPaymentUrlExpires3                                          AS kennelPaymentUrlExpires3,
        k.KennelPaymentMemberSurcharge3                                     AS kennelPaymentMemberSurcharge3,
        k.KennelPaymentNonMemberSurcharge3                                  AS kennelPaymentNonMemberSurcharge3,
        k.TrailSymbolsConfigJson                                            AS trailSymbolsConfigJson,
        k.removed                                                           AS removed,
        CONVERT(NVARCHAR(50), CAST(k.updatedAt AS DATETIME2))               AS updatedAt
    FROM HC.Kennel k WITH (INDEX(IX_AllSyncKennels))
    INNER JOIN HC.City c ON c.id = k.CityId
    WHERE k.updatedAt > @ua
    ORDER BY k.updatedAt ASC, k.id ASC
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
        hkm.KennelCredit                                                    AS kennelCredit,
        hkm.DiscountAmount                                                  AS discountAmount,
        hkm.DiscountPercent                                                 AS discountPercent,
        hkm.DiscountDescription                                             AS discountDescription,
        hkm.HcTotalRunCount                                                 AS hcTotalRunCount,
        hkm.HcHaringCount                                                   AS hcHaringCount,
        hkm.HistoricalTotalRunCount                                         AS historicalTotalRunCount,
        hkm.HistoricalHaringCount                                           AS historicalHaringCount,
        hkm.HistoricalCountIsEstimate                                       AS historicalCountIsEstimate,
        hkm.MembershipExpirationDate                                        AS membershipExpirationDate,
        hkm.MemberSince                                                     AS memberSince,
        hkm.DateOfLastRun                                                   AS dateOfLastRun,
        ''                                                                  AS authorizedDeviceList,
        0                                                                   AS authorizedDeviceCount,
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
-- HASHERS (global)
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
-- PAYMENTS (scoped to @targetHasherId if provided)
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
    WHERE pmt.updatedAt > @ua AND pmt.UserId = @targetHasherId;
END

-- ---------------------------------------------------------------
-- HASHER–EVENT MAP (scoped to @targetHasherId if provided)
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
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetime) END AS hemEventStartDatetime,
        CASE WHEN evt.UseFbRunDetails = 1 THEN CONVERT(DATETIME2, evt.FbEventStartDatetime) ELSE CONVERT(DATETIME2, evt.EventStartDatetimeGmt) END AS hemEventStartDatetimeGmt,
        COALESCE(evt.EventStartDatetimeGmt, evt.EventStartDatetime)        AS eventStartDatetimeGmt,
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
    WHERE hem.UserId = @targetHasherId AND hem.updatedAt > @ua
    ORDER BY hem.updatedAt ASC, hem.id ASC;
END
