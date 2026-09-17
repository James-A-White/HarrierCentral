-- =====================================================================
-- Procedure: HC6.publicWeb_getChatMessages
-- Description: One chat thread's messages for a web member (E9.F7.S15)
--   through the app's own SPs: a run (hcapp_getEventMessages), a kennel
--   (hcapp_getKennelMessages) or a room (hcapp_getRoomMessages, which
--   also marks it read when asked). The token is signed for the SP the
--   kind selects; this wrapper only resolves the public ids.
-- Parameters: @kind 'run' | 'kennel' | 'room'; the matching id;
--   @sinceSequenceCount for polling; @markRead for rooms
-- Returns: rowset 0 envelope with my PublicHasherId (Me); then the
--   messages as the app SP returns them (newest first)
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getChatMessages]
    @deviceId           UNIQUEIDENTIFIER,
    @accessToken        NVARCHAR(1000),
    @kind               NVARCHAR(10),
    @publicEventId      UNIQUEIDENTIFIER = NULL,
    @publicKennelId     UNIQUEIDENTIFIER = NULL,
    @roomType           INT              = NULL,
    @sinceSequenceCount INT              = NULL,
    @markRead           SMALLINT         = 0
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @me NVARCHAR(40), @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER;
    SELECT @me = UPPER(CAST(h.PublicHasherId AS NVARCHAR(40)))
    FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
    WHERE d.id = @deviceId AND d.removed = 0;
    IF (@kind = 'run')    SELECT @eventId  = e.id FROM HC.Event  e WHERE e.PublicEventId  = @publicEventId  AND e.deleted = 0 AND e.removed = 0;
    IF (@kind = 'kennel') SELECT @kennelId = k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    IF (@me IS NULL OR (@kind = 'run' AND @eventId IS NULL) OR (@kind = 'kennel' AND @kennelId IS NULL)
        OR (@kind = 'room' AND @roomType IS NULL) OR @kind NOT IN ('run', 'kennel', 'room'))
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Chat thread not found or bad request',
                'kind=' + COALESCE(@kind, 'null') + ' event=' + COALESCE(CAST(@publicEventId AS NVARCHAR(40)), 'null')
                + ' kennel=' + COALESCE(CAST(@publicKennelId AS NVARCHAR(40)), 'null') + ' room=' + COALESCE(CAST(@roomType AS NVARCHAR(10)), 'null'),
                @procName, NULL, @deviceId);
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType, @me AS Me;
        SELECT @errorId AS errorId, 12 AS errorType, 1230 AS errorCode,
               'Not found' AS errorTitle, 'That chat could not be found.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType, @me AS Me;

    IF (@kind = 'run')
        EXEC HC6.hcapp_getEventMessages  @deviceId = @deviceId, @accessToken = @accessToken, @eventId = @eventId, @sinceSequenceCount = @sinceSequenceCount;
    ELSE IF (@kind = 'kennel')
        EXEC HC6.hcapp_getKennelMessages @deviceId = @deviceId, @accessToken = @accessToken, @kennelId = @kennelId, @sinceSequenceCount = @sinceSequenceCount;
    ELSE
        EXEC HC6.hcapp_getRoomMessages   @deviceId = @deviceId, @accessToken = @accessToken, @roomType = @roomType, @sinceSequenceCount = @sinceSequenceCount, @markRead = @markRead;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getChatMessages', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
