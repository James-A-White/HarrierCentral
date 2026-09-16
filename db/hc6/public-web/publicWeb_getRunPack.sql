CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getRunPack]
    @deviceId      UNIQUEIDENTIFIER,
    @accessToken   NVARCHAR(1000),
    @publicEventId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getRunPack
-- Description: A signed-in web member's own state for a run and who else
--              is coming (E9.F7.S4) — the first member-only content the
--              public web shows. Gated on a valid device token via
--              ValidateAppAuth: any registered device, because the pack
--              list is what the app shows any member on the RSVP tab.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
--              @publicEventId           - HC.Event.PublicEventId
-- Returns:     Rowset 0: envelope (success 1) or standard error rows.
--              Rowset 1: one row — hasherId, hashName, rsvpState,
--                        attendenceState, isHare, isPast
--              Rowset 2: the pack — hasherId, name, photo, rsvpState,
--                        attendenceState, isHare; going and maybes and
--                        hares and anyone already checked in, never the
--                        "not coming" rows.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 109, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @eventId UNIQUEIDENTIFIER, @isPast SMALLINT;
    SELECT @eventId = e.id,
           @isPast  = CASE WHEN e.EventStartDateTimeGmt < SYSDATETIMEOFFSET() THEN 1 ELSE 0 END
    FROM HC.Event e
    WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND e.removed = 0;

    IF (@eventId IS NULL)
    BEGIN
        SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Run not found',
                'publicEventId=' + CAST(@publicEventId AS NVARCHAR(40)), @procName, @userId, @deviceId);
        SELECT 0 AS success, 1200 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1200 AS errorCode,
               'Run not found' AS errorTitle, 'That run could not be found.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    -- Rowset 1: me
    SELECT
        h.id                                AS hasherId,
        COALESCE(h.HashName, h.DisplayName, '') AS hashName,
        COALESCE(hem.RsvpState, 0)          AS rsvpState,
        COALESCE(hem.AttendenceState, 0)    AS attendenceState,
        COALESCE(hem.IsHare, 0)             AS isHare,
        @isPast                             AS isPast
    FROM HC.Hasher h
    LEFT JOIN HC.HasherEventMap hem ON hem.UserId = h.id AND hem.EventId = @eventId
    WHERE h.id = @userId;

    -- Rowset 2: the pack, hares first, then going, then maybe
    SELECT
        h.id                                                          AS hasherId,
        COALESCE(NULLIF(hem.DisplayName, ''), h.DisplayName, h.HashName, '') AS name,
        COALESCE(NULLIF(hkm.KennelUserPhoto, ''), h.Photo, '')       AS photo,
        hem.RsvpState                                                 AS rsvpState,
        hem.AttendenceState                                           AS attendenceState,
        hem.IsHare                                                    AS isHare
    FROM HC.HasherEventMap hem
    INNER JOIN HC.Hasher h ON h.id = hem.UserId AND h.Removed = 0 AND h.deleted = 0
    LEFT JOIN HC.HasherKennelMap hkm ON hkm.UserId = hem.UserId AND hkm.KennelId = hem.KennelId
    WHERE hem.EventId = @eventId
      AND (hem.IsHare = 1 OR hem.RsvpState IN (2, 3) OR hem.AttendenceState >= 20)
    ORDER BY hem.IsHare DESC,
             CASE WHEN hem.AttendenceState >= 20 THEN 0 WHEN hem.RsvpState = 3 THEN 1 ELSE 2 END,
             name;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getRunPack',
            ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
