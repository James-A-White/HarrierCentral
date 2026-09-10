-- Run-once (E3.F3.S7): add this hasher's PackTrack summary to HC.HasherEventMap.
-- HasherEventMap is a SYNCED table with an updatedAt trigger — the trigger is
-- disabled around the ALTER so no row is stamped and no client re-syncs
-- (CLAUDE.md, "ALTER TABLE on synced tables"). James runs this, not the deploy
-- script. Archive after running. Nullable columns, no default, no backfill here:
-- tools/backfill_hem_track_columns.sh fills them from GetPositions afterwards.
IF COL_LENGTH('HC.HasherEventMap', 'TrackPointCount') IS NULL
BEGIN
    ALTER TABLE HC.HasherEventMap DISABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
    ALTER TABLE HC.HasherEventMap
        ADD TrackFirstPointAt DATETIME2(3) NULL,
            TrackLastPointAt  DATETIME2(3) NULL,
            TrackPointCount   INT          NULL;
    ALTER TABLE HC.HasherEventMap ENABLE TRIGGER trgUpdateModifiedOnDateForHasherEventMap;
END
GO
