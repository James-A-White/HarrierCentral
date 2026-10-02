CREATE OR ALTER PROCEDURE [HC6].[hcapp_getDirectoryVisibility]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getDirectoryVisibility
-- Description: Who may find the caller in hasher search (E9.F1.S26), so
--   the app knows at launch whether to ask. NOT synced to any phone: the
--   answer is the caller's own and reaches nobody else's device.
-- Returns: rowset 0 — { DirectoryVisibility } (NULL = not asked yet;
--   low bits 0 nobody, 1 people I have run with, 2 members of a kennel I
--   belong to, 3 anyone; + 16 = may also be found by real name)
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 141, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT h.DirectoryVisibility FROM HC.Hasher h WHERE h.id = @userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getDirectoryVisibility',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
