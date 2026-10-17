import 'package:eventide/eventide.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/util/kennel_calendar_feed.dart';

/// The run page's **Add to calendar** (E3.F6.S8, James 2026-10-15): asks
/// whether to add THIS run once, or to subscribe to the kennel's calendar so
/// every run — and every change to one — arrives by itself, each entry
/// linking back to its run in the app. The single run is a snapshot: the
/// sheet and the confirmation say later changes will not follow (James,
/// 2026-10-17); the subscription is refreshed by the calendar app on its own
/// schedule.
///
/// The sheet opens in the same frame as the tap, so it is the tap's feedback,
/// and being modal it refuses a second press.
Future<void> showRunCalendarChoice(
  BuildContext context,
  RunDetailsAggregate futureRun,
) async {
  final String kennel = futureRun.kennel.kennelShortName;
  final bool canSubscribe = futureRun.kennel.kennelUniqueShortName
      .trim()
      .isNotEmpty;
  // Resolved now, while the page is certainly alive (flutter.md: a captured
  // BuildContext is a bug).
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  final _CalendarChoice? choice = await showModalBottomSheet<_CalendarChoice>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Text(
              'Add to calendar',
              style: ts_titleMedium.copyWith(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            _row(
              context,
              icon: Icons.event,
              title: 'This run only',
              // A snapshot (James, 2026-10-17): say so before they choose.
              subtitle:
                  'A snapshot of the run as it is now. If the time, place or '
                  "hares change later, your calendar won't be updated.",
              choice: _CalendarChoice.thisRun,
            ),
            if (canSubscribe)
              _row(
                context,
                icon: Icons.event_repeat,
                title: 'All $kennel runs',
                subtitle:
                    "Subscribe to $kennel's calendar: new runs and changes "
                    'arrive by themselves whenever your calendar app checks '
                    'for updates, each with a link back to the run.',
                choice: _CalendarChoice.allRuns,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  switch (choice) {
    case _CalendarChoice.thisRun:
      await _addThisRun(futureRun, messenger);
    case _CalendarChoice.allRuns:
      if (!Utilities.isConnected(showDialog: true)) return;
      // The calendar app's own subscribe dialog is the feedback; say so only
      // if nothing could open it.
      final bool opened = await openCalendarSubscription(
        kennelCalendarFeedUrl(futureRun.kennel.kennelUniqueShortName),
      );
      if (!opened) {
        hcSnack('No calendar app could open the feed.', error: true);
      }
    case null:
      return;
  }
}

/// The run on its own, as the button always did before the choice.
Future<void> _addThisRun(
  RunDetailsAggregate futureRun,
  ScaffoldMessengerState messenger,
) async {
  // THIS IS A H@CK: strip the "Z" timezone character off of the time so it imports as local time and not GMT
  String url =
      '$BASE_HASHRUNS_DOT_ORG_URL${futureRun.kennel.kennelUniqueShortName}/${futureRun.event.eventNumber}';

  String startTime = futureRun.event.eventStartDatetime.toString();
  startTime = startTime.substring(0, startTime.length - 1);
  DateTime localTime = DateTime.tryParse(startTime) ?? DateTime.now();

  String? oneLineLocForDesc = futureRun.event.locationOneLineDesc;

  String? oneLineLocForTitle;

  if ((oneLineLocForDesc != null) && (oneLineLocForDesc.isNotEmpty)) {
    oneLineLocForTitle = ' @ $oneLineLocForDesc';
    oneLineLocForDesc = 'Location: $oneLineLocForDesc\r\n\r\n';
  } else {
    oneLineLocForDesc = '';
    oneLineLocForTitle = '';
  }

  var eventide = Eventide();

  // Create an event in the default calendar (iOS write-only access)
  await eventide.createEventInDefaultCalendar(
    title: futureRun.event.eventName + oneLineLocForTitle,
    description: oneLineLocForDesc + (futureRun.event.eventDescription ?? ''),
    location: Utilities.buildMapLocation(futureRun.event),
    startDate: localTime,
    endDate: localTime.add(Duration(hours: 4)),
    url: url,
  );

  closeAllSnackbarsSafely();

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.blue,
      content: Text(
        '${futureRun.event.eventName}$oneLineLocForTitle has been added to '
        'your calendar. Later changes to the run will not be updated there.',
      ),
    ),
  );
}

Widget _row(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required _CalendarChoice choice,
}) {
  return ListTile(
    leading: Icon(icon, color: hc_blue, size: 30),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Colors.black54, fontSize: 14),
    ),
    onTap: () => Navigator.of(context).pop(choice),
  );
}

enum _CalendarChoice { thisRun, allRuns }
