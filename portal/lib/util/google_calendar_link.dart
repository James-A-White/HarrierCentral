/// Whether an address is a Google Calendar link the runs-page reader can turn
/// into the calendar's public iCal feed (E3.F6.S5, James 2026-10-15): an embed
/// link (?src=), a share link (?cid=) or an iCal link (/calendar/ical/).
///
/// THE SAME test is GoogleCalendarIcsUrl in api/Endpoints/RunsPageImport.cs
/// and the "Google Calendar" check in HC6.hcportal_editKennel. Change all three
/// together.
bool isGoogleCalendarLink(String? address) {
  final Uri? u = Uri.tryParse((address ?? '').trim());
  if (u == null || u.scheme != 'https' || u.host.toLowerCase() != 'calendar.google.com') return false;
  if (!u.path.startsWith('/calendar/')) return false;
  return u.path.contains('/calendar/ical/') ||
      (u.queryParameters['src'] ?? '').isNotEmpty ||
      (u.queryParameters['cid'] ?? '').isNotEmpty;
}

/// The inbound integration id of "Google Calendar" (HC.Integration 2).
const int kGoogleCalendarIntegration = 2;

/// What to tell an admin whose Google Calendar choice has the wrong link.
const String kGoogleCalendarLinkHelp =
    'Runs come from Google Calendar, so the address must be your Google '
    "Calendar's link. In Google Calendar open Settings, choose the calendar, "
    'and copy "Public URL to this calendar" (it starts '
    'https://calendar.google.com/calendar/). The calendar must be public: '
    'Settings › the calendar › Access permissions › Make available to public.';
