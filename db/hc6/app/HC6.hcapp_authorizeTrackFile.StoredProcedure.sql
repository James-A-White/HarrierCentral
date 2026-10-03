CREATE OR ALTER PROCEDURE [HC6].[hcapp_authorizeTrackFile]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_authorizeTrackFile
-- Description: Identity check for the API's ParseTrackFile function
--   (E5.F6.S6): a hare reading a GPX/TCX/FIT file to make it a run's
--   official trail. The function only READS the file and hands the points
--   back — saving them is hcapp_setOfficialTrail, which does the
--   hare/admin check — so a signed-in device is all this asks.
-- Returns: rowset 0 — { success, userId } or the error envelope.
-- Author: Harrier Central
-- Created: 2026-10-03
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 149, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT 1 AS success, @userId AS userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in authorizeTrackFile', ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
