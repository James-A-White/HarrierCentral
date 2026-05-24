CREATE OR ALTER PROCEDURE [HC6].[hcapp_logClientErrors]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @errorLog    NVARCHAR(MAX)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_logClientErrors
-- Description: Stores a session-level client error log in HC.ClientErrorLog.
--   The device must be registered in HC.Device, but the access token is NOT
--   validated — this mirrors hcapp_logAppError and allows the app to upload
--   logs even when token generation has itself failed.
--   The @accessToken parameter is accepted for API consistency but ignored.
-- Parameters:
--   @deviceId    - Registered device UUID (must exist in HC.Device)
--   @accessToken - Accepted but not validated (see description)
--   @errorLog    - Full session error log text (exception entries separated
--                  by newlines and '===' delimiters)
-- Returns:
--   Rowset 0: standard success envelope (success, errorCode, errorType)
--   On error: rowset 0 failure + rowset 1 standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-24
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName  NVARCHAR(128)    = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- Device-only validation: access token is intentionally not checked
DECLARE @userId UNIQUEIDENTIFIER;
SELECT @userId = d.UserId FROM HC.Device d WHERE d.id = @deviceId;

IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1392; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Device not registered',
            'Device not found for logClientErrors', @procName, NULL);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Device not registered' AS errorTitle,
           'The device is not registered. Please re-authorise the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        INSERT INTO HC.ClientErrorLog ([DeviceId], [ErrorLog])
        VALUES (@deviceId, @errorLog);

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1992; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
