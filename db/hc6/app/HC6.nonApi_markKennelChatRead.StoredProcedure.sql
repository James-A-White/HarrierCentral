CREATE OR ALTER PROCEDURE [HC6].[nonApi_markKennelChatRead]
    @userId           UNIQUEIDENTIFIER,
    @kennelId         UNIQUEIDENTIFIER = NULL,
    @kennelThread     SMALLINT         = 0,
    @hcVersion        NVARCHAR(100)    = NULL,
    @callerProcName   NVARCHAR(128)    = NULL,
    @errorCode        INT              = NULL OUTPUT,
    @errorType        INT              = NULL OUTPUT,
    @errorId          UNIQUEIDENTIFIER = NULL OUTPUT,
    @errorTitle       NVARCHAR(200)    = NULL OUTPUT,
    @errorUserMessage NVARCHAR(500)    = NULL OUTPUT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_markKennelChatRead
-- Description: THE read mark for one of a kennel's two chat threads
--   (E9.F1.S33, 2026-10-16), moved out of hcapp_markKennelChatRead so the
--   portal's hcportal_markKennelChatRead marks read by the same rules. The
--   mark is the (UserId, KennelId, MessageType) row at that thread's
--   current maximum. Returns NO rowset; @errorCode is NULL on success, else
--   1901 no kennel, 1913 not in mismanagement / unknown thread, 1933 an
--   unexpected error (all logged here).
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none
-- Breaking Changes: none (new)
-- Idempotency: set-state — writes the read mark to the thread's current maximum
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @errorCode = NULL; SET @errorType = NULL; SET @errorId = NULL;
SET @errorTitle = NULL; SET @errorUserMessage = NULL;
DECLARE @procName NVARCHAR(128) = COALESCE(@callerProcName, OBJECT_NAME(@@PROCID));

IF (@kennelId IS NULL)
BEGIN
    SET @errorId = NEWID(); SET @errorCode = 1901; SET @errorType = 2;
    SET @errorTitle = 'Missing kennel'; SET @errorUserMessage = 'A kennel must be specified.';
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Null kennelId', 'kennelId is required', @procName, @userId);
    RETURN;
END

DECLARE @messageType INT = HC6.KennelThreadMessageType(@kennelThread);
IF (@messageType IS NULL
    OR (@messageType <> 0 AND HC6.UserInKennelMismanagement(@userId, @kennelId) = 0))
BEGIN
    SET @errorId = NEWID(); SET @errorCode = 1913; SET @errorType = 13;
    SET @errorTitle = 'Not available';
    SET @errorUserMessage = 'This chat is only for the kennel''s mismanagement.';
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Not in kennel mismanagement',
            CONCAT('kennelId=', CAST(@kennelId AS VARCHAR(40)), ' kennelThread=', @kennelThread),
            @procName, @userId);
    RETURN;
END

BEGIN TRY
    DECLARE @maxSeq INT;
    DECLARE @lastMessageId UNIQUEIDENTIFIER;

    SELECT @maxSeq = MAX(MessageSequenceCount)
    FROM HC.EventMessage
    WHERE KennelId = @kennelId AND EventId IS NULL AND MessageType = @messageType AND removed = 0;

    SELECT TOP 1 @lastMessageId = id
    FROM HC.EventMessage
    WHERE KennelId = @kennelId AND EventId IS NULL AND MessageType = @messageType AND removed = 0
    ORDER BY createdAt DESC;

    BEGIN TRANSACTION;

    MERGE HC.EventMessageBadgeCounts WITH (HOLDLOCK) AS target
    USING (SELECT @kennelId AS KennelId, @userId AS UserId, @messageType AS MessageType) AS source
    ON (    target.KennelId    = source.KennelId
        AND target.UserId      = source.UserId
        AND target.EventId     IS NULL
        AND target.MessageType = source.MessageType
        AND target.Removed     = 0)
    WHEN MATCHED THEN
        UPDATE SET target.LastSequenceCount = COALESCE(@maxSeq, 0),
                   target.LastReadAt        = GETUTCDATE(),
                   target.LastReadMessageId = @lastMessageId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, KennelId, MessageType, LastSequenceCount, LastReadAt, LastReadMessageId)
        VALUES (source.UserId, source.KennelId, source.MessageType, COALESCE(@maxSeq, 0), GETUTCDATE(), @lastMessageId);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID(); SET @errorCode = 1933; SET @errorType = 5;
    SET @errorTitle = 'Unexpected error'; SET @errorUserMessage = 'The chat could not be marked read.';
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
END CATCH
GO
