-- =====================================================================
-- Procedure: HC6.publicWeb_deletePasskey
-- Description: Removes one of the web member's passkeys (E9.F7.S18)
--   through the app's own hcapp_deletePasskey. All the authorization
--   lives there — the hasher comes from the token and the UPDATE is
--   scoped to them — so this wrapper deliberately adds no checks of its
--   own that could drift from the app's.
--
--   A browser removing ITS OWN passkey stays signed in: the device row
--   and its secret survive, only the credential goes.
-- Parameters: @deviceId, @accessToken (signed for hcapp_deletePasskey),
--             @targetDeviceId — the device whose passkey to remove
-- Returns: hcapp_deletePasskey's envelope and remaining-passkey rowset
-- Author: Harrier Central
-- Created: 2026-09-20
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_deletePasskey]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @targetDeviceId UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    EXEC HC6.hcapp_deletePasskey
        @deviceId       = @deviceId,
        @accessToken    = @accessToken,
        @targetDeviceId = @targetDeviceId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_deletePasskey',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    THROW;
END CATCH
