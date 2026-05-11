CREATE OR ALTER PROCEDURE [HC6].[hcapp_authenticateWebPortal]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @scanData    NVARCHAR(1000)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_authenticateWebPortal
-- Description: Records a device-authenticated QR code scan for web
--   portal login. The access token is validated against DeviceSecret
--   concatenated with @scanData, binding the token to this specific
--   scan event (single-use). If the scanData has not already been
--   recorded, inserts a row into HC.WebPortalAuthenticationRequests.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret + scanData
--   @scanData    - QR code scan data from the web portal login page
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): single row with result = 'Success'
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_authenticateWebPortal
-- Breaking Changes:
--   Standard HC6 error format replaces HC5 Pascal-cased non-standard format.
--   errorType 3 for device not found (was 2 in HC5).
--   errorType 1 for auth failure (was 1 in HC5 — unchanged but now standard).
--   Success envelope added.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- ---------------------------------------------------------------
-- Auth via ValidateAppAuth (compound param: deviceSecret + scanData)
-- ---------------------------------------------------------------
DECLARE @userId        UNIQUEIDENTIFIER;
DECLARE @deviceSecret  NVARCHAR(150);
DECLARE @timeWindow    INT;
DECLARE @authErrorCode INT;
DECLARE @authErrorType INT;
DECLARE @authErrorId   UNIQUEIDENTIFIER;
DECLARE @authErrorTitle NVARCHAR(500);
DECLARE @authErrorMsg  NVARCHAR(MAX);

-- Resolve device credentials first so we can build the compound param
SELECT @userId = d.UserId, @deviceSecret = d.DeviceSecret, @timeWindow = d.TimeWindow
FROM HC.Device d WHERE d.id = @deviceId;

IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @authErrorCode = 1304; SET @authErrorType = 3; SET @authErrorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@authErrorId, '<unknown>', 'Device not registered',
            'Device not found in HC.Device', @procName, NULL);
    SELECT 0 AS success, @authErrorCode AS errorCode, @authErrorType AS errorType;
    SELECT @authErrorId AS errorId, @authErrorType AS errorType, @authErrorCode AS errorCode,
           'Device not registered' AS errorTitle,
           'The device is not registered. Please re-authorise the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Token validated against DeviceSecret + scanData (event-bound, single-use)
DECLARE @tokenContext NVARCHAR(650) = @deviceSecret + @scanData;

IF HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, COALESCE(@accessToken, 'error'), @tokenContext, @timeWindow) = 0
BEGIN
    SET @authErrorCode = 1104; SET @authErrorType = 1; SET @authErrorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@authErrorId, '<unknown>', 'Invalid access token',
            'Access token failed validation', @procName, @userId);
    SELECT 0 AS success, @authErrorCode AS errorCode, @authErrorType AS errorType;
    SELECT @authErrorId AS errorId, @authErrorType AS errorType, @authErrorCode AS errorCode,
           'Invalid access token' AS errorTitle,
           'The access token is invalid. Please restart the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Write (idempotent — only insert if this scanData not already present)
-- ---------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1 FROM HC.WebPortalAuthenticationRequests WHERE scanData = @scanData
        )
        BEGIN
            INSERT HC.WebPortalAuthenticationRequests (hasherId, scanData)
            VALUES (@userId, @scanData);
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT 'Success' AS result;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1904; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
