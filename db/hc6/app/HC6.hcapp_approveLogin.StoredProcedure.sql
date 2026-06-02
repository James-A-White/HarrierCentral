CREATE OR ALTER PROCEDURE [HC6].[hcapp_approveLogin]

    @deviceId             UNIQUEIDENTIFIER,
    @accessToken          NVARCHAR(1000),
    @deviceType           NVARCHAR(100),
    @deviceName           NVARCHAR(100),
    @systemName           NVARCHAR(100),
    @systemVersion        NVARCHAR(100),
    @manufacturer         NVARCHAR(100),
    @latitude             DECIMAL(18,15),
    @longitude            DECIMAL(19,15),
    @hcVersion            NVARCHAR(50)  = 'pre 3.0',
    @buildNumber          NVARCHAR(25)  = '?',
    @usesLocSvcs          SMALLINT      = -1,
    @ipInfo               NVARCHAR(4000)= NULL,
    @splashSequenceViewed DATETIMEOFFSET= NULL,
    @splashSequenceRootName NVARCHAR(100) = NULL,
    @locale               NVARCHAR(50)  = ''

AS
-- =====================================================================
-- Procedure: HC6.hcapp_approveLogin
-- Description: Called on every app launch after initial device
--   authorisation. Validates the device token, records the login event,
--   updates device metadata, marks any viewed splash sequence, and
--   returns session configuration from HC.ServerStatus plus the next
--   pending splash sequence (if any).
-- Parameters:
--   @deviceId             - Registered device UUID
--   @accessToken          - Short-lived token derived from DeviceSecret
--   @deviceType           - Device model string (stored in LaunchAndLogin)
--   @deviceName           - User-assigned device name (LaunchAndLogin)
--   @systemName           - OS name, e.g. 'iOS' (LaunchAndLogin)
--   @systemVersion        - OS version string (LaunchAndLogin)
--   @manufacturer         - Device manufacturer (LaunchAndLogin)
--   @latitude             - GPS latitude (stored on Device)
--   @longitude            - GPS longitude (stored on Device)
--   @hcVersion            - App version, e.g. '3.0.0' (max 50 chars)
--   @buildNumber          - Build number (max 25 chars)
--   @usesLocSvcs          - 1=location permitted, 0=denied, -1=unknown
--   @ipInfo               - IP/geo string (stored in LaunchAndLogin)
--   @splashSequenceViewed - Timestamp of splash screen the user just viewed
--   @splashSequenceRootName - Root name of the splash that was viewed
--   @locale               - Device locale string (stored on Device)
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): session config from HC.ServerStatus
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_approveLogin
-- Breaking Changes:
--   @deviceId type NVARCHAR(100) -> UNIQUEIDENTIFIER.
--   @hcVersion widened NVARCHAR(200) -> NVARCHAR(50) to match Hasher.HcVersion.
--   @buildNumber widened NVARCHAR(50) -> NVARCHAR(25) to match Device.BuildNumber.
--   @homeKennelId local variable type NVARCHAR(100) -> UNIQUEIDENTIFIER.
--   Removed @fbToken (dead parameter — Facebook token update code was removed).
--   Removed @screenWidth, @screenHeight (dead parameters — never used).
--   Removed dead integration CTE and hardcoded output columns (integrationCount,
--     lastIntegrationExecuted, integrationStopped) — removed from result set.
--   Auth check now runs BEFORE removed-user check (fixes HC5 information
--     disclosure: a removed user with invalid token got "user removed" not
--     "invalid token").
--   errorType 4 for removed user (was 5 in HC5).
--   errorType 1 for auth failure is now standard 1 (unchanged, already correct).
--   LaunchAndLogin INSERT always executes (including on auth failure) — retained
--     from HC5 to preserve the audit trail of failed attempts.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- ---------------------------------------------------------------
-- Resolve device → userId, deviceSecret, timeWindow
-- ---------------------------------------------------------------
DECLARE @userId       UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
DECLARE @deviceSecret NVARCHAR(150)    = '<none>';
DECLARE @timeWindow   INT              = 30;

IF (@deviceId IS NOT NULL)
BEGIN
    SELECT
        @userId       = d.UserId,
        @deviceSecret = d.DeviceSecret,
        @timeWindow   = d.TimeWindow
    FROM HC.Device d
    WHERE d.id = @deviceId;
END

-- ---------------------------------------------------------------
-- Read user state before auth (needed for LaunchAndLogin audit)
-- ---------------------------------------------------------------
DECLARE @userName              NVARCHAR(250);
DECLARE @email                 NVARCHAR(250);
DECLARE @isBetaTester          SMALLINT;
DECLARE @homeKennelId          UNIQUEIDENTIFIER;
DECLARE @thirdPartyForceTokenRefresh DATETIMEOFFSET(7);
DECLARE @removed               INT;
DECLARE @betaFeaturesEnabled   NVARCHAR(1000);
DECLARE @hasherPreferences     INT;

