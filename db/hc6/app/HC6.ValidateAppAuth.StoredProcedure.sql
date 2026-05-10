CREATE OR ALTER PROCEDURE [HC6].[ValidateAppAuth]
    @deviceId     UNIQUEIDENTIFIER,
    @accessToken  NVARCHAR(1000),
    @procName     NVARCHAR(128),
    @spNumber     INT,
    @param        NVARCHAR(500)    = NULL,
    @userId       UNIQUEIDENTIFIER OUTPUT,
    @deviceSecret NVARCHAR(150)    OUTPUT,
    @timeWindow   INT              OUTPUT,
    @errorCode    INT              OUTPUT,
    @errorType    INT              OUTPUT,
    @errorId      UNIQUEIDENTIFIER OUTPUT,
    @errorTitle   NVARCHAR(500)    OUTPUT,
    @errorMsg     NVARCHAR(MAX)    OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.ValidateAppAuth
-- Description: Shared auth validation helper for all HC6 app SPs.
--              Resolves the calling user and device credentials from
--              HC.Device, then validates the access token via
--              HC.CHECK_ACCESS_TOKEN_V2. Returns userId, deviceSecret,
--              and timeWindow to the calling SP on success. On failure,
--              populates error OUTPUT parameters for the calling SP to
--              emit standard error rowsets.
-- Parameters:
--   @deviceId     - Device UUID from HC.Device.id
--   @accessToken  - Short-lived cryptographic token from the app
--   @procName     - Caller MUST pass OBJECT_NAME(@@PROCID). Baked into
--                   the token hash on the client side.
--   @spNumber     - Two-digit SP number (e.g., 2 for hcapp_authorizeDevice).
--                   Used to compute errorCode: auth=1100+N, not found=1300+N.
--   @param        - Optional compound param string (e.g., deviceSecret +
--                   targetUserId). When provided, replaces @deviceSecret as
--                   the token validation context string. Mirrors HC5 behaviour.
--   @userId       - OUTPUT: HC.Hasher.id of the authenticated user
--   @deviceSecret - OUTPUT: HC.Device.DeviceSecret (stored uppercase)
--   @timeWindow   - OUTPUT: HC.Device.TimeWindow for token validation
--   @errorCode    - OUTPUT: NULL on success. Error code on failure.
--   @errorType    - OUTPUT: HC6 errorType code (1=auth, 3=not found)
--   @errorId      - OUTPUT: HC.ErrorLog GUID on failure
--   @errorTitle   - OUTPUT: Short error title on failure
--   @errorMsg     - OUTPUT: User-facing error message on failure
-- Returns: Nothing. Caller checks @errorCode OUTPUT; NULL = auth passed.
-- Author: Harrier Central
-- Created: 2026-05-10
-- =====================================================================
SET NOCOUNT ON;

SET @errorCode = NULL;
SET @userId       = NULL;
SET @deviceSecret = NULL;
SET @timeWindow   = NULL;
SET @errorId      = NULL;
SET @errorType    = NULL;
SET @errorTitle   = NULL;
SET @errorMsg     = NULL;

-- Resolve device → user credentials
SELECT
    @userId       = d.UserId,
    @deviceSecret = d.DeviceSecret,
    @timeWindow   = d.TimeWindow
FROM HC.Device d
WHERE d.id = @deviceId;

-- Device or user not found
IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode  = 1300 + @spNumber;
    SET @errorType  = 3;
    SET @errorId    = NEWID();
    SET @errorTitle = 'Device not registered';
    SET @errorMsg   = 'The device making this request is not registered. Please re-authorise the app.';

    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Device not registered', @errorMsg, @procName, NULL);
    RETURN;
END

-- Validate access token
DECLARE @tokenContext NVARCHAR(650) = COALESCE(@param, @deviceSecret);

IF HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, @accessToken, @tokenContext, @timeWindow) = 0
BEGIN
    SET @errorCode  = 1100 + @spNumber;
    SET @errorType  = 1;
    SET @errorId    = NEWID();
    SET @errorTitle = 'Invalid access token';
    SET @errorMsg   = 'The access token is invalid or has expired. Please restart the app.';

    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid access token', @errorMsg, @procName, @userId);
    RETURN;
END
