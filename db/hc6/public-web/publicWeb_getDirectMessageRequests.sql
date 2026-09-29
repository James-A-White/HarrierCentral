-- =====================================================================
-- Procedure: HC6.publicWeb_getDirectMessageRequests
-- Description: The web member's door to hcapp_getDirectMessageRequests (direct
--   messages, E9.F1.S7/S18/S19, 2026-09-29). Everything that decides
--   anything lives in the app SP; this wrapper adds nothing that could
--   drift from it.
-- Parameters: @deviceId, @accessToken (signed for hcapp_getDirectMessageRequests)
--   the app SP's own
-- Returns: hcapp_getDirectMessageRequests's rowsets
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getDirectMessageRequests]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
    
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_getDirectMessageRequests @deviceId = @deviceId, @accessToken = @accessToken ;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getDirectMessageRequests', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
