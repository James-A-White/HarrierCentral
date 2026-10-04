CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunForPhone]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunForPhone
-- Description: ONE run, in the phone's events-table shape (HC6.EventsForPhone),
--   so the app can store and open a run that is not on the phone without
--   following its kennel (James, 2026-10-04: "is there a way to load just
--   that one run?"). The user sync carries only ten days of the runs of
--   kennels a hasher does not follow; the kennel trail map shows them all.
--   Only visible, non-deleted runs — the same runs the public web shows.
-- Returns: rowset 0 — the run's events row (first column eventId, which the
--   app's sync writer recognises), or no row when there is no such run.
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 150, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT f.*
    FROM HC6.EventsForPhone() f
    JOIN HC.Event e ON e.id = f.eventId
    WHERE e.id = @eventId
      AND e.deleted = 0
      AND e.IsVisible = 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getRunForPhone',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
