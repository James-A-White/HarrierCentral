CREATE OR ALTER PROCEDURE [HC6].[hcapp_getResetCode]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @supportCode NVARCHAR(250)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getResetCode
-- Description: Returns the ResetCode (invite/QR code) for the Hasher
--   identified by the given SupportCode. The SupportCode is a short
--   numeric code visible on the user's profile and used for admin-
--   assisted device re-authorisation. Platform admins only (HC.PlatformAdmin,
--   2026-10-13; errorCode 1312) — until then any authenticated user could
--   call it, and the reset code it returns signs a phone in as that user.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @supportCode - HC.Hasher.SupportCode value for the target user
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): single row with resetCode NVARCHAR(250)
--   On not found (rowset 0): standard HC6 error detail
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getResetCode
-- Breaking Changes:
--   @supportCode widened NVARCHAR(1000) → NVARCHAR(250) to match column.
--   On not found, standard HC6 error rowset returned instead of HC5's
--     'Support code not found' string result.
--   Removed users are now excluded (HC5 returned the code even for
--     removed users).
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
    @spNumber     = 13,
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
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Platform admins only (2026-10-13). A reset code signs a phone in as its
-- owner, so this lookup is an account takeover in the wrong hands. It was
-- open to every signed-in device; the support code is the only thing that
-- stood in the way, and a hasher can be talked into reading theirs out.
IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @userId AND pa.removed = 0)
BEGIN
    SET @errorCode = 1312; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised to look up reset codes',
            'Caller is not a platform admin', @procName, @userId, @supportCode);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'Only Harrier Central support can look up reset codes.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY

DECLARE @resetCode NVARCHAR(250);

SELECT TOP 1 @resetCode = h.ResetCode
FROM HC.Hasher h
WHERE h.SupportCode = @supportCode
  AND h.Removed = 0;

IF (@resetCode IS NULL)
BEGIN
    SET @errorCode = 1313; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Support code not found',
            'No active user found for support code: ' + COALESCE(@supportCode, ''),
            @procName, @userId, @supportCode);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Support code not found' AS errorTitle,
           'No active account was found for that support code.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

SELECT @resetCode AS resetCode;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getResetCode',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
