-- =====================================================================
-- Procedure: HC6.publicWeb_listDevices
-- Description: the web member's device list (E9.F7.S19), through the app's own hcapp_listDevices.
--   A write goes through the app's SP rather than being written twice —
--   see claude.md, "wrap for writes, query for screens". All the
--   authorization lives there; this wrapper adds none of its own that
--   could drift from the app's.
-- Parameters: @deviceId, @accessToken (signed for hcapp_listDevices)
-- Returns: hcapp_listDevices's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-20
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_listDevices]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_listDevices
        @deviceId    = @deviceId,
        @accessToken = @accessToken;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_listDevices',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
