-- =====================================================================
-- Procedure: HC6.publicWeb_logWebError
-- Description: The public web's own errors, in the same HC.ErrorLog every
--   other component writes to, so `tools/log_sweep.sh` and the portal's
--   Usage Data see them without learning a new place to look. Until now a
--   Next.js failure only ever reached console.error, which on App Service
--   means nobody reads it (E16.F3).
--
--   Deliberately NOT behind ValidateAppAuth: the most valuable errors are
--   the ones from a visitor with no session at all, and a crashing page
--   cannot be asked to prove who it is. The guard is instead that this is
--   reachable only through PublicWebAdminApi, which requires the internal
--   secret, so only our own server can write here.
--
-- Parameters: @source  — the route or component that failed (ProcName)
--             @message — one line, what went wrong (ErrorName)
--             @detail  — stack or context (ErrorDescription, 2500)
--             @version — the web build, e.g. 'web 0.21.63' (HcVersion)
--             @url     — the page or endpoint (string_1)
--             @userId / @deviceId — when a member session was present
-- Returns: rowset 0 standard envelope
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_logWebError]
    @source   NVARCHAR(250),
    @message  NVARCHAR(250),
    @detail   NVARCHAR(MAX)  = NULL,
    @version  NVARCHAR(250)  = NULL,
    @url      NVARCHAR(MAX)  = NULL,
    @userId   UNIQUEIDENTIFIER = NULL,
    @deviceId NVARCHAR(250)  = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, string_1)
    VALUES (NEWID(),
            LEFT(COALESCE(NULLIF(LTRIM(RTRIM(@version)), ''), 'web'), 250),
            LEFT(COALESCE(NULLIF(LTRIM(RTRIM(@message)), ''), 'Unhandled web error'), 250),
            LEFT(COALESCE(@detail, ''), 2500),
            LEFT(COALESCE(NULLIF(LTRIM(RTRIM(@source)), ''), 'public-web'), 250),
            @userId,
            LEFT(COALESCE(@deviceId, ''), 250),
            LEFT(COALESCE(@url, ''), 4000));

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    -- Logging must never be the thing that breaks a page: swallow and report.
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
