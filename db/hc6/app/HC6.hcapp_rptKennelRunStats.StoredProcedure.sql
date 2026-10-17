CREATE OR ALTER PROCEDURE [HC6].[hcapp_rptKennelRunStats]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_rptKennelRunStats
-- Description: Returns run statistics for a kennel by delegating to the
--   HC6.nonApi_rptKennelRunStats helper after validating the device token.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel to report on
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): run statistics from HC6.nonApi_rptKennelRunStats
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_rptKennelRunStats
-- Breaking Changes: None.
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
    @spNumber     = 51,
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

-- Wrap the body so any runtime error is LOGGED to HC.ErrorLog before it reaches
-- the client, then re-raised (THROW) instead of vanishing as a raw HTTP 500.
-- Gate (2026-10-16, permissions audit): the report carries each hasher's
-- payments, and it had none — any signed-in hasher could run it for any
-- kennel. The app shows the button to run editors (KennelFeature
-- createEditRuns on the kennel page), so either right is accepted here;
-- whether run editors should see payment amounts is James's call.
DECLARE @mayEdit SMALLINT = 0, @mayPay SMALLINT = 0;
IF (@kennelId IS NOT NULL)
BEGIN
    EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'createEditRuns', @allowed = @mayEdit OUTPUT;
    IF (@mayEdit = 0)
        EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId, @functionKey = 'viewPaymentReport', @allowed = @mayPay OUTPUT;
END
IF (@mayEdit = 0 AND @mayPay = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised',
            CONCAT('rptKennelRunStats kennel=', COALESCE(CAST(@kennelId AS NVARCHAR(40)), 'null')), @procName, @userId);
    SELECT @errorId AS errorId, 13 AS errorType, 1340 AS errorCode,
           'Not authorised' AS errorTitle,
           'You do not have access to this kennel''s reports.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY

EXEC HC6.nonApi_rptKennelRunStats @kennelId = @kennelId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in rptKennelRunStats',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
