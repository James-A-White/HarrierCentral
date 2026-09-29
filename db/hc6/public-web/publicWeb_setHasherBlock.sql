-- =====================================================================
-- Procedure: HC6.publicWeb_setHasherBlock
-- Description: The web member's door to hcapp_setHasherBlock (E9.F1.S16/S17,
--   2026-09-29). Everything that decides anything lives in the app SP, so
--   this wrapper adds no checks that could drift from the app's.
-- Parameters: @deviceId, @accessToken (signed for hcapp_setHasherBlock),
--   the app SP's own
-- Returns: hcapp_setHasherBlock's rowsets
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setHasherBlock]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @targetPublicHasherId UNIQUEIDENTIFIER = NULL,
    @blocked SMALLINT = 1
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_setHasherBlock @deviceId = @deviceId, @accessToken = @accessToken, @targetPublicHasherId = @targetPublicHasherId, @blocked = @blocked;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_setHasherBlock', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
