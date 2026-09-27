import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/auto_start_detector.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// How long before a run's start auto-start may be armed.
const Duration kAutoStartArmBefore = Duration(hours: 2);

/// When an armed runner's GPS switches to precise and starts filling the ring.
const Duration kAutoStartPreciseBefore = Duration(minutes: 5);

/// PackTrack auto-start (James, 2026-09-27). Arm from the Live Run page up to
/// two hours before a run; tracking then starts by itself when you set off.
///
/// * Arming starts a LOW-POWER background stream at once — a timer does not
///   fire in a locked phone, and Android only lets a location service start
///   while the app is on screen, so the stream has to begin at the tap.
/// * From T−5 (a hare: at once) the stream is precise and every fix goes into
///   an [AutoStartDetector]. Arrived at the start and then more than 150 m
///   from it for 60 s ⇒ tracking starts, backfilled from 60 s before the
///   runner crossed out. Nothing earlier leaves the phone.
/// * A run with a start point anchors on it, so arming at home is fine; a run
///   without one anchors on the first fix, so a hare arms where they start.
/// * Disarms itself: the pack if not at the start by T+30, anyone by T+2h.
///
/// Owned by [LocationService], like the On-Inn auto-stop monitor.
class AutoStartMonitor {
  AutoStartMonitor(this._ls);

  final LocationService _ls;

  final RxBool armed = false.obs;

  /// One line for the Live Run page while armed.
  final RxString status = ''.obs;

  String? _eventId;
  String? _eventName;
  DateTime? _startGmt;
  bool _isHare = false;
  latlng.LatLng? _anchor;
  AutoStartDetector? _detector;
  Timer? _tick;

  String? get eventId => _eventId;

  /// True while GPS should be precise and fixes should feed the detector.
  bool get wantsPrecise {
    if (!armed.value || _startGmt == null) return false;
    // Android: precise from the tap. Android 12+ refuses to START a location
    // foreground service from the background, and switching streams at T−5
    // in a pocket restarts it — the refusal seen on 1324. One stream, begun
    // on screen, never switched.
    if (GetPlatform.isAndroid) return true;
    if (_isHare) return true;
    return !DateTime.now().toUtc().isBefore(
      _startGmt!.toUtc().subtract(kAutoStartPreciseBefore),
    );
  }

  /// Whether a run starting at [startGmt] may be armed now.
  static bool canArm(DateTime startGmt, {DateTime? asOf}) {
    final DateTime now = (asOf ?? DateTime.now()).toUtc();
    return !now.isBefore(startGmt.toUtc().subtract(kAutoStartArmBefore)) &&
        now.isBefore(startGmt.toUtc().add(const Duration(hours: 2)));
  }

  /// Arms auto-start for a run. Called from the Live Run page, so the app is
  /// in the foreground — which Android needs to start the location service.
  Future<void> arm({
    required String eventId,
    required String eventName,
    required DateTime startGmt,
    required bool isHare,
    double? startLat,
    double? startLng,
    bool setRsvp = true,
  }) async {
    final bool hasStart =
        startLat != null && startLng != null && (startLat != 0 || startLng != 0);
    _eventId = normalizeUuid(eventId);
    _eventName = eventName;
    _startGmt = startGmt.toUtc();
    _isHare = isHare;
    _anchor = hasStart ? latlng.LatLng(startLat, startLng) : null;
    _detector = AutoStartDetector(anchor: _anchor);
    armed.value = true;
    await _save();
    _updateStatus();
    _startTick();
    await _ls.refreshIdleStream();
    BootLogger.logBreadcrumb(
      '[AutoStart] armed $_eventId (hare=$_isHare, anchor=${_anchor != null})',
    );

    // Arming says "I'm going": RSVP Yes (not At Hash — that is set when
    // tracking actually starts). Best-effort.
    final String me = currentUserId;
    if (setRsvp && me.isNotEmpty) {
      unawaited(
        tableModel.hasherEventMapService
            .setEventRsvp(eventId, me, AppDomainType.user, rsvpYes.value)
            .catchError((Object e) => <dynamic>[]),
      );
    }
  }

  /// Disarms. [reason] is shown when the runner did not ask for it.
  Future<void> disarm({String? reason}) async {
    if (!armed.value) return;
    armed.value = false;
    status.value = '';
    _tick?.cancel();
    _tick = null;
    _detector = null;
    await setStringPref(StringPrefsEnum.autoStartJson, null);
    BootLogger.logBreadcrumb('[AutoStart] disarmed ${reason ?? 'by the runner'}');
    if (!_ls.joinRunTracking.value && !_ls.isPaused.value) {
      await _ls.refreshIdleStream();
    }
    if (reason != null) showHcSnackbar(reason);
  }

