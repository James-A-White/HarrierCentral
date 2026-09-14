CREATE OR ALTER PROCEDURE [HC6].[hcapp_setChatRoomParticipation]
    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @roomType           INT              = NULL,
    -- 0 participate with push · 1 participate, badges only · 2 opt out
    @participationState SMALLINT         = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setChatRoomParticipation
-- Description: Sets how this hasher participates in one chat room, from
--   their settings console (James, 2026-09-14).
--
--     0  participate, with push notifications   (the default)
--     1  participate, no push — badges only
--     2  do not participate — the room is not listed
--
--   Stored on HC.EventMessageBadgeCounts, which is already the per-hasher,
--   per-room row. MERGE because a room the hasher has never opened has no
--   row yet, and changing a setting must not require visiting the room
--   first.
--
--   ⚠ Nothing pushes for a room yet, so 0 and 1 behave identically today.
--   The choice is recorded now so it is already right when push is built.
--
-- Authorization: HC6.UserMayEnterChatRoom — the same gate as reading and
--   sending. A hasher cannot set a preference for a room they could not
--   enter, which stops this becoming a way to probe which rooms exist.
--
-- Returns: rowset 0 — standard success envelope.
-- Author: Harrier Central
-- Created: 2026-09-14
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
    @spNumber = 107, @param = NULL,
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

IF (@roomType IS NULL OR @participationState IS NULL
    OR @participationState NOT IN (0, 1, 2))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad participation state',
            'roomType or participationState was missing or out of range', @procName, @userId);
    SELECT 0 AS Success, 'That setting could not be saved.' AS ErrorMessage;
    RETURN;
END

IF (HC6.UserMayEnterChatRoom(@userId, @roomType) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not in this room',
            'Setting participation for a room the hasher may not enter', @procName, @userId);
    SELECT 0 AS Success, 'That chat room is for the hashers who hold its role.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    -- Same full key as every other room statement: EventId, KennelId and
    -- ThreadId all NULL, MessageType naming the room. ThreadId is in the
    -- match because it is reserved for DMs — without it this would one day
    -- overwrite a conversation's row.
    MERGE INTO HC.EventMessageBadgeCounts AS Target
    USING (VALUES (@userId, @participationState)) AS Source (UserId, ParticipationState)
    ON (Target.UserId = Source.UserId
        AND Target.EventId IS NULL
        AND Target.KennelId IS NULL
        AND Target.ThreadId IS NULL
        AND Target.MessageType = @roomType)
    WHEN MATCHED THEN
        UPDATE SET Target.ParticipationState = Source.ParticipationState
    WHEN NOT MATCHED BY TARGET THEN
        -- LastSequenceCount 0: a room never opened has read nothing, so the
        -- unread count must stay honest rather than being zeroed by the act
        -- of changing a notification setting.
        INSERT (UserId, EventId, KennelId, MessageType, LastSequenceCount, ParticipationState)
        VALUES (Source.UserId, NULL, NULL, @roomType, 0, Source.ParticipationState);

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_setChatRoomParticipation',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
