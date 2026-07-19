CREATE OR ALTER PROCEDURE [HC6].[hcapp_checkConnection]
AS
-- =====================================================================
-- Procedure: HC6.hcapp_checkConnection
-- Description: Unauthenticated end-to-end connectivity ping. Returns a
--   single hardcoded row to confirm the app can reach the database via
--   the API shim. No parameters, no auth, no side effects.
-- Parameters: None
-- Returns: Single row: result NVARCHAR = 'Connected'
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_checkConnection
-- Breaking Changes:
--   @deviceId and @accessToken parameters removed (were dead inputs in HC5).
-- =====================================================================
SET NOCOUNT ON;

-- Wrap the body so any runtime error is LOGGED to HC.ErrorLog before it reaches
-- the client, then re-raised (THROW) instead of vanishing as a raw HTTP 500.
BEGIN TRY

SELECT 'Connected' AS result;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in checkConnection',
            ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
