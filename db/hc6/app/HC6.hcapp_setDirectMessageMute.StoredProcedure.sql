CREATE OR ALTER PROCEDURE [HC6].[hcapp_setDirectMessageMute]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @threadId    UNIQUEIDENTIFIER = NULL,
    @mute        SMALLINT         = NULL   -- 1 mute (silent pushes), 0 normal
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setDirectMessageMute
-- Description: Mute one direct message thread for the caller (E9.F1.S7):
--   HasherFriendMap.FriendNotificationPreference on the caller's row —
--   3 (mute, the Silver Bell) or 0 (auto). The other party is not told.
-- Returns: rowset 0 — { success, errorMessage }; rowset 1 — { Muted }
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
    @spNumber = 133, @param = NULL,
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

IF (@threadId IS NULL OR @mute NOT IN (0, 1)
    OR NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap f WHERE f.UserId = @userId AND f.ThreadId = @threadId))
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('thread=', COALESCE(CAST(@threadId AS NVARCHAR(40)), 'null'), ' mute=', @mute);
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No such conversation', @detail, @procName, @userId);
    SELECT 0 AS success, 2008 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 2008 AS errorCode,
           'No such conversation' AS errorTitle, 'That conversation could not be found.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    UPDATE HC.HasherFriendMap SET FriendNotificationPreference = CASE WHEN @mute = 1 THEN 3 ELSE 0 END, updatedAt = SYSDATETIMEOFFSET()
    WHERE UserId = @userId AND ThreadId = @threadId;
    SELECT 1 AS success, NULL AS errorMessage;
    SELECT @mute AS Muted;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in setDirectMessageMute', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 2009 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 2009 AS errorCode,
           'Something went wrong' AS errorTitle, 'That could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
