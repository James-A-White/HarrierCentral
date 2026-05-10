CREATE OR ALTER PROCEDURE [HC6].[hcapp_processThirdPartyLogin]

    @deviceId                   UNIQUEIDENTIFIER,
    @accessToken                NVARCHAR(1000),
    @hcVersion                  NVARCHAR(50),
    @firstName                  NVARCHAR(250),
    @lastName                   NVARCHAR(250),
    @hashName                   NVARCHAR(250),
    @email                      NVARCHAR(250),
    @photo                      NVARCHAR(1000),
    @thirdPartyLoginType        NVARCHAR(120),
    @thirdPartyUserId           NVARCHAR(1000),
    @thirdPartyAccessToken      NVARCHAR(1000),
    @thirdPartyAuthorizationCode NVARCHAR(1000),
    @thirdPartyAccessTokenExpires DATETIMEOFFSET(7) = NULL,
    @includeInGlobalHashDirectory INT = NULL,
    @latitude                   DECIMAL(18,15) = 0,
    @longitude                  DECIMAL(19,15) = 0,
    @thirdPartyEmail            NVARCHAR(250)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_processThirdPartyLogin
-- Description: Handles OAuth login (Facebook, Apple, Google). Resolves
--   an existing Hasher by thirdPartyUserId, email, or thirdPartyEmail —
--   updating OAuth tokens when found. Creates a new Hasher if no match.
--   Updates Kennel Facebook tokens when loginType = 'facebook'.
--   Returns the hasher profile on success.
-- Parameters:
--   @deviceId                   - Registered device UUID
--   @accessToken                - Token validated against DeviceSecret + UPPER(userId)
--   @hcVersion                  - App version string
--   @firstName / @lastName      - From OAuth provider
--   @hashName                   - Hash name (NULL/empty = not set)
--   @email                      - Primary email from OAuth provider
--   @photo                      - Profile photo URL (NULL/empty = not set)
--   @thirdPartyLoginType        - 'facebook', 'apple', or 'google'
--   @thirdPartyUserId           - OAuth provider's user identifier
--   @thirdPartyAccessToken      - OAuth access token
--   @thirdPartyAuthorizationCode - OAuth authorization code
--   @thirdPartyAccessTokenExpires - Token expiry (DATETIMEOFFSET, not string)
--   @includeInGlobalHashDirectory - NULL = don't update. -1 treated as NULL.
--   @latitude / @longitude      - Device location (USA detection for units pref)
--   @thirdPartyEmail            - Email as reported by the OAuth provider
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): hasher profile
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_processThirdPartyLogin
-- Breaking Changes:
--   @deviceId type NVARCHAR(50) -> UNIQUEIDENTIFIER.
--   @firstName/@lastName/@hashName/@email widened to NVARCHAR(250) to match columns.
--   @photo widened to NVARCHAR(1000) to match Hasher.Photo.
--   @thirdPartyEmail widened to NVARCHAR(250) to match column.
--   @thirdPartyAccessTokenExpires type NVARCHAR(150) -> DATETIMEOFFSET(7).
--   Hardcoded 'FILTH Leiden' default kennel follow removed.
--   Duplicate UPDATE passes consolidated into single UPDATE per path.
--   errorTitle corrected for user-creation failure (was 'Reset code not found').
--   errorType corrected to 9 for creation failure (was 5, semantically wrong but same value).
--   Standard HC6 error format replaces HC5 Pascal-cased auth error.
--   Token validated against DeviceSecret + UPPER(userId) compound.
--   Success envelope added. TRY/CATCH added.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- Normalise empty strings to NULL
IF (LEN(@hashName) = 0) SET @hashName = NULL;
IF (LEN(@photo)    = 0) SET @photo    = NULL;
IF (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL;

-- ---------------------------------------------------------------
-- Detect USA timezone for default units preference
-- ---------------------------------------------------------------
DECLARE @useUsaMiles SMALLINT = 0;
IF ((@latitude BETWEEN 24.74 AND 49.35) AND (@longitude BETWEEN -124.78 AND -66.95)) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 51.21 AND 71.37) AND (@longitude BETWEEN -180   AND -179.15)) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 51.21 AND 71.37) AND (@longitude BETWEEN 179.78 AND  180   )) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 18.91 AND 28.40) AND (@longitude BETWEEN -178.33 AND -154.81)) SET @useUsaMiles = 1;

