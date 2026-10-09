import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/auto_start_detector.dart';
import 'package:harrier_central/services/location_service/motion_activity.dart';
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
/// * Disarms itself: the pack if not at (or within 1 km of) the start by
///   T+90, anyone by T+2h.
/// * The phone's motion sensing (E5.F1.S15, 2026-10-01) can start it sooner:
///   after arriving, running for 20 s — or walking for 20 s more than 100 m
///   from the start — sets off; being in a vehicle vetoes any start, the GPS
///   rule's too. Permission refused or no sensor: the GPS rule alone, as
///   before. See [MotionStartRule].
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
  MotionStartRule? _motion;
  MotionKind? _lastMotionKind;
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
        startLat != null &&
        startLng != null &&
        (startLat != 0 || startLng != 0);
    _eventId = normalizeUuid(eventId);
    _eventName = eventName;
    _startGmt = startGmt.toUtc();
    _isHare = isHare;
    _anchor = hasStart ? latlng.LatLng(startLat, startLng) : null;
    _detector = AutoStartDetector(anchor: _anchor);
    _motion = MotionStartRule();
    _lastMotionKind = null;
    _armedAtMs = ClockOffset.trackNowUtc().millisecondsSinceEpoch;
    armed.value = true;
    // Asked here, on the Live Run page, so the permission prompt has a screen.
    unawaited(MotionActivityService.start(_onMotion));
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
  /// When [arm] was called this session (epoch ms); null after a restore,
  /// when the ring's own 15-minute window is the bound instead.
  int? _armedAtMs;

  /// The ring's fixes since the runner armed, for a MANUAL Start pressed
  /// while armed (James, 2026-09-30). Pressing Start used to throw the ring
  /// away: City H3 #1941 was armed at 19:33:16 as the pack set off and Start
  /// was pressed 86 s later, so the track began 86 s after everyone else's.
  /// The detector's departure test is still running, so this does not wait
  /// for it: whatever was seen since arming is the run so far.
  List<AutoStartFix> takeRingForManualStart() {
    final AutoStartDetector? d = _detector;
    if (d == null) return const <AutoStartFix>[];
    final int since =
        _armedAtMs ??
        ClockOffset.trackNowUtc().millisecondsSinceEpoch - 15 * 60 * 1000;
    return d.pointsFrom(since);
  }

  Future<void> disarm({String? reason}) async {
    if (!armed.value) return;
    armed.value = false;
    status.value = '';
    _tick?.cancel();
    _tick = null;
    _detector = null;
    _motion = null;
    unawaited(MotionActivityService.stop());
    await setStringPref(StringPrefsEnum.autoStartJson, null);
    BootLogger.logBreadcrumb(
      '[AutoStart] disarmed ${reason ?? 'by the runner'}',
    );
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
    final int nowMs = ClockOffset.trackNowUtc().millisecondsSinceEpoch;
    final int? startTs = d.add(
      // In a vehicle: not setting off, however far from the start.
      blocked: _motion?.vetoed(nowMs) ?? false,
      AutoStartFix(
        lat: p.latitude,
        lng: p.longitude,
        acc: p.accuracy,
        alt: p.altitude,
        // The fix's time on the server's clock, like every other point (E1.F1.S7).
        tsMs: p.timestamp.millisecondsSinceEpoch + ClockOffset.trackOffsetMs,
      ),
    );
    final bool wasArrived = status.value.startsWith('At the start');
    if (d.hasArrived && !wasArrived) _updateStatus();
    if (startTs != null) {
      unawaited(_trigger(startTs, via: 'gps'));
      return;
    }
    _checkMotion(nowMs);
  }

  /// A change in what the phone says the hasher is doing.
  void _onMotion(MotionActivity a) {
    final MotionStartRule? m = _motion;
    if (!armed.value || m == null) return;
    if (a.kind != _lastMotionKind) {
      _lastMotionKind = a.kind;
      BootLogger.logBreadcrumb(
        '[AutoStart] motion: ${a.kind.name} (${a.confidence}%)',
      );
    }
    m.onActivity(a.kind.name, a.confidence, a.tsMs);
    _checkMotion(a.tsMs);
  }

  /// Asked on every fix and every motion change: has the motion rule seen
  /// the hasher set off?
  void _checkMotion(int nowMs) {
    final MotionStartRule? m = _motion;
    final AutoStartDetector? d = _detector;
    if (!armed.value || m == null || d == null) return;
    final List<AutoStartFix> ring = d.ring;
    final latlng.LatLng? anchor = d.anchor;
    final double? meters = (anchor == null || ring.isEmpty)
        ? null
        : const latlng.Distance().as(
            latlng.LengthUnit.Meter,
            anchor,
            latlng.LatLng(ring.last.lat, ring.last.lng),
          );
    final int? startTs = m.check(
      nowMs: nowMs,
      arrived: d.hasArrived,
      metersFromStart: meters,
    );
    if (startTs != null) unawaited(_trigger(startTs, via: 'motion'));
  }

  Future<void> _trigger(int startTsMs, {String via = 'gps'}) async {
    final String? eventId = _eventId;
    final AutoStartDetector? d = _detector;
    if (eventId == null || d == null || !armed.value) return;
    final List<AutoStartFix> backfill = d.pointsFrom(startTsMs);
    final String name = _eventName ?? 'the run';
    // Clear the armed state first: tracking owns the stream from here.
    armed.value = false;
    status.value = '';
    _tick?.cancel();
    _tick = null;
    _detector = null;
    _motion = null;
    unawaited(MotionActivityService.stop());
    await setStringPref(StringPrefsEnum.autoStartJson, null);

    BootLogger.logBreadcrumb(
      '[AutoStart] set off (by $via) — tracking $eventId from '
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
    // arm() opens the stream at THIS precision, so the tick must start from
    // it. Left at false, the first tick saw a change that never happened and
    // re-subscribed 30 s after arming. On Android that restarts the location
    // foreground service, which a phone already in a pocket may not do:
    // "Starting FGS with type location … requires permissions" (Inspector
    // Gorse, 1435, 2026-10-07), and auto start lost its stream.
    _wasPrecise = wantsPrecise;
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
  }

  bool _wasPrecise = false;

  void _onTick() {
    if (!armed.value || _startGmt == null) return;
    final DateTime now = DateTime.now().toUtc();
    final DateTime start = _startGmt!;
    if (now.isAfter(start.add(const Duration(hours: 2)))) {
      unawaited(
        disarm(
          reason:
              'Auto start switched off — the run started over two hours ago.',
        ),
      );
      return;
    }
    // Not at the start by T+90 — and not near it either — so not coming.
    // This was T+30, which a late pack beats: Black Death #200 (2026-09-27)
    // left at 12:31 for a 12:00 start, one minute after auto start had
    // switched itself off. Someone still within 1 km of the start is kept
    // armed until the T+2h stop above.
    if (!_isHare &&
        _anchor != null &&
        !(_detector?.hasArrived ?? false) &&
        now.isAfter(start.add(const Duration(minutes: 90))) &&
        !_nearStart()) {
      unawaited(
        disarm(
          reason: 'Auto start switched off — you did not reach the start.',
        ),
      );
      return;
    }
    final bool precise = wantsPrecise;
    if (precise != _wasPrecise) {
      _wasPrecise = precise;
      unawaited(_ls.refreshIdleStream());
    }
    _updateStatus();
  }

  /// The last fix is within 1 km of the start (any accuracy).
  bool _nearStart() {
    final latlng.LatLng? anchor = _anchor;
    final List<AutoStartFix> ring = _detector?.ring ?? const <AutoStartFix>[];
    if (anchor == null || ring.isEmpty) return false;
    final AutoStartFix last = ring.last;
    return const latlng.Distance().as(
          latlng.LengthUnit.Meter,
          anchor,
          latlng.LatLng(last.lat, last.lng),
        ) <=
        1000;
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
