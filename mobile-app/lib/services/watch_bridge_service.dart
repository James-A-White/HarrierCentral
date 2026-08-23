import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_general_page.dart';

/// Dart side of the Apple Watch companion bridge (iOS only).
///
/// Outbound: [pushState] mirrors the live-run session onto the wrist via the
/// native `updateApplicationContext` broadcast — called once a second from
/// `LiveRunGeneralController`'s elapsed ticker while a session is active, and
/// once with `tracking: false` when it ends.
///
/// Inbound: watch button taps arrive as `watchCommand` calls. The returned
/// map is relayed verbatim to the watch as the tap's reply (`ok` drives the
/// success/failure haptic). Watch taps are deliberate — marks commit to the
/// track buffer immediately, with no flash card or Undo.
class WatchBridgeService extends GetxService {
  static const MethodChannel _channel = MethodChannel('harrier_central/watch');

  static WatchBridgeService get to => Get.find<WatchBridgeService>();

  bool get _supported => Platform.isIOS;

  // pushState fires every second while tracking — a channel-level failure
  // (no watch paired, plugin missing) would otherwise spam the harvest log.
  bool _pushFailureLogged = false;

  @override
  void onInit() {
    super.onInit();
    if (!_supported) return;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  // ---------------------------------------------------------------- outbound

  /// Broadcasts session state to the watch. Safe to call unconditionally —
  /// no-ops on Android and swallows channel errors (no paired watch, etc.).
  Future<void> pushState({
    required bool tracking,
    bool paused = false,
    double? distanceKm,
    int elapsedSec = 0,
    String eventName = '',
    bool powerSaver = false,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<bool>('updateState', <String, Object?>{
        'tracking': tracking,
        'paused': paused,
        'distanceKm': distanceKm,
        'elapsedSec': elapsedSec,
        'eventName': eventName,
        'powerSaver': powerSaver,
      });
    } catch (e) {
      // Missing plugin / no watch — never let the wrist break the run.
      if (!_pushFailureLogged) {
        _pushFailureLogged = true;
        BootLogger.logError('[WatchBridge] pushState failed (logged once)', e, null);
      }
    }
  }

  /// Clears the wrist back to the idle screen.
  Future<void> pushIdle() => pushState(tracking: false);

  // ----------------------------------------------------------------- inbound

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method != 'watchCommand') return null;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    switch (args['cmd'] as String?) {
      case 'mark':
        return _handleMark(args['type'] as String?);
      case 'onInn':
        return _handleOnInn();
      case 'lostQuery':
        return _handleLostQuery();
      default:
        return {'ok': false};
    }
  }

  LiveRunGeneralController? get _liveController =>
      Get.isRegistered<LiveRunGeneralController>()
          ? Get.find<LiveRunGeneralController>()
          : null;

  Future<Map<String, Object?>> _handleMark(String? type) async {
    final controller = _liveController;
    if (controller == null || type == null) return {'ok': false};
    final slot = _resolveSlot(controller.run.kennel.trailSlots, type);
    if (slot == null) return {'ok': false};
    final ok = await controller.markFromWatch(slot);
    return {'ok': ok};
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
    final controller = _liveController;
    if (controller == null || !controller.isTracking.value) {
      return {'ok': false};
    }
    await controller.endRun(markOnInn: true);
    await pushIdle();
    return {'ok': true};
  }

  /// Phase 1: the wrist vector view isn't fed real bearings yet — reply with
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
