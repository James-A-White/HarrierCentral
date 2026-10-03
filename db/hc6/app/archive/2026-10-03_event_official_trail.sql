-- =====================================================================
-- RUN-ONCE (E5.F6.S6, James 2026-10-03): the run's official trail(s).
--   HC.Event.OfficialTrailGzip  VARBINARY(MAX) — COMPRESS() of the trail JSON
--     {"lanes":[{"type":3,"points":[[lat,lon],...]}, ...]} (one lane per
--     trail type: 1 Walkers, 2 Short, 3 Normal, 4 Long, 5 Ballbreaker,
--     >= 100 kennel-defined). SQL DECOMPRESS()es it, so no codec is needed.
--   HC.Event.OfficialTrailInfo  NVARCHAR(MAX) — small JSON per lane:
--     type, distanceM, points, source, sourceRef, setBy, setAt.
-- In NO sync rowset: phones fetch a trail only when a map opens. The
-- UpdatedAt trigger is taught to ignore a trail-only write (below), and the
-- triggers are disabled around the ALTER as the synced-table rule requires.
-- Afterwards: archive this file.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DISABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
DISABLE TRIGGER HC.trgRecalculateRunCounts ON HC.Event;
IF COL_LENGTH('HC.Event', 'OfficialTrailGzip') IS NULL
    ALTER TABLE HC.Event ADD OfficialTrailGzip VARBINARY(MAX) NULL;
IF COL_LENGTH('HC.Event', 'OfficialTrailInfo') IS NULL
    ALTER TABLE HC.Event ADD OfficialTrailInfo NVARCHAR(MAX) NULL;
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForEvent ON HC.Event;
ENABLE TRIGGER HC.trgRecalculateRunCounts ON HC.Event;
COMMIT TRANSACTION;
GO
CREATE OR ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForEvent]
   ON  [HC].[Event]
   AFTER INSERT, UPDATE
AS
BEGIN

	SET NOCOUNT ON;
	-- 2026-10-03 (E5.F6.S6): a write of ONLY the official-trail columns is
	-- not a change any phone needs — they are in no sync rowset — so it must
	-- not stamp updatedAt (the same rule as HasherEventMap's track columns).
	-- COLUMNS_UPDATED() is checked byte by byte: any bit other than the two
	-- trail columns means a real change, which stamps as before. An INSERT
	-- sets every bit, so inserts always stamp.
	IF UPDATE(OfficialTrailGzip) OR UPDATE(OfficialTrailInfo)
	BEGIN
		DECLARE @cu VARBINARY(128) = COLUMNS_UPDATED();
		DECLARE @a INT = COLUMNPROPERTY(OBJECT_ID('HC.Event'), 'OfficialTrailGzip', 'ColumnID');
		DECLARE @b INT = COLUMNPROPERTY(OBJECT_ID('HC.Event'), 'OfficialTrailInfo', 'ColumnID');
		-- The rowversion column ("version") is set by SQL Server on EVERY
		-- update, so its bit is always present and must be allowed too.
		DECLARE @v INT = (SELECT TOP (1) column_id FROM sys.columns
		                  WHERE object_id = OBJECT_ID('HC.Event') AND system_type_id = 189);
		DECLARE @i INT = 1, @n INT = DATALENGTH(@cu), @onlyTrail BIT = 1, @byte INT, @allowed INT;
		WHILE @i <= @n
		BEGIN
			SET @byte = CAST(SUBSTRING(@cu, @i, 1) AS INT);
			SET @allowed = CASE WHEN (@a - 1) / 8 + 1 = @i THEN POWER(2, (@a - 1) % 8) ELSE 0 END
			             | CASE WHEN (@b - 1) / 8 + 1 = @i THEN POWER(2, (@b - 1) % 8) ELSE 0 END
			             | CASE WHEN (@v - 1) / 8 + 1 = @i THEN POWER(2, (@v - 1) % 8) ELSE 0 END;
			IF (@byte & ~@allowed) <> 0 SET @onlyTrail = 0;
			SET @i += 1;
		END
		IF @onlyTrail = 1 RETURN;
	END
	IF UPDATE(EventStartDateTime)
		BEGIN
			UPDATE tbl SET EventStartDateTimeGmt =
				CASE WHEN tz.Timezone IS NOT NULL
					 THEN (CAST(tbl.EventStartDatetime AS datetime) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC'
					 ELSE tbl.EventStartDatetime AT TIME ZONE 'UTC'   -- fallback: never null
				END
			FROM HC.Event tbl
			INNER JOIN INSERTED ins on tbl.id = ins.id
			LEFT JOIN HC.Kennel k on k.id = tbl.KennelId
			LEFT JOIN HC.City   c on c.id = k.CityId
			LEFT JOIN DomainValues.Timezone tz on tz.id = c.TimezoneId
		END

	IF (
		UPDATE([GlobalGoogleCalendarLastUpdated]) OR
		UPDATE([GlobalGoogleCalendarId])
	)
	BEGIN
		RETURN
	END

	IF NOT UPDATE(updatedAt)
		BEGIN
			UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,SYSDATETIME())
			FROM HC.Event tbl
			INNER JOIN INSERTED ins on tbl.id = ins.id
		END
	ELSE
		BEGIN
			UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,CAST(ins.updatedAt as datetime2))
			FROM HC.Event tbl
			INNER JOIN INSERTED ins on tbl.id = ins.id
		END

END
GO
SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Event');
SELECT COL_LENGTH('HC.Event','OfficialTrailGzip') AS gzipCol, COL_LENGTH('HC.Event','OfficialTrailInfo') AS infoCol;
