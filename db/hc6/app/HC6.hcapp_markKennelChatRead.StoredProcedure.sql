CREATE OR ALTER PROCEDURE [HC6].[hcapp_markKennelChatRead]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @kennelId    UNIQUEIDENTIFIER = NULL,
    -- 0 the general chat, 1 the private Mismanagement chat (E9.F1.S33).
    @kennelThread SMALLINT        = 0
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
--   2026-10-16 (E9.F1.S33): optional @kennelThread. The read mark is the
--   row for (UserId, KennelId, MessageType) and the max is of that thread
--   only, so reading one of a kennel's two threads never clears the other.
--   Before this the MERGE matched any of the user's rows for the kennel.
--   Thread 1 is refused (errorType 13) unless HC6.UserInKennelMismanagement.
--   The mark is HC6.nonApi_markKennelChatRead (shared with the portal).
-- Idempotency: set-state — writes the read mark to the thread's current maximum
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

-- The mark itself is HC6.nonApi_markKennelChatRead (2026-10-16), shared with
-- the portal's hcportal_markKennelChatRead.
DECLARE @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);
DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);
BEGIN TRY
    EXEC HC6.nonApi_markKennelChatRead
        @userId = @userId, @kennelId = @kennelId, @kennelThread = @kennelThread,
        @hcVersion = @hcv, @callerProcName = @procName,
        @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
        @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;

    -- A missing kennel or a refusal answers with the app's error envelope,
    -- an unexpected error with { success: 0 }, as before.
    IF (@errorCode IN (1901, 1913))
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               @eTitle AS errorTitle, @eMsg AS errorUserMessage, @procName AS errorProc;
    ELSE
        SELECT CASE WHEN @errorCode IS NULL THEN 1 ELSE 0 END AS success;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcv, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success;
END CATCH
