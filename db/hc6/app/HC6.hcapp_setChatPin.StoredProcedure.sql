CREATE OR ALTER PROCEDURE [HC6].[hcapp_setChatPin]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    -- Exactly ONE of these four names the chat being pinned.
    @eventId     UNIQUEIDENTIFIER = NULL,
    @kennelId    UNIQUEIDENTIFIER = NULL,
    @roomType    INT              = NULL,
    @threadId    UNIQUEIDENTIFIER = NULL,   -- a direct message (2026-10-01)
    @pinned      SMALLINT         = NULL,  -- 1 pin, 0 unpin
    -- With @kennelId: 0 the general chat, 1 the private Mismanagement chat
    -- (E9.F1.S33) — each pinned on its own.
    @kennelThread SMALLINT        = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setChatPin
-- Description: Pins or unpins one chat for the calling hasher (E9.F1.S8).
--   One SP for all three kinds, because the pin icon is one control.
--
--   Storage differs by kind, and deliberately so — see
--   db/hc6/app/archive/2026-09-15_chat_pinning.sql for the reasoning:
--     run     HasherEventMap.Pinned    0/1
--     kennel  HasherKennelMap.Pinned   0/1, NULL = default (home kennel)
--     kennel Mismanagement chat (@kennelThread 1, 2026-10-16)
--             EventMessageBadgeCounts.Pinned on the caller's row for
--             (KennelId, MessageType 100); NULL = unpinned
--     room    HC.Hasher.Unpinned*Rooms bit SET means "turned off"
--     DM      HasherFriendMap.Pinned   0/1 on the caller's own row for the
--             thread (2026-10-01) — never created here: no row, no DM
--
--   MISSING ROWS ARE CREATED (James, 2026-09-14: "that's not a problem...
--   just make one"). 42% of run chats that people have read have no HEM row,
--   because you can open any run's chat without RSVPing. The created row is
--   neutral: only EventId/KennelId/UserId are supplied and everything else
--   takes its default, giving AttendenceState 0 / RsvpState 0 / IsHare 0 —
--   a shape 276 existing rows already have. Verified 2026-09-14 that this is
--   inert: the HEM activity trigger fires but HC6.nonApi_refreshEventActivity
--   guards its UPDATE, so no event row is written and nothing re-syncs; and
--   history and run counts both filter on AttendenceState >= 20, so a
--   neutral row is invisible to both.
--
-- Idempotency: set-state — writes the pin (1/0), never toggles it
-- Authorization: a hasher may only pin their OWN chats, and @userId comes
--   from the token, never from a parameter — so there is nothing to spoof.
--   Rooms additionally go through HC6.UserMayEnterChatRoom, the same gate as
--   reading and sending, so a pin cannot be used to probe which rooms exist.
--   Run and kennel chats need no further gate: pinning is a private
--   preference that grants no access and reveals nothing.
--
-- Returns: rowset 0 — standard success envelope.
-- Author: Harrier Central
-- Created: 2026-09-15
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
    @spNumber = 108, @param = NULL,
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

-- Exactly one target, and a valid state.
DECLARE @targets INT =
      CASE WHEN @eventId  IS NOT NULL THEN 1 ELSE 0 END
    + CASE WHEN @kennelId IS NOT NULL THEN 1 ELSE 0 END
    + CASE WHEN @roomType IS NOT NULL THEN 1 ELSE 0 END
    + CASE WHEN @threadId IS NOT NULL THEN 1 ELSE 0 END;

IF (@targets <> 1 OR @pinned IS NULL OR @pinned NOT IN (0, 1))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad pin request',
            'Expected exactly one of eventId/kennelId/roomType/threadId and pinned in (0,1)',
            @procName, @userId);
    SELECT 0 AS Success, 'That chat could not be pinned.' AS ErrorMessage;
    RETURN;
END

-- A DM is pinned on the caller's own row for it; no row means not their DM.
IF (@threadId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap f
                                          WHERE f.UserId = @userId AND f.ThreadId = @threadId))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'No such conversation',
            CONCAT('thread=', CAST(@threadId AS NVARCHAR(40))), @procName, @userId);
    SELECT 0 AS Success, 'That conversation could not be found.' AS ErrorMessage;
    RETURN;
END

IF (@kennelId IS NOT NULL
    AND (HC6.KennelThreadMessageType(@kennelThread) IS NULL
         OR (COALESCE(@kennelThread, 0) <> 0 AND HC6.UserInKennelMismanagement(@userId, @kennelId) = 0)))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not in kennel mismanagement',
            CONCAT('kennelId=', CAST(@kennelId AS VARCHAR(40)), ' kennelThread=', @kennelThread),
            @procName, @userId);
    SELECT 0 AS Success, 'This chat is only for the kennel''s mismanagement.' AS ErrorMessage;
    RETURN;
END

