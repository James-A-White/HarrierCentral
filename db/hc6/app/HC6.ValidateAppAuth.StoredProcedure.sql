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
DECLARE @signedOutAt DATETIMEOFFSET;

SELECT
    @userId       = d.UserId,
    @deviceSecret = d.DeviceSecret,
    @timeWindow   = d.TimeWindow,
    @signedOutAt  = d.SignedOutAt
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
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Device not registered', @errorMsg, @procName, NULL);
    RETURN;
END

-- Signed out deliberately (E9.F7.S19)
--
-- This MUST be tested before the token check, and must be its own error.
-- hcapp_signOutDevice rotates DeviceSecret, so the token would fail anyway
-- — but it would fail as errorType 1, which is also what a phone with a
-- drifting clock produces. The client wipes the install on THIS error and
-- must never wipe on that one, so the two cannot share a code.
--
-- SignedOutAt is written only by hcapp_signOutDevice. It is NOT the same
-- as `removed`: 300 devices carry removed = 1 and 46 of those signed in
-- within 90 days, so reading `removed` here would wipe the app for people
-- actively using it.
IF (@signedOutAt IS NOT NULL)
BEGIN
    SET @errorCode  = 1200 + @spNumber;
    SET @errorType  = 7;
    SET @errorId    = NEWID();
    SET @errorTitle = 'Signed out';
    SET @errorMsg   = 'This device was signed out of your Harrier Central account. Sign in again to carry on.';

    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Device signed out', @errorMsg, @procName, @userId);
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
    SET @errorMsg   = 'The access token is invalid. Please check that the clock on your phone is set automatically from Apple or Google.';

    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Invalid access token', @errorMsg, @procName, @userId);
    RETURN;
END
