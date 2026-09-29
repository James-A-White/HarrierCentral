CREATE OR ALTER PROCEDURE [HC6].[hcapp_startDirectMessage]
    @deviceId             UNIQUEIDENTIFIER = NULL,
    @accessToken          NVARCHAR(1000)   = NULL,
    @targetPublicHasherId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_startDirectMessage
-- Description: The door to a direct message (E9.F1.S19): "Message <name>"
--   from a message in any chat. Answers with ONE of:
--     open      — already friends, or the target accepts anyone; the
--                 thread exists (minted now if not). Go to it.
--     requested — the target is friends-only: a request is on file (this
--                 tap or an earlier one). ALSO the answer when the target
--                 has BLOCKED the caller, or once declined: nothing may
--                 reveal either. Nothing is written in those cases.
--     refused   — the target accepts nobody.
--     blocked   — the CALLER has blocked the target (their own doing).
--   Two rows in HC.HasherFriendMap carry the pair; FriendSince NULL is a
--   pending request; both set = friends; a shared ThreadId is the thread.
--   Two hashers who request each other are friends on the second tap.
-- Returns: rowset 0 — { success, errorMessage }
--          rowset 1 — { Outcome, ThreadId, OtherPublicHasherId,
--                       OtherDisplayName, OtherPhoto }
--          rowset 2 (new request only) — push detail { Kind, ThreadId,
--                       FromPublicHasherId, FromDisplayName, FromPhoto }
--          rowset 3 (new request only) — recipients { UserId, FcmToken,
--                       BadgeTotal }, builds >= HC6.MinBuildForDmPush
--   The API sends the push and strips rowsets 2-3.
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
    @spNumber = 129, @param = NULL,
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

DECLARE @targetId UNIQUEIDENTIFIER, @targetPrefs INT;
SELECT @targetId = h.id, @targetPrefs = h.Preferences
FROM HC.Hasher h WHERE h.PublicHasherId = @targetPublicHasherId AND h.Removed = 0;

IF (@targetId IS NULL OR @targetId = @userId)
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('target=', COALESCE(CAST(@targetPublicHasherId AS NVARCHAR(40)), 'null'));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Cannot message', @detail, @procName, @userId);
    SELECT 0 AS success, 2002 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 2002 AS errorCode,
           'Cannot message' AS errorTitle, CASE WHEN @targetId = @userId THEN 'You cannot message yourself.' ELSE 'That hasher could not be found.' END AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @outcome NVARCHAR(10), @threadId UNIQUEIDENTIFIER, @newRequest SMALLINT = 0;
DECLARE @mineSince DATETIMEOFFSET(7), @mineRemoved SMALLINT, @mineIgnore SMALLINT, @mineThread UNIQUEIDENTIFIER, @mineExists SMALLINT = 0;
DECLARE @theirSince DATETIMEOFFSET(7), @theirRemoved SMALLINT, @theirIgnore SMALLINT, @theirThread UNIQUEIDENTIFIER, @theirExists SMALLINT = 0;

SELECT @mineExists = 1, @mineSince = FriendSince, @mineRemoved = Removed, @mineIgnore = Ignore, @mineThread = ThreadId
FROM HC.HasherFriendMap WHERE UserId = @userId AND Friend_UserId = @targetId;
SELECT @theirExists = 1, @theirSince = FriendSince, @theirRemoved = Removed, @theirIgnore = Ignore, @theirThread = ThreadId
FROM HC.HasherFriendMap WHERE UserId = @targetId AND Friend_UserId = @userId;

DECLARE @pref SMALLINT = HC6.DirectMessagePreference(@targetPrefs);

BEGIN TRY
    BEGIN TRANSACTION;

    IF (@mineIgnore = 1)
        SET @outcome = 'blocked';
    ELSE IF (@theirIgnore = 1)
        SET @outcome = 'requested';                       -- silent: a block must not show
    ELSE IF (@mineExists = 1 AND @theirExists = 1 AND @mineSince IS NOT NULL AND @theirSince IS NOT NULL
             AND @mineRemoved = 0 AND @theirRemoved = 0)
        SET @outcome = 'open';                            -- friends already
    ELSE IF (@pref = 2)
        SET @outcome = 'refused';
    ELSE IF (@pref = 1 OR (@theirExists = 1 AND @theirSince IS NULL AND @theirRemoved = 0))
        SET @outcome = 'open';                            -- accepts anyone, or they asked me first
    ELSE IF (@mineExists = 1)
        SET @outcome = 'requested';                       -- pending, declined or unfriended: nothing changes
    ELSE
    BEGIN
        SET @outcome = 'requested'; SET @newRequest = 1;
        INSERT HC.HasherFriendMap (UserId, Friend_UserId, FriendSince) VALUES (@userId, @targetId, NULL);
    END

    IF (@outcome = 'open')
    BEGIN
        SET @threadId = COALESCE(@mineThread, @theirThread, NEWID());
        DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();
        MERGE INTO HC.HasherFriendMap WITH (HOLDLOCK) AS T
        USING (VALUES (@userId, @targetId), (@targetId, @userId)) AS S (UserId, Friend_UserId)
           ON T.UserId = S.UserId AND T.Friend_UserId = S.Friend_UserId
        WHEN MATCHED THEN UPDATE SET FriendSince = COALESCE(T.FriendSince, @now), ThreadId = @threadId, Removed = 0, updatedAt = @now
        WHEN NOT MATCHED BY TARGET THEN INSERT (UserId, Friend_UserId, FriendSince, ThreadId) VALUES (S.UserId, S.Friend_UserId, @now, @threadId);
    END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorMessage;

    SELECT @outcome AS Outcome,
           CASE WHEN @outcome = 'open' THEN UPPER(CAST(@threadId AS NVARCHAR(40))) END AS ThreadId,
           UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS OtherPublicHasherId,
           h.DisplayName AS OtherDisplayName, h.Photo AS OtherPhoto
    FROM HC.Hasher h WHERE h.id = @targetId;

    IF (@newRequest = 1)
    BEGIN
        SELECT 'dmRequest' AS Kind, CAST(NULL AS NVARCHAR(40)) AS ThreadId,
               UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS FromPublicHasherId,
               h.DisplayName AS FromDisplayName, h.Photo AS FromPhoto
        FROM HC.Hasher h WHERE h.id = @userId;

        DECLARE @idleCutoff DATETIMEOFFSET(7) = DATEADD(DAY, -180, SYSDATETIMEOFFSET());
        SELECT DISTINCT d.UserId, d.FcmToken,
               CASE WHEN TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForIconBadge() THEN bt.BadgeTotal END AS BadgeTotal
        FROM HC.Device d
        CROSS APPLY HC6.UserUnreadChatTotal(d.UserId) bt
        WHERE d.UserId = @targetId AND d.removed = 0 AND d.FcmToken IS NOT NULL
          AND d.LastLogin >= @idleCutoff
          AND TRY_CAST(d.BuildNumber AS INT) >= HC6.MinBuildForDmPush();
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in startDirectMessage', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 2003 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 2003 AS errorCode,
           'Something went wrong' AS errorTitle, 'That conversation could not be started. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
