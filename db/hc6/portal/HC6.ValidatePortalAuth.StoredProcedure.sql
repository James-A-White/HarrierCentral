CREATE OR ALTER PROCEDURE [HC6].[ValidatePortalAuth]
    @publicHasherId     UNIQUEIDENTIFIER,
    @accessToken        NVARCHAR(1000),
    @contextId          UNIQUEIDENTIFIER = NULL,
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
--   @contextId       - Optional context passed to CHECK_PORTAL_ACCESS_TOKEN
--                      (typically @publicKennelId or NULL)
--   @errorMessage    - OUTPUT: NULL on success, error description on failure
-- Returns: Nothing. Caller checks @errorMessage OUTPUT parameter.
-- Author: Harrier Central
-- Created: 2026-03-15
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
SET @tokenResult = HC.CHECK_PORTAL_ACCESS_TOKEN(@publicHasherId, OBJECT_NAME(@@PROCID), @accessToken, @contextId);

IF @tokenResult != 1
BEGIN
    SET @errorMessage = 'Authentication failed';
    RETURN;
END

-- Auth passed
RETURN;
