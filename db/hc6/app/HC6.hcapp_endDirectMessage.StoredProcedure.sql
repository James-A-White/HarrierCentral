CREATE OR ALTER PROCEDURE [HC6].[hcapp_endDirectMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @threadId    UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_endDirectMessage
-- Description: Unfriend (E9.F1.S7): the caller's row for the thread is
--   marked Removed. The thread stays readable to both; sendDirectMessage
--   refuses while either side's row is removed. The other party is not
--   told and only learns when they try to write.
-- Returns: rowset 0 — { success, errorMessage }
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 132, @param = NULL,
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

IF (@threadId IS NULL OR NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap f WHERE f.UserId = @userId AND f.ThreadId = @threadId))
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('thread=', COALESCE(CAST(@threadId AS NVARCHAR(40)), 'null'));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No such conversation', @detail, @procName, @userId);
    SELECT 0 AS success, 2006 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 2006 AS errorCode,
           'No such conversation' AS errorTitle, 'That conversation could not be found.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    UPDATE HC.HasherFriendMap SET Removed = 1, updatedAt = SYSDATETIMEOFFSET()
    WHERE UserId = @userId AND ThreadId = @threadId;
    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('HC6.hcapp_endDirectMessage', 'Direct message ended', CAST(@userId AS NVARCHAR(40)), 'thread=' + CAST(@threadId AS NVARCHAR(40)), SYSDATETIMEOFFSET());
    SELECT 1 AS success, NULL AS errorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in endDirectMessage', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 2007 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 2007 AS errorCode,
           'Something went wrong' AS errorTitle, 'That could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
