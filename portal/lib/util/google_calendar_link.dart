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

/// The Google account that publishes runs to kennels' calendars: the Logic
/// App PublishRunsToGoogleCalendars connects as it (connection
/// googlecalendar-3). A kennel's calendar must be shared with it.
const String kHarrierCentralGoogleAccount = 'harriercentral@gmail.com';

/// How to let Harrier Central publish to a calendar (E3.F6.S7). Without the
/// share Google refuses every run ("You need to have writer access to this
/// calendar"): Big Lik H3, 13–14 Oct 2026.
const String kGoogleCalendarPublishHelp =
    'Harrier Central can only publish to a calendar it has been given '
    'permission to change. In Google Calendar on a computer:\n'
    '1. Open Settings (the gear), and under "Settings for my calendars" '
    'choose the calendar.\n'
    '2. In "Share with specific people or groups", choose "Add people and '
    'groups".\n'
    '3. Enter $kHarrierCentralGoogleAccount, set the permission to "Make '
    'changes to events", and choose Send.\n'
    '4. On the same page, under "Integrate calendar", copy the Calendar ID '
    'and paste it in Google Calendar IDs here (separate several with commas).\n'
    'Until the calendar is shared, none of your runs will appear in it.';
