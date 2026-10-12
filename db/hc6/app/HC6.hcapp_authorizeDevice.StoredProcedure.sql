CREATE OR ALTER PROCEDURE [HC6].[hcapp_authorizeDevice]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @hcVersion   NVARCHAR(50),
    @scanText    NVARCHAR(250) = NULL,
    @userId      UNIQUEIDENTIFIER = NULL,
    @deviceData  NVARCHAR(MAX),
    @apnsToken   NVARCHAR(500)  = NULL,
    @fcmToken    NVARCHAR(500)  = NULL,
    @isMobile    SMALLINT       = 1,
    -- What the phone is, for the login row (2026-10-12). All optional: an
    -- older app sends none of them and the row is filled from @deviceData.
    @buildNumber   NVARCHAR(25)  = NULL,
    @deviceType    NVARCHAR(100) = NULL,
    @deviceName    NVARCHAR(100) = NULL,
    @systemName    NVARCHAR(100) = NULL,
    @systemVersion NVARCHAR(100) = NULL,
    @manufacturer  NVARCHAR(100) = NULL,
    @locale        NVARCHAR(50)  = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_authorizeDevice
-- Description: First-time device registration. Resolves a user by
--   invite code (@scanText URC: prefix) or directly by @userId, writes
--   a Device record with a cryptographic secret, logs the login, and
--   returns the hasher profile plus the device credentials needed for
--   all subsequent token generation.
-- Parameters:
--   @deviceId    - Client-generated device UUID (PK for HC.Device)
--   @accessToken - Global shared access token (validated against null UUID)
--   @hcVersion   - App version string e.g. '3.0.0'
--   @scanText    - Invite code in 'URC:XXXXXX' format. Mutually exclusive
--                  with @userId — one must be provided.
--   @isMobile    - 1 (default) = the phone app; 0 = a browser signing in
--                  with an emailed invite code (E9.F7, 2026-09-16). Only
--                  the HC.Device.IsMobile flag differs — a browser must not
--                  be offered push tokens or counted as a phone in Device
--                  Health.
--   @userId      - Direct user lookup by HC.Hasher.id. When provided,
--                  @scanText is ignored for lookup.
--   @deviceData  - JSON blob of device metadata stored in HC.Device
--   @apnsToken   - Apple Push Notification token (NULL for Android)
--   @fcmToken    - Firebase Cloud Messaging token
--   @buildNumber, @deviceType, @deviceName, @systemName, @systemVersion,
--   @manufacturer, @locale
--                - What the phone is (2026-10-12), the same five fields and
--                  build hcapp_approveLogin takes, so the first login row a
--                  new account writes reads like every later one. All
--                  optional; an older app's row is filled from @deviceData.
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): hasher profile + device credentials
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_authorizeDevice
-- Breaking Changes:
--   @hcVersion widened NVARCHAR(250) -> NVARCHAR(50) to match Hasher.HcVersion.
--   DeviceSecret stored uppercase (was mixed-case in HC5).
--   Device cleanup now deletes by @deviceId (fixes NULL-semantics bug in HC5
--     where AND join on ApnsToken+FcmToken silently skipped Android devices).
--   iconDataBase64 alias renamed to deviceSecret (security-through-obscurity removed).
--   colorPaletteIndex alias renamed to timeWindow.
--   Removed-user returns errorType 4 (was 5 in HC5).
--   Not-found returns errorType 3 (was 5 in HC5).
--   All writes wrapped in transaction with TRY/CATCH.
--   2026-10-12: LaunchAndLogin row gains DeviceId and the five device
--     columns, and HcVersion is 'HC Ver: x, Bld: n' when @buildNumber is
--     sent; HC.Device gets Version/BuildNumber/Locale on insert. Additive —
--     no parameter or rowset changed.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

