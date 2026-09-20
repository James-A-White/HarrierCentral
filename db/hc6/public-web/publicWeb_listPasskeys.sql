-- =====================================================================
-- Procedure: HC6.publicWeb_listPasskeys
-- Description: The web member's passkey list (E9.F7.S18), through the
--   app's own hcapp_listPasskeys. The browser is a device, so the same SP
--   answers for both clients and the list cannot drift between them.
--   The token is signed for hcapp_listPasskeys; this wrapper adds nothing
--   but the call.
-- Parameters: @deviceId, @accessToken (signed for hcapp_listPasskeys)
-- Returns: hcapp_listPasskeys's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-20
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_listPasskeys]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_listPasskeys @deviceId = @deviceId, @accessToken = @accessToken;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_listPasskeys',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
