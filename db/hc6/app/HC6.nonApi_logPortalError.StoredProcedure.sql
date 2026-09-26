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
--   @userId           - Despite the name, PortalApiHC6 passes the portal
--                       DEVICE id here (the public-web shims pass NULL).
--                       A device id is written to HC.ErrorLog.deviceId and
--                       its hasher to userId; anything else is kept as
--                       userId, as before.
-- Returns: Nothing. Fire-and-forget helper; errors swallowed by caller.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: PortalApiHC6.LogErrorAsync inline SQL
-- Changes:
--   - 2026-09-26: resolve a device id to its hasher. userId held the device
--     id, so a join to HC.Hasher found nobody and a portal error looked
--     anonymous (Kilty's duplicate-email errors, 2026-09-23, were read as
--     someone else's). Parameter name kept: the shim binds it by name.
-- =====================================================================
SET NOCOUNT ON;

DECLARE @deviceId NVARCHAR(250) = NULL;
DECLARE @hasherId UNIQUEIDENTIFIER = @userId;

SELECT @deviceId = CAST(d.id AS NVARCHAR(250)),
       @hasherId = d.UserId
FROM HC.Device d
WHERE d.id = @userId;

INSERT INTO HC.ErrorLog
    (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, createdAt, updatedAt)
VALUES
    (NEWID(), 'HC6-API', @errorName, @errorDescription, @procName, @hasherId, @deviceId,
     SYSUTCDATETIME(), SYSUTCDATETIME());
