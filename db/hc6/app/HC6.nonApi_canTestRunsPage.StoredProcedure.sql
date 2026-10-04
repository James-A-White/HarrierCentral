CREATE OR ALTER PROCEDURE [HC6].[nonApi_canTestRunsPage]
    @hasherId       UNIQUEIDENTIFIER = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_canTestRunsPage
-- Description: May this portal user test / import a kennel's runs page?
--   (the kennel editor's Test button, 2026-10-04). The API's RunsPageTest
--   has already validated the portal token (HC6.ValidatePortalAuth, bound to
--   the kennel); this is the permission: createEditRuns on that kennel, via
--   the shared HC6.CheckKennelPermission (a runs page writes runs).
-- Returns: rowset 0 — { KennelId, Allowed }
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER =
        (SELECT id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId AND deleted = 0);
    DECLARE @allowed SMALLINT = 0;
    IF (@kennelId IS NOT NULL AND @hasherId IS NOT NULL)
        EXEC HC6.CheckKennelPermission @userId = @hasherId, @kennelId = @kennelId,
             @functionKey = 'createEditRuns', @isHareOfEvent = 0, @allowed = @allowed OUTPUT;
    SELECT LOWER(CAST(@kennelId AS NVARCHAR(40))) AS KennelId, @allowed AS Allowed;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in canTestRunsPage', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    THROW;
END CATCH
GO
