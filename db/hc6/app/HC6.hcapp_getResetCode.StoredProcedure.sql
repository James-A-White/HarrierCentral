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
--   assisted device re-authorisation. Any authenticated user may call
--   this endpoint — the SupportCode is not a secret.
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
    VALUES (@errorId, '<unknown>', 'Support code not found',
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
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcapp_getResetCode',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
