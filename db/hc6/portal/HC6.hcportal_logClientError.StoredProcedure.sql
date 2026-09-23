CREATE OR ALTER PROCEDURE [HC6].[hcportal_logClientError]
    @deviceId         UNIQUEIDENTIFIER = NULL,
    @accessToken      NVARCHAR(1000)   = NULL,
    @errorName        NVARCHAR(500),
    @errorDescription NVARCHAR(MAX)    = NULL,
    @source           NVARCHAR(250)    = 'portal-client',
    @appVersion       NVARCHAR(50)     = NULL,
    @route            NVARCHAR(4000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_logClientError
-- Description: Where the Flutter portal reports what it could not
--   survive. Until 2026-09-23 the portal had NO client-side error
--   telemetry — no FlutterError.onError, no zone handler, nothing
--   shipped — so an exception there was seen by exactly one person.
--   The app writes its session log to HC.ClientErrorLog and the public
--   web writes to HC.ErrorLog through publicWeb_logWebError; this is the
--   portal's equivalent of the latter, into the same table the sweep and
--   the Usage Data dashboard already read.
--
--   Auth is ATTEMPTED, not required: a crash before sign-in is the one
--   most worth hearing about, and it has no token. An unauthenticated
--   report is accepted only from a device that exists, which stops the
--   endpoint being a free write into ErrorLog for anyone with the URL.
--   The client throttles itself (ClientErrorReporter, 20 per session).
-- Parameters: @deviceId/@accessToken (auth, optional), @errorName,
--   @errorDescription (stack), @source (which handler caught it),
--   @appVersion (portal version), @route (page the user was on)
-- Returns: rowset 0: Success/ErrorMessage envelope
-- Author: Harrier Central
-- Created: 2026-09-23
-- HC5 Source: none
-- Breaking Changes: none (new)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255);
DECLARE @hasherId  UNIQUEIDENTIFIER;
DECLARE @callerType INT;

IF (LEN(COALESCE(@errorName, N'')) = 0)
BEGIN
    SELECT 0 AS Success, 'errorName is required' AS ErrorMessage;
    RETURN;
END

-- Try to identify the caller; do not refuse the report if that fails.
IF (@deviceId IS NOT NULL AND @accessToken IS NOT NULL)
    EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL,
         @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

IF (@hasherId IS NULL)
BEGIN
    -- Unauthenticated: only a device we have issued may report.
    IF (@deviceId IS NULL OR NOT EXISTS (SELECT 1 FROM HC.Device WHERE id = @deviceId))
    BEGIN
        SELECT 0 AS Success, 'Unknown device' AS ErrorMessage;
        RETURN;
    END
END

BEGIN TRY
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId, string_1)
    VALUES (NEWID(),
            LEFT('portal ' + COALESCE(NULLIF(LTRIM(RTRIM(@appVersion)), ''), 'unknown'), 250),
            LEFT(@errorName, 250),
            LEFT(COALESCE(@errorDescription, ''), 2500),
            LEFT(COALESCE(NULLIF(LTRIM(RTRIM(@source)), ''), 'portal-client'), 250),
            @hasherId,
            LEFT(COALESCE(CAST(@deviceId AS NVARCHAR(50)), ''), 250),
            LEFT(COALESCE(@route, ''), 4000));

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- The logger failing is not something the logger can log. Return the
    -- envelope so the client knows, and stop there.
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
