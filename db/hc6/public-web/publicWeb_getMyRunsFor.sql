CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getMyRunsFor]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @countryId      UNIQUEIDENTIFIER = NULL,
    @allRuns        SMALLINT         = 0
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getMyRunsFor
-- Description: The app's "My runs for <kennel>" / "My runs for <country>"
--              drill-down (user_run_history_list_page.dart /
--              user_country_history_list_page.dart), server-side. One
--              row per run — and per payment where a run has more than
--              one, exactly as the app (LEFT JOIN on non-cancelled
--              payments). @allRuns = 1 is the app's "All Runs" toggle:
--              attendance >= 0 instead of >= 20, so every counted run
--              of the kennel/country appears, with my row where I have
--              one. The run's country is Event.CountryId — a travelling
--              kennel's runs sit under several countries.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
--              @publicKennelId OR @countryId - exactly one
--              @allRuns - 0 my runs (default), 1 all runs
-- Returns:     Rowset 0: envelope.
--              Rowset 1: header — for a kennel: name, logo, my verified
--                        (Hc) counts, credit, currency; for a country:
--                        the country name and flag.
--              Rowset 2: runs, newest first, the app's columns.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 114, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER;
    IF (@publicKennelId IS NOT NULL)
        SELECT @kennelId = k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    IF (@kennelId IS NULL AND @countryId IS NULL)
    BEGIN
        SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Kennel or country not found',
                'publicKennelId=' + COALESCE(CAST(@publicKennelId AS NVARCHAR(40)), 'null') + ' countryId=' + COALESCE(CAST(@countryId AS NVARCHAR(40)), 'null'),
                @procName, @userId, @deviceId);
        SELECT 0 AS success, 1240 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1240 AS errorCode,
               'Not found' AS errorTitle, 'That kennel or country could not be found.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    DECLARE @minAttendance INT = CASE WHEN @allRuns = 1 THEN 0 ELSE 20 END;
    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    -- Rowset 1: header
    IF (@kennelId IS NOT NULL)
        SELECT
            'kennel'                                                 AS Kind,
            k.PublicKennelId,
            k.KennelUniqueShortName                                  AS KennelSlug,
            k.KennelShortName,
            k.KennelName,
            k.KennelLogo,
            COALESCE(hkm.HcTotalRunCount, 0)                         AS HcRuns,
            COALESCE(hkm.HcHaringCount, 0)                           AS HcHaring,
            COALESCE(hkm.KennelCredit, 0)                            AS KennelCredit,
            COALESCE(k.DigitsAfterDecimal, c.DigitsAfterDecimal, 2)  AS DigitsAfterDecimal,
            COALESCE(k.CurrencySymbol, c.CurrencySymbol, '$^')       AS CurrencySymbol,
            NULL AS CountryId, NULL AS CountryName, NULL AS FlagFile
        FROM HC.Kennel k
        LEFT JOIN HC.Country c ON c.id = k.CountryId
        LEFT JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = @userId AND hkm.removed = 0
        WHERE k.id = @kennelId;
    ELSE
        SELECT
            'country' AS Kind,
            NULL AS PublicKennelId, NULL AS KennelSlug, NULL AS KennelShortName, NULL AS KennelName, NULL AS KennelLogo,
            NULL AS HcRuns, NULL AS HcHaring, NULL AS KennelCredit, NULL AS DigitsAfterDecimal, NULL AS CurrencySymbol,
            n.id AS CountryId, n.CountryName, n.FlagFile
        FROM HC.Country n WHERE n.id = @countryId;

    -- Rowset 2: the runs — the app's SELECT list, from the server's tables
    SELECT
        hem.TotalRunsThisKennel                                          AS totalRunsThisKennel,
        hem.TotalHaringThisKennel                                        AS totalHaringThisKennel,
        e.PublicEventId                                                  AS publicEventId,
        e.EventName                                                      AS eventName,
        e.EventNumber                                                    AS eventNumber,
        n.CountryName                                                    AS countryName,
        n.FlagFile                                                       AS flagFile,
        n.CountryCode                                                    AS countryCode,
        k.KennelName                                                     AS kennelName,
        k.KennelShortName                                                AS kennelShortName,
        k.KennelUniqueShortName                                          AS kennelSlug,
        k.KennelLogo                                                     AS kennelLogo,
        COALESCE(k.DigitsAfterDecimal, n.DigitsAfterDecimal, 2)          AS digitsAfterDecimal,
        COALESCE(k.CurrencySymbol, n.CurrencySymbol, '$^')               AS currencySymbol,
        CAST(e.EventStartDatetime AS datetime2(7))                       AS eventStartDatetime,
        e.ExtrasDescription                                              AS extrasDescription,
        e.EventPriceForExtras                                            AS extrasPrice,
        hem.id                                                           AS hemId,
        COALESCE(hem.AttendenceState, 0)                                 AS attendenceState,
        COALESCE(hem.IsHare, 0)                                          AS isHare,
        pay.CreditAmount                                                 AS creditAmount,
        pay.DebitAmount                                                  AS debitAmount,
        pay.CreditAvailable                                              AS creditAvailable,
        pay.PaymentType                                                  AS paymentType,
        pay.DoPayForExtras                                               AS doPayForExtras
    FROM HC.Event e
    JOIN HC.Kennel  k ON k.id = e.KennelId
    JOIN HC.Country n ON n.id = e.CountryId
    LEFT JOIN HC.HasherEventMap hem ON hem.EventId = e.id AND hem.UserId = @userId
    LEFT JOIN HC.Payment pay ON pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL AND pay.removed = 0
    WHERE e.IsCountedRun = 1 AND e.IsVisible = 1 AND e.removed = 0  -- as the app: no deleted filter
      AND (@kennelId IS NULL OR e.KennelId = @kennelId)
      AND (@countryId IS NULL OR e.CountryId = @countryId)
      AND COALESCE(hem.AttendenceState, 0) >= @minAttendance
      AND e.EventStartDateTimeGmt <= @now
    ORDER BY e.EventStartDateTimeGmt DESC, e.EventNumber DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getMyRunsFor', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