BEGIN TRY

    -- ---------------------------------------------------------------
    -- Auth: global shared token (null userId = public endpoint)
    -- ---------------------------------------------------------------
    DECLARE @nullUserId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';

    IF HC.CHECK_ACCESS_TOKEN_V2(@nullUserId, @procName,
                                COALESCE(@accessToken, 'error'), NULL, 30) = 0
    BEGIN
        SET @errorCode = 1102; SET @errorType = 11; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, @hcVersion, 'Invalid access token',
                'Global access token failed validation', @procName, @nullUserId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Invalid access token' AS errorTitle,
               'The access token is invalid. Please check that the clock on your phone is set automatically from Apple or Google.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- ---------------------------------------------------------------
    -- Resolve user by @userId or @scanText (URC: invite code)
    -- ---------------------------------------------------------------
    DECLARE @hasherName NVARCHAR(250);
    DECLARE @removed    INT;

    IF (@userId IS NOT NULL)
    BEGIN
        SELECT TOP 1
            @scanText   = h.ResetCode,
            @hasherName = h.DisplayName,
            @removed    = h.Removed
        FROM HC.Hasher h
        WHERE h.id = @userId;
    END

    IF (@userId IS NULL AND @scanText LIKE 'URC:%')
    BEGIN
        SELECT TOP 1
            @userId     = h.id,
            @hasherName = h.DisplayName,
            @removed    = h.Removed
        FROM HC.Hasher h
        WHERE h.ResetCode = @scanText;
    END

    -- ---------------------------------------------------------------
    -- Not found
    -- ---------------------------------------------------------------
    IF (@userId IS NULL)
    BEGIN
        SET @errorCode = 1302; SET @errorType = 13; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, string_1)
        VALUES (@errorId, @hcVersion, 'Invite code not found',
                'Invite code "' + COALESCE(@scanText, '') + '" not found',
                @procName, @nullUserId, @deviceId, @scanText);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Invite code not found' AS errorTitle,
               'The invite code provided was not found in the Harrier Central system.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- ---------------------------------------------------------------
    -- User removed
    -- ---------------------------------------------------------------
    IF (@removed = 1)
    BEGIN
        SET @errorCode = 1402; SET @errorType = 14; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, string_1)
        VALUES (@errorId, @hcVersion,
                'Attempt to load removed user (' + @hasherName + ')',
                @hasherName + ' attempted to authorise a device after account removal',
                @procName, @nullUserId, @deviceId, @scanText);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Account removed' AS errorTitle,
               'The account associated with this invite code has been removed. '
               + 'Contact your Kennel admin or harriercentral@gmail.com for a new invite code.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- ---------------------------------------------------------------
    -- Generate device secret (uppercase base64, no + or /)
    -- ---------------------------------------------------------------
    DECLARE @binaryData   VARBINARY(MAX) = CRYPT_GEN_RANDOM(150);
    DECLARE @deviceSecret NVARCHAR(150);
    DECLARE @timeWindow   INT;

    SELECT @deviceSecret = LEFT(
        UPPER(REPLACE(REPLACE(
            CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
            '+', ''), '/', '')),
        75);

    SELECT @timeWindow = CAST((RAND() * 15) + 30 AS INT);

    -- ---------------------------------------------------------------
    -- Writes (transacted)
    -- ---------------------------------------------------------------
    BEGIN TRANSACTION;

        UPDATE HC.Hasher
        SET LastLoginDateTime = GETDATE(),
            HcVersion         = @hcVersion,
            updatedAt         = GETDATE()
        WHERE id = @userId;

        -- The first login row a new account writes. It used to carry the
        -- version string alone, so a member who had just redeemed an invite
        -- code showed as '<no HC version>' with no device, indistinguishable
        -- from a browser sign-in in the portal's login list (Sierra H4's
        -- invites, 2026-10-12). Now the same shape hcapp_approveLogin writes
        -- on every launch: 'HC Ver: x, Bld: n' and the five device fields.
        -- An app that sends none of them still gets a device from the JSON
        -- it has always sent — the iOS and Android key names differ, hence
        -- the pairs — and a browser (@isMobile = 0) gets its browser name.
        INSERT HC.LaunchAndLogin
            (HcVersion, UserId, UserName, DeviceId,
             DeviceType, DeviceName, SystemName, SystemVersion, Manufacturer)
        VALUES
            (CASE WHEN @buildNumber IS NOT NULL
                  THEN 'HC Ver: ' + @hcVersion + ', Bld: ' + @buildNumber
                  ELSE @hcVersion END,
             @userId, '~' + @hasherName + '~', CAST(@deviceId AS NVARCHAR(100)),
             COALESCE(@deviceType,
                      JSON_VALUE(@deviceData, '$.model'),
                      JSON_VALUE(@deviceData, '$.browserName')),
             COALESCE(@deviceName,
                      JSON_VALUE(@deviceData, '$.name'),
                      JSON_VALUE(@deviceData, '$.platform')),
             COALESCE(@systemName,
                      JSON_VALUE(@deviceData, '$.systemName'),
                      CASE WHEN JSON_VALUE(@deviceData, '$.manufacturer') IS NOT NULL THEN 'Android' END),
             COALESCE(@systemVersion,
                      JSON_VALUE(@deviceData, '$.systemVersion'),
                      JSON_VALUE(@deviceData, '$.version.release')),
             COALESCE(@manufacturer,
                      JSON_VALUE(@deviceData, '$.manufacturer'),
                      CASE WHEN JSON_VALUE(@deviceData, '$.systemName') = 'iOS' THEN 'Apple' END));

        -- Remove the old device record for this deviceId (idempotent re-registration)
        DELETE FROM HC.Device WHERE id = @deviceId;

        -- Version and build on the device row from the first call, so the
        -- Usage Data tiles count a new phone on the build it is actually on
        -- rather than '<unknown>' until its next launch.
        INSERT INTO HC.Device
            ([id], [DeviceSecret], [TimeWindow], [DeviceData], [UserId], [ApnsToken], [FcmToken], [IsMobile],
             [Version], [BuildNumber], [Locale])
        VALUES
            (@deviceId, @deviceSecret, @timeWindow, @deviceData, @userId, @apnsToken, @fcmToken, COALESCE(@isMobile, 1),
             CASE WHEN @buildNumber IS NOT NULL THEN LEFT(@hcVersion, 25) ELSE N'<unknown>' END,
             COALESCE(@buildNumber, N'<unknown>'),
             COALESCE(@locale, ''));

    COMMIT TRANSACTION;

    -- ---------------------------------------------------------------
    -- Success
    -- ---------------------------------------------------------------
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        h.id                            AS hasherId,
        h.PublicHasherId                AS publicHasherId,
        h.Photo                         AS photo,
        h.DisplayName                   AS displayName,
        h.Email                         AS email,
        h.FacebookId                    AS facebookId,
        h.FirstName                     AS firstName,
        h.HashName                      AS hashName,
        h.LastName                      AS lastName,
        h.QR_code                       AS qrCode,
        h.SupportCode                   AS supportCode,
        h.QR_secret_code                AS qrSecretCode,
        h.ResetCode                     AS resetCode,
        h.IncludeInGlobalHashDirectory  AS includeInGlobalHashDirectory,
        h.Preferences                   AS preferences,
        h.IsBetaTester                  AS isBetaTester,
        h.HomeKennelId                  AS homeKennelId,
        h.ThirdPartyAccessToken         AS thirdPartyAccessToken,
        h.ThirdPartyAuthorizationCode   AS thirdPartyAuthorizationCode,
        h.ThirdPartyEmail               AS thirdPartyEmail,
        h.ThirdPartyForceTokenRefresh   AS thirdPartyForceTokenRefresh,
        h.ThirdPartyLoginType           AS thirdPartyLoginType,
        h.ThirdPartyUserId              AS thirdPartyUserId,
        h.ThirdPartyTokenLastUpdated    AS thirdPartyTokenLastUpdated,
        h.ThirdPartyAccessTokenExpires  AS thirdPartyAccessTokenExpires,
        d.DeviceSecret                  AS deviceSecret,
        d.TimeWindow                    AS timeWindow
    FROM HC.Hasher h
    INNER JOIN HC.Device d ON d.UserId = h.id AND d.id = @deviceId
    WHERE h.id = @userId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1902; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
