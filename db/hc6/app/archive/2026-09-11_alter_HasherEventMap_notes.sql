-- Run-once (E3.F4.S5, 2026-09-11): HC.HasherEventMap.Notes and NotesVisibility — the
-- hasher's own notes on a run and whether they share them, written in the app or filled from a Strava title /
-- description on import when blank. HasherEventMap is a SYNCED table with an
-- updatedAt trigger — disabled around the ALTER so no row is stamped and no
-- client re-syncs (CLAUDE.md, "ALTER TABLE on synced tables"). James runs
-- this, not the deploy script. Archive after running.
-- Batch 2 re-issues the trigger with Notes in its "did anything but the Track
-- columns change" lists, so a note change always stamps updatedAt.
IF COL_LENGTH('HC.HasherEventMap', 'Notes') IS NULL
BEGIN
    ALTER TABLE HC.HasherEventMap DISABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
    ALTER TABLE HC.HasherEventMap
        ADD Notes NVARCHAR(4000) NULL,
            NotesVisibility SMALLINT NOT NULL CONSTRAINT DF_HasherEventMap_NotesVisibility DEFAULT (0);  -- 0 private · 1 shared
    ALTER TABLE HC.HasherEventMap ENABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
    PRINT 'HC.HasherEventMap.Notes added';
END
ELSE
    PRINT 'HC.HasherEventMap.Notes already exists';
GO
ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
   ON  [HC].[HasherEventMap]
   AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	IF (UPDATE(TrackFirstPointAt) OR UPDATE(TrackLastPointAt) OR UPDATE(TrackPointCount) OR UPDATE(TrackGzip))
	   AND NOT UPDATE(updatedAt)
	   AND NOT EXISTS (
			SELECT i.id, i.EventId, i.KennelId, i.HasherOwnEventId, i.UserId, i.RegistrationId,
			       i.UserStartEvent, i.UserEndEvent, i.EventCost, i.Rsvp, i.RsvpState,
			       i.AttendenceState, i.IsHare, i.EventNotificationPreference,
			       i.EventEmailAlertPreference, i.EventCountOverride, i.VirginVisitorType,
			       i.TotalRuns, i.TotalHaring, i.TotalRunsThisKennel, i.TotalHaringThisKennel,
			       i.YtdTotalRunsThisKennel, i.YtdHaringThisKennel, i.DisplayName, i.Email,
			       i.PhoneNumber, i.removed, i.Notes, i.NotesVisibility
			FROM INSERTED i
			EXCEPT
			SELECT d.id, d.EventId, d.KennelId, d.HasherOwnEventId, d.UserId, d.RegistrationId,
			       d.UserStartEvent, d.UserEndEvent, d.EventCost, d.Rsvp, d.RsvpState,
			       d.AttendenceState, d.IsHare, d.EventNotificationPreference,
			       d.EventEmailAlertPreference, d.EventCountOverride, d.VirginVisitorType,
			       d.TotalRuns, d.TotalHaring, d.TotalRunsThisKennel, d.TotalHaringThisKennel,
			       d.YtdTotalRunsThisKennel, d.YtdHaringThisKennel, d.DisplayName, d.Email,
			       d.PhoneNumber, d.removed, d.Notes, d.NotesVisibility
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
