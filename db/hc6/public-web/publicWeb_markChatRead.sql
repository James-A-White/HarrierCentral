-- =====================================================================
-- Procedure: HC6.publicWeb_markChatRead
-- Description: A web member opened a run or kennel chat (E9.F7.S15):
--   the app's own hcapp_markEventChatRead / hcapp_markKennelChatRead.
--   Rooms are marked read by hcapp_getRoomMessages itself. The token is
--   signed for the SP the kind selects.
-- Returns: the app SP's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
-- 2026-10-03: @roomType and @threadId are ACCEPTED, not used. The web's
--   shared chatIds() sends every kind's id (null when not this kind) and
--   PublicWebAdminApi forwards a JSON null as a real parameter, so since the
--   DM work (2026-09-29) every call failed "too many arguments" and no web
--   member's run or kennel chat was ever marked read. Rooms are marked read
--   by hcapp_getRoomMessages and DMs by hcapp_getDirectMessages. Every
--   parameter now has a default, so an omitted one reaches the SP's own
--   graceful check instead of failing before it runs.
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_markChatRead]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @kind           NVARCHAR(10)     = NULL,
    @publicEventId  UNIQUEIDENTIFIER = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @roomType       INT              = NULL,   -- accepted, unused (see above)
    @threadId       UNIQUEIDENTIFIER = NULL    -- accepted, unused (see above)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER;
    IF (@kind = 'run')    SELECT @eventId  = e.id FROM HC.Event  e WHERE e.PublicEventId  = @publicEventId  AND e.deleted = 0 AND e.removed = 0;
    IF (@kind = 'kennel') SELECT @kennelId = k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    IF ((@kind = 'run' AND @eventId IS NULL) OR (@kind = 'kennel' AND @kennelId IS NULL) OR @kind NOT IN ('run', 'kennel'))
    BEGIN
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType;
        RETURN;
    END

    IF (@kind = 'run')
        EXEC HC6.hcapp_markEventChatRead  @deviceId = @deviceId, @accessToken = @accessToken, @eventId = @eventId;
    ELSE
        EXEC HC6.hcapp_markKennelChatRead @deviceId = @deviceId, @accessToken = @accessToken, @kennelId = @kennelId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_markChatRead', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
