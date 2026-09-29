CREATE OR ALTER PROCEDURE [HC6].[hcapp_setHasherBlock]
    @deviceId             UNIQUEIDENTIFIER = NULL,
    @accessToken          NVARCHAR(1000)   = NULL,
    @targetPublicHasherId UNIQUEIDENTIFIER = NULL,
    @blocked              SMALLINT         = 1      -- 1 block, 0 unblock
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setHasherBlock
-- Description: Blocks or unblocks another hasher for the caller
--   (E9.F1.S16, James 2026-09-29). A block is the caller's own tool: every
--   chat reader hides the blocked hasher's messages from the caller, no
--   push from them reaches the caller's devices, and the unread counts
--   leave them out. The blocked hasher is told nothing and sees nothing
--   different. Directional, so A blocking B says nothing about B.
--
--   Stored as HC.HasherFriendMap (UserId = caller, Friend_UserId = target,
--   Ignore = 1) — the 2019 table that was waiting for exactly this. Unblock
--   sets Ignore back to 0 and keeps the row.
-- Parameters: @targetPublicHasherId — the other hasher's PUBLIC id (what the
--   chat rowsets carry as authorId); @blocked 1/0
-- Returns: rowset 0 — standard success envelope;
--          rowset 1 — the caller's blocked list, the shape of
--                     hcapp_getBlockedHashers, so the screen repaints
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
    @spNumber = 125, @param = NULL,
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

DECLARE @targetId UNIQUEIDENTIFIER;
SELECT @targetId = h.id FROM HC.Hasher h WHERE h.PublicHasherId = @targetPublicHasherId AND h.Removed = 0;

IF (@targetId IS NULL OR @targetId = @userId OR @blocked NOT IN (0, 1))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad block request',
            CONCAT('target=', COALESCE(CAST(@targetPublicHasherId AS NVARCHAR(40)), 'null'), ' blocked=', @blocked),
            @procName, @userId);
    SELECT 0 AS success, 1985 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1985 AS errorCode,
           'Not blocked' AS errorTitle,
           CASE WHEN @targetId = @userId THEN 'You cannot block yourself.'
                ELSE 'That hasher could not be found.' END AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    MERGE INTO HC.HasherFriendMap WITH (HOLDLOCK) AS Target
    USING (VALUES (@userId, @targetId)) AS Source (UserId, Friend_UserId)
       ON (Target.UserId = Source.UserId AND Target.Friend_UserId = Source.Friend_UserId)
    WHEN MATCHED THEN
        UPDATE SET Target.Ignore = @blocked, Target.updatedAt = SYSDATETIMEOFFSET()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UserId, Friend_UserId, Ignore)
        VALUES (Source.UserId, Source.Friend_UserId, @blocked);

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('HC6.hcapp_setHasherBlock', CASE WHEN @blocked = 1 THEN 'Hasher blocked' ELSE 'Hasher unblocked' END,
            CAST(@userId AS NVARCHAR(40)), 'target=' + CAST(@targetId AS NVARCHAR(40)), SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorMessage;

    SELECT UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS PublicHasherId,
           h.DisplayName AS DisplayName, h.Photo AS Photo, f.updatedAt AS BlockedAt
    FROM HC.HasherFriendMap f
    JOIN HC.Hasher h ON h.id = f.Friend_UserId
    WHERE f.UserId = @userId AND f.Ignore = 1
    ORDER BY f.updatedAt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in setHasherBlock',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 1986 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1986 AS errorCode,
           'Something went wrong' AS errorTitle,
           'That could not be saved. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
