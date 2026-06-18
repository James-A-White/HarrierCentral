CREATE OR ALTER PROCEDURE [HC6].[nonApi_logError]
    @errorType NVARCHAR(250) = '<unknown>',
    @message   NVARCHAR(2500) = '<unknown>',
    @location  NVARCHAR(250) = '<unknown>',
    @inputText NVARCHAR(1000) = '<unknown>'
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logError
-- Description: Inserts an error entry into HC.ErrorLog. Called directly
--   by name from EmailInviteCode when an invite-code lookup fails.
-- Parameters:
--   @errorType - Exception type name or short error label.
--   @message   - Exception message or full error description.
--   @location  - Method or SP where the error was caught.
--   @inputText - Input value relevant to the error (email, hasher ID, etc.)
-- Returns: Nothing. Fire-and-forget helper.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_logError
-- Breaking Changes vs HC5:
--   @errorCode, @string_2, @string_3, @string_4 parameters removed —
--   no HC6 caller uses them and they were only needed for the
--   HcExternalDataIntegration Facebook token-refresh side effect
--   (errorCode = 30010), which belongs to that component, not here.
--   INFO-type filter removed — HC6 callers should not use this SP for
--   informational logging (use LOG.GeneralLog for that).
-- =====================================================================
SET NOCOUNT ON;

INSERT INTO HC.ErrorLog
    (HcVersion, ErrorName, ErrorDescription, ProcName, string_1)
VALUES
    ('HC6-EmailInviteCode', @errorType, @message, @location, @inputText);
