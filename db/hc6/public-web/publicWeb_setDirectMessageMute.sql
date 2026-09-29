-- =====================================================================
-- Procedure: HC6.publicWeb_setDirectMessageMute
-- Description: The web member's door to hcapp_setDirectMessageMute (direct
--   messages, E9.F1.S7/S18/S19, 2026-09-29). Everything that decides
--   anything lives in the app SP; this wrapper adds nothing that could
--   drift from it.
-- Parameters: @deviceId, @accessToken (signed for hcapp_setDirectMessageMute),
--   the app SP's own
-- Returns: hcapp_setDirectMessageMute's rowsets
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setDirectMessageMute]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @threadId UNIQUEIDENTIFIER = NULL,
    @mute SMALLINT = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_setDirectMessageMute @deviceId = @deviceId, @accessToken = @accessToken, @threadId = @threadId, @mute = @mute;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_setDirectMessageMute', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
GO
