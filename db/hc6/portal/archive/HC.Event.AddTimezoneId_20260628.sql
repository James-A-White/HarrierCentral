-- =====================================================================
-- Run-once migration: add TimezoneId to HC.Event
-- Date: 2026-06-28
-- Purpose: Manual timezone override for runs whose location is entered as
--          free text ("Other" region/city) and therefore has no structured
--          CityId to derive a timezone from. Resolution precedence for a
--          run's timezone is: City's zone -> Event.TimezoneId -> kennel city.
--          FK-style reference to DomainValues.Timezone.id (INT), matching
--          HC.City.TimezoneId's type.
--
-- HC.Event is a mobile-synced table. Adding a NULLABLE column with no
-- default is metadata-only (no row touch), but we still disable the
-- updatedAt trigger during the ALTER per the project rule.
--
-- Nullable, no FK (consistent with the RegionId/CityId columns already
-- added to HC.Event). Run-once; lives in archive/ so deploy globs skip it.
-- =====================================================================

SET XACT_ABORT ON;
BEGIN TRANSACTION;

ALTER TABLE [HC].[Event] DISABLE TRIGGER [trgUpdateModifiedOnDateForEvent];

IF COL_LENGTH('HC.Event', 'TimezoneId') IS NULL
    ALTER TABLE [HC].[Event] ADD [TimezoneId] [int] NULL;

ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgUpdateModifiedOnDateForEvent];

COMMIT TRANSACTION;
GO
