import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_general_page.dart';

/// Dart side of the Apple Watch companion bridge (iOS only).
///
/// Outbound: while a tracking session runs, the bridge broadcasts state to
/// the wrist once a second via the native `updateApplicationContext` call.
/// The broadcast loop lives HERE (a permanent service), not in the live-run
/// page controller — tracking is service-scoped and survives navigation, so
/// the wrist must too. `LiveRunGeneralController` only announces the session
/// via [startSession]; after that the bridge reads `LocationService` directly
/// and notices the session ending on its own.
///
/// Inbound: watch button taps arrive as `watchCommand` calls. The returned
/// map is relayed verbatim to the watch as the tap's reply (`ok` drives the
/// success/failure haptic; `why` names the refusal in logs). Watch taps are
/// deliberate — marks commit to the track buffer immediately, with no flash
/// card or Undo. When the live-run page is open its controller handles the
/// mark (sharing the phone-tap cooldown); when it's closed the bridge marks
/// directly through `LocationService`.
class WatchBridgeService extends GetxService {
  static const MethodChannel _channel = MethodChannel('harrier_central/watch');

  static WatchBridgeService get to => Get.find<WatchBridgeService>();

  bool get _supported => Platform.isIOS;

  // pushState fires every second while tracking — a channel-level failure
  // (no watch paired, plugin missing) would otherwise spam the harvest log.
  bool _pushFailureLogged = false;

  // Session context captured at startSession so marks and broadcasts keep
  // working after the live-run page (and its controller) are gone.
  Timer? _pushTimer;
  String _eventName = '';
  List<TrailSlot> _sessionSlots = const [];
  DateTime? _startedAt;

  // Totals for the end-of-run summary screen. Distance/elapsed are the last
  // values seen while tracking (the source resets on stop); mark counts come
  // from LocationService's typed-point listener, so phone taps, wrist taps,
  // and photos are all counted no matter which page placed them.
  bool _sessionSawTracking = false;
  double _lastDistanceKm = 0;
  int _lastElapsedSec = 0;
  int _cntChecks = 0;
  int _cntFalses = 0;
  int _cntOtherMarks = 0;
  int _cntPhotos = 0;

  // Cooldown for service-level marks (page closed). The controller path has
  // its own map shared with phone taps; this one only guards wrist repeats.
  static const Duration _slotCooldown = Duration(seconds: 8);
  final Map<String, DateTime> _lastServiceMarkAt = {};

  // The summary is STICKY: once pushed, no idle broadcast may replace it —
  // only the wrist's Done (dismissSummary) or the next tracking session.
  // Guards against any raced idle push wiping the stats off the wrist.
  bool _summaryOnWrist = false;

