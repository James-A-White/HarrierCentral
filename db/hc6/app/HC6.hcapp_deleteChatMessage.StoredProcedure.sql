CREATE OR ALTER PROCEDURE [HC6].[hcapp_deleteChatMessage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @messageId   UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_deleteChatMessage
-- Description: Deletes one chat message — run, kennel or room — for
--   everyone (E9.F1.S13/S14, 2026-09-29). The caller's own message, or
--   anyone's if they moderate that thread. The rule is in
--   HC6.nonApi_deleteChatMessage; this SP authenticates and replies.
--
--   A standard token: the target is a message, and who may remove it is
--   decided by the server from the token's user, so binding the token to
--   the message id would add a failure mode without removing a risk.
-- Parameters: @messageId — the message (HC.EventMessage.id)
-- Returns: rowset 0 — standard success envelope { success, errorMessage };
--          on error { success, errorCode, errorType } then the error detail
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
    @spNumber = 123, @param = NULL,
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

IF (@messageId IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            'messageId was not supplied', @procName, @userId);
    SELECT 0 AS success, 1980 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1980 AS errorCode,
           'Missing fields' AS errorTitle,
           'That message could not be deleted. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    DECLARE @outcome SMALLINT;
    DECLARE @hcVersion NVARCHAR(50) = HC6.DeviceHcVersion(@deviceId);
    EXEC HC6.nonApi_deleteChatMessage
        @userId = @userId, @messageId = @messageId,
        @callerProcName = @procName, @hcVersion = @hcVersion,
        @outcome = @outcome OUTPUT, @errorId = @errorId OUTPUT;

    IF (@outcome = 1)
    BEGIN
        SELECT 1 AS success, NULL AS errorMessage;
        RETURN;
    END

    DECLARE @code INT = CASE @outcome WHEN 3 THEN 1982 ELSE 1981 END;
    SELECT 0 AS success, @code AS errorCode, 3 AS errorType;
    SELECT @errorId AS errorId, 3 AS errorType, @code AS errorCode,
           CASE @outcome WHEN 3 THEN 'Not allowed' ELSE 'Not found' END AS errorTitle,
           CASE @outcome
               WHEN 3 THEN 'You can delete your own messages. Only a chat administrator can delete someone else''s.'
               ELSE 'That message is no longer in the chat.' END AS errorUserMessage,
           @procName AS errorProc;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in deleteChatMessage',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1983 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1983 AS errorCode,
           'Something went wrong' AS errorTitle,
           'That message could not be deleted. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
