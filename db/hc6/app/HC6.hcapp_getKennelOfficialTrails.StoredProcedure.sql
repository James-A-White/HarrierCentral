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
--   never synced.
-- Returns: rowset 0 — { EventId, PublicEventId, EventNumber, EventName,
--   EventStartLocal, OfficialTrail, OfficialTrailInfo }
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
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getKennelOfficialTrails',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
