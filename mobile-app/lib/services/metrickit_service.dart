import 'package:harrier_central/imports.dart';

/// Drains MetricKit diagnostics captured natively on iOS — crashes, hangs,
/// CPU/disk exceptions, and the daily app-exit metrics that include the OOM /
/// memory-pressure / memory-limit terminations Xcode Organizer often does NOT
/// surface — and ships them to the server harvest (HC.ClientErrorLog via
/// [ServiceCommon.recordClientErrorLog]).
///
/// MetricKit delivers payloads on the launch AFTER the event, so this runs at
/// boot: the same one-launch-late model as the breadcrumb harvest. Gated on
/// [BoolPrefsEnum.debugHarvestEnabled] so it only reports for enabled testers,
/// matching the rest of the harvest — remove that guard to collect from all
/// users. No-op on Android and on iOS < 14 (channel absent).
class MetricKitService {
  static const MethodChannel _channel =
      MethodChannel('harrier_central/metrickit');

  /// Pulls any pending native MetricKit payloads and uploads each to the
  /// harvest. Safe to call unawaited during boot.
  static Future<void> drainAndUpload() async {
    if (!Platform.isIOS) return;
    if (getBoolPref(BoolPrefsEnum.debugHarvestEnabled) != true) return;

    List<dynamic>? payloads;
    try {
      payloads = await _channel.invokeMethod<List<dynamic>>('drainDiagnostics');
    } catch (_) {
      // Channel unavailable (iOS < 14, or handler not registered) — nothing to do.
      return;
    }
    if (payloads == null || payloads.isEmpty) return;

    for (final p in payloads) {
      final text = p?.toString() ?? '';
      if (text.isEmpty) continue;
      // ErrorLog is NVARCHAR(MAX); cap only against a pathologically large payload.
      final capped = text.length > 200000 ? text.substring(0, 200000) : text;
      unawaited(ServiceCommon.recordClientErrorLog('[METRICKIT]\n$capped'));
    }
  }
}
