CREATE OR ALTER PROCEDURE [HC6].[hcportal_getHcAdminPrivileges]

    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getHcAdminPrivileges
-- Description: Returns platform-admin privilege flags for the calling
--   user. Always returns exactly one row; all flags are 0 if the user
--   has no HC.PlatformAdmin row or has been removed.
-- Parameters: @deviceId, @accessToken
-- Returns:
--   On error: HC6 standard envelope (Success, ErrorMessage).
--   On success: single row { CanViewMonitor SMALLINT,
--                             CanManageNewsflash SMALLINT }.
-- Author: Harrier Central
-- Created: 2026-05-27
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

DECLARE @authError  NVARCHAR(255);
DECLARE @hasherId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF @callerType != 0
BEGIN
    SELECT 0 AS Success, 'Service accounts may not call this endpoint' AS ErrorMessage;
    RETURN;
END

SELECT
    COALESCE(pa.CanViewMonitor,    0) AS CanViewMonitor,
    COALESCE(pa.CanManageNewsflash, 0) AS CanManageNewsflash
FROM (SELECT 1 AS Dummy) AS base
LEFT OUTER JOIN HC.PlatformAdmin pa
    ON pa.UserId = @hasherId AND pa.removed = 0;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
