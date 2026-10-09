CREATE OR ALTER PROCEDURE [HC6].[hcapp_getMyEmailStatus]

    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getMyEmailStatus
-- Description: The signed-in hasher's OWN email delivery status (E19.F4),
--   so the app can ask for a new address when it is bouncing. Deliberately
--   not in the hashers sync rowset: that would push everybody's status to
--   every phone.
-- Returns: rowset 0 — email, emailStatus (0 Unknown, 1 OK, 2 Suspect,
--   3 Bounced), emailStatusChangedAt, emailBlocked
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT, @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName_self, @spNumber = 152, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT h.Email AS email, h.EmailStatus AS emailStatus, h.EmailStatusChangedAt AS emailStatusChangedAt, h.EmailBlocked AS emailBlocked
    FROM HC.Hasher h WHERE h.id = @userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getMyEmailStatus', ERROR_MESSAGE(), @procName_self, @userId);
    THROW;
END CATCH
