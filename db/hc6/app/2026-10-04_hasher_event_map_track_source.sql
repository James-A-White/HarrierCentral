-- Run-once (James runs it): HC.HasherEventMap.TrackSource — where a runner's
-- track came from (James, 2026-10-04: "record the source of the track …
-- PackTrack native, Strava, Garmin etc." / "I want this to be displayable").
-- Values: packtrack | strava | garmin | fitbit | apple | coros | suunto |
-- polar | wahoo | komoot | file (api/Endpoints/TrackSources.cs). Kept OUT of
-- every sync rowset; GetPositions returns it per runner as "trackSource".
--
-- HasherEventMap is a SYNCED table: its updatedAt trigger is disabled for
-- the ALTER (house rule) and re-enabled straight after. Step 2 then teaches
-- the trigger that TrackSource is a track column, so writing it (here and by
-- the API) never stamps updatedAt and no phone re-syncs.
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. The column, with the updatedAt trigger off.
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
IF COL_LENGTH('HC.HasherEventMap', 'TrackSource') IS NULL
    ALTER TABLE HC.HasherEventMap ADD TrackSource NVARCHAR(40) NULL;
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForHasherEventMap ON HC.HasherEventMap;
GO

-- 2. The trigger: TrackSource joins the track-only columns.
CREATE OR ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
   ON  [HC].[HasherEventMap]
   AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	IF (UPDATE(TrackFirstPointAt) OR UPDATE(TrackLastPointAt) OR UPDATE(TrackPointCount) OR UPDATE(TrackGzip) OR UPDATE(TrackSource))
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

-- 3. Backfill. Imported tracks from their import record (files read
--    2026-10-04: the zips are Strava account archives, activity_24588526765.gpx
--    says "Garmin Connect", Shoreditch_Hash_1871.gpx says "StravaGPX");
--    every other track was recorded live by the app.
BEGIN TRANSACTION;
DECLARE @src TABLE (ImportId UNIQUEIDENTIFIER PRIMARY KEY, Source NVARCHAR(40));
INSERT @src VALUES
    ('f234f1e1-05fc-4628-a599-1d1064440d88', 'strava'),
    ('722c7339-1be9-4cff-bbfc-26116928e7fa', 'garmin'),
    ('d00c0c9d-0995-4ac2-abc3-51f259f3a087', 'strava'),
    ('dc789e1c-8df1-41f2-a5ac-661b01578944', 'strava'),
    ('38fb9f19-cc84-4f87-92e1-69acce87cd34', 'strava'),
    ('aa446622-231e-411b-ae92-880eace1a79f', 'strava'),
    ('4dd7c0a2-4493-4544-9fac-8e72963ef861', 'strava'),
    ('08474663-6f43-4058-b27b-ed349ba9d230', 'strava');

UPDATE hem SET TrackSource = x.Source
FROM HC.HasherEventMap hem
JOIN (
    SELECT DISTINCT ti.HasherId, CAST(JSON_VALUE(a.[value], '$.eventId') AS UNIQUEIDENTIFIER) AS EventId, s.Source
    FROM HC.TrackImport ti
    JOIN @src s ON s.ImportId = ti.id
    CROSS APPLY OPENJSON(ti.ResultJson, '$.activities') a
    WHERE JSON_VALUE(a.[value], '$.outcome') IN ('imported', 'replaced')
      AND JSON_VALUE(a.[value], '$.eventId') IS NOT NULL
) x ON x.HasherId = hem.UserId AND x.EventId = hem.EventId
WHERE hem.TrackPointCount > 0;
DECLARE @imported INT = @@ROWCOUNT;

UPDATE HC.HasherEventMap SET TrackSource = 'packtrack'
WHERE TrackPointCount > 0 AND TrackSource IS NULL;
DECLARE @live INT = @@ROWCOUNT;
COMMIT TRANSACTION;

SELECT @imported AS fromImports, @live AS recordedLive;
SELECT TrackSource, COUNT(*) AS tracks FROM HC.HasherEventMap WHERE TrackSource IS NOT NULL GROUP BY TrackSource ORDER BY tracks DESC;
-- A track-only write: this must still be the time before the script ran.
SELECT MAX(updatedAt) AS newestHemUpdatedAt FROM HC.HasherEventMap;
GO
