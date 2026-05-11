CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRuns]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000)    = 'none',
    @kennelId    UNIQUEIDENTIFIER  = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRuns
-- Description: Returns all runs the calling user has been counted as
--   attending (AttendenceState >= 20) for the given kennel, ordered
--   newest first. Used to display the user's personal run history.
--   Facebook-override columns (UseFbRunDetails, UseFbLocation) select
--   between the locally-stored and Facebook-sourced event fields.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel whose run history to return
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): event + HEM run history rows
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getRuns
-- Breaking Changes:
--   Duplicate @kennelId null check removed (HC5 had two sequential IS NULL
--     guards with different errorTypes — second was dead code).
--   errorType corrected: device-not-found was errorType 2 in HC5, now 3.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
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
    @spNumber     = 22,
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
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1222; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty kennelId',
            'A null or empty kennelId was passed to ' + @procName, @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing kennel' AS errorTitle,
           'A kennel must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

SELECT
    e.id                                                                     AS eventId,
    CASE WHEN e.UseFbRunDetails = 1
         THEN CONVERT(DATETIME2, e.FbEventStartDatetime)
         ELSE CONVERT(DATETIME2, e.EventStartDatetime)
    END                                                                      AS eventStartDatetime,
    e.EventEndDatetime                                                       AS eventEndDatetime,
    CASE WHEN e.UseFbRunDetails = 1 THEN e.FbEventName ELSE e.EventName END AS eventName,
    e.EventNumber                                                            AS eventNumber,
    COALESCE(
        CASE WHEN e.UseFbLocation = 1 THEN e.FbLocationOneLineDesc ELSE e.LocationOneLineDesc END,
        e.LocationOneLineDesc,
        e.FbLocationOneLineDesc,
        '<unknown location>')                                                AS locationOneLineDesc,
    e.userEventCounterIncrement                                              AS userEventCounterIncrement,
    e.EventFacebookId                                                        AS eventFacebookId,
    e.IsVisible                                                              AS isVisible,
    e.IsCountedRun                                                           AS isCountedRun,
    e.AbsoluteEventNumber                                                    AS absoluteEventNumber,
    hem.IsHare                                                               AS isHare,
    hem.TotalRunsThisKennel                                                  AS totalRunsThisKennel,
    hem.TotalRuns                                                            AS totalRunsAllKennels,
    COALESCE(hem.TotalHaringThisKennel, 0)                                   AS totalHaringThisKennel,
    hem.UserStartEvent                                                       AS userStartEvent,
    COALESCE(hem.RsvpState, 0)                                               AS rsvpState,
    COALESCE(hem.AttendenceState, 0)                                         AS attendenceState
FROM HC.Event e
INNER JOIN HC.HasherEventMap hem ON hem.EventId = e.id AND hem.UserId = @userId
WHERE e.KennelId        = @kennelId
  AND COALESCE(hem.AttendenceState, 0) >= 20
  AND e.EventStartDatetime < GETDATE()
  AND e.IsVisible      = 1
  AND e.IsCountedRun   = 1
ORDER BY
    CASE WHEN e.UseFbRunDetails = 1
         THEN CONVERT(DATETIME2, e.FbEventStartDatetime)
         ELSE CONVERT(DATETIME2, e.EventStartDatetime)
    END DESC;
