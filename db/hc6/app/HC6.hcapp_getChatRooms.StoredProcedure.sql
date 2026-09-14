CREATE OR ALTER PROCEDURE [HC6].[hcapp_getChatRooms]
    @deviceId        UNIQUEIDENTIFIER = NULL,
    @accessToken     NVARCHAR(1000)   = NULL,
    -- 1 also returns rooms the hasher has opted OUT of (ParticipationState 2).
    -- The settings console passes 1; the chat list passes 0. Without it,
    -- opting out would be a one-way door with no way back.
    @includeOptedOut SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getChatRooms
-- Description: The rooms THIS hasher may enter, with each room's unread
--   count and mute state. One call, whatever the rooms happen to be.
--
--   This is what makes new rooms cost no app release. The phone asks the
--   server which rooms it has rather than holding a hard-coded list, so
--   appending a row to HC6.ChatRoomCatalog() and redeploying reaches every
--   installed app immediately — no build, no store review, no upgrade wait
--   (James, 2026-09-14: "make it easy to extend to other rooms as well").
--   It also means a hasher who is made an RA today sees the RA room today.
--
--   Returns ZERO rows for a hasher who holds none of the roles, which is a
--   normal answer and not an error — most hashers are in no room at all.
--
--   participationState per room (James, 2026-09-14):
--     0  participate, with push   1  participate, badges only   2  opted out
--   Opted-out rooms are omitted unless @includeOptedOut = 1.
--
-- Authorization: per room, via HC6.UserMayEnterChatRoom — the same gate the
--   two message SPs use, so a room can never be listed that the reader is
--   then refused.
--
-- Returns: rowset 0 — one row per room the hasher may enter:
--   roomType, roomName, sortOrder, unreadCount, newestSequenceCount,
--   participationState
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
    @spNumber = 106, @param = NULL,
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

    SELECT
        c.RoomType                                   AS roomType,
        c.RoomName                                   AS roomName,
        c.SortOrder                                  AS sortOrder,
        -- Messages by OTHER people that this hasher has not reached yet.
        (SELECT COUNT(*)
           FROM HC.EventMessage em
          WHERE em.EventId IS NULL AND em.KennelId IS NULL AND em.ThreadId IS NULL
            AND em.MessageType = c.RoomType
            AND em.Removed = 0
            AND em.UserId <> @userId
            AND em.MessageSequenceCount > ISNULL(b.LastSequenceCount, 0)) AS unreadCount,
        ISNULL((SELECT MAX(em.MessageSequenceCount)
                  FROM HC.EventMessage em
                 WHERE em.EventId IS NULL AND em.KennelId IS NULL AND em.ThreadId IS NULL
                   AND em.MessageType = c.RoomType
                   AND em.Removed = 0), 0)           AS newestSequenceCount,
        ISNULL(b.ParticipationState, 0)              AS participationState
    FROM HC6.ChatRoomCatalog() c
    -- The badge row is per hasher per room. LEFT JOIN because a room never
    -- opened has no row yet, and that must read as "nothing read", not as
    -- "no room".
    LEFT JOIN HC.EventMessageBadgeCounts b
           ON b.UserId = @userId
          AND b.EventId IS NULL
          AND b.KennelId IS NULL
          AND b.ThreadId IS NULL
          AND b.MessageType = c.RoomType
    WHERE HC6.UserMayEnterChatRoom(@userId, c.RoomType) = 1
      -- ISNULL: a room never opened has no badge row, and no row means the
      -- default, which is participating.
      AND (@includeOptedOut = 1 OR ISNULL(b.ParticipationState, 0) <> 2)
    ORDER BY c.SortOrder;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getChatRooms',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
