CREATE OR ALTER FUNCTION [HC6].[KennelThreadMessageType]
(
    @kennelThread SMALLINT
)
RETURNS INT
AS
-- =====================================================================
-- Function: HC6.KennelThreadMessageType
-- Description: Which HC.EventMessage.MessageType a kennel thread is stored
--   under (E9.F1.S33, 2026-10-16). A kennel has two threads, both rows with
--   KennelId set and EventId NULL:
--     @kennelThread 0 → MessageType 0    the kennel's general chat
--     @kennelThread 1 → MessageType 100  its private Mismanagement chat
--   Sequence numbers (trgCreateSeqNum) and read marks
--   (EventMessageBadgeCounts, unique per MessageType) are already kept per
--   MessageType, so the two threads count and read independently.
--   100, not a small number: 1–8 are the platform-wide rooms' RoomTypes
--   (KennelId NULL), and 3 is the run reminders'. Permanent once used.
--
--   Every kennel-chat reader filters on this value. A reader that forgets
--   would show private messages in the general chat — so callers pass
--   @kennelThread and never write the literal.
--
-- Returns: the MessageType, or NULL for an unknown thread (refuse it).
-- Author: Harrier Central
-- Created: 2026-10-16
-- =====================================================================
BEGIN
    RETURN CASE COALESCE(@kennelThread, 0)
               WHEN 0 THEN 0
               WHEN 1 THEN 100
           END;
END
GO
