CREATE OR ALTER PROCEDURE [HC6].[hcapp_gdprDelete]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_gdprDelete
-- Description: Scrubs all PII from the calling user's Hasher record and
--   marks it Removed = 1. Replaces name, email, photo, and social IDs
--   with anonymous placeholders. Obfuscates SupportCode, ResetCode and
--   QR_code so they remain unique but reveal no original data. This
--   operation is irreversible.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): none
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_gdprDelete
-- Breaking Changes:
--   TRY/CATCH and transaction added (HC5 had neither).
--   QR_secret_code, ThirdPartyAuthorizationCode, ThirdPartyTokenLastUpdated
--     and ThirdPartyAccessTokenExpires now also nulled (HC5 missed these).
--   HomeGeolocation column removed (geography column not used in HC6).
--   If user is already removed, errorCode 1511 returned (HC5 silently
--     returned 'failed').
--   Success envelope added.
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
    @spNumber     = 11,
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

        -- All column refs in SET evaluate to pre-update values, so
        -- Email = ResetCode + '...' uses the original (un-prefixed) ResetCode.
        UPDATE HC.Hasher SET
            HomeKennelId                 = NULL,
            MotherKennelId               = NULL,
            SupportCode                  = '*' + SupportCode,
            ResetCode                    = '*' + ResetCode,
            QR_code                      = '*' + QR_code,
            QR_secret_code               = NEWID(),
            HashName                     = 'Deleted User',
            FirstName                    = 'Deleted',
            LastName                     = 'User',
            Email                        = ResetCode + '@harriercentral.com',
            Photo                        = 'bundle://avatar-0',
            FacebookId                   = NULL,
            FacebookAccessToken          = NULL,
            FacebookAccessTokenLastUpdated = NULL,
            ThirdPartyUserId             = NULL,
            ThirdPartyAccessToken        = NULL,
            ThirdPartyAuthorizationCode  = NULL,
            ThirdPartyEmail              = NULL,
            ThirdPartyLoginType          = 'none',
            ThirdPartyTokenLastUpdated   = NULL,
            ThirdPartyAccessTokenExpires = NULL,
            Description                  = NULL,
            HomeLatitude                 = NULL,
            HomeLongitude                = NULL,
            SingleSignOnId               = NULL,
            SingleSignOnType             = NULL,
            IsBetaTester                 = 0,
            Removed                      = 1,
            updatedAt                    = GETDATE()
        WHERE id = @userId AND Removed = 0;

        IF (@@ROWCOUNT = 0)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @errorCode = 1511; SET @errorType = 15; SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, '<unknown>', 'GDPR delete failed',
                    'User not found or already removed', @procName, @userId);
            SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
            SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                   'Delete failed' AS errorTitle,
                   'Your account could not be deleted. It may have already been removed. '
                   + 'Please contact connect@harriercentral.com for assistance.' AS errorUserMessage,
                   @procName AS errorProc;
            RETURN;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1911; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
