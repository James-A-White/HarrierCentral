CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setRunRsvp]
    @deviceId      UNIQUEIDENTIFIER,
    @accessToken   NVARCHAR(1000),
    @publicEventId UNIQUEIDENTIFIER,
    @rsvpState     INT
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_setRunRsvp
-- Description: RSVP from the public web (E9.F7.S1). The browser is a
--              registered HC.Device, so this is the app's own
--              hcapp_setEventRsvp — the web only knows the run by its
--              PublicEventId, and that map is all this wrapper adds. The
--              inner SP validates the token (generated for procName
--              'hcapp_setEventRsvp'), defaults the hasher to the caller,
--              and does everything the app's RSVP does: notifications,
--              sequence numbers, run counts.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
--              @publicEventId           - HC.Event.PublicEventId
--              @rsvpState               - 1 No · 2 Maybe · 3 Yes
-- Returns:     hcapp_setEventRsvp's rowsets (rowset 0 = envelope), or this
--              SP's own error envelope when the run is unknown.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @eventId UNIQUEIDENTIFIER;
    SELECT @eventId = e.id
    FROM HC.Event e
    WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND e.removed = 0;

    IF (@eventId IS NULL OR @rsvpState NOT IN (1, 2, 3))
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Run not found or bad RSVP state',
                'publicEventId=' + CAST(@publicEventId AS NVARCHAR(40)) + ' rsvpState=' + CAST(@rsvpState AS NVARCHAR(10)),
                @procName, NULL, @deviceId);
        SELECT 0 AS success, 1200 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1200 AS errorCode,
               'Run not found' AS errorTitle,
               'That run could not be found.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    EXEC HC6.hcapp_setEventRsvp
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @eventId                     = @eventId,
        @hasherId                    = NULL,
        @isHare                      = -1,
        @rsvpState                   = @rsvpState,
        @hasherEventMapUpdatedAfter  = '2050-01-01',
        @hasherKennelMapUpdatedAfter = '2050-01-01',
        @hemId                       = NULL,
        @autoSetNotifications        = 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_setRunRsvp',
            ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