  /// Every fix the shared stream delivers while not tracking.
  void onFix(Position p) {
    if (!armed.value || !wantsPrecise) return;
    final AutoStartDetector? d = _detector;
    if (d == null) return;
    final int? startTs = d.add(
      AutoStartFix(
        lat: p.latitude,
        lng: p.longitude,
        acc: p.accuracy,
        alt: p.altitude,
        tsMs: p.timestamp.millisecondsSinceEpoch,
      ),
    );
    final bool wasArrived = status.value.startsWith('At the start');
    if (d.hasArrived && !wasArrived) _updateStatus();
    if (startTs != null) unawaited(_trigger(startTs));
  }

  Future<void> _trigger(int startTsMs) async {
    final String? eventId = _eventId;
    final AutoStartDetector? d = _detector;
    if (eventId == null || d == null) return;
    final List<AutoStartFix> backfill = d.pointsFrom(startTsMs);
    final String name = _eventName ?? 'the run';
    // Clear the armed state first: tracking owns the stream from here.
    armed.value = false;
    status.value = '';
    _tick?.cancel();
    _tick = null;
    _detector = null;
    await setStringPref(StringPrefsEnum.autoStartJson, null);

    BootLogger.logBreadcrumb(
      '[AutoStart] set off — tracking $eventId from '
      '${DateTime.fromMillisecondsSinceEpoch(startTsMs).toIso8601String()} '
      '(${backfill.length} buffered fixes)',
    );
    await _ls.startTrackingFromAutoStart(
      eventId: eventId,
      userId: currentUserId,
      backfill: backfill,
    );
    // Tracking this run is attending it, exactly as a manual start does.
    if (currentUserId.isNotEmpty) {
      unawaited(
        tableModel.hasherEventMapService
            .setEventAttendence(
              eventId,
              currentUserId,
              AppDomainType.user,
              attendenceAtHash.value,
            )
            .catchError((Object e) => <dynamic>[]),
      );
    }
    showHcSnackbar('On on! Tracking started for $name.');
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
  }

  bool _wasPrecise = false;

  void _onTick() {
    if (!armed.value || _startGmt == null) return;
    final DateTime now = DateTime.now().toUtc();
    final DateTime start = _startGmt!;
    if (now.isAfter(start.add(const Duration(hours: 2)))) {
      unawaited(disarm(reason: 'Auto start switched off — the run started over two hours ago.'));
      return;
    }
    if (!_isHare &&
        _anchor != null &&
        !(_detector?.hasArrived ?? false) &&
        now.isAfter(start.add(const Duration(minutes: 30)))) {
      unawaited(disarm(reason: 'Auto start switched off — you did not reach the start.'));
      return;
    }
    final bool precise = wantsPrecise;
    if (precise != _wasPrecise) {
      _wasPrecise = precise;
      unawaited(_ls.refreshIdleStream());
    }
    _updateStatus();
  }

  void _updateStatus() {
    if (!armed.value) {
      status.value = '';
    } else if (_detector?.hasArrived ?? false) {
      status.value = 'At the start — tracking begins when you set off.';
    } else if (wantsPrecise) {
      status.value = _anchor == null
          ? 'Armed — tracking begins when you move off from here.'
          : 'Armed — waiting for you to reach the start.';
    } else {
      status.value = 'Armed — GPS wakes up 5 minutes before the start.';
    }
  }

  Future<void> _save() async {
    await setStringPref(
      StringPrefsEnum.autoStartJson,
      jsonEncode(<String, dynamic>{
        'eventId': _eventId,
        'eventName': _eventName,
        'startGmtMs': _startGmt?.millisecondsSinceEpoch,
        'isHare': _isHare,
        'lat': _anchor?.latitude,
        'lng': _anchor?.longitude,
      }),
    );
  }

  /// Re-arms after a relaunch if the saved run is still inside its window.
  Future<void> restore() async {
    try {
      final String raw = getStringPref(StringPrefsEnum.autoStartJson) ?? '';
      if (raw.isEmpty) return;
      final Map<String, dynamic> m = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      final int? startMs = (m['startGmtMs'] as num?)?.toInt();
      if (startMs == null) return;
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(
        startMs,
        isUtc: true,
      );
      if (!canArm(start)) {
        await setStringPref(StringPrefsEnum.autoStartJson, null);
        return;
      }
      await arm(
        eventId: m['eventId'] as String,
        eventName: m['eventName'] as String? ?? 'the run',
        startGmt: start,
        isHare: m['isHare'] == true,
        startLat: (m['lat'] as num?)?.toDouble(),
        startLng: (m['lng'] as num?)?.toDouble(),
        setRsvp: false,
      );
    } catch (e, s) {
      BootLogger.logError('[AutoStart.restore]', e, s);
      await setStringPref(StringPrefsEnum.autoStartJson, null);
    }
  }
}
