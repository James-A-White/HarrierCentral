CREATE OR ALTER PROCEDURE [HC6].[nonApi_logPortalError]
    @errorName        NVARCHAR(500),
    @errorDescription NVARCHAR(MAX)  = NULL,
    @procName         NVARCHAR(500),
    @userId           UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logPortalError
-- Description: Inserts an HC6 portal error entry into HC.ErrorLog.
--   Called by PortalApiHC6.LogErrorAsync when an HC6 portal SP returns
--   Success = 0 in its error envelope.
-- Parameters:
--   @errorName        - Short error label.
--   @errorDescription - Full error description (nullable).
--   @procName         - SP name that raised the error.
--   @userId           - Device UUID stored as userId for audit trail
--                       (HC.ErrorLog.userId is UNIQUEIDENTIFIER).
-- Returns: Nothing. Fire-and-forget helper; errors swallowed by caller.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: PortalApiHC6.LogErrorAsync inline SQL
-- =====================================================================
SET NOCOUNT ON;

INSERT INTO HC.ErrorLog
    (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, createdAt, updatedAt)
VALUES
    (NEWID(), 'HC6-API', @errorName, @errorDescription, @procName, @userId,
     SYSUTCDATETIME(), SYSUTCDATETIME());
