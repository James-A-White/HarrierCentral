-- =====================================================================
-- Run-once (2026-10-14, James: "P1, yes add the unique index"):
-- UX_Event_RunsPageImport — at most one live imported run per kennel and
-- runs-page run number (EventFacebookId = 'runspage:<n>'). The backstop
-- behind nonApi_importRunsPageRuns' per-kennel sp_getapplock (E14.G2.R5).
-- CREATE INDEX writes no rows, so the Event UpdatedAt trigger does not
-- fire and no phone re-syncs. Checked first: 0 duplicate groups among the
-- 21 rows in scope. Idempotent. Archive after running.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Event_RunsPageImport' AND object_id = OBJECT_ID('HC.Event'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_Event_RunsPageImport
        ON HC.Event (KennelId, EventFacebookId)
        WHERE InboundIntegrationId = 6 AND deleted = 0 AND EventFacebookId IS NOT NULL;
GO
