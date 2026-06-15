CREATE OR ALTER PROCEDURE [HC6].[nonApi_logPortalRequest]
    @logSource NVARCHAR(50),
    @message   NVARCHAR(255)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logPortalRequest
-- Description: Inserts a portal request audit entry into LOG.GeneralLog.
--   Called by PortalApiHC6 after every successful HC6 portal SP dispatch.
-- Parameters:
--   @logSource - Short source label, e.g. "Admin Portal: hcportal_X"
--                (caller truncates to LOG.GeneralLog.LogSource limit of 50).
--   @message   - IP address or request identifier
--                (LOG.GeneralLog.Message is NVARCHAR(255)).
-- Returns: Nothing. Fire-and-forget helper; errors swallowed by caller.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: PortalApiHC6.LogRequestAsync inline SQL
-- =====================================================================
SET NOCOUNT ON;

INSERT INTO LOG.GeneralLog (LogSource, Message, Timestamp)
VALUES (@logSource, @message, SYSUTCDATETIME());