-- ---------------------------------------------------------------
-- Resolve device → userId (needed for compound token)
-- ---------------------------------------------------------------
DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

SELECT @userId = d.UserId, @deviceSecret = d.DeviceSecret, @timeWindow = d.TimeWindow
FROM HC.Device d WHERE d.id = @deviceId;

IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1305; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Device not registered', 'Device not found', @procName, NULL);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Device not registered' AS errorTitle,
           'The device is not registered. Please re-authorise the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Token validated against DeviceSecret + UPPER(userId)
DECLARE @paramString NVARCHAR(500) = @deviceSecret + UPPER(CAST(@userId AS NVARCHAR(50)));

IF HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, COALESCE(@accessToken, 'error'), @paramString, @timeWindow) = 0
BEGIN
    SET @errorCode = 1105; SET @errorType = 1; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Invalid access token', 'Access token failed validation', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid access token' AS errorTitle,
           'The access token is invalid. Please restart the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        -- ---------------------------------------------------------------
        -- Upsert Hasher by thirdPartyUserId, email, or thirdPartyEmail
        -- ---------------------------------------------------------------
        DECLARE @resolvedUserId UNIQUEIDENTIFIER;

        SELECT TOP 1 @resolvedUserId = h.id
        FROM HC.Hasher h
        WHERE h.ThirdPartyUserId = @thirdPartyUserId
           OR h.Email            = @email
           OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail)
           OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @email)
           OR h.Email            = @thirdPartyEmail;

        IF (@resolvedUserId IS NOT NULL)
        BEGIN
            -- Update existing hasher
            UPDATE HC.Hasher
            SET HashName                   = COALESCE(@hashName, HashName),
                Email                      = COALESCE(@email, Email),
                FirstName                  = COALESCE(@firstName, FirstName),
                LastName                   = COALESCE(@lastName, LastName),
                Photo                      = COALESCE(Photo, @photo,
                                               'bundle://avatar-' + CAST(CAST(RAND() * 50 AS INT) AS NVARCHAR(2))),
                ThirdPartyLoginType        = @thirdPartyLoginType,
                ThirdPartyUserId           = @thirdPartyUserId,
                ThirdPartyAccessToken      = @thirdPartyAccessToken,
                ThirdPartyAuthorizationCode= @thirdPartyAuthorizationCode,
                ThirdPartyTokenLastUpdated = GETDATE(),
                ThirdPartyAccessTokenExpires = COALESCE(@thirdPartyAccessTokenExpires, '2100-01-01'),
                ThirdPartyEmail            = @thirdPartyEmail,
                FacebookId                 = CASE WHEN @thirdPartyLoginType = 'facebook' THEN @thirdPartyUserId    ELSE NULL END,
                FacebookAccessToken        = CASE WHEN @thirdPartyLoginType = 'facebook' THEN @thirdPartyAccessToken ELSE NULL END,
                FacebookAccessTokenLastUpdated = CASE WHEN @thirdPartyLoginType = 'facebook' THEN GETDATE() ELSE NULL END,
                Removed                    = 0,
                updatedAt                  = GETDATE()
            WHERE id = @resolvedUserId;
        END
        ELSE
        BEGIN
            -- Insert new hasher
            SET @resolvedUserId = NEWID();

            INSERT [HC].[Hasher]
                ([id], [FirstName], [LastName], [Email], [HashName], [Photo],
                 [NameDisplayPreference], [IncludeInGlobalHashDirectory],
                 [FacebookId], [FacebookAccessToken], [FacebookAccessTokenLastUpdated],
                 [ThirdPartyLoginType], [ThirdPartyUserId], [ThirdPartyAccessToken],
                 [ThirdPartyAuthorizationCode], [ThirdPartyTokenLastUpdated],
                 [ThirdPartyAccessTokenExpires], [ThirdPartyEmail],
                 [Preferences], [HomeLatitude], [HomeLongitude], [updatedAt])
            VALUES
                (@resolvedUserId,
                 COALESCE(@firstName, ''), COALESCE(@lastName, ''),
                 COALESCE(@email, @thirdPartyEmail, ''),
                 COALESCE(@hashName, ''),
                 COALESCE(@photo, 'bundle://avatar-' + CAST(CAST(RAND() * 50 AS INT) AS NVARCHAR(2))),
                 CASE WHEN @hashName IS NOT NULL THEN 1 ELSE 2 END,
                 COALESCE(@includeInGlobalHashDirectory, 0),
                 CASE WHEN @thirdPartyLoginType = 'facebook' THEN @thirdPartyUserId     ELSE NULL END,
                 CASE WHEN @thirdPartyLoginType = 'facebook' THEN @thirdPartyAccessToken ELSE NULL END,
                 CASE WHEN @thirdPartyLoginType = 'facebook' THEN GETDATE()              ELSE NULL END,
                 @thirdPartyLoginType, @thirdPartyUserId, @thirdPartyAccessToken,
                 @thirdPartyAuthorizationCode, GETDATE(),
                 COALESCE(@thirdPartyAccessTokenExpires, '2100-01-01'),
                 @thirdPartyEmail,
                 14 + @useUsaMiles,
                 @latitude, @longitude, GETDATE());
        END

        -- Sync Facebook token to any Kennel that uses this user's email as admin
        IF (@thirdPartyLoginType = 'facebook')
        BEGIN
            UPDATE HC.Kennel
            SET KennelFacebookToken            = @thirdPartyAccessToken,
                KennelFacebookTokenLastUpdated = GETDATE()
            WHERE KennelFacebookTokenUsername  = @email
               OR KennelFacebookTokenUsername  = @thirdPartyEmail;
        END

    COMMIT TRANSACTION;

    -- ---------------------------------------------------------------
    -- Verify user was created/found (safety check)
    -- ---------------------------------------------------------------
    DECLARE @verifiedUserId UNIQUEIDENTIFIER;
    SELECT TOP 1 @verifiedUserId = h.id
    FROM HC.Hasher h
    WHERE h.ThirdPartyUserId = @thirdPartyUserId
       OR h.Email = @email
       OR (h.ThirdPartyEmail IS NOT NULL AND h.ThirdPartyEmail = @thirdPartyEmail)
       OR h.Email = @thirdPartyEmail;

    IF (@verifiedUserId IS NULL)
    BEGIN
        SET @errorCode = 1905; SET @errorType = 9; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, string_1)
        VALUES (@errorId, @hcVersion, 'User account not created',
                'Failed to create or locate a user account via third party login.',
                @procName, '00000000-0000-0000-0000-000000000000', @thirdPartyEmail, @email);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Account creation failed' AS errorTitle,
               'There was a problem creating your account. Please contact connect@harriercentral.com.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- ---------------------------------------------------------------
    -- Success
    -- ---------------------------------------------------------------
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        h.id                         AS hasherId,
        h.Photo                      AS photo,
        h.DisplayName                AS displayName,
        h.Email                      AS email,
        h.ThirdPartyUserId           AS thirdPartyUserId,
        h.ThirdPartyLoginType        AS thirdPartyLoginType,
        h.ThirdPartyAccessToken      AS thirdPartyAccessToken,
        h.ThirdPartyAuthorizationCode AS thirdPartyAuthorizationCode,
        h.ThirdPartyTokenLastUpdated AS thirdPartyTokenLastUpdated,
        h.ThirdPartyAccessTokenExpires AS thirdPartyAccessTokenExpires,
        h.ThirdPartyEmail            AS thirdPartyEmail,
        h.FirstName                  AS firstName,
        h.HashName                   AS hashName,
        h.LastName                   AS lastName,
        h.NameDisplayPreference      AS dispPref,
        COALESCE(h.DisplayName, '')  AS dispName,
        h.QR_code                    AS qrCode,
        h.SupportCode                AS supportCode,
        h.QR_secret_code             AS qrSecretCode,
        h.ResetCode                  AS resetCode,
        h.IncludeInGlobalHashDirectory AS includeInGlobalHashDirectory,
        h.Preferences                AS preferences,
        h.updatedAt                  AS updatedAt,
        h.Removed                    AS removed
    FROM HC.Hasher h
    WHERE h.id = @verifiedUserId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1905; SET @errorType = 9; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
