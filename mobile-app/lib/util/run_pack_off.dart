import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// A run's PACK-OFF time (E3.F1.S6): many kennels gather at one time and set
/// off at another ("gather 12:00, pack off 12:30").
///
/// Two synced columns, both minutes after the gather (`eventStartDatetime`):
/// * `kennels.packOffMinutes` — the kennel's default; null = at the gather.
/// * `events.packOffMinutes` — this run's own; null = the kennel's default.
///   An explicit 0 means "at the gather" and beats a kennel default.
///
/// Effective = COALESCE(run, kennel, 0), the same rule the SPs use
/// (`publicWeb_getEvents` & co.). Every screen reads it through here, so the
/// rule lives once — the run card, the run page and PackTrack auto start
/// cannot disagree about when the pack leaves.
class RunPackOff {
  RunPackOff._();

  /// The largest value `hcapp_addEditEvent` accepts (errorCode 1227 above).
  static const int maxMinutes = 600;

  /// Both tables call the column `packOffMinutes`, so a query that selects
  /// `evt.*, k.*` returns ONE `packOffMinutes` key — the later table's — and
  /// the run's override would silently read as the kennel's default. Joined
  /// queries add [joinedColumns]; the table helpers' `fromMap` prefer these
  /// aliases when present.
  static const String evtAlias = 'evtPackOffMinutes';
  static const String kennelAlias = 'kennelPackOffMinutes';

  /// SELECT-list text for a query joining events [evt] and kennels [k].
  static String joinedColumns({String evt = 'evt', String k = 'k'}) =>
      '$evt.packOffMinutes AS $evtAlias, $k.packOffMinutes AS $kennelAlias,';

  /// `hcapp_addEditEvent @packOffMinutes` sentinels, the same as the prices'.
  static const int sendKeep = -1;
  static const int sendClear = -2;

  /// Minutes after the gather that the pack leaves; 0 = at the gather.
  /// The run's own setting for a picked pack-off of [pickedMinutes]: null —
  /// follow the kennel — when it matches the kennel's default (null = at the
  /// gather, 0), so an OK on the picker without changing it never saves an
  /// override that later hides a kennel default (SWH3 #1814, 2026-10-17).
  static int? overrideFor(int pickedMinutes, int? kennelMinutes) =>
      pickedMinutes == (kennelMinutes ?? 0) ? null : pickedMinutes;

  static int effectiveMinutes({int? runMinutes, int? kennelMinutes}) {
    final int m = runMinutes ?? kennelMinutes ?? 0;
    return m < 0 ? 0 : m;
  }

  /// [effectiveMinutes] for a run and its kennel.
  static int minutesFor(EventModel event, KennelsModel kennel) =>
      effectiveMinutes(
        runMinutes: event.packOffMinutes,
        kennelMinutes: kennel.packOffMinutes,
      );

  /// The pack-off wall clock for a gather at [gatherLocal], or null when the
  /// pack leaves at the gather — callers show nothing extra then.
  static DateTime? packOffAt(DateTime gatherLocal, int minutes) =>
      minutes > 0 ? gatherLocal.add(Duration(minutes: minutes)) : null;

  /// The kennel-local wall clock the pack leaves, or null when at the gather.
  static DateTime? packOffLocal(EventModel event, KennelsModel kennel) =>
      packOffAt(event.eventStartDatetime, minutesFor(event, kennel));

  /// The INSTANT the pack leaves — the gather instant when there is no
  /// separate pack-off. What PackTrack auto start counts from.
  static DateTime packOffGmt(EventModel event, KennelsModel kennel) =>
      event.eventStartDatetimeGmt.add(
        Duration(minutes: minutesFor(event, kennel)),
      );

  /// " · Pack off 12:30 PM" to follow a start time, or '' at the gather.
  static String suffix(EventModel event, KennelsModel kennel) {
    final DateTime? at = packOffLocal(event, kennel);
    return at == null ? '' : ' · Pack off ${DateFormat('h:mm a').format(at)}';
  }

  /// "30 min after the gather" / "at the gather", for the run editor.
  static String describeMinutes(int minutes) {
    if (minutes <= 0) return 'at the gather';
    final int h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '$m min after the gather';
    return m == 0
        ? '$h h after the gather'
        : '$h h $m min after the gather';
  }
}