SELECT
    @userName                    = h.DisplayName,
    @email                       = h.Email,
    @isBetaTester                = h.IsBetaTester,
    @homeKennelId                = h.HomeKennelId,
    @thirdPartyForceTokenRefresh = h.ThirdPartyForceTokenRefresh,
    @removed                     = h.Removed,
    @betaFeaturesEnabled         = h.BetaFeaturesEnabled,
    @hasherPreferences           = h.Preferences
FROM HC.Hasher h
WHERE h.id = @userId;

-- ---------------------------------------------------------------
-- Auth check (before removed-user check — avoids information disclosure)
-- ---------------------------------------------------------------
DECLARE @invalidAccessToken SMALLINT = 0;

IF HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, @accessToken, @deviceSecret, @timeWindow) = 0
BEGIN
    SET @errorCode = 1103; SET @errorType = 11; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
    VALUES (@errorId, @hcVersion, 'Invalid access token', 'Access token failed validation',
            @procName, @userId, CAST(@deviceId AS NVARCHAR(40)));

    -- Always record failed attempts in LaunchAndLogin
    INSERT HC.LaunchAndLogin (UserId, UserName, HcVersion, DeviceType, DeviceId, DeviceName,
                               SystemName, SystemVersion, Manufacturer, Latitude, Longitude,
                               UsesLocSvcs, IpInfo, errorInfo)
    VALUES (@userId, @userName, 'HC Ver: ' + @hcVersion + ', Bld: ' + @buildNumber,
            @deviceType, @deviceId, @deviceName, @systemName, @systemVersion,
            @manufacturer, @latitude, @longitude, COALESCE(@usesLocSvcs, -1),
            @ipInfo, 'Invalid Access Token');

    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid access token' AS errorTitle,
           'A security check has been activated. Please restart the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Removed-user check (after auth, so auth failure takes priority)
-- ---------------------------------------------------------------
IF (@removed = 1)
BEGIN
    SET @errorCode = 1403; SET @errorType = 14; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (@errorId, @hcVersion,
            'Attempt to login as removed user (' + @userName + ')',
            @userName + ' attempted to launch the app after account removal',
            @procName, '00000000-0000-0000-0000-000000000000', @deviceId);

    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Account removed' AS errorTitle,
           'The account for "' + @userName + '" has been removed. '
           + 'Contact your Kennel admin or connect@harriercentral.com for assistance.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Writes (transacted)
