CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunsAtStart]

    @deviceId      UNIQUEIDENTIFIER = NULL,
    @accessToken   NVARCHAR(1000)   = NULL,
    @kennelId      UNIQUEIDENTIFIER = NULL,
    @eventId       UNIQUEIDENTIFIER = NULL,
    @startDatetime DATETIMEOFFSET(7) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunsAtStart
-- Description: The kennel's other runs that start at the same local date
--   and time as a run about to be saved (E3.F1.S8). The app asks before
--   saving a new run or a changed start; anything returned makes it ask
--   "Another run at this time?" — weekend events have several runs at
--   once, so it is a confirmation, never a refusal. The rule is
--   HC6.RunsAtLocalStart, shared with hcportal_getRunsAtStart.
--   Nothing here is an error to the user: missing input or a caller who
--   may not edit the kennel's runs gets an empty answer (the save that
--   follows refuses that caller on its own), so this can never put the
--   app's error dialog on screen.
-- Parameters:
--   @deviceId / @accessToken - device auth (standard token)
--   @kennelId                - the run's kennel
--   @eventId                 - the run being saved (the id the app minted
--                              for a new one); never matches itself
--   @startDatetime           - the start exactly as addEditEvent will be
--                              sent it; its local wall clock is compared
-- Returns:
--   rowset 0 — success envelope { success, errorCode, errorType }
--   rowset 1 — adHocData { adHocDataId, eventId, eventName, eventNumber,
--              isVisible }, one row per run at that time (none = no clash)
-- Author: Harrier Central
-- Created: 2026-10-14
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName_self NVARCHAR(128) = OBJECT_NAME(@@PROCID);

DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName_self,
    @spNumber     = 154,
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
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName_self AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    IF (@kennelId IS NULL OR @startDatetime IS NULL) RETURN;
    IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL;

    -- The same gate as hcapp_addEditEvent: hidden runs are listed, so only
    -- someone who may edit the kennel's runs is told about them.
    -- Hare rights need an APPOINTED hare (E8.F5.S6, 2026-10-17): HC6.IsAppointedHare.
    DECLARE @isHare SMALLINT = HC6.IsAppointedHare(@userId, @eventId);
    DECLARE @allowed SMALLINT = 0;
    EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId,
         @functionKey = 'createEditRuns', @isHareOfEvent = @isHare, @allowed = @allowed OUTPUT;
    IF (@allowed = 0) RETURN;

    SELECT 1                                       AS adHocDataId,
           LOWER(CAST(r.eventId AS NVARCHAR(40)))  AS eventId,
           r.eventName,
           r.eventNumber,
           r.isVisible
    FROM HC6.RunsAtLocalStart(@kennelId, CAST(@startDatetime AS DATETIME2(7)), @eventId) r
    ORDER BY r.eventNumber, r.eventName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getRunsAtStart',
            ERROR_MESSAGE(), @procName_self, @userId, @kennelId);
    THROW;
END CATCH
GO
