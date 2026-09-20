-- =====================================================================
-- Procedure: HC6.publicWeb_signOutDevice
-- Description: signing one device out (E9.F7.S19), through the app's own hcapp_signOutDevice.
--   A write goes through the app's SP rather than being written twice —
--   see claude.md, "wrap for writes, query for screens". All the
--   authorization lives there; this wrapper adds none of its own that
--   could drift from the app's.
-- Parameters: @deviceId, @accessToken (signed for hcapp_signOutDevice)
-- Returns: hcapp_signOutDevice's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-20
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_signOutDevice]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @targetDeviceId UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_signOutDevice
        @deviceId    = @deviceId,
        @accessToken = @accessToken,
        @targetDeviceId = @targetDeviceId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_signOutDevice',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