-- ---------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

        INSERT HC.LaunchAndLogin
            (UserId, UserName, HcVersion, DeviceType, DeviceId, DeviceName,
             SystemName, SystemVersion, Manufacturer, Latitude, Longitude,
             UsesLocSvcs, IpInfo, errorInfo)
        VALUES
            (@userId, @userName,
             'HC Ver: ' + @hcVersion + ', Bld: ' + @buildNumber,
             @deviceType, @deviceId, @deviceName,
             @systemName, @systemVersion, @manufacturer,
             @latitude, @longitude, COALESCE(@usesLocSvcs, -1),
             @ipInfo, NULL);

        UPDATE HC.Hasher
        SET LastLoginDateTime = GETDATE(),
            HcVersion         = @hcVersion
        WHERE id = @userId;

        IF (@splashSequenceViewed IS NOT NULL)
        BEGIN
            INSERT HC.SplashSequenceViews (SplashSequenceId, UserId, ViewedOn)
            SELECT ss.id, @userId, @splashSequenceViewed
            FROM HC.SplashSequence ss
            WHERE ss.SplashSequenceRootName = @splashSequenceRootName;
        END

        UPDATE HC.Device
        SET LastLogin  = GETDATE(),
            Latitude   = @latitude,
            Longitude  = @longitude,
            updatedAt  = GETDATE(),
            BuildNumber= @buildNumber,
            [Version]  = @hcVersion,
            Locale     = @locale
        WHERE id = @deviceId;

    COMMIT TRANSACTION;

    -- ---------------------------------------------------------------
    -- Load server status / login notifications
    -- ---------------------------------------------------------------
    DECLARE @serverStatusCode  SMALLINT;
    DECLARE @loginMessageTitle NVARCHAR(120);
    DECLARE @loginMessage      NVARCHAR(500);
    DECLARE @messageEndDate    DATETIMEOFFSET(7);
    DECLARE @messageDisplayType SMALLINT;
    DECLARE @messageImageUrl   NVARCHAR(500);

    SELECT TOP 1
        @serverStatusCode   = smp.ServerStatusCode,
        @loginMessageTitle  = smp.LoginMessageTitle,
        @loginMessage       = smp.LoginMessage,
        @messageEndDate     = smp.MessageWindowCloses,
        @messageDisplayType = smp.MessageDisplayType,
        @messageImageUrl    = smp.MessageImageUrl
    FROM HC.LoginNotifications smp
    WHERE GETDATE() BETWEEN smp.MessageWindowOpens AND smp.MessageWindowCloses
    ORDER BY smp.CreatedDate DESC;

    -- Re-read ThirdPartyForceTokenRefresh and BetaFeaturesEnabled after write
    SELECT @thirdPartyForceTokenRefresh = h.ThirdPartyForceTokenRefresh,
           @betaFeaturesEnabled         = h.BetaFeaturesEnabled
    FROM HC.Hasher h WHERE h.id = @userId;

    -- Next unseen splash sequence for this user
    DECLARE @splashSequenceRootNameOut NVARCHAR(100);
    DECLARE @splashSequenceType        SMALLINT;

    SELECT TOP 1
        @splashSequenceRootNameOut = splash.SplashSequenceRootName,
        @splashSequenceType        = splash.SequenceType
    FROM HC.SplashSequence splash
    LEFT OUTER JOIN HC.SplashSequenceViews sv
        ON splash.id = sv.SplashSequenceId AND sv.UserId = @userId
    WHERE splash.Removed = 0
      AND sv.id IS NULL
      AND GETDATE() BETWEEN splash.ValidFromDate AND splash.ValidUntilDate
    ORDER BY splash.SequenceType, splash.SequenceOrder;

    -- ---------------------------------------------------------------
    -- Active song proximity check (500m bounding-box approximation)
    -- Returns non-null if a song was selected in the last 5 minutes
    -- for a run whose start location is within ~500m of the device.
    -- ---------------------------------------------------------------
    DECLARE @activeSongId      UNIQUEIDENTIFIER = NULL;
    DECLARE @activeSongEventId UNIQUEIDENTIFIER = NULL;

    IF (@latitude IS NOT NULL AND @longitude IS NOT NULL)
    BEGIN
        SELECT TOP 1
            @activeSongId      = ss.SongId,
            @activeSongEventId = ss.EventId
        FROM HC.SongSession ss
        INNER JOIN HC.Event evt ON evt.id = ss.EventId
        WHERE ss.Removed   = 0
          AND ss.SelectedAt > DATEADD(MINUTE, -5, SYSUTCDATETIME())
          AND evt.Removed   = 0
          AND ABS(COALESCE(evt.Latitude,  999) - @latitude)  < 0.0045
          AND ABS(COALESCE(evt.Longitude, 999) - @longitude) < 0.0045
        ORDER BY ss.SelectedAt DESC;
    END

    -- ---------------------------------------------------------------
    -- Success envelope + result
    -- ---------------------------------------------------------------
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT TOP 1
        svr.ApiVersion          AS apiVersion,
        CASE WHEN COALESCE(@serverStatusCode, 1) = 1 THEN 1 ELSE 0 END AS approvalCode,
        COALESCE(@loginMessageTitle,  'Harrier Central') AS loginMessageTitle,
        COALESCE(@loginMessage,       'Server running')  AS loginMessage,
        COALESCE(@serverStatusCode,   1)                 AS serverStatusCode,
        COALESCE(@messageEndDate,     '2100-01-01')      AS messageEndDate,
        COALESCE(@messageDisplayType, 0)                 AS messageDisplayType,
        COALESCE(@messageImageUrl,    '')                AS messageImageUrl,
        svr.IosDownloadLink     AS iosDownloadLink,
        svr.AndroidDownloadLink AS androidDownloadLink,
        svr.ImageRootUrl        AS imageRootUrl,
        @isBetaTester           AS isBetaTester,
        @email                  AS email,
        @homeKennelId           AS homeKennelId,
        @thirdPartyForceTokenRefresh AS thirdPartyForceTokenRefresh,
        @splashSequenceRootNameOut AS splashSequenceRootName,
        @splashSequenceType        AS splashSequenceType,
        @betaFeaturesEnabled    AS betaFeaturesEnabled,
        @hasherPreferences      AS hasherPreferences,
        LOWER(CAST(@activeSongId      AS NVARCHAR(40))) AS activeSongId,
        LOWER(CAST(@activeSongEventId AS NVARCHAR(40))) AS activeSongEventId
    FROM HC.ServerStatus svr
    ORDER BY svr.CreatedDate DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1903; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
