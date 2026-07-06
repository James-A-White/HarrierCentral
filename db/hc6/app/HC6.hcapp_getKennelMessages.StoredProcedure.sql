CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelMessages]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @kennelId           UNIQUEIDENTIFIER = NULL,
    @sinceSequenceCount INT              = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getKennelMessages
-- Description: Returns messages for a KENNEL-LEVEL chat thread
--   (EventMessage rows with KennelId = @kennelId, EventId NULL). Mirrors
--   hcapp_getEventMessages' rowset shape so the app's ChatPageController
--   parses it unchanged (roomId = PublicKennelId).
-- Parameters:
--   @kennelId           - Kennel whose thread to read
--   @sinceSequenceCount - Delta fetch: only messages with a higher
--                         MessageSequenceCount (NULL = full fetch)
-- Returns: message rows, newest-first (same columns as getEventMessages)
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
    @spNumber = 65, @param = NULL,
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

SELECT
    UPPER(msg.id)                                                    AS id,
    'text'                                                           AS type,
    msg.MessageContent                                               AS text,
    msg.PublicKennelId                                               AS roomId,
    DATEDIFF_BIG(MILLISECOND, '1970-01-01 00:00:00', msg.createdAt)  AS createdAt,
    UPPER(h.PublicHasherId)                                          AS authorId,
    h.DisplayName                                                    AS authorFirstName,
    h.Photo                                                          AS authorImageUrl,
    msg.MessageSequenceCount                                         AS sequenceCount
FROM HC.EventMessage msg
INNER JOIN HC.Hasher h ON msg.UserId = h.id
WHERE msg.KennelId = @kennelId
  AND msg.EventId IS NULL
  AND msg.Removed = 0
  AND h.Removed = 0
  AND (@sinceSequenceCount IS NULL OR msg.MessageSequenceCount > @sinceSequenceCount)
ORDER BY msg.createdAt DESC;
