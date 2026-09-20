-- =====================================================================
-- 2026-09-20 — make PackTrack trails archived BEFORE 2026-09-12 reachable
--              by incremental sync (run once)
--
-- Why this is needed
-- ------------------
-- E5.F7.S1 added hem.TrackGzip / TrackPointCount / TrackFirstPointAt /
-- TrackLastPointAt to the HasherEventMap rowset of HC6.hcapp_syncUserData on
-- 2026-09-12. That rowset is watermarked: `WHERE hem.updatedAt > @ua`.
--
-- Adding a COLUMN to a watermarked rowset does not make existing rows
-- reappear. Every track archived before 2026-09-12 already sat behind every
-- phone's watermark, so those rows are never sent again and the phone has
-- no bytes to draw — the trails map comes up empty until the user presses
-- Reload Data, which drops the watermark and refetches everything.
--
-- James hit this on 2026-09-20: 191 of his own archived tracks were in this
-- state. 737 rows across 52 users in total. The nightly archiver stamps
-- updatedAt correctly (verified: 2026-09-19's tracks all carry
-- updatedAt = 2026-09-20 03:30:01), so this is a one-off backlog, not an
-- ongoing fault, and nothing in the trigger needs changing.
--
-- The fix is to touch updatedAt on exactly those rows so each one is sent
-- once more. updatedAt is written as a bare SYSDATETIME(): the table's
-- trgUpdateModifiedOnDateForHasherEventMap trigger re-applies the row's
-- updatedAtBias on top, which is what keeps the paged replication ordering
-- deterministic (see project_updated_at_bias).
--
-- Cost: 737 rows, biggest single user 234 rows — under one 250-row sync page
-- each. No column is added and no synced column's VALUE changes, so no
-- trigger needs disabling.
--
-- LESSON (why this file exists rather than a quiet UPDATE): adding a column
-- to a watermarked sync rowset is a schema change for the CLIENTS as well as
-- the server. The rowset only carries rows whose updatedAt has moved since
-- the phone last looked, so the new column reaches history only if history
-- is touched. Any future column added to a sync rowset needs the same sweep.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @cutoff DATETIMEOFFSET = '2026-09-12T00:00:00+00:00';

SELECT COUNT(*) AS RowsToTouch, COUNT(DISTINCT UserId) AS UsersAffected
FROM HC.HasherEventMap
WHERE TrackGzip IS NOT NULL AND removed = 0 AND updatedAt < @cutoff;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE HC.HasherEventMap
       SET updatedAt = SYSDATETIME()
     WHERE TrackGzip IS NOT NULL
       AND removed = 0
       AND updatedAt < @cutoff;

    SELECT @@ROWCOUNT AS RowsTouched;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

-- Verification: should return 0.
SELECT COUNT(*) AS StillBehindTheCutoff
FROM HC.HasherEventMap
WHERE TrackGzip IS NOT NULL AND removed = 0 AND updatedAt < '2026-09-12T00:00:00+00:00';
GO
