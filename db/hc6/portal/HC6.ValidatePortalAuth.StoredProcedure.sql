CREATE OR ALTER PROCEDURE [HC6].[ValidatePortalAuth]
    @deviceId           UNIQUEIDENTIFIER,
    @accessToken        NVARCHAR(1000),
    @callerProcName     NVARCHAR(100),
    @callerParamString  NVARCHAR(500) = NULL,
    @errorMessage       NVARCHAR(255) OUTPUT,
    @hasherId           UNIQUEIDENTIFIER OUTPUT,
    @callerType         INT OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.ValidatePortalAuth
-- Description: Shared auth validation for all HC6 portal SPs.
--              Looks up the device secret and associated hasher from
--              HC.Device, determines caller type (regular user vs service
--              account), builds the token param string, then validates
--              the access token via HC6.CHECK_PORTAL_ACCESS_TOKEN.
--              Returns @hasherId and @callerType as OUTPUT parameters
--              for use by the calling SP.
-- Parameters:
--   @deviceId          - The device ID used to look up the shared secret
--                        and associated hasher (HC.Device.id)
--   @accessToken       - Short-lived cryptographic token
--   @callerProcName    - Caller MUST pass OBJECT_NAME(@@PROCID). The SP name
--                        is baked into the token hash on the Flutter client
--                        side and must match exactly for validation to succeed.
--   @callerParamString - Optional context string also baked into the token
--                        hash on the client side. Pass NULL when no additional
--                        context is used.
--   @errorMessage      - OUTPUT: NULL on success, error description on failure
--   @hasherId          - OUTPUT: HC.Hasher.id of the authenticated user
--   @callerType        - OUTPUT: 0=regular user, 1=HashRuns.org service account,
--                        2=admin portal service account
-- Returns: Nothing. Caller checks @errorMessage OUTPUT parameter.
-- Author: Harrier Central
-- Created: 2026-03-15
-- Breaking Changes vs original (single-SP inline auth):
--   - @publicHasherId replaced with @deviceId (device-bound auth)
--   - @hasherId OUTPUT added: callers no longer resolve hasher from publicHasherId
--   - @callerType OUTPUT added: callers no longer need GUID comparisons for service accounts
--   - @paramString renamed to @callerParamString (same semantics, clearer name)
--   - Token validation now calls HC6.CHECK_PORTAL_ACCESS_TOKEN (device-first)
--     instead of HC.CHECK_PORTAL_ACCESS_TOKEN
--   - @callerProcName added: each SP must pass OBJECT_NAME(@@PROCID) so
--     the correct SP name is used in token validation (not 'ValidatePortalAuth')
-- Prerequisites:
--   - HC6.CHECK_PORTAL_ACCESS_TOKEN scalar function must exist
--   - HC.Device rows must be pre-seeded for service account hashers
--     (11111111-1111-1111-1111-111111111111 and 22222222-2222-2222-2222-222222222222)
-- =====================================================================

SET NOCOUNT ON;
SET @errorMessage = NULL;
SET @hasherId = NULL;
SET @callerType = NULL;

-- Validate deviceId is present
IF @deviceId IS NULL
BEGIN
    SET @errorMessage = 'deviceId is required';
    RETURN;
END

-- Look up device secret and associated hasher
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @publicHasherId UNIQUEIDENTIFIER;

SELECT
    @deviceSecret = d.SharedSecret,
    @hasherId = h.id,
    @publicHasherId = h.PublicHasherId
FROM HC.Device d
INNER JOIN HC.Hasher h ON h.id = d.HasherId
WHERE d.id = @deviceId;

IF @hasherId IS NULL
BEGIN
    SET @errorMessage = 'Authentication failed';
    RETURN;
END

-- Determine caller type from publicHasherId
SET @callerType = CASE
    WHEN @publicHasherId = '11111111-1111-1111-1111-111111111111' THEN 1
    WHEN @publicHasherId = '22222222-2222-2222-2222-222222222222' THEN 2
    ELSE 0
END;

-- Build param string: prepend UPPER(deviceSecret) to callerParamString
DECLARE @paramString NVARCHAR(650);
SET @paramString = UPPER(@deviceSecret) + COALESCE(CAST(@callerParamString AS NVARCHAR(500)), '');

-- Validate access token
DECLARE @tokenResult INT;
SET @tokenResult = HC6.CHECK_PORTAL_ACCESS_TOKEN(@deviceId, @callerProcName, @accessToken, @paramString);

IF @tokenResult != 1
BEGIN
    SET @errorMessage = 'Authentication failed';
    RETURN;
END

-- Auth passed
RETURN;
