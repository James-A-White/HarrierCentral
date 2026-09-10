-- Run-once (E3.F3.S7 + E5.F6.S4): add this hasher's PackTrack summary AND the
-- column that will hold their gzipped trail to HC.HasherEventMap — one ALTER on
-- the synced table for the whole feature (James, 2026-09-10).
-- HasherEventMap is a SYNCED table with an updatedAt trigger — the trigger is
-- disabled around the ALTER so no row is stamped and no client re-syncs
-- (CLAUDE.md, "ALTER TABLE on synced tables"). James runs this, not the deploy
-- script. Archive after running. Nullable columns, no default, no backfill here:
-- tools/backfill_hem_track_columns.sh fills them from GetPositions afterwards.
-- Second batch: the trigger learns to ignore a write that changes only the
-- four Track columns, so per-batch writes never stamp updatedAt.
IF COL_LENGTH('HC.HasherEventMap', 'TrackGzip') IS NULL
BEGIN
    ALTER TABLE HC.HasherEventMap DISABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
    ALTER TABLE HC.HasherEventMap
        ADD TrackFirstPointAt DATETIME2(3) NULL,
            TrackLastPointAt  DATETIME2(3) NULL,
            TrackPointCount   INT          NULL,
            TrackGzip         VARBINARY(MAX) NULL;   -- E5.F6.S4: delta-encoded + gzipped trail, written once at end; no writer yet
    ALTER TABLE HC.HasherEventMap ENABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
END
GO

-- Batch 2: the trigger ignores track-only writes (must follow the ADD, which
-- the trigger text references). Same body as db/schema/tables/HC.HasherEventMap.Table.sql.
ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
   ON  [HC].[HasherEventMap]
   AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	-- A write that touches ONLY the PackTrack columns (TrackFirstPointAt,
	-- TrackLastPointAt, TrackPointCount, TrackGzip — set by the StorePositions / DeletePositions
	-- Azure Functions per batch, and by the one-off backfill) is not a change any
	-- client needs to hear about: the columns are in no sync rowset. So it must
	-- NOT stamp updatedAt, or every runner's row would re-sync once a minute for
	-- nothing. If a Track column is in the SET list and no other column changed
	-- value, leave updatedAt alone. (James, 2026-09-10: exclude the columns from
	-- the trigger rather than have the writer overwrite updatedAt.)
	IF (UPDATE(TrackFirstPointAt) OR UPDATE(TrackLastPointAt) OR UPDATE(TrackPointCount) OR UPDATE(TrackGzip))
	   AND NOT UPDATE(updatedAt)
	   AND NOT EXISTS (
			SELECT i.id, i.EventId, i.KennelId, i.HasherOwnEventId, i.UserId, i.RegistrationId,
			       i.UserStartEvent, i.UserEndEvent, i.EventCost, i.Rsvp, i.RsvpState,
			       i.AttendenceState, i.IsHare, i.EventNotificationPreference,
			       i.EventEmailAlertPreference, i.EventCountOverride, i.VirginVisitorType,
			       i.TotalRuns, i.TotalHaring, i.TotalRunsThisKennel, i.TotalHaringThisKennel,
			       i.YtdTotalRunsThisKennel, i.YtdHaringThisKennel, i.DisplayName, i.Email,
			       i.PhoneNumber, i.removed
			FROM INSERTED i
			EXCEPT
			SELECT d.id, d.EventId, d.KennelId, d.HasherOwnEventId, d.UserId, d.RegistrationId,
			       d.UserStartEvent, d.UserEndEvent, d.EventCost, d.Rsvp, d.RsvpState,
			       d.AttendenceState, d.IsHare, d.EventNotificationPreference,
			       d.EventEmailAlertPreference, d.EventCountOverride, d.VirginVisitorType,
			       d.TotalRuns, d.TotalHaring, d.TotalRunsThisKennel, d.TotalHaringThisKennel,
			       d.YtdTotalRunsThisKennel, d.YtdHaringThisKennel, d.DisplayName, d.Email,
			       d.PhoneNumber, d.removed
			FROM DELETED d)
		RETURN;

	IF NOT UPDATE(updatedAt)
		BEGIN
			UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,SYSDATETIME())
			FROM HC.HasherEventMap tbl
			INNER JOIN INSERTED ins on tbl.id = ins.id
		END
	ELSE
		BEGIN
			UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,CAST(ins.updatedAt as datetime2))
			FROM HC.HasherEventMap tbl
			INNER JOIN INSERTED ins on tbl.id = ins.id
		END
END
GO
