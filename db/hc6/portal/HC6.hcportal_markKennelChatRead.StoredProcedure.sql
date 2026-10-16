CREATE OR ALTER PROCEDURE [HC6].[hcportal_markKennelChatRead]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @kennelThread   SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcportal_markKennelChatRead
-- Description: Marks one of a kennel's two chat threads read for the portal user
--   (E9.F1.S33), through HC6.nonApi_markKennelChatRead — the same SP the
--   app's hcapp_markKennelChatRead uses.
-- Parameters: @publicKennelId (paramString '<deviceSecret>:<publicKennelId>'), @kennelThread.
-- Returns: { Success, ErrorMessage } — Success 1, or 0 with the reason.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none (new — the portal had no kennel chat; E9.F1.S33)
-- Breaking Changes: none (new)
-- Idempotency: set-state — writes the read mark to the thread's current maximum
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @authError NVARCHAR(255);
DECLARE @hasherId UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER, @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = k.id FROM HC.Kennel k
WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
IF (@kennelId IS NULL)
BEGIN
    SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    EXEC HC6.nonApi_markKennelChatRead
        @userId = @hasherId, @kennelId = @kennelId, @kennelThread = @kennelThread,
        @hcVersion = @hcv, @callerProcName = @procName,
        @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
        @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;
    SELECT CASE WHEN @errorCode IS NULL THEN 1 ELSE 0 END AS Success, @eMsg AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcv, 'Unhandled error in hcportal_markKennelChatRead', ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
