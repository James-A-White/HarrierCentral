import 'package:harrier_central/imports.dart';

/// A kennel's iCal feed on hashruns.org (E3.F6.S8): subscribe once and its
/// runs keep themselves current in the phone's calendar, each entry linking
/// back to the run (which opens this app).
Uri kennelCalendarFeedUrl(String kennelUniqueShortName) => Uri.parse(
  '$BASE_HASHRUNS_DOT_ORG_URL${kennelUniqueShortName.toLowerCase()}/runs.ics',
);

/// Opens the subscribe flow for [feed] (an https `…/runs.ics` address):
/// iOS hands `webcal://` to Calendar, which asks to subscribe; Android has no
/// standard webcal handler, so it goes to Google Calendar's add-by-URL page
/// (the Google Calendar app or the browser). Returns false if nothing opened.
Future<bool> openCalendarSubscription(Uri feed) async {
  final String webcal = feed.replace(scheme: 'webcal').toString();
  final Uri target = Platform.isIOS
      ? Uri.parse(webcal)
      : Uri.parse(
          'https://calendar.google.com/calendar/r?cid=${Uri.encodeComponent(webcal)}',
        );
  try {
    return await launchUrl(target, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
