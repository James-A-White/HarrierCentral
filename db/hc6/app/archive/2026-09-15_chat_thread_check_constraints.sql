-- =====================================================================
-- Run-once: let the thread CHECK constraints admit a global room.
--
-- THE BUG
--   HC.EventMessage and HC.EventMessageBadgeCounts each carry
--       ([EventId] IS NOT NULL OR [KennelId] IS NOT NULL)
--   which predates chat rooms and encodes "a message belongs to a run or a
--   kennel". A platform-wide room has BOTH keys NULL, so every write for a
--   room was refused:
--       The MERGE statement conflicted with the CHECK constraint
--       "CK_EventMessageBadgeCounts_Thread"
--
--   That blocked hcapp_setChatRoomParticipation, the @markRead MERGE in
--   hcapp_getRoomMessages, and the message INSERT in hcapp_sendRoomMessage —
--   so no room message could ever be sent. The room list worked because
--   reading touches neither constraint, which is exactly why this survived
--   to production: every check run before deploying was a READ.
--
-- THE FIX
--   Widen the rule rather than drop it. The intent — a message must belong
--   to SOMETHING — is right and worth keeping; it simply predates the third
--   and fourth kinds of thread:
--       run     EventId set
--       kennel  KennelId set
--       room    MessageType <> 0      (the room id; 0 is run/kennel chat)
--       DM      ThreadId set          (reserved, not yet used)
--
--   A check constraint's definition cannot be altered in place, so each is
--   dropped and recreated WITH CHECK, which validates the existing rows as
--   it goes. All 1,227 messages and 632 badge rows carry an EventId or a
--   KennelId, so they satisfy the new rule unchanged.
--
-- SAFETY
--   * Neither table is in any sync SP, and neither has an UpdatedAt trigger.
--   * DDL does not fire DML triggers, and a constraint swap writes no rows.
--   * WITH CHECK means a failure here means existing data would have
--     violated the new rule — it cannot leave the table unprotected.
--
-- Author: Harrier Central
-- Created: 2026-09-15
-- =====================================================================

SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM sys.check_constraints
            WHERE name = 'CK_EventMessage_Thread'
              AND parent_object_id = OBJECT_ID('HC.EventMessage'))
    ALTER TABLE HC.EventMessage DROP CONSTRAINT CK_EventMessage_Thread;
GO

ALTER TABLE HC.EventMessage WITH CHECK
    ADD CONSTRAINT CK_EventMessage_Thread CHECK (
        [EventId] IS NOT NULL
     OR [KennelId] IS NOT NULL
     OR [ThreadId] IS NOT NULL
     OR [MessageType] <> 0
    );
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints
            WHERE name = 'CK_EventMessageBadgeCounts_Thread'
              AND parent_object_id = OBJECT_ID('HC.EventMessageBadgeCounts'))
    ALTER TABLE HC.EventMessageBadgeCounts DROP CONSTRAINT CK_EventMessageBadgeCounts_Thread;
GO

ALTER TABLE HC.EventMessageBadgeCounts WITH CHECK
    ADD CONSTRAINT CK_EventMessageBadgeCounts_Thread CHECK (
        [EventId] IS NOT NULL
     OR [KennelId] IS NOT NULL
     OR [ThreadId] IS NOT NULL
     OR [MessageType] <> 0
    );
GO

SELECT c.name AS ConstraintName, c.is_disabled AS Disabled_MustBeZero,
       c.is_not_trusted AS NotTrusted_MustBeZero, c.definition
FROM sys.check_constraints c
WHERE c.name IN ('CK_EventMessage_Thread','CK_EventMessageBadgeCounts_Thread');
GO
