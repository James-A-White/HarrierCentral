CREATE OR ALTER PROCEDURE [HC6].[hcportal_markEventChatRead]

-- Required parameters (nullable so validation errors are caught in SQL)
@deviceId    UNIQUEIDENTIFIER = NULL,
@accessToken NVARCHAR(1000)   = NULL,
@publicEventId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_markEventChatRead
-- Description: Records that the calling user has read all current
--   messages in an event chat. Upserts HC.EventMessageBadgeCounts with
--   the current message count, timestamp, and latest message ID.
--   Returns the FCM tokens of the user's other devices so the API shim
--   can fan-out a silent read_sync push, zeroing the badge on those
--   devices without showing a notification.
-- Parameters:
--   @deviceId      - Calling device (used for auth and excluded from fan-out)
--   @accessToken   - Short-lived auth token
--   @publicEventId - The event whose chat was read
-- Returns:
--   On error:   HC6 standard envelope (Success, ErrorMessage)
--   On success:
--     Rowset 0: LastSequenceCount (the count written)
--     Rowset 1: FcmToken rows for the user's other devices (fan-out targets)
-- Author: Harrier Central
-- Created: 2026-03-23
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- ----------------------------------------------------------------
    -- Auth
    -- ----------------------------------------------------------------
    DECLARE @authError  NVARCHAR(255),
            @hasherId   UNIQUEIDENTIFIER,
            @callerType INT;
    DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

    EXEC HC6.ValidatePortalAuth
        @deviceId, @accessToken, @procName, @publicEventId,
        @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    IF @callerType != 0
    BEGIN
        SELECT 0 AS Success, 'Service accounts may not mark chats as read' AS ErrorMessage;
        RETURN;
    END

    -- ----------------------------------------------------------------
    -- Validate
    -- ----------------------------------------------------------------
    IF @publicEventId IS NULL
    BEGIN
        SELECT 0 AS Success, 'publicEventId is required' AS ErrorMessage;
        RETURN;
    END

    -- ----------------------------------------------------------------
    -- Resolve event
    -- ----------------------------------------------------------------
    DECLARE @eventId UNIQUEIDENTIFIER;
    SELECT @eventId = id FROM HC.Event WHERE PublicEventId = @publicEventId;

    IF @eventId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Event not found' AS ErrorMessage;
        RETURN;
    END

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
    USING (SELECT @eventId AS EventId, @hasherId AS UserId) AS source
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
        VALUES (NEWID(), @eventId, @hasherId, @messageCount, SYSUTCDATETIME(), @lastMessageId);

    COMMIT TRANSACTION;

    -- ----------------------------------------------------------------
    -- Rowset 0: result (used by the API shim to confirm success)
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
    WHERE device.UserId    = @hasherId
      AND device.id       != @deviceId
      AND device.FcmToken IS NOT NULL;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
