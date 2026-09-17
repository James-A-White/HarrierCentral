CREATE OR ALTER PROCEDURE [HC6].[hcapp_setFcmTokens]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @apnsToken   NVARCHAR(500) = NULL,
    @fcmToken    NVARCHAR(500) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setFcmTokens
-- Description: Updates the Apple Push Notification (APNS) and Firebase
--   Cloud Messaging (FCM) tokens for the calling device. Called after
--   the OS grants or refreshes notification permissions. @apnsToken is
--   NULL for Android devices.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @apnsToken   - Apple Push Notification token (NULL for Android)
--   @fcmToken    - Firebase Cloud Messaging token (NULL if not available)
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success: no additional rowset
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_setFcmTokens
-- Breaking Changes:
--   TRY/CATCH added (HC5 had none).
--   Success envelope replaces HC5 'Success'/'Failed' string result.
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
    @spNumber     = 15,
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

-- This device's own identity, read once for the scoped clearing below.
DECLARE @idfv    NVARCHAR(100);
DECLARE @isApple SMALLINT;
SELECT @idfv    = JSON_VALUE(CAST(d.DeviceData AS NVARCHAR(MAX)), '$.identifierForVendor'),
       @isApple = CASE WHEN d.OperatingSystem IN ('iOS', 'iPadOS') THEN 1 ELSE 0 END
FROM HC.Device d
WHERE d.id = @deviceId;

BEGIN TRY
    BEGIN TRANSACTION;

        UPDATE HC.Device SET
            ApnsToken        = @apnsToken,
            FcmToken         = @fcmToken,
            -- Stamp FcmTokenCreatedAt when a fresh token arrives; clear FcmTokenDeleted
            -- to show the token trail: deleted < created means a new token replaced a stale one.
            FcmTokenCreatedAt = CASE WHEN @fcmToken IS NOT NULL THEN SYSUTCDATETIME() ELSE FcmTokenCreatedAt END,
            FcmTokenDeleted   = CASE WHEN @fcmToken IS NOT NULL THEN NULL              ELSE FcmTokenDeleted   END
        WHERE id = @deviceId;

        -- ---------------------------------------------------------------
        -- Retire the same DEVICE's older rows (2026-09-17). A hasher
        -- accumulates HC.Device rows because re-authorisation mints a new
        -- one whenever the stored device id is lost, and every old row kept
        -- a live token: one hasher was receiving 43 copies of one chat
        -- message. Clearing is scoped to the same physical device, never to
        -- the hasher — an admin registering her browser must not silence
        -- her phone, and two phones must not silence each other (James,
        -- 2026-09-17).
        -- ---------------------------------------------------------------
        IF (@fcmToken IS NOT NULL)
        BEGIN
            -- (a) The same token STRING. Firebase mints one per app install
            -- per device, so an identical string on another row is by
            -- definition the same install. Deliberately not scoped to the
            -- hasher: if someone else signed in on this handset before, the
            -- install is ours now and must not keep receiving theirs.
            UPDATE HC.Device
            SET FcmToken        = NULL,
                FcmTokenDeleted = SYSUTCDATETIME()
            WHERE FcmToken = @fcmToken
              AND id      <> @deviceId;

            -- (b) Apple only: identifierForVendor is stable for this app on
            -- this device, so an older row of the SAME hasher carrying the
            -- SAME identifier is this very phone under a re-minted device
            -- id. Android is excluded on purpose — its payload carries only
            -- the build fingerprint, manufacturer and model, identical
            -- across two handsets of one model, so matching on it would
            -- silence a second phone. Browsers carry no such identifier.
            IF (@idfv IS NOT NULL AND @isApple = 1)
                UPDATE d
                SET d.FcmToken        = NULL,
                    d.FcmTokenDeleted = SYSUTCDATETIME()
                FROM HC.Device d
                WHERE d.id      <> @deviceId
                  AND d.UserId   = @userId
                  AND d.FcmToken IS NOT NULL
                  AND d.OperatingSystem IN ('iOS', 'iPadOS')
                  AND JSON_VALUE(CAST(d.DeviceData AS NVARCHAR(MAX)), '$.identifierForVendor') = @idfv;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1915; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
