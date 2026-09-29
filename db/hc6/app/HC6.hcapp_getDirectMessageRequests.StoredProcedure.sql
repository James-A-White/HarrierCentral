CREATE OR ALTER PROCEDURE [HC6].[hcapp_getDirectMessageRequests]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getDirectMessageRequests
-- Description: Requests to message the caller that are still pending
--   (E9.F1.S19): the other hasher's row exists with FriendSince NULL and
--   Removed 0, the caller has no row back yet, and the caller has not
--   blocked them. Shown at the top of the chat list with Accept / Decline.
-- Returns: rowset 0 — { FromPublicHasherId, DisplayName, Photo, RequestedAt }
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
    @spNumber = 130, @param = NULL,
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

BEGIN TRY
    SELECT UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS FromPublicHasherId,
           h.DisplayName AS DisplayName, h.Photo AS Photo, f.createdAt AS RequestedAt
    FROM HC.HasherFriendMap f
    JOIN HC.Hasher h ON h.id = f.UserId AND h.Removed = 0
    WHERE f.Friend_UserId = @userId AND f.FriendSince IS NULL AND f.Removed = 0 AND f.Ignore = 0
      AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap m
                      WHERE m.UserId = @userId AND m.Friend_UserId = f.UserId AND (m.Ignore = 1 OR m.Removed = 0))
    ORDER BY f.createdAt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getDirectMessageRequests', ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
