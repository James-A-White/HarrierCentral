-- =====================================================================
-- Procedure: HC6.publicWeb_sendChatMessage
-- Description: A web member posts one chat message (E9.F7.S15) through
--   the app's own SPs — hcapp_sendEventMessage, hcapp_sendKennelMessage
--   or hcapp_sendRoomMessage by @kind. The token is signed for the SP the
--   kind selects; this wrapper only resolves the public ids. @messageId is
--   the client's id, so a retried post cannot double up.
-- Returns: the app SP's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_sendChatMessage]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @kind           NVARCHAR(10),
    @publicEventId  UNIQUEIDENTIFIER = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @roomType       INT              = NULL,
    @messageId      UNIQUEIDENTIFIER,
    @messageContent NVARCHAR(500)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER;
    IF (@kind = 'run')    SELECT @eventId  = e.id FROM HC.Event  e WHERE e.PublicEventId  = @publicEventId  AND e.deleted = 0 AND e.removed = 0;
    IF (@kind = 'kennel') SELECT @kennelId = k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    IF ((@kind = 'run' AND @eventId IS NULL) OR (@kind = 'kennel' AND @kennelId IS NULL)
        OR (@kind = 'room' AND @roomType IS NULL) OR @kind NOT IN ('run', 'kennel', 'room')
        OR @messageId IS NULL OR LEN(LTRIM(RTRIM(COALESCE(@messageContent, '')))) = 0)
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Chat thread not found or bad request',
                'kind=' + COALESCE(@kind, 'null') + ' event=' + COALESCE(CAST(@publicEventId AS NVARCHAR(40)), 'null')
                + ' kennel=' + COALESCE(CAST(@publicKennelId AS NVARCHAR(40)), 'null') + ' room=' + COALESCE(CAST(@roomType AS NVARCHAR(10)), 'null'),
                @procName, NULL, @deviceId);
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1230 AS errorCode,
               'Not found' AS errorTitle, 'That chat could not be found.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    IF (@kind = 'run')
        EXEC HC6.hcapp_sendEventMessage  @deviceId = @deviceId, @accessToken = @accessToken, @eventId = @eventId, @messageId = @messageId, @messageTitle = NULL, @messageContent = @messageContent;
    ELSE IF (@kind = 'kennel')
        EXEC HC6.hcapp_sendKennelMessage @deviceId = @deviceId, @accessToken = @accessToken, @kennelId = @kennelId, @messageId = @messageId, @messageTitle = NULL, @messageContent = @messageContent;
    ELSE
        EXEC HC6.hcapp_sendRoomMessage   @deviceId = @deviceId, @accessToken = @accessToken, @roomType = @roomType, @messageId = @messageId, @messageContent = @messageContent;

    -- The app's send SPs return no rowset on success (the app reads the
    -- message back through sync); the web reads an envelope, so give it one
    -- when the message landed. On failure the app SP's own envelope comes
    -- first and this one sits behind it.
    IF EXISTS (SELECT 1 FROM HC.EventMessage em WHERE em.id = @messageId)
        SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_sendChatMessage', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
