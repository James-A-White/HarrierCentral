CREATE OR ALTER PROCEDURE [HC6].[hcapp_logAppError]

    @deviceId   UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @httpBody   NVARCHAR(MAX) = NULL,
    @errorText  NVARCHAR(1000),
    @extraData  NVARCHAR(MAX) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_logAppError
-- Description: Records a client-side error in HC.AppError. The device
--   must be registered in HC.Device, but the access token is NOT
--   validated — this allows the app to log errors even when it cannot
--   generate a valid token (e.g. after a token generation failure).
--   The @accessToken parameter is accepted but ignored.
-- Parameters:
--   @deviceId    - Registered device UUID (must exist in HC.Device)
--   @accessToken - Accepted but not validated (see description)
--   @httpBody    - Optional HTTP request body captured at the time of error
--   @errorText   - The error message or exception text
--   @extraData   - Optional additional diagnostic data (JSON, stack trace, etc.)
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_logAppError
-- Breaking Changes:
--   Device existence is now validated (HC5 did no auth whatsoever).
--   TRY/CATCH added.
--   Success envelope added.
--   @accessToken parameter retained for API compatibility but ignored.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- Device-only validation: check device is registered (token NOT checked)
DECLARE @userId UNIQUEIDENTIFIER;
SELECT @userId = d.UserId FROM HC.Device d WHERE d.id = @deviceId;

IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1392; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Device not registered',
            'Device not found for logAppError', @procName, NULL);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Device not registered' AS errorTitle,
           'The device is not registered. Please re-authorise the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        INSERT INTO HC.AppError ([DeviceId], [HttpBody], [ErrorText], [ExtraData])
        VALUES (@deviceId, @httpBody, @errorText, @extraData);

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
