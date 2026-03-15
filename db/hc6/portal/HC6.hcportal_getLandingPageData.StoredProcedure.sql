CREATE OR ALTER PROCEDURE [HC6].[hcportal_getLandingPageData]

@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@fcmToken nvarchar(500) = NULL,
@deviceId uniqueidentifier = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getLandingPageData
-- Description: Returns landing page data for an authenticated portal
--   user. Updates FCM token on device if changed, and returns user
--   profile and list of kennels the user follows (with membership
--   status and kennel details).
-- Parameters: @publicHasherId, @accessToken, @fcmToken, @deviceId
-- Returns: On error: HC6 envelope (Success, ErrorMessage). On success:
--   Rowset 0 = UserProfile (firstName, lastName, hashName, displayName).
--   Rowset 1 = KennelList (kennel details, membership, location data).
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_getLandingPageData
-- Breaking Changes: Fixed wrong SP name in GeneralLog
--   ('hcportal_getKennelHashers' -> 'hcportal_getLandingPageData').
--   Moved FCM token update after validation (HC5 ran it before error
--   check). Validation now short-circuits on first error. Added
--   TRY/CATCH and transaction around Device UPDATE + PortalAccess
--   INSERT. Removed commented-out debug code.
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Auth validation
    DECLARE @authError NVARCHAR(255);
    EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, NULL, @authError OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- HC5 BUG FIX: FCM token update moved AFTER validation (HC5 ran it before error check)
    -- Wrap Device UPDATE + PortalAccess INSERT in a transaction
    DECLARE @firstName nvarchar(250),
            @lastName nvarchar(250),
            @hashName nvarchar(250),
            @displayName nvarchar(250),
            @hasherId uniqueidentifier

    SELECT
        @firstName = coalesce(h.FirstName, ''),
        @lastName = coalesce(h.LastName, ''),
        @hashName = coalesce(h.HashName, ''),
        @displayName = coalesce(h.DisplayName, ''),
        @hasherId = h.id
    FROM  HC.Hasher h
    WHERE h.PublicHasherId = @publicHasherId

    BEGIN TRANSACTION;

    -- If the FCM token has changed, update the table accordingly
    UPDATE device SET device.FcmToken = @fcmToken, updatedAt = GETDATE()
    FROM HC.Device device
    WHERE device.id = @deviceId and FcmToken != @fcmToken

    INSERT HC.PortalAccess(hasherId) VALUES (@hasherId)

    COMMIT TRANSACTION;

    -- Rowset 0: User profile
    SELECT
        @firstName as firstName,
        @lastName as lastName,
        @hashName as hashName,
        @displayName as displayName

    -- Rowset 1: Kennel list
    SELECT
    k.PublicKennelId as publicKennelId
    , k.KennelName as kennelName
    , k.KennelShortName as kennelShortName
    , k.KennelUniqueShortName as kennelUniqueShortName
    , k.KennelLogo as kennelLogo
    , k.DefaultRunTags1 as defaultTags1
    , k.DefaultRunTags2 as defaultTags2
    , k.DefaultRunTags3 as defaultTags3
    , k.CountryId as countryId
    , n.CountryName as countryName
    , k.DefaultEventPriceForMembers as defaultEventPriceForMembers
    , k.DefaultEventPriceForNonMembers as defaultEventPriceForNonMembers
    , coalesce(k.CurrencySymbol, n.CurrencySymbol) as defaultCurrencySymbol
    , coalesce(k.DigitsAfterDecimal, n.DigitsAfterDecimal) as defaultDigitsAfterDecimal
    , cast(k.DefaultRunStartTime as datetime) as defaultRunStartTime
    , k.Latitude as kennelLat
    , k.Longitude as kennelLon
    , c.Latitude as cityLat
    , c.Longitude as cityLon
    , n.NeighboringCountries as kennelCountryCodes
    , hkm.Following as isFollowing
    , hkm.MembershipExpirationDate as membershipExpirationDate
    , case when hkm.MembershipExpirationDate > getdate() then 1 else 0 end as isMember
    , case when h.HomeKennelId = k.id then 1 else 0 end as isHomeKennel
    , hkm.AppAccessFlags as appAccessFlags
    FROM
    HC.Hasher h
    INNER JOIN HC.HasherKennelMap hkm on hkm.UserId = h.id
    INNER JOIN HC.Kennel k on k.id = hkm.KennelId
    INNER JOIN HC.City c on k.CityId = c.id
    INNER JOIN HC.Country n on k.CountryId = n.id
    WHERE h.PublicHasherId = @publicHasherId
    AND hkm.Following = 1

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
