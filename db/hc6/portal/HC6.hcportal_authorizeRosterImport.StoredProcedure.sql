CREATE OR ALTER PROCEDURE [HC6].[hcportal_authorizeRosterImport]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_authorizeRosterImport
-- Description: The gate for "Import from file" (E2.F2.S6, James
--   2026-10-10). The RosterImport API endpoint calls this before it reads
--   the file or spends anything on the AI: the caller must be allowed to
--   add members to the kennel — the same gate as hcportal_bulkAddHashers,
--   which the grid saves through afterwards. Reads only.
-- Returns: { Success, ErrorMessage, kennelId, kennelShortName, adminId }
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @userId UNIQUEIDENTIFIER, @callerType INT;
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @userId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage, NULL AS kennelId, NULL AS kennelShortName, NULL AS adminId;
    RETURN;
END

BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER, @short NVARCHAR(100);
    SELECT @kennelId = k.id, @short = k.KennelShortName FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId;
    IF (@kennelId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No kennel with that id.' AS ErrorMessage, NULL AS kennelId, NULL AS kennelShortName, NULL AS adminId;
        RETURN;
    END
    IF (ISNULL((SELECT hkm.AppAccessFlags FROM HC.HasherKennelMap hkm WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId), 0) & 0x40000081) = 0
    BEGIN
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
        VALUES (NEWID(), '<portal>', 'Not authorised', 'Caller may not add members to this kennel', @procName, @userId, @kennelId);
        SELECT 0 AS Success, 'You are not authorised to add members to this kennel.' AS ErrorMessage, NULL AS kennelId, NULL AS kennelShortName, NULL AS adminId;
        RETURN;
    END
    SELECT 1 AS Success, NULL AS ErrorMessage, LOWER(CAST(@kennelId AS NVARCHAR(40))) AS kennelId,
           @short AS kennelShortName, LOWER(CAST(@userId AS NVARCHAR(40))) AS adminId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_authorizeRosterImport', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS Success, 'Please try again.' AS ErrorMessage, NULL AS kennelId, NULL AS kennelShortName, NULL AS adminId;
END CATCH
