-- =====================================================================
-- Run-once: guarantee HC.Event.EventStartDateTimeGmt is never NULL
-- =====================================================================
-- EventStartDateTimeGmt is the TRUE UTC instant of a run start. It must be
-- correct even though EventStartDatetime is often stored with a spurious +00:00
-- offset (the portal saves local wall-time tagged +00:00 for ~67% of rows), so
-- the instant is derived from the wall-clock via the kennel's City->Timezone.
--
-- The previous trigger left Gmt NULL when a kennel had no City (INNER JOIN
-- excluded the row) or the City had no Timezone (AT TIME ZONE NULL -> NULL).
-- This rewrite uses LEFT JOINs and a non-null fallback so EVERY inserted/updated
-- row gets a non-null Gmt:
--   * timezone known  -> wall-clock AT TIME ZONE <tz> AT TIME ZONE 'UTC' (correct)
--   * timezone unknown -> EventStartDatetime AT TIME ZONE 'UTC' (best-effort,
--     uses the stored offset; never null because EventStartDatetime is NOT NULL)
--
-- Only the EventStartDateTimeGmt block changes; the GoogleCalendar short-circuit
-- and the updatedAt/updatedAtBias stamping are preserved verbatim.
-- ALTER TRIGGER only (no row writes) -> no mobile re-sync, no trigger-disable dance.
-- Author:  Harrier Central   Created: 2026-06-28   Run-once: archived.
-- =====================================================================
CREATE OR ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForEvent]
   ON  [HC].[Event]
   AFTER INSERT, UPDATE
AS
BEGIN

	SET NOCOUNT ON;

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
