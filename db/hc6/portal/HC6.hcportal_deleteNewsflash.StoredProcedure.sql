CREATE OR ALTER PROCEDURE [HC6].[hcportal_deleteNewsflash]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL,
    @newsflashId    UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_deleteNewsflash
-- Description: Soft-deletes a portal newsflash by setting IsDeleted = 1.
--              Associated HC.PortalNewsflashRead records are retained for
--              audit purposes. Once deleted the newsflash will no longer
--              be returned by hcportal_getPendingNewsflashes.
-- Parameters: @deviceId, @accessToken (auth)
--             @newsflashId — the newsflash to delete
-- Returns: Standard success envelope
-- Author: Harrier Central
-- Created: 2026-04-10
-- HC5 Source: n/a — new feature
-- Breaking Changes: n/a
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    IF @newsflashId IS NULL
    BEGIN
        SELECT 0 AS Success, 'newsflashId is required' AS ErrorMessage;
        RETURN;
    END

    -- Auth
    DECLARE @authError  NVARCHAR(255);
    DECLARE @hasherId   UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);

    EXEC HC6.ValidatePortalAuth
        @deviceId, @accessToken, @procName, NULL,
        @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 FROM HC.PortalNewsflash
        WHERE NewsflashId = @newsflashId AND IsDeleted = 0
    )
    BEGIN
        SELECT 0 AS Success, 'Newsflash not found' AS ErrorMessage;
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE HC.PortalNewsflash
    SET IsDeleted = 1,
        UpdatedAt = GETUTCDATE()
    WHERE NewsflashId = @newsflashId;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
