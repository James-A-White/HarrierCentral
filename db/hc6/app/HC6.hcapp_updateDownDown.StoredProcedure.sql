CREATE OR ALTER PROCEDURE [HC6].[hcapp_updateDownDown]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER,
    @eventId     UNIQUEIDENTIFIER,
    @downDownId  UNIQUEIDENTIFIER,
    @chargeText  NVARCHAR(MAX)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_updateDownDown
-- Description: Updates the charge text on an existing DownDown. Only
--   the original creator or a GM/RA for the kennel may edit.
--   The operation is scoped to @eventId + @kennelId for safety.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns the event (auth scope)
--   @eventId     - Event the DownDown belongs to (validation scope)
--   @downDownId  - DownDown to update
--   @chargeText  - New charge text
-- Returns:
--   On success (rowset 0): { success=1, errorCode=NULL, errorType=NULL }
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
-- HC5 Source: None — new feature
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
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
    @spNumber     = 58,
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

IF (@kennelId   IS NULL OR @kennelId   = '00000000-0000-0000-0000-000000000000'
 OR @eventId    IS NULL OR @eventId    = '00000000-0000-0000-0000-000000000000'
 OR @downDownId IS NULL OR @downDownId = '00000000-0000-0000-0000-000000000000'
 OR LEN(LTRIM(RTRIM(ISNULL(@chargeText, '')))) = 0)
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing parameter',
            '@kennelId, @eventId, @downDownId and @chargeText are all required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Auth: caller must be the original creator, or hold GM (0x02) | RA (0x08) for the kennel.
DECLARE @createdByUserId UNIQUEIDENTIFIER;
SELECT @createdByUserId = CreatedByUserId
FROM HC.DownDowns
WHERE id       = @downDownId
  AND EventId  = @eventId
  AND KennelId = @kennelId;

IF (@createdByUserId IS NULL)
BEGIN
    SET @errorCode = 4041; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'DownDown not found',
            'No DownDown matched @downDownId + @eventId + @kennelId', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Charge not found' AS errorTitle,
           'The charge could not be found. It may have been removed.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@createdByUserId <> @userId)
BEGIN
    DECLARE @mmRoleFlags INT = 0;
    SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
    FROM HC.HasherKennelMap
    WHERE UserId = @userId AND KennelId = @kennelId;

    IF (@mmRoleFlags & 0x0000000A = 0)
    BEGIN
        SET @errorCode = 1337; SET @errorType = 3; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<unknown>', 'Not authorised',
                'Caller is not the creator and lacks GM or RA role', @procName, @userId);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Not authorised' AS errorTitle,
               'You can only edit charges you created.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END

BEGIN TRY

    UPDATE HC.DownDowns
    SET ChargeText = @chargeText,
        UpdatedAt  = GETUTCDATE()
    WHERE id       = @downDownId
      AND EventId  = @eventId
      AND KennelId = @kennelId;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1933 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1933 AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
