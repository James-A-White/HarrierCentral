import 'package:harrier_central/imports.dart';

/// What the phone's own motion sensing says the hasher is doing (E5.F1.S15).
/// iOS: Core Motion; Android: Play Services Activity Recognition — both on
/// low-power hardware. See MotionActivityBridge (AppDelegate.swift) and
/// MainActivity.kt for the native halves.
enum MotionKind { running, walking, onFoot, inVehicle, cycling, still, unknown }

class MotionActivity {
  const MotionActivity(this.kind, this.confidence, this.tsMs);
  final MotionKind kind;

  /// 0-100. iOS's low / medium / high arrive as 30 / 60 / 90.
  final int confidence;
  final int tsMs;

  static MotionKind kindOf(String? type) => switch (type) {
    'running' => MotionKind.running,
    'walking' => MotionKind.walking,
    'on_foot' => MotionKind.onFoot,
    'in_vehicle' => MotionKind.inVehicle,
    'cycling' => MotionKind.cycling,
    'still' => MotionKind.still,
    _ => MotionKind.unknown,
  };
}

/// Starts and stops the native activity stream. Never throws: anything that
/// goes wrong — no API, permission refused, a build without the channel —
/// means [start] returns false and auto start keeps its GPS rule alone.
class MotionActivityService {
  MotionActivityService._();

  static const MethodChannel _method = MethodChannel(
    'harrier_central/activity',
  );
  static const EventChannel _events = EventChannel(
    'harrier_central/activity/events',
  );

  static StreamSubscription<dynamic>? _sub;

  /// Asks for permission where the platform needs it (Android 10+: Physical
  /// activity; iOS prompts by itself on the first start), then starts.
  static Future<bool> start(void Function(MotionActivity) onActivity) async {
    try {
      if (Platform.isAndroid) {
        final PermissionStatus status = await Permission.activityRecognition
            .request();
        if (!status.isGranted) {
          BootLogger.logBreadcrumb('[AutoStart] motion: permission $status');
          return false;
        }
      }
      await _sub?.cancel();
      _sub = _events.receiveBroadcastStream().listen(
        (dynamic e) {
          if (e is! Map) return;
          final int confidence = (e['confidence'] as num?)?.toInt() ?? 0;
          onActivity(
            MotionActivity(
              MotionActivity.kindOf(e['type'] as String?),
              confidence,
              ClockOffset.trackNowUtc().millisecondsSinceEpoch,
            ),
          );
        },
        onError: (Object e) =>
            BootLogger.logBreadcrumb('[AutoStart] motion stream error: $e'),
      );
      final bool ok = await _method.invokeMethod<bool>('start') ?? false;
      if (!ok) {
        await _sub?.cancel();
        _sub = null;
      }
      BootLogger.logBreadcrumb(
        '[AutoStart] motion: ${ok ? 'started' : 'unavailable'}',
      );
      return ok;
    } catch (e) {
      BootLogger.logBreadcrumb('[AutoStart] motion: not started ($e)');
      await _sub?.cancel();
      _sub = null;
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _sub?.cancel();
      _sub = null;
      await _method.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
