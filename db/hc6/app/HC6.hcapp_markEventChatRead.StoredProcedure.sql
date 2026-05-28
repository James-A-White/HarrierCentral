CREATE OR ALTER PROCEDURE [HC6].[hcapp_markEventChatRead]

    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_markEventChatRead
-- Description: Records that the calling user has read all current
--   messages in an event chat. Upserts HC.EventMessageBadgeCounts with
--   the current message count, timestamp, and latest message ID.
--   Returns the FCM tokens of the user's other devices so the API shim
--   can fan-out a silent read_sync push, zeroing the badge on those
--   devices without showing a notification.
-- Parameters:
--   @deviceId    - Calling device (used for auth and excluded from fan-out)
--   @accessToken - Short-lived auth token (DeviceSecret only, @param = NULL)
--   @eventId     - The event whose chat was read
-- Returns:
--   On error: HC6 app error rowset (errorId, errorType, errorCode, errorTitle,
--             errorUserMessage, errorProc)
--   On success:
--     Rowset 0: LastSequenceCount (the count written)
--     Rowset 1: FcmToken rows for the user's other devices (fan-out targets)
-- Author: Harrier Central
-- Created: 2026-05-24
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

-- ----------------------------------------------------------------
-- Auth
-- ----------------------------------------------------------------
EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 61,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- ----------------------------------------------------------------
-- Validate
-- ----------------------------------------------------------------
IF @eventId IS NULL
BEGIN
    SET @errorCode = 1270; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null eventId', 'eventId is required', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY

    -- ----------------------------------------------------------------
    -- Snapshot current message state
    -- ----------------------------------------------------------------
    DECLARE @messageCount  INT;
    DECLARE @lastMessageId UNIQUEIDENTIFIER;

    SELECT @messageCount = COUNT(*)
    FROM HC.EventMessage
    WHERE EventId = @eventId AND removed = 0;

    SELECT TOP 1 @lastMessageId = id
    FROM HC.EventMessage
    WHERE EventId = @eventId AND removed = 0
    ORDER BY createdAt DESC;

    -- ----------------------------------------------------------------
    -- Upsert badge record
    -- ----------------------------------------------------------------
    BEGIN TRANSACTION;

    MERGE HC.EventMessageBadgeCounts AS target
    USING (SELECT @eventId AS EventId, @userId AS UserId) AS source
    ON (    target.EventId = source.EventId
        AND target.UserId  = source.UserId
        AND target.Removed = 0)
    WHEN MATCHED THEN
        UPDATE SET
            LastSequenceCount = @messageCount,
            LastReadAt        = SYSUTCDATETIME(),
            LastReadMessageId = @lastMessageId,
            updatedAt         = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (id, EventId, UserId, LastSequenceCount, LastReadAt, LastReadMessageId)
        VALUES (NEWID(), @eventId, @userId, @messageCount, SYSUTCDATETIME(), @lastMessageId);

    COMMIT TRANSACTION;

    -- ----------------------------------------------------------------
    -- Rowset 0: result
    -- ----------------------------------------------------------------
    SELECT @messageCount AS LastSequenceCount;

    -- ----------------------------------------------------------------
    -- Rowset 1: FCM tokens for the user's other devices.
    -- The API shim sends a silent read_sync push to each of these so
    -- their badge counts are zeroed without showing a notification.
    -- The current device is excluded — it already knows it has read.
    -- ----------------------------------------------------------------
    SELECT device.FcmToken
    FROM HC.Device device
    WHERE device.UserId    = @userId
      AND device.id       != @deviceId
      AND device.FcmToken IS NOT NULL;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID(); SET @errorCode = 9999; SET @errorType = 5;
    INSERT INTO HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, createdAt, updatedAt)
    VALUES (@errorId, 6, 'UnhandledError', ERROR_MESSAGE(), @procName, GETUTCDATE(), GETUTCDATE());
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Database error' AS errorTitle, 'An unexpected error occurred.' AS errorUserMessage, @procName AS errorProc;
END CATCH
