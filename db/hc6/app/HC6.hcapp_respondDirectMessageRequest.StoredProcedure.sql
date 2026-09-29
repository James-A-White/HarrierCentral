CREATE OR ALTER PROCEDURE [HC6].[hcapp_respondDirectMessageRequest]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @fromPublicHasherId UNIQUEIDENTIFIER = NULL,
    @accept             SMALLINT         = NULL   -- 1 accept, 0 decline
AS
-- =====================================================================
-- Procedure: HC6.hcapp_respondDirectMessageRequest
-- Description: Accept or decline a request to message the caller
--   (E9.F1.S19). Accept: both rows become friends (FriendSince) sharing a
--   freshly minted ThreadId, and the requester is pushed "<name> accepted".
--   Decline: the requester's row is marked Removed and they are told
--   NOTHING — their app keeps saying "requested". A decline is final
--   unless the caller later starts a DM with them.
-- Returns: rowset 0 — { success, errorMessage }
--          rowset 1 — { Outcome ('open' | 'declined'), ThreadId,
--                       OtherPublicHasherId, OtherDisplayName, OtherPhoto }
--          rowset 2 (accept) — push detail { Kind 'dmAccepted', ThreadId,
--                       FromPublicHasherId, FromDisplayName, FromPhoto }
--          rowset 3 (accept) — recipients { UserId, FcmToken, BadgeTotal }
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
    @spNumber = 131, @param = NULL,
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

DECLARE @fromId UNIQUEIDENTIFIER;
SELECT @fromId = h.id FROM HC.Hasher h WHERE h.PublicHasherId = @fromPublicHasherId AND h.Removed = 0;
DECLARE @pending SMALLINT = CASE WHEN EXISTS (SELECT 1 FROM HC.HasherFriendMap f
    WHERE f.UserId = @fromId AND f.Friend_UserId = @userId AND f.FriendSince IS NULL AND f.Removed = 0) THEN 1 ELSE 0 END;

IF (@fromId IS NULL OR @accept NOT IN (0, 1) OR @pending = 0)
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('from=', COALESCE(CAST(@fromPublicHasherId AS NVARCHAR(40)), 'null'), ' accept=', @accept, ' pending=', @pending);
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No such request', @detail, @procName, @userId);
    SELECT 0 AS success, 2004 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 2004 AS errorCode,
           'No such request' AS errorTitle, 'That request is no longer waiting.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @threadId UNIQUEIDENTIFIER, @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();
BEGIN TRY
    BEGIN TRANSACTION;
    IF (@accept = 1)
    BEGIN
        SET @threadId = NEWID();
        MERGE INTO HC.HasherFriendMap WITH (HOLDLOCK) AS T
        USING (VALUES (@userId, @fromId), (@fromId, @userId)) AS S (UserId, Friend_UserId)
           ON T.UserId = S.UserId AND T.Friend_UserId = S.Friend_UserId
        WHEN MATCHED THEN UPDATE SET FriendSince = COALESCE(T.FriendSince, @now), ThreadId = @threadId, Removed = 0, updatedAt = @now
        WHEN NOT MATCHED BY TARGET THEN INSERT (UserId, Friend_UserId, FriendSince, ThreadId) VALUES (S.UserId, S.Friend_UserId, @now, @threadId);
    END
    ELSE
        UPDATE HC.HasherFriendMap SET Removed = 1, updatedAt = @now
        WHERE UserId = @fromId AND Friend_UserId = @userId AND FriendSince IS NULL;
    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorMessage;
    SELECT CASE WHEN @accept = 1 THEN 'open' ELSE 'declined' END AS Outcome,
           UPPER(CAST(@threadId AS NVARCHAR(40))) AS ThreadId,
           UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS OtherPublicHasherId, h.DisplayName AS OtherDisplayName, h.Photo AS OtherPhoto
    FROM HC.Hasher h WHERE h.id = @fromId;

    IF (@accept = 1)
    BEGIN
        SELECT 'dmAccepted' AS Kind, UPPER(CAST(@threadId AS NVARCHAR(40))) AS ThreadId,
               UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS FromPublicHasherId, h.DisplayName AS FromDisplayName, h.Photo AS FromPhoto
        FROM HC.Hasher h WHERE h.id = @userId;
        DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());
        SELECT DISTINCT d.UserId, d.FcmToken,
               CASE WHEN TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForIconBadge() THEN bt.BadgeTotal END AS BadgeTotal
        FROM HC.Device d CROSS APPLY HC6.UserUnreadChatTotal(d.UserId) bt
        WHERE d.UserId = @fromId AND d.removed = 0 AND d.FcmToken IS NOT NULL AND d.LastLogin >= @idleCutoff
          AND TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForDmPush();
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in respondDirectMessageRequest', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 2005 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 2005 AS errorCode,
           'Something went wrong' AS errorTitle, 'That could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
