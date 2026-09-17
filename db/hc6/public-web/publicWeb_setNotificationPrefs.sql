-- =====================================================================
-- Procedure: HC6.publicWeb_setNotificationPrefs
-- Description: The bell and the envelope on the web (E9.F7.S14): a web
--   member's notification and email-alert preference for one kennel
--   (HasherKennelMap) or one run (HasherEventMap), through the app's own
--   hcapp_setEmailAndNotificationPrefs. The token is signed for that SP;
--   this wrapper only resolves the public ids. Values are the app's:
--   notification 0 auto · 1 on · 2 ignore · 3 mute · 4 on before the run;
--   email 1 on · 2 off; -1 = unchanged.
-- Parameters: exactly one of @publicKennelId / @publicEventId
-- Returns: hcapp_setEmailAndNotificationPrefs's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setNotificationPrefs]
    @deviceId               UNIQUEIDENTIFIER,
    @accessToken            NVARCHAR(1000),
    @publicKennelId         UNIQUEIDENTIFIER = NULL,
    @publicEventId          UNIQUEIDENTIFIER = NULL,
    @notificationPreference INT = -1,
    @emailPreference        INT = -1
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER, @eventId UNIQUEIDENTIFIER, @userId UNIQUEIDENTIFIER;
    IF (@publicKennelId IS NOT NULL)
        SELECT @kennelId = k.id FROM HC.Kennel k
        WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
    IF (@publicEventId IS NOT NULL)
        SELECT @eventId = e.id FROM HC.Event e
        WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND e.removed = 0;
    SELECT @userId = d.UserId FROM HC.Device d WHERE d.id = @deviceId AND d.removed = 0;

    IF (@userId IS NULL OR (@kennelId IS NULL AND @eventId IS NULL)
        OR @notificationPreference NOT IN (-1, 0, 1, 2, 3, 4)
        OR @emailPreference NOT IN (-1, 0, 1, 2))
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Kennel or run not found, or bad request',
                'publicKennelId=' + COALESCE(CAST(@publicKennelId AS NVARCHAR(40)), 'null')
                + ' publicEventId=' + COALESCE(CAST(@publicEventId AS NVARCHAR(40)), 'null')
                + ' notification=' + CAST(@notificationPreference AS NVARCHAR(10))
                + ' email=' + CAST(@emailPreference AS NVARCHAR(10)),
                @procName, @userId, @deviceId);
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1230 AS errorCode,
               'Not found' AS errorTitle, 'That kennel or run could not be found.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    EXEC HC6.hcapp_setEmailAndNotificationPrefs
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @hasherId                    = @userId,
        @emailPreference             = @emailPreference,
        @notificationPreference      = @notificationPreference,
        @kennelId                    = @kennelId,
        @eventId                     = @eventId,
        @hasherEventMapUpdatedAfter  = '2050-01-01',
        @hasherKennelMapUpdatedAfter = '2050-01-01';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_setNotificationPrefs', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
