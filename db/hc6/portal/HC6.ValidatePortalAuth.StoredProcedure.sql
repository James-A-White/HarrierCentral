CREATE OR ALTER PROCEDURE [HC6].[ValidatePortalAuth]
    @publicHasherId     UNIQUEIDENTIFIER,
    @accessToken        NVARCHAR(1000),
    @callerProcName     NVARCHAR(100),
    @paramString        NVARCHAR(500) = NULL,
    @errorMessage       NVARCHAR(255) OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.ValidatePortalAuth
-- Description: Shared auth validation for all HC6 portal SPs.
--              Validates publicHasherId is not null, then checks the
--              access token via HC.CHECK_PORTAL_ACCESS_TOKEN.
-- Parameters:
--   @publicHasherId  - The user's public hasher ID (or service account GUID)
--   @accessToken     - Short-lived cryptographic token
--   @callerProcName  - Caller MUST pass OBJECT_NAME(@@PROCID). The SP name
--                      is baked into the token hash on the Flutter client
--                      side and must match exactly for validation to succeed.
--   @paramString     - Optional context string also baked into the token
--                      hash on the client side. Must match exactly what
--                      Flutter passed to generateToken() as paramString.
--                      Pass NULL when no additional context is used.
--   @errorMessage    - OUTPUT: NULL on success, error description on failure
-- Returns: Nothing. Caller checks @errorMessage OUTPUT parameter.
-- Author: Harrier Central
-- Created: 2026-03-15
-- Breaking Changes vs original (single-SP inline auth):
--   - @callerProcName added: each SP must pass OBJECT_NAME(@@PROCID) so
--     the correct SP name is used in token validation (not 'ValidatePortalAuth')
--   - @contextId renamed to @paramString (NVARCHAR(500)) to match Flutter
--     generateToken() parameter naming and accept non-GUID values
-- Notes:
--   Service account GUIDs (11111111-... and 22222222-...) are valid
--   publicHasherIds and will pass the NULL check. The token function
--   handles service account validation internally.
--
--   SP-specific authorization (e.g., permission bitmask checks) should
--   be done by the calling SP after this procedure returns success.
-- =====================================================================

SET NOCOUNT ON;
SET @errorMessage = NULL;

-- Validate publicHasherId is present
IF @publicHasherId IS NULL
BEGIN
    SET @errorMessage = 'publicHasherId is required';
    RETURN;
END

-- Validate access token
DECLARE @tokenResult INT;
SET @tokenResult = HC.CHECK_PORTAL_ACCESS_TOKEN(@publicHasherId, @callerProcName, @accessToken, @paramString);

IF @tokenResult != 1
BEGIN
    SET @errorMessage = 'Authentication failed';
    RETURN;
END

-- Auth passed
RETURN;
