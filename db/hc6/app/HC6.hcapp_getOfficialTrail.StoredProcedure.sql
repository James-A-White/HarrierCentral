CREATE OR ALTER PROCEDURE [HC6].[hcapp_getOfficialTrail]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL,
    @lost        SMALLINT         = 0     -- 1 = asked for from the I'm-lost flow
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getOfficialTrail
-- Description: A run's official (hare's) trail for the app (E5.F6.S6,
--   decided with James 2026-10-03). Who sees it, when:
--     * the run's hares and kennel admins (createEditRuns) — always;
--     * a LOST runner, from the I'm-lost flow — from 1 hour before the
--       start to 12 hours after it (only the lost runner, nobody else);
--     * everyone else — once the run has ended (start + 4 hours, the same
--       rule as publicWeb_getOfficialTrail and HC6.KennelOfficialTrails).
--   Points are [lat, lon] or [lat, lon, t] where t = ms after the trail's
--   first point; replay places that first point at the first pack track's
--   start (auto-align, decided 2026-10-03). A trail with no t is drawn whole.
-- Returns: rowset 0 — { Available, CanEdit, OfficialTrailInfo, OfficialTrail }
-- Author: Harrier Central
-- Created: 2026-10-03
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 147, @param = NULL,
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
    DECLARE @kennelId UNIQUEIDENTIFIER, @startGmt DATETIMEOFFSET, @gzip VARBINARY(MAX), @info NVARCHAR(MAX);
    SELECT @kennelId = e.KennelId, @startGmt = e.EventStartDatetimeGmt,
           @gzip = e.OfficialTrailGzip, @info = e.OfficialTrailInfo
    FROM HC.Event e
    WHERE e.id = @eventId AND e.deleted = 0 AND ISNULL(e.removed, 0) = 0;

    DECLARE @isHare SMALLINT = CASE WHEN EXISTS (
        SELECT 1 FROM HC.HasherEventMap h
        WHERE h.EventId = @eventId AND h.UserId = @userId AND ISNULL(h.IsHare, 0) <> 0
          AND ISNULL(h.removed, 0) = 0) THEN 1 ELSE 0 END;
    DECLARE @canEdit SMALLINT = 0;
    IF (@kennelId IS NOT NULL)
        EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId,
             @functionKey = 'createEditRuns', @isHareOfEvent = @isHare, @allowed = @canEdit OUTPUT;

    DECLARE @now DATETIMEOFFSET = SYSDATETIMEOFFSET();
    DECLARE @available SMALLINT = CASE
        WHEN @gzip IS NULL THEN 0
        WHEN @canEdit = 1 THEN 1
        WHEN DATEADD(HOUR, 4, @startGmt) <= @now THEN 1
        WHEN @lost = 1 AND @now >= DATEADD(HOUR, -1, @startGmt)
                       AND @now <= DATEADD(HOUR, 12, @startGmt) THEN 1
        ELSE 0 END;

    SELECT @available AS Available,
           @canEdit   AS CanEdit,
           CASE WHEN @available = 1 THEN @info END AS OfficialTrailInfo,
           CASE WHEN @available = 1 THEN CAST(DECOMPRESS(@gzip) AS NVARCHAR(MAX)) END AS OfficialTrail;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getOfficialTrail',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
