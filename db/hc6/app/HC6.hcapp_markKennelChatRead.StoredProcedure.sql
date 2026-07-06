CREATE OR ALTER PROCEDURE [HC6].[hcapp_markKennelChatRead]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @kennelId    UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_markKennelChatRead
-- Description: Marks a KENNEL-LEVEL chat thread as read for the calling
--   user — upserts the (UserId, KennelId) row in EventMessageBadgeCounts
--   with the thread's current max MessageSequenceCount. Mirrors
--   hcapp_markEventChatRead.
-- Parameters: @kennelId — kennel whose thread to mark read.
-- Returns: rowset 0: { success }
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — kennel chat, design of record)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 66, @param = NULL,
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

IF (@kennelId IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null kennelId', 'kennelId is required', @procName, @userId);
    SELECT @errorId AS errorId, 2 AS errorType, 1901 AS errorCode,
           'Missing kennel' AS errorTitle, 'A kennel must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @maxSeq INT;
    DECLARE @lastMessageId UNIQUEIDENTIFIER;

    SELECT @maxSeq = MAX(MessageSequenceCount)
    FROM HC.EventMessage
    WHERE KennelId = @kennelId AND EventId IS NULL AND removed = 0;

    SELECT TOP 1 @lastMessageId = id
    FROM HC.EventMessage
    WHERE KennelId = @kennelId AND EventId IS NULL AND removed = 0
    ORDER BY createdAt DESC;

    BEGIN TRANSACTION;

    MERGE HC.EventMessageBadgeCounts AS target
    USING (SELECT @kennelId AS KennelId, @userId AS UserId) AS source
    ON (    target.KennelId = source.KennelId
        AND target.UserId   = source.UserId
        AND target.Removed  = 0)
    WHEN MATCHED THEN
        UPDATE SET target.LastSequenceCount = COALESCE(@maxSeq, 0),
                   target.LastReadAt        = GETUTCDATE(),
                   target.LastReadMessageId = @lastMessageId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, KennelId, LastSequenceCount, LastReadAt, LastReadMessageId)
        VALUES (source.UserId, source.KennelId, COALESCE(@maxSeq, 0), GETUTCDATE(), @lastMessageId);

    COMMIT TRANSACTION;
    SELECT 1 AS success;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success;
END CATCH
