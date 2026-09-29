CREATE OR ALTER PROCEDURE [HC6].[nonApi_deleteChatMessage]
    @userId         UNIQUEIDENTIFIER,
    @messageId      UNIQUEIDENTIFIER,
    @callerProcName NVARCHAR(128),
    @hcVersion      NVARCHAR(50),
    @outcome        SMALLINT         OUTPUT,   -- 1 removed (or already was), 2 not found, 3 not allowed
    @errorId        UNIQUEIDENTIFIER OUTPUT    -- set for 2 and 3: the HC.ErrorLog row
AS
-- =====================================================================
-- Procedure: HC6.nonApi_deleteChatMessage
-- Description: Removes one chat message for everyone (E9.F1.S13/S14,
--   James 2026-09-29). The rule lives HERE, once; hcapp_ and hcportal_
--   deleteChatMessage only authenticate and shape the reply, and
--   publicWeb_deleteChatMessage wraps the app SP.
--
--   Allowed when the caller WROTE the message, or moderates its thread
--   (HC6.nonApi_mayModerateChat: moderateChat in the kennel, SuperAdmin
--   for rooms).
--
--   A soft delete: Removed = 1. Every reader already filters it out, and
--   returns it in its { removedId } rowset so an open chat drops it. The
--   run card's chat count follows through trgEventMessageActivityCount.
--   Deleting a message that is already gone succeeds: two admins removing
--   the same abuse at once is not an error.
--
--   A moderator removing someone ELSE's message writes a LOG.GeneralLog
--   line with the text it removed — the only record left of what was said
--   and who took it down.
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @outcome = 2;
SET @errorId = NULL;

BEGIN TRY
    DECLARE @authorId UNIQUEIDENTIFIER, @eventId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER, @threadId UNIQUEIDENTIFIER,
            @roomType INT, @removed SMALLINT, @content NVARCHAR(MAX);

    SELECT @authorId = em.UserId, @eventId = em.EventId, @kennelId = em.KennelId, @threadId = em.ThreadId,
           @roomType = em.MessageType, @removed = em.Removed, @content = em.MessageContent
    FROM HC.EventMessage em
    WHERE em.id = @messageId;

    IF (@authorId IS NULL)
    BEGIN
        SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, @hcVersion, 'Chat message not found',
                'messageId=' + COALESCE(CAST(@messageId AS NVARCHAR(40)), 'null'), @callerProcName, @userId);
        RETURN;
    END

    IF (@removed = 1)
    BEGIN
        SET @outcome = 1;
        RETURN;
    END

    DECLARE @isModeratorAct SMALLINT = CASE WHEN @authorId = @userId THEN 0 ELSE 1 END;
    IF (@isModeratorAct = 1)
    BEGIN
        DECLARE @mayModerate SMALLINT;
        EXEC HC6.nonApi_mayModerateChat
            @userId = @userId, @eventId = @eventId, @kennelId = @kennelId,
            @allowed = @mayModerate OUTPUT;
        IF (@mayModerate = 0)
        BEGIN
            SET @outcome = 3;
            SET @errorId = NEWID();
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
            VALUES (@errorId, @hcVersion, 'Not allowed to delete chat message',
                    'messageId=' + CAST(@messageId AS NVARCHAR(40)), @callerProcName, @userId);
            RETURN;
        END
    END

    BEGIN TRANSACTION;

    UPDATE HC.EventMessage
       SET Removed = 1, updatedAt = SYSDATETIMEOFFSET()
     WHERE id = @messageId AND Removed = 0;

    IF (@isModeratorAct = 1)
        INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
        VALUES ('HC6.nonApi_deleteChatMessage', 'Chat message removed by a moderator',
                CAST(@userId AS NVARCHAR(40)),
                LEFT('message=' + CAST(@messageId AS NVARCHAR(40))
                     + ' author=' + CAST(@authorId AS NVARCHAR(40))
                     + ' event=' + COALESCE(CAST(@eventId AS NVARCHAR(40)), '-')
                     + ' kennel=' + COALESCE(CAST(@kennelId AS NVARCHAR(40)), '-')
                     + ' thread=' + COALESCE(CAST(@threadId AS NVARCHAR(40)), '-')
                     + ' room=' + CASE WHEN @eventId IS NULL AND @kennelId IS NULL AND @threadId IS NULL
                                       THEN CAST(@roomType AS NVARCHAR(10)) ELSE '-' END
                     + ' via=' + @callerProcName
                     + ' text=' + COALESCE(@content, ''), 4000),
                SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;
    SET @outcome = 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcVersion, 'Unhandled error in nonApi_deleteChatMessage',
            ERROR_MESSAGE(), @callerProcName, @userId);
    THROW;
END CATCH
GO
