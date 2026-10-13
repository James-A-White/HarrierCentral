-- =====================================================================
-- RUN-ONCE (James, 2026-10-13): one read marker per person per chat.
-- HC.EventMessageBadgeCounts had no unique key on its natural key, so two
-- concurrent MERGEs could each insert a row; one identical pair exists
-- (2026-09-01). The SPs now MERGE WITH (HOLDLOCK) (86122c12); this makes
-- the database refuse a duplicate even from code that forgets the lock.
-- A SQL Server unique index treats NULLs as equal, which is what is wanted:
-- EventId / KennelId / ThreadId are NULL on most rows.
-- No triggers on this table; it is not synced to phones.
-- Idempotent. After running: move to db/hc6/app/archive/.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- Keep one row per key (the duplicate pair is identical, so any one will do).
;WITH d AS (
    SELECT id, ROW_NUMBER() OVER (
               PARTITION BY UserId, EventId, KennelId, ThreadId, MessageType
               ORDER BY LastSequenceCount DESC, id) AS rn
    FROM HC.EventMessageBadgeCounts WITH (TABLOCKX, HOLDLOCK)
)
DELETE FROM d WHERE rn > 1;
PRINT CONCAT('Duplicate rows removed: ', @@ROWCOUNT);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('HC.EventMessageBadgeCounts')
                 AND name = 'UX_EventMessageBadgeCounts_Thread')
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_EventMessageBadgeCounts_Thread
        ON HC.EventMessageBadgeCounts (UserId, EventId, KennelId, ThreadId, MessageType);
    PRINT 'Created UX_EventMessageBadgeCounts_Thread';
END
ELSE
    PRINT 'UX_EventMessageBadgeCounts_Thread already exists';

COMMIT TRANSACTION;
