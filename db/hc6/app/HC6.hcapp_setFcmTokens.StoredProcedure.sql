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

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1915; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
