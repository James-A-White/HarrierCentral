-- =====================================================================
-- Procedure: HC6.publicWeb_startDirectMessage
-- Description: The web member's door to hcapp_startDirectMessage (direct
--   messages, E9.F1.S7/S18/S19, 2026-09-29). Everything that decides
--   anything lives in the app SP; this wrapper adds nothing that could
--   drift from it.
-- Parameters: @deviceId, @accessToken (signed for hcapp_startDirectMessage),
--   the app SP's own
-- Returns: hcapp_startDirectMessage's rowsets
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_startDirectMessage]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @targetPublicHasherId UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_startDirectMessage @deviceId = @deviceId, @accessToken = @accessToken, @targetPublicHasherId = @targetPublicHasherId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_startDirectMessage', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
