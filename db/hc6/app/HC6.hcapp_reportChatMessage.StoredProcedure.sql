CREATE OR ALTER PROCEDURE [HC6].[hcapp_reportChatMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @messageId   UNIQUEIDENTIFIER = NULL,
    -- MAX, never a width: an NVARCHAR(n) parameter truncates silently.
    @reason      NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_reportChatMessage
-- Description: A hasher reports a chat message (E9.F1.S17, James
--   2026-09-29). Harrier Central is a letterbox, not a moderator: the
--   report is written to LOG.GeneralLog and the API emails it to the
--   platform reviewers — the same list as kennel requests (platform admins
--   plus the shared mailbox). Nothing is hidden or removed by this SP;
--   Block (hcapp_setHasherBlock) is the hasher's own tool for that.
--
--   Reporting the same message twice is a success that sends nothing new.
--   Reason is optional and capped at 1,000 characters.
-- Returns: rowset 0 — standard success envelope { success, errorMessage }
--          rowset 1 — the report for the email (the API strips it):
--            { MessageId, ReporterName, ReporterEmail, SenderName,
--              SenderPublicHasherId, ThreadLabel, MessageKind,
--              MessageContent, MessageAt, Reason, AlreadyReported }
--          rowset 2 — { reviewerEmail } (the API strips it)
-- Author: Harrier Central
-- Created: 2026-09-29
-- HC5 Source: none (new)
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
    @spNumber = 127, @param = NULL,
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

DECLARE @senderId UNIQUEIDENTIFIER, @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER,
        @roomType INT, @kind SMALLINT, @content NVARCHAR(MAX), @messageAt DATETIMEOFFSET(7);
SELECT @senderId = em.UserId, @eventId = em.EventId, @kennelId = em.KennelId, @roomType = em.MessageType,
       @kind = em.MessageKind, @content = em.MessageContent, @messageAt = em.createdAt
FROM HC.EventMessage em WHERE em.id = @messageId;

IF (@senderId IS NULL OR @senderId = @userId OR LEN(COALESCE(@reason, '')) > 1000)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad report request',
            CONCAT('messageId=', COALESCE(CAST(@messageId AS NVARCHAR(40)), 'null'), ' reasonLen=', LEN(COALESCE(@reason, ''))),
            @procName, @userId);
    SELECT 0 AS success, 1987 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1987 AS errorCode,
           'Not reported' AS errorTitle,
           CASE WHEN @senderId = @userId THEN 'That is your own message.'
                WHEN @senderId IS NULL THEN 'That message is no longer in the chat.'
                ELSE 'The reason can be up to 1,000 characters.' END AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

DECLARE @threadLabel NVARCHAR(400) =
    CASE WHEN @eventId IS NOT NULL THEN
             (SELECT k.KennelShortName + N' — ' + e.EventName FROM HC.Event e JOIN HC.Kennel k ON k.id = e.KennelId WHERE e.id = @eventId)
         WHEN @kennelId IS NOT NULL THEN
             (SELECT k.KennelShortName + N' kennel chat' FROM HC.Kennel k WHERE k.id = @kennelId)
         ELSE (SELECT c.RoomName FROM HC6.ChatRoomCatalog() c WHERE c.RoomType = @roomType) END;

DECLARE @key NVARCHAR(200) = 'message=' + CAST(@messageId AS NVARCHAR(40)) + ' reporter=' + CAST(@userId AS NVARCHAR(40));
DECLARE @alreadyReported SMALLINT =
    CASE WHEN EXISTS (SELECT 1 FROM LOG.GeneralLog g
                      WHERE g.LogSource = 'HC6.hcapp_reportChatMessage' AND g.Data LIKE @key + '%') THEN 1 ELSE 0 END;

BEGIN TRY
    IF (@alreadyReported = 0)
        INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
        VALUES ('HC6.hcapp_reportChatMessage', 'Chat message reported',
                CAST(@userId AS NVARCHAR(40)),
                LEFT(@key + ' sender=' + CAST(@senderId AS NVARCHAR(40))
                     + ' thread=' + COALESCE(@threadLabel, '-')
                     + ' reason=' + COALESCE(@reason, '')
                     + ' text=' + COALESCE(@content, ''), 4000),
                SYSDATETIMEOFFSET());

    SELECT 1 AS success, NULL AS errorMessage;

    SELECT UPPER(CAST(@messageId AS NVARCHAR(40)))            AS MessageId,
           r.DisplayName                                      AS ReporterName,
           r.Email                                            AS ReporterEmail,
           s.DisplayName                                      AS SenderName,
           UPPER(CAST(s.PublicHasherId AS NVARCHAR(40)))      AS SenderPublicHasherId,
           @threadLabel                                       AS ThreadLabel,
           @kind                                              AS MessageKind,
           @content                                           AS MessageContent,
           @messageAt                                         AS MessageAt,
           @reason                                            AS Reason,
           @alreadyReported                                   AS AlreadyReported
    FROM HC.Hasher r, HC.Hasher s
    WHERE r.id = @userId AND s.id = @senderId;

    -- The same letterbox as kennel requests (publicWeb_confirmKennelRequest).
    SELECT h.Email AS reviewerEmail
    FROM HC.PlatformAdmin pa
    JOIN HC.Hasher h ON h.id = pa.UserId AND h.Removed = 0
    WHERE pa.removed = 0 AND pa.CanEditKennel = 1
      AND LEN(COALESCE(h.Email, N'')) > 0
    UNION
    SELECT N'harriercentral@gmail.com';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in reportChatMessage',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1988 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1988 AS errorCode,
           'Something went wrong' AS errorTitle,
           'The report could not be sent. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
