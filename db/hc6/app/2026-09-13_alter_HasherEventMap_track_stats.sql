-- =====================================================================
-- Run-once: track statistics on HC.HasherEventMap (2026-09-13)
--
--   The dashboard's PackTrack counter drills into one row per captured
--   track — hasher, kennel, how far, how long — and nothing server-side
--   knew how far a track was. The archive holds every point (time, lat,
--   lng, altitude, accuracy), so these are all measured ONCE when the
--   nightly archiver decodes the track, and read cheaply for ever after.
--
--   ⚠ HC.HasherEventMap IS A SYNCED TABLE. The UpdatedAt trigger must be
--   DISABLED for the ALTER or SQL Server fires it against every row,
--   stamping the lot and forcing a full re-sync to every phone on the
--   platform. The script does that and re-enables it; James runs this by
--   hand (see claude.md "ALTER TABLE on synced tables").
--
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

-- Named, not pattern-matched: getting the wrong trigger here re-syncs the
-- whole table to every phone, so it fails loudly instead of guessing.
IF NOT EXISTS (SELECT 1 FROM sys.triggers
               WHERE parent_id = OBJECT_ID('HC.HasherEventMap')
                 AND name = 'trgUpdateModifiedOnDateForHasherEventMap')
BEGIN
    RAISERROR('trgUpdateModifiedOnDateForHasherEventMap not found — stopping rather than ALTERing a synced table with its UpdatedAt trigger live.', 16, 1);
    RETURN;
END

IF COL_LENGTH('HC.HasherEventMap', 'TrackDistanceM') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
        ON [HC].[HasherEventMap];

    ALTER TABLE [HC].[HasherEventMap] ADD
        -- How far, in whole metres. Haversine over the archived points,
        -- skipping any the accuracy field says not to trust.
        [TrackDistanceM]      INT              NULL,
        -- Seconds actually moving. Elapsed is already derivable from
        -- TrackFirstPointAt/TrackLastPointAt; this is the new information —
        -- a hash spends a lot of its time standing still at a check.
        [TrackMovingSeconds]  INT              NULL,
        -- Metres climbed, summed over rises big enough to be real. GPS
        -- altitude is noisy, so small wobbles are ignored rather than added
        -- up into a mountain.
        [TrackElevationGainM] INT              NULL,
        -- Where the track began and ended: did they make the On-Inn?
        [TrackStartLat]       DECIMAL(9,6)     NULL,
        [TrackStartLng]       DECIMAL(9,6)     NULL,
        [TrackEndLat]         DECIMAL(9,6)     NULL,
        [TrackEndLng]         DECIMAL(9,6)     NULL,
        -- The bounding box, so the server can pick tracks for a map without
        -- decoding a single blob.
        [TrackMinLat]         DECIMAL(9,6)     NULL,
        [TrackMinLng]         DECIMAL(9,6)     NULL,
        [TrackMaxLat]         DECIMAL(9,6)     NULL,
        [TrackMaxLng]         DECIMAL(9,6)     NULL,
        -- The GPS parameters ACTUALLY in force, not the tier's name: the
        -- tiers have been redefined between builds (the Android cadence went
        -- from 15s/15s/15min to 15s/1min/15min), so "Balanced" alone does not
        -- say what was recorded. JSON keeps it queryable via JSON_VALUE
        -- without deciding today which parameter matters in a year:
        --   {"tier":2,"tierName":"Best","accuracy":"bestForNavigation",
        --    "distanceFilterM":5,"intervalSec":15,"platform":"ios",
        --    "build":1348}
        -- NULL on every track recorded before 2026-09-13 — the phone did not
        -- send it and it cannot be reconstructed.
        [TrackGpsSettings]    NVARCHAR(400)    NULL;

    -- Pace, derived rather than stored: a second copy of distance-over-time
    -- can disagree with the two columns it came from, a computed one never
    -- can. PERSISTED so it is indexable and free to read — which materialises
    -- a value on all 136k rows, so it belongs inside the disabled window with
    -- the rest.
    ALTER TABLE [HC].[HasherEventMap] ADD [TrackPaceSecPerKm] AS (
        CASE WHEN [TrackDistanceM] > 0 AND [TrackMovingSeconds] > 0
             THEN CONVERT(INT, ([TrackMovingSeconds] * 1000.0) / [TrackDistanceM])
        END
    ) PERSISTED;

    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
        ON [HC].[HasherEventMap];

    PRINT 'HasherEventMap track statistic columns added (incl. TrackPaceSecPerKm)';
END
ELSE PRINT 'HasherEventMap track statistic columns already exist';
GO

-- Proof the ALTER did not stamp the table: this must come back 0.
SELECT COUNT(*) AS rowsStampedInTheLastMinute
  FROM HC.HasherEventMap
 WHERE updatedAt > DATEADD(MINUTE, -1, SYSUTCDATETIME());
GO

-- The dashboard counts captured tracks by when they were captured, and
-- drills into the most recent. Partial: only rows that ARE a track.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_HasherEventMap_TrackCaptured'
                 AND object_id = OBJECT_ID('HC.HasherEventMap'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_HasherEventMap_TrackCaptured]
        ON [HC].[HasherEventMap] ([TrackFirstPointAt])
        INCLUDE ([userId], [EventId], [TrackDistanceM], [TrackMovingSeconds])
        WHERE [TrackPointCount] > 0 AND [removed] = 0;
    PRINT 'IX_HasherEventMap_TrackCaptured created';
END
ELSE PRINT 'IX_HasherEventMap_TrackCaptured already exists';
GO
