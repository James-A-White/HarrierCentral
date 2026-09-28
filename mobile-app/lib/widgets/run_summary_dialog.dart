import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/run_summary.dart';

/// What the run summary card shows. Two sources provide it: the Live Run page
/// the moment a run ends (distance and time as its screen showed them), and
/// the PackTrack map afterwards, from the runner's recorded track (James,
/// 2026-09-27: "a button that lets me pull that screen back up").
abstract class RunSummarySource {
  RxDouble get summaryDistanceMeters;
  Rx<Duration> get summaryElapsed;

  /// Checks and drink stops — null until they have been worked out.
  Rxn<RunSummary> get summary;
  RxBool get summaryLoading;

  /// The marks could not be read (offline): distance and time still show.
  RxBool get summaryUnavailable;
  bool get summaryImperial;
}

/// A summary whose numbers are already known — the map's, from a recorded
/// track.
class FixedRunSummary implements RunSummarySource {
  FixedRunSummary({
    required double distanceMeters,
    required Duration elapsed,
    required RunSummary marks,
    required this.summaryImperial,
  }) : summaryDistanceMeters = distanceMeters.obs,
       summaryElapsed = elapsed.obs,
       summary = Rxn<RunSummary>(marks);

  @override
  final RxDouble summaryDistanceMeters;
  @override
  final Rx<Duration> summaryElapsed;
  @override
  final Rxn<RunSummary> summary;
  @override
  final RxBool summaryLoading = false.obs;
  @override
  final RxBool summaryUnavailable = false.obs;
  @override
  final bool summaryImperial;
}

/// The run summary card (James, 2026-09-27): the runner's own distance and
/// time, the checks they went through and the drink stops, with the time
/// spent at them when there was any. Distance and time show at once; the
/// counts arrive when the pack's marks have been read.
Future<void> showRunSummaryDialog(
  BuildContext context,
  RunSummarySource source, {
  String title = 'Your run',
}) {
  String hms(Duration d) {
    final int t = d.inSeconds;
    final String m = ((t % 3600) ~/ 60).toString().padLeft(2, '0');
    final String s = (t % 60).toString().padLeft(2, '0');
    return t >= 3600 ? '${t ~/ 3600}:$m:$s' : '${t ~/ 60}:$s';
  }

  String minutes(Duration d) {
    final int m = (d.inSeconds / 60).round();
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${(m % 60).toString().padLeft(2, '0')} min';
  }

  Widget row(IconData icon, String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: hc_red, size: 26),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: Text(label, style: ts_alertDialogBody)),
        const SizedBox(width: 8),
        // A value shrinks rather than overflow: "12:56 /km" at a large text
        // size on a small phone is wider than the column.
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: value,
          ),
        ),
      ],
    ),
  );

  Widget big(String text) =>
      Text(text, style: ts_alertDialogTitle, textAlign: TextAlign.end);

  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title, style: ts_alertDialogTitle, textAlign: TextAlign.center),
      content: Obx(() {
        // Read every Rx first (an Obx whose reads can be skipped throws).
        final double meters = source.summaryDistanceMeters.value;
        final Duration elapsed = source.summaryElapsed.value;
        final RunSummary? s = source.summary.value;
        final bool loading = source.summaryLoading.value;
        final bool unavailable = source.summaryUnavailable.value;

        // Time on trail: the whole run less the time at drink stops. Known
        // only once the marks are read; before then the pace row waits.
        final Duration running = s == null
            ? elapsed
            : (elapsed - s.drinkStopTime).isNegative
            ? Duration.zero
            : elapsed - s.drinkStopTime;
        final String? pace = formatPace(
          running,
          meters,
          imperial: source.summaryImperial,
        );

        final Widget pending = loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : big('–');

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(
              Icons.directions_run,
              'Distance',
              big(formatDistance(meters, imperial: source.summaryImperial)),
            ),
            row(Icons.timer_outlined, 'Time', big(hms(elapsed))),
            row(
              Icons.help_outline,
              'Checks',
              s == null
                  ? pending
                  : big(
                      s.checksOnTrail > s.checksReached
                          ? '${s.checksReached} of ${s.checksOnTrail}'
                          : '${s.checksReached}',
                    ),
            ),
            if (s == null || s.drinkStopsReached > 0)
              row(
                Icons.sports_bar,
                'Drink stops',
                s == null ? pending : big('${s.drinkStopsReached}'),
              ),
            if (s != null && s.drinkStopTime.inSeconds >= 60)
              row(
                Icons.hourglass_bottom,
                'Time at drink stops',
                big(minutes(s.drinkStopTime)),
              ),
            // Running time and pace leave the drink stops out (James,
            // 2026-09-28): the time on trail, not the time at the pub.
            if (s != null && s.drinkStopTime.inSeconds >= 60)
              row(
                Icons.directions_run,
                'Running time',
                big(hms(running)),
              ),
            if (s == null || pace != null)
              row(
                Icons.speed,
                'Running pace',
                s == null ? pending : big(pace!),
              ),
            if (unavailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Checks and drink stops need a connection — they will be '
                  'on the map when you are back online.',
                  style: ts_alertDialogBody,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      }),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: hc_red,
            foregroundColor: Colors.white,
          ),
          child: Text('On On!', style: ts_button, textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}
