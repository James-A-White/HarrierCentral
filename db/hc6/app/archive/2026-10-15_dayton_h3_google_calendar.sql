-- =====================================================================
-- Run-once data fix (James approved 2026-10-15): Dayton H3 (DH3) reads its
-- runs from its public Google Calendar (E3.F6.S5). DH3 chose "Google
-- Calendar" on 2026-10-14 15:08 UTC, when that choice had no code behind it,
-- and its runs page still pointed at its website (which lists one run). The
-- calendar link is the embed link DH3's admin tried first. RunsPageHash is
-- cleared so the next timer run reads it. One kennel row; it re-syncs to
-- phones once, which is right — nothing else about the kennel changes.
-- =====================================================================
SET NOCOUNT ON;
UPDATE HC.Kennel
SET RunsPageUrl  = N'https://calendar.google.com/calendar/embed?src=dh3calendar%40gmail.com&ctz=America%2FNew_York',
    RunsPageHash = NULL
WHERE id = '332cc8ad-39e4-4151-b3d8-28eaa7717e1f'
  AND InboundIntegrationId = 2
  AND PublishToGoogleCalendar = 0;
SELECT @@ROWCOUNT AS rowsUpdated;
SELECT KennelShortName, InboundIntegrationId, RunsPageUrl, RunsPageHash FROM HC.Kennel WHERE id = '332cc8ad-39e4-4151-b3d8-28eaa7717e1f';
