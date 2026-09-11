CREATE OR ALTER PROCEDURE [HC6].[hcapp_findRunForTrack]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @firstPointUtc  DATETIME2(3),
    @lastPointUtc   DATETIME2(3),
    @latitude       DECIMAL(18, 15),
    @longitude      DECIMAL(19, 15)
AS
-- =====================================================================
-- Procedure: HC6.hcapp_findRunForTrack
-- Description: Which run does an imported GPX file belong to? (E5.F5.S6)
--   Given the first and last point times of a track (UTC) and the first
--   point's position, returns the runs that started between three hours
--   before the first point and the last point — nearest start first — with
--   how far each run's recorded start is from that first point, whether the
--   caller already has a PackTrack trail on it, and their attendance state.
--   The app applies the rule: a run with a recorded location must be within
--   a mile; a run with none is accepted on time alone once the user confirms.
--   Done server-side because the phone only holds runs for followed kennels
--   and the last ten days; a GPX from a visit months ago would find nothing
--   locally. Instant comparison ⇒ EventStartDateTimeGmt (hc-event-datetimes).
-- Parameters:
--   @firstPointUtc / @lastPointUtc - the track's time span, UTC.
--   @latitude / @longitude         - the first point.
-- Returns: rowset 0 — up to 10 candidate runs (see contract). Empty when
--   nothing started in the window.
-- Author: Harrier Central
-- Created: 2026-09-10
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;

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
    @spNumber     = 95,
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

IF (@firstPointUtc IS NULL OR @lastPointUtc IS NULL OR @lastPointUtc < @firstPointUtc
    OR @latitude IS NULL OR @longitude IS NULL
    OR @latitude < -90 OR @latitude > 90 OR @longitude < -180 OR @longitude > 180)
BEGIN
    SET @errorCode = 1295; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Invalid track span',
            'firstPointUtc/lastPointUtc/latitude/longitude missing or out of range', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid track' AS errorTitle,
           'The track''s first point has no usable time or position.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    -- The rule lives in nonApi_findRunForTrack so the server-side import
    -- processor (ProcessTrackImport) and the app match identically.
    EXEC HC6.nonApi_findRunForTrack
        @userId = @userId, @firstPointUtc = @firstPointUtc, @lastPointUtc = @lastPointUtc,
        @latitude = @latitude, @longitude = @longitude;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_findRunForTrack',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