  @override
  void onInit() {
    super.onInit();
    if (!_supported) return;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  // ------------------------------------------------------------- session

  /// Announces a live tracking session to the bridge. Called by
  /// `LiveRunGeneralController` when tracking starts, when it finds a session
  /// already running, and again after it re-bases the elapsed clock on a
  /// resumed track (idempotent — later calls just refresh the context).
  void startSession({
    required String eventName,
    required List<TrailSlot> slots,
    required DateTime startedAt,
  }) {
    if (!_supported) return;
    // A live timer means this call is a mid-session refresh (page reopened,
    // elapsed re-based) — keep the accumulated totals in that case.
    if (_pushTimer == null) {
      _sessionSawTracking = false;
      _lastDistanceKm = 0;
      _lastElapsedSec = 0;
      _cntChecks = 0;
      _cntFalses = 0;
      _cntOtherMarks = 0;
      _cntPhotos = 0;
    }
    _eventName = eventName;
    _sessionSlots = slots;
    _startedAt = startedAt;
    unawaited(_sendMarkButtons(slots));
    _locationService?.typedPointListeners[this] = _onTypedPoint;
    _pushTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Only tick immediately when tracking is already on. The start flow
    // announces the session BEFORE flipping joinRunTracking (the resume
    // check runs first), and an immediate tick then would see "not
    // tracking" and finish the session it just started. The armed timer's
    // first fire (1s) catches the fresh session either way.
    if (_locationService?.joinRunTracking.value == true) {
      _tick();
    }
  }

  /// Classifies each mark placed this session for the summary counts.
  /// Metadata points (lane declarations, admin boundaries) and the On-Inn
  /// terminator are not user "marks" and are skipped.
  void _onTypedPoint(String evId, TrackPoint point) {
    final segs = (point.type ?? '').split('::');
    final head = segs.isEmpty ? '' : segs.first.trim();
    switch (head) {
      case '':
      case 'TRL':
      case 'AST':
      case 'AEN':
      case 'OIN':
        break;
      case 'PHO':
        _cntPhotos++;
      case 'GLY':
        (segs.length > 1 && segs[1] == 'check') ? _cntChecks++ : _cntOtherMarks++;
      case 'TXT':
        (segs.length > 1 && segs[1] == 'FT') ? _cntFalses++ : _cntOtherMarks++;
      case 'CHK':
        _cntChecks++;
      case 'FT':
        _cntFalses++;
      default:
        // Legacy keyed marks (DRK, RG, CAU, LAB, ...).
        _cntOtherMarks++;
    }
  }

  LocationService? get _locationService =>
      Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;

  LiveRunGeneralController? get _liveController =>
      Get.isRegistered<LiveRunGeneralController>()
          ? Get.find<LiveRunGeneralController>()
          : null;

  void _tick() {
    final loc = _locationService;
    if (loc == null || !loc.joinRunTracking.value) {
      _finishSession();
      return;
    }
    _sessionSawTracking = true;
    _summaryOnWrist = false; // live session replaces any lingering summary
    _lastDistanceKm = loc.filteredSessionDistanceMeters.value / 1000.0;
    _lastElapsedSec = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    unawaited(_send(<String, Object?>{
      'phase': 'tracking',
      'tracking': true,
      'paused': loc.isPaused.value,
      'distanceKm': _lastDistanceKm,
      'elapsedSec': _lastElapsedSec,
      'eventName': _eventName,
      'powerSaver': (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) == 0,
    }));
  }

  /// Ends the broadcast loop. A session that actually tracked gets a totals
  /// summary on the wrist (dismissed by its Done button → `dismissSummary`);
  /// otherwise the watch just returns to idle.
  void _finishSession() {
    _pushTimer?.cancel();
    _pushTimer = null;
    _locationService?.typedPointListeners.remove(this);
    // Catch the final second: distance never shrinks within a session, so a
    // larger current reading is fresher than the last tick's.
    final loc = _locationService;
    if (loc != null) {
      final cur = loc.filteredSessionDistanceMeters.value / 1000.0;
      if (cur > _lastDistanceKm) _lastDistanceKm = cur;
    }
    if (_startedAt != null) {
      final sec = DateTime.now().difference(_startedAt!).inSeconds;
      if (sec > _lastElapsedSec) _lastElapsedSec = sec;
    }
    _startedAt = null;
    if (_sessionSawTracking) {
      _sessionSawTracking = false;
      _summaryOnWrist = true;
      unawaited(_send(<String, Object?>{
        'phase': 'summary',
        'tracking': false,
        'eventName': _eventName,
        'distanceKm': _lastDistanceKm,
        'elapsedSec': _lastElapsedSec,
        'checks': _cntChecks,
        'falses': _cntFalses,
        'otherMarks': _cntOtherMarks,
        'photos': _cntPhotos,
      }));
    } else {
      unawaited(pushIdle());
    }
  }

  // ------------------------------------------------------------- outbound

  /// Broadcasts a state map to the watch. Safe to call unconditionally —
  /// no-ops on Android and swallows channel errors (no paired watch, etc.).
  Future<void> _send(Map<String, Object?> state) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<bool>('updateState', state);
    } catch (e) {
      // Missing plugin / no watch — never let the wrist break the run.
      if (!_pushFailureLogged) {
        _pushFailureLogged = true;
        BootLogger.logError(
            '[WatchBridge] pushState failed (logged once)', e, null);
      }
    }
  }

  /// Clears the wrist back to the idle screen. No-op while an undismissed
  /// summary is showing unless [force] (the wrist's own Done button) — the
  /// stats must never vanish on their own.
  Future<void> pushIdle({bool force = false}) {
    if (_summaryOnWrist && !force) return Future.value();
    _summaryOnWrist = false;
    return _send(const {'phase': 'idle', 'tracking': false});
  }

  // -------------------------------------------------------------- inbound

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method != 'watchCommand') return null;
    try {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      switch (args['cmd'] as String?) {
        case 'mark':
          return await _handleMark(args['type'] as String?);
        case 'onInn':
          return await _handleOnInn();
        case 'lostQuery':
          return await _handleLostQuery();
        case 'dismissSummary':
          await pushIdle(force: true);
          return {'ok': true};
        default:
          return {'ok': false, 'why': 'unknown-cmd'};
      }
    } catch (e, st) {
      // A thrown handler becomes a bare channel error on the native side —
      // log it here where the reason is still visible.
      BootLogger.logError('[WatchBridge] command failed', e, st);
      return {'ok': false, 'why': 'exception: $e'};
    }
  }

  Future<Map<String, Object?>> _handleMark(String? type) async {
    if (type == null) return {'ok': false, 'why': 'no-type'};

    final controller = _liveController;
    final slots = controller?.run.kennel.trailSlots ??
        (_sessionSlots.isNotEmpty ? _sessionSlots : TrailSlot.defaults);
    final slot = _resolveSlot(slots, type);
    if (slot == null) return {'ok': false, 'why': 'no-slot'};

    // Page open — the controller marks (shares its cooldown with phone taps).
    if (controller != null) {
      final why = await controller.markFromWatch(slot);
      return {'ok': why == null, 'why': why};
    }

    // Page closed — mark directly at service level.
    final loc = _locationService;
    if (loc == null || !loc.joinRunTracking.value) {
      return {'ok': false, 'why': 'not-tracking'};
    }
    final key = slot.trackType();
    final last = _lastServiceMarkAt[key];
    if (last != null && DateTime.now().difference(last) < _slotCooldown) {
      return {'ok': false, 'why': 'cooldown'};
    }
    _lastServiceMarkAt[key] = DateTime.now();
    try {
      final mark = await loc.captureSlotMark(slot);
      await loc.commitSlotMark(mark);
      return {'ok': true};
    } catch (e) {
      BootLogger.logError('[WatchBridge] service-level mark failed', e, null);
      return {'ok': false, 'why': 'gps: $e'};
    }
  }

  /// Tells the watch what its Check and False buttons should LOOK like, using
  /// this kennel's configured slots — the same slots `_resolveSlot` already
  /// uses when recording the mark, so wrist and phone agree.
  ///
  /// Sent once per session over `transferUserInfo`, never on the 1 Hz state
  /// push: the glyph PNGs are a few KB each, and applicationContext is
  /// latest-wins, so including them would re-send the images every second.
  /// transferUserInfo is queued and guaranteed, so it still lands if the watch
  /// app is shut or out of range when the run starts.
  ///
  /// A slot can be a glyph OR a short text (e.g. "FT"), so both are sent; the
  /// watch prefers the glyph, falls back to the text, then to its built-in SF
  /// Symbol. Only BUNDLED glyphs travel — an id resolved from blob storage has
  /// no local asset, and the watch's own fallback covers it.
  Future<void> _sendMarkButtons(List<TrailSlot> slots) async {
    if (!_supported) return;
    final payload = <String, Object?>{};
    for (final entry in {'check': 'check', 'false': 'falseTrail'}.entries) {
      final slot = _resolveSlot(slots, entry.value);
      if (slot == null) continue;
      payload['${entry.key}Label'] = slot.name;
      if (slot.kind == 'text') {
        payload['${entry.key}Text'] = slot.text;
        continue;
      }
      final glyph = slot.glyph;
      if (glyph == null) continue;
      try {
        final bytes = await rootBundle.load(glyph.assetPath);
        payload['${entry.key}Glyph'] = bytes.buffer.asUint8List();
        payload['${entry.key}Fixed'] = glyph.fixed;
      } catch (e) {
        // Missing asset is not worth failing the session over — the watch
        // keeps its built-in symbol.
        BootLogger.logError('[WatchBridge] glyph load failed', e, null);
      }
    }
    if (payload.isEmpty) return;
    try {
      await _channel.invokeMethod<bool>('updateMarkButtons', payload);
    } catch (e) {
      BootLogger.logError('[WatchBridge] updateMarkButtons failed', e, null);
    }
  }

  /// Maps the watch's fixed buttons onto the kennel's configured trail slots
  /// so wrist marks render with the same glyph/text as phone marks. Falls
  /// back to the built-in defaults if the kennel hid the slot.
  TrailSlot? _resolveSlot(List<TrailSlot> slots, String type) {
    bool isCheck(TrailSlot s) =>
        s.glyphId == 'check' || s.name.toLowerCase() == 'check';
    bool isFalse(TrailSlot s) =>
        s.text == 'FT' || s.name.toLowerCase().contains('false');

    switch (type) {
      case 'check':
        return _firstWhereOrNull(slots, isCheck) ??
            _firstWhereOrNull(TrailSlot.defaults, isCheck);
      case 'falseTrail':
        return _firstWhereOrNull(slots, isFalse) ??
            _firstWhereOrNull(TrailSlot.defaults, isFalse);
      default:
        return null;
    }
  }

  TrailSlot? _firstWhereOrNull(
      List<TrailSlot> slots, bool Function(TrailSlot) test) {
    for (final s in slots) {
      if (test(s)) return s;
    }
    return null;
  }

  Future<Map<String, Object?>> _handleOnInn() async {
    // Page open — use the controller's full end-run path (bookkeeping + UI).
    final controller = _liveController;
    if (controller != null) {
      if (!controller.isTracking.value) {
        return {'ok': false, 'why': 'not-tracking'};
      }
      await controller.endRun(markOnInn: true);
      _finishSession();
      return {'ok': true};
    }

    // Page closed — mirror endRun at service level: best-effort On-Inn
    // terminator, then stop tracking.
    final loc = _locationService;
    if (loc == null || !loc.joinRunTracking.value) {
      return {'ok': false, 'why': 'not-tracking'};
    }
    try {
      await loc.markPoint(HashRunPointTypes.onInn);
    } catch (_) {
      // Best-effort: a failed one-shot fix must never block the stop.
    }
    await loc.stopTracking();
    _finishSession();
    return {'ok': true};
  }

  /// Phase 2: the wrist vector view isn't fed real bearings yet — reply with
  /// a pointer to the phone's I'm Lost compass. Wiring the lost-compass
  /// nearest-trail math into this reply is the next watch milestone.
  Future<Map<String, Object?>> _handleLostQuery() async {
    return {
      'ok': true,
      'message':
          "Open I'm Lost on your phone for the compass — wrist vectors are coming soon.",
    };
  }
}