IF (@roomType IS NOT NULL AND HC6.UserMayEnterChatRoom(@userId, @roomType) = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not in this room',
            'Pinning a room the hasher may not enter', @procName, @userId);
    SELECT 0 AS Success, 'That chat room is for the hashers who hold its role.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    -- ---------------------------------------------------------------
    -- A RUN's chat.
    -- ---------------------------------------------------------------
    IF (@eventId IS NOT NULL)
    BEGIN
        IF EXISTS (SELECT 1 FROM HC.HasherEventMap
                    WHERE UserId = @userId AND EventId = @eventId)
            UPDATE HC.HasherEventMap SET Pinned = @pinned
             WHERE UserId = @userId AND EventId = @eventId;
        ELSE
            -- KennelId is NOT NULL on HEM and is the event's kennel, not a
            -- choice. Everything else defaults, giving the neutral shape.
            INSERT HC.HasherEventMap (UserId, EventId, KennelId, Pinned)
            SELECT @userId, e.id, e.KennelId, @pinned
              FROM HC.Event e WHERE e.id = @eventId;
    END

    -- ---------------------------------------------------------------
    -- A KENNEL's chat. Writes the explicit 0/1 rather than clearing to
    -- NULL: once someone has touched the control, their choice is theirs
    -- and must not silently revert if the home kennel changes.
    -- ---------------------------------------------------------------
    IF (@kennelId IS NOT NULL AND COALESCE(@kennelThread, 0) = 0)
    BEGIN
        -- A new row (2026-10-13) is created the way posting in the kennel's
        -- chat creates one (hcapp_sendKennelMessage): Following = 0 and
        -- MemberSince NULL, because the columns DEFAULT to 1 and now, and
        -- pinning a chat is neither following the kennel nor joining it.
        -- Locked as there, so a double tap cannot hit the unique key.
        IF EXISTS (SELECT 1 FROM HC.HasherKennelMap WITH (UPDLOCK, HOLDLOCK)
                    WHERE UserId = @userId AND KennelId = @kennelId)
            UPDATE HC.HasherKennelMap SET Pinned = @pinned
             WHERE UserId = @userId AND KennelId = @kennelId;
        ELSE
            INSERT HC.HasherKennelMap (UserId, KennelId, Pinned, Following, MemberSince)
            VALUES (@userId, @kennelId, @pinned, 0, NULL);
    END

    -- ---------------------------------------------------------------
    -- A kennel's MISMANAGEMENT chat (E9.F1.S33): its own pin on the
    -- caller's read-mark row for that thread, made if they have none yet
    -- (LastSequenceCount 0 reads exactly as no row: everything unread).
    -- ---------------------------------------------------------------
    IF (@kennelId IS NOT NULL AND COALESCE(@kennelThread, 0) <> 0)
    BEGIN
        DECLARE @mt INT = HC6.KennelThreadMessageType(@kennelThread);
        MERGE HC.EventMessageBadgeCounts WITH (HOLDLOCK) AS t
        USING (SELECT @userId AS UserId, @kennelId AS KennelId, @mt AS MessageType) AS s
        ON (t.UserId = s.UserId AND t.KennelId = s.KennelId AND t.EventId IS NULL
            AND t.ThreadId IS NULL AND t.MessageType = s.MessageType)
        WHEN MATCHED THEN UPDATE SET t.Pinned = @pinned
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (UserId, KennelId, MessageType, LastSequenceCount, Pinned)
            VALUES (s.UserId, s.KennelId, s.MessageType, 0, @pinned);
    END

    -- ---------------------------------------------------------------
    -- A DIRECT MESSAGE: the caller's own row only — the other side's pin is
    -- theirs.
    -- ---------------------------------------------------------------
    IF (@threadId IS NOT NULL)
        UPDATE HC.HasherFriendMap SET Pinned = @pinned
         WHERE UserId = @userId AND ThreadId = @threadId;

    -- ---------------------------------------------------------------
    -- A ROOM. The mirrors store DEVIATIONS, so pinning CLEARS the bit and
    -- unpinning SETS it. Which mirror is decided by the catalog, never
    -- guessed — 0x08 is RA in MismanagementRoles but ManageHashCash in
    -- AppAccessFlags, so the column matters as much as the bit.
    -- ---------------------------------------------------------------
    IF (@roomType IS NOT NULL)
    BEGIN
        DECLARE @grantColumn VARCHAR(8), @grantMask INT;
        SELECT @grantColumn = c.GrantColumn, @grantMask = c.GrantMask
          FROM HC6.ChatRoomCatalog() c WHERE c.RoomType = @roomType;

        IF (@grantColumn = 'mm')
            UPDATE HC.Hasher
               SET UnpinnedMismanagementRooms = CASE WHEN @pinned = 1
                        THEN UnpinnedMismanagementRooms & ~@grantMask
                        ELSE UnpinnedMismanagementRooms | @grantMask END
             WHERE id = @userId;
        ELSE IF (@grantColumn IN ('flags', 'platform', 'beta'))  -- platform and beta rooms mirror here too
            UPDATE HC.Hasher
               SET UnpinnedAppAccessRooms = CASE WHEN @pinned = 1
                        THEN UnpinnedAppAccessRooms & ~@grantMask
                        ELSE UnpinnedAppAccessRooms | @grantMask END
             WHERE id = @userId;
    END

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_setChatPin',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
