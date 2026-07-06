-- =====================================================================
-- Run-once migration: kennel-level chat threads
-- Date: 2026-07-06 — design of record: project_kennel_standing_design
--
-- A kennel thread is an EventMessage row with KennelId set and EventId NULL
-- (no sentinel/fake events). EventMessage + EventMessageBadgeCounts gain
-- nullable KennelId; EventId columns become nullable. The per-thread
-- sequence trigger partitions by COALESCE(eventId, KennelId).
-- Neither table is mobile-synced (chat flows via FCM-delta) — no trigger dance.
-- Deploy order: run BEFORE deploying the kennel chat SPs.
-- =====================================================================
SET XACT_ABORT ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('HC.EventMessage') AND name = 'KennelId')
BEGIN
    ALTER TABLE [HC].[EventMessage] ALTER COLUMN [EventId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [HC].[EventMessage] ALTER COLUMN [PublicEventId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [HC].[EventMessage] ADD [KennelId] UNIQUEIDENTIFIER NULL
        CONSTRAINT [FK_EventMessage_Kennel] REFERENCES [HC].[Kennel]([id]);
    ALTER TABLE [HC].[EventMessage] ADD [PublicKennelId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [HC].[EventMessage] ADD CONSTRAINT [CK_EventMessage_Thread]
        CHECK (EventId IS NOT NULL OR KennelId IS NOT NULL);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('HC.EventMessageBadgeCounts') AND name = 'KennelId')
BEGIN
    ALTER TABLE [HC].[EventMessageBadgeCounts] ALTER COLUMN [EventId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [HC].[EventMessageBadgeCounts] ADD [KennelId] UNIQUEIDENTIFIER NULL;
    ALTER TABLE [HC].[EventMessageBadgeCounts] ADD CONSTRAINT [CK_EventMessageBadgeCounts_Thread]
        CHECK (EventId IS NOT NULL OR KennelId IS NOT NULL);
END
GO
CREATE INDEX [IX_EventMessage_KennelId] ON [HC].[EventMessage]([KennelId])
    WHERE [KennelId] IS NOT NULL;
GO
-- Sequence trigger: per-thread numbering — a thread is an event OR a kennel.
ALTER TRIGGER [HC].[trgCreateSeqNum]
   ON  [HC].[EventMessage]
   AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update only rows from the same thread(s) as the inserted messages.
    -- Thread key = eventId for run chats, KennelId for kennel chats.
    ;WITH affected AS (
        SELECT DISTINCT COALESCE(eventId, KennelId) AS threadId
        FROM inserted
    ),
    cte AS (
        SELECT
            em.id,
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(em.eventId, em.KennelId)
                ORDER BY em.createdAt ASC, em.id
            ) AS RowNum
        FROM HC.EventMessage em
        INNER JOIN affected a ON a.threadId = COALESCE(em.eventId, em.KennelId)
    )
    UPDATE em
    SET em.MessageSequenceCount = cte.RowNum
    FROM HC.EventMessage em
    INNER JOIN cte ON cte.id = em.id;
END
GO
SELECT COUNT(*) AS Messages,
       SUM(CASE WHEN KennelId IS NOT NULL THEN 1 ELSE 0 END) AS KennelThreadMsgs
FROM HC.EventMessage;
GO
