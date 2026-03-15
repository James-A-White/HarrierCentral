CREATE OR ALTER PROCEDURE [HC6].[hcportal_updateFcmToken]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@fcmToken nvarchar(500) = NULL,
@buildNumber nvarchar(25) = NULL,
@version nvarchar(25) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_updateFcmToken
-- Description: Updates the FCM (Firebase Cloud Messaging) push
--   notification token for a device after the browser has refreshed
--   its token. Also updates device version, build number, and last
--   login timestamp.
-- Parameters: @deviceId, @publicHasherId (service account GUID),
--   @accessToken, @fcmToken, @buildNumber, @version
-- Returns: On error: HC6 envelope (Success, ErrorMessage). On success:
--   result = 'Success'
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_updateFcmToken
-- Breaking Changes: Re-enabled token validation (was commented
--   out in HC5). Fixed inverted GUID validation logic. Fixed wrong SP
--   name in GeneralLog ('hcportal_confirmAuthentication' ->
--   'hcportal_updateFcmToken'). Validation now short-circuits on first
--   error. Added TRY/CATCH and transaction around Device UPDATE.
--   - @fcmToken narrowed from NVARCHAR(1000) to NVARCHAR(500) to match
--     ValidatePortalAuth @paramString and typical FCM token length
--   - Added @deviceId null check (previously returned 'Success' silently on NULL)
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
    EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @fcmToken, @authError OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Validation: deviceId
    IF @deviceId IS NULL
    BEGIN
        SELECT 0 AS Success, 'deviceId is required' AS ErrorMessage;
        RETURN;
    END

    -- Update Device record
    BEGIN TRANSACTION;

    UPDATE HC.Device SET
        FcmToken = @fcmToken,
        [Version] = @version,
        [BuildNumber] = @buildNumber,
        [LastLogin] = GetDate()
    where id = @deviceId

    COMMIT TRANSACTION;

    SELECT 'Success' as result

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
