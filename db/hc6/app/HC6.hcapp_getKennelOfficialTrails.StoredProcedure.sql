CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelOfficialTrails]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @kennelId    UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getKennelOfficialTrails
-- Description: The kennel page's full-screen trail map (E5.F6.S6): every
--   official trail of the kennel's runs that have ended
--   (HC6.KennelOfficialTrails), newest first. Fetched when the map opens,
--   never synced. Since 2026-10-03 also every run's START POINT (James:
--   "I would love to see the start points as well") — all of the kennel's
--   visible runs, past and future, from the trail-independent Sync* columns
--   the app shows as the run's location. Apps before 1442 read rowset 0 only.
-- Returns: rowset 0 — { EventId, PublicEventId, EventNumber, EventName,
--   EventStartLocal, OfficialTrail, OfficialTrailInfo }
--          rowset 1 — { EventId, EventNumber, EventName, EventStartLocal,
--   Lat, Lon } newest first; runs with no position (NULL, 0/0, or the
--   app's -2/-2 "cleared" sentinel) are left out.
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
    @spNumber = 146, @param = NULL,
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
    SELECT LOWER(CAST(t.EventId AS NVARCHAR(40)))       AS EventId,
           LOWER(CAST(t.PublicEventId AS NVARCHAR(40))) AS PublicEventId,
           t.EventNumber, t.EventName, t.EventStartLocal,
           t.OfficialTrail, t.OfficialTrailInfo
    FROM HC6.KennelOfficialTrails(@kennelId) t
    ORDER BY t.EventStartDatetimeGmt DESC;

    SELECT LOWER(CAST(e.id AS NVARCHAR(40))) AS EventId,
           e.EventNumber, e.EventName, e.EventStartLocal,
           CAST(e.SyncLatitude  AS DECIMAL(9, 6)) AS Lat,
           CAST(e.SyncLongitude AS DECIMAL(9, 6)) AS Lon
    FROM HC.Event e
    WHERE e.KennelId = @kennelId
      AND e.deleted = 0
      AND ISNULL(e.removed, 0) = 0
      AND e.IsVisible = 1
      AND e.SyncLatitude IS NOT NULL AND e.SyncLongitude IS NOT NULL
      AND ABS(e.SyncLatitude) <= 90 AND ABS(e.SyncLongitude) <= 180
      AND NOT (e.SyncLatitude = 0 AND e.SyncLongitude = 0)
      AND NOT (e.SyncLatitude = -2 AND e.SyncLongitude = -2)
    ORDER BY e.EventStartDatetimeGmt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getKennelOfficialTrails',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
