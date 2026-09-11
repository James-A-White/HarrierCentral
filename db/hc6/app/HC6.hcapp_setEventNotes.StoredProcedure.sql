CREATE OR ALTER PROCEDURE [HC6].[hcapp_setEventNotes]
    @deviceId                   UNIQUEIDENTIFIER,
    @accessToken                NVARCHAR(1000),
    @eventId                    UNIQUEIDENTIFIER,
    @notes                      NVARCHAR(4000),
    @hasherEventMapUpdatedAfter NVARCHAR(50)
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setEventNotes
-- Description: The hasher's own private notes on a run (E3.F4.S5). Writes
--   Notes on their attendance row for @eventId (blank clears it), then hands
--   back the changed row through the user sync so every device they own
--   sees it. The row must already exist — notes belong to a run they RSVPed
--   to, attended, or tracked.
-- Parameters:
--   @notes                      - Up to 4000 characters; NULL/blank clears.
--   @hasherEventMapUpdatedAfter - The app's HEM sync watermark.
-- Returns:
--   rowset 0 — success envelope { success, errorCode, errorType }
--   rowset 1 — adHocData { adHocDataId, hasherEventMapId }
--   rowsets 2+ — sync data from hcapp_syncUserData
-- Author: Harrier Central
-- Created: 2026-09-11
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);
DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 100,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @hemId UNIQUEIDENTIFIER = (SELECT TOP (1) id FROM HC.HasherEventMap
                                    WHERE EventId = @eventId AND UserId = @userId AND removed = 0
                                    ORDER BY AttendenceState DESC);
IF (@hemId IS NULL)
BEGIN
    SET @errorCode = 1200; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No attendance row for notes',
            'hcapp_setEventNotes: the hasher has no HasherEventMap row on this event', @procName, @userId, @eventId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not on this run' AS errorTitle,
           'RSVP to or check in to this run before adding notes.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE HC.HasherEventMap
       SET Notes = NULLIF(LTRIM(RTRIM(@notes)), ''),
           updatedAt = GETDATE()
     WHERE id = @hemId;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorCode = 1900; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error', ERROR_MESSAGE(), @procName, @userId, @eventId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
SELECT 1 AS adHocDataId, LOWER(CAST(@hemId AS NVARCHAR(40))) AS hasherEventMapId;

EXEC HC6.hcapp_syncUserData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @hashersUpdatedAfter         = 'ignore',
    @hasherKennelMapUpdatedAfter = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = 'ignore',
    @usePaging                   = 0,
    @procName                    = @procName,
    @param                       = NULL;
GO
