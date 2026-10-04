import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

/// What can stop a phone recording a usable trail, checked before tracking
/// starts (E5.F1.S13). Every finding is named in plain words with a button
/// that goes to the right place. Most only warn; a [PreflightIssue.blocking]
/// one stops the start until it is put right (James, 2026-10-04): an iPhone
/// on While Using, or no location at all, cannot record a trail.
enum PreflightIssueKind {
  /// Location Services are off for the whole phone.
  locationServicesOff,

  /// The app has no location permission at all.
  locationDenied,

  /// iOS "While Using" / Android "Only while using the app": no fixes once
  /// the app is in the background — the City H3 #1941 27-minute hole.
  locationNotAlways,

  /// iOS Precise Location off: fixes are ~km-scale.
  reducedAccuracy,

  /// iOS Low Power Mode / Android Battery Saver: the OS throttles GPS.
  lowPowerMode,

  /// Android battery optimisation not exempted: Doze can stop the stream.
  batteryOptimisation,

  /// The Power Saver tracking tier: 15 fixes in an hour on #1941.
  powerSaverTier,
}

class PreflightIssue {
  const PreflightIssue({
    required this.kind,
    required this.title,
    required this.detail,
    required this.summary,
    this.actionLabel,
    this.action,
    this.blocking = false,
  });

  final PreflightIssueKind kind;

  /// Tracking cannot start until this is fixed: the dialog offers Cancel,
  /// not "Start anyway".
  final bool blocking;

  /// Bold, one line: `Location is set to While Using`.
  final String title;

  /// What it does to the trail and what to change.
  final String detail;

  /// Past tense, for the run summary's health line: `Location was While
  /// Using`.
  final String summary;

  /// The button, when there is somewhere to send them.
  final String? actionLabel;
  final Future<void> Function()? action;
}

/// The Android side lives in MainActivity.kt (`harrier_central/power`); iOS
/// has no public route to its Battery settings, so it only answers
/// `snapshot` on the metrics channel, which carries `lowPower`.
class _PowerChannel {
  static const MethodChannel _power = MethodChannel('harrier_central/power');
  static const MethodChannel _metrics = MethodChannel(
    'harrier_central/device_metrics',
  );

  static Future<bool?> lowPowerMode() async {
    try {
      final dynamic raw = await _metrics
          .invokeMethod<dynamic>('snapshot')
          .timeout(const Duration(seconds: 3));
      if (raw is Map) return raw['lowPower'] == true;
    } catch (_) {
      // Channel absent (tests, an older native build): unknown, not wrong.
    }
    return null;
  }

  static Future<bool?> ignoringBatteryOptimisations() async {
    try {
      return await _power
          .invokeMethod<bool>('isIgnoringBatteryOptimizations')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  static Future<void> requestIgnoreBatteryOptimisations() async {
    try {
      await _power.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } catch (e) {
      BootLogger.logBreadcrumb('[Preflight] battery optimisation intent: $e');
    }
  }

  static Future<void> openBatterySaverSettings() async {
    try {
      await _power.invokeMethod<void>('openBatterySaverSettings');
    } catch (e) {
      BootLogger.logBreadcrumb('[Preflight] battery saver intent: $e');
    }
  }
}

class TrackingPreflight {
  TrackingPreflight._();

  /// The iOS purpose key for a temporary Precise Location grant — must match
  /// `NSLocationTemporaryUsageDescriptionDictionary` in Info.plist.
  static const String precisePurposeKey = 'PackTrack';

  /// Everything wrong right now, worst first. Empty means go.
  static Future<List<PreflightIssue>> check() async {
    final List<PreflightIssue> issues = <PreflightIssue>[];
    final bool ios = Platform.isIOS;

    // Location permission — the #1941 finding. Android 10+ has the same
    // "only while using" state and calls it that.
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        issues.add(
          PreflightIssue(
            kind: PreflightIssueKind.locationServicesOff,
            title: 'Location Services are off',
            detail:
                'The phone is not giving any app its position, so there '
                'is nothing to record. Turn Location Services on.',
            summary: 'Location Services were off',
            blocking: true,
            actionLabel: 'Open Location Settings',
            action: () async {
              await Geolocator.openLocationSettings();
            },
          ),
        );
      }
      final LocationPermission perm = await Geolocator.checkPermission();
      switch (perm) {
        case LocationPermission.denied:
        case LocationPermission.deniedForever:
        case LocationPermission.unableToDetermine:
          issues.add(
            PreflightIssue(
              kind: PreflightIssueKind.locationDenied,
              title: 'Harrier Central cannot see your location',
              detail: ios
                  ? 'Location is off for Harrier Central, so no trail can '
                        'be recorded. Allow Location and set it to Always, so '
                        'it keeps working with the phone in your pocket.'
                  : 'Location is off for Harrier Central, so no trail can '
                        'be recorded. Allow Location while using the app.',
              summary: 'Location was denied',
              blocking: true,
              actionLabel: 'Open Settings',
              action: () async {
                if (perm == LocationPermission.denied) {
                  await Geolocator.requestPermission();
                }
                await Geolocator.openAppSettings();
              },
            ),
          );
        case LocationPermission.whileInUse:
          // iPhone only (James, 2026-10-04). On While Using, iOS stops the
          // fixes when the screen locks (Mouthwash, WLH3 #2114: 7 points,
          // then 93 minutes of nothing), so tracking may not start until
          // Location is Always. Android needs no such thing: its foreground
          // service ("Tracking run in progress") keeps a while-in-use
          // session alive, and the app does not even request background
          // location — telling Android users to pick "Allow all the time"
          // pointed them at an option their phone does not offer.
          if (!ios) break;
          issues.add(
            PreflightIssue(
              kind: PreflightIssueKind.locationNotAlways,
              title: 'Location needs to be set to Always',
              detail:
                  'On While Using, your iPhone stops sending PackTrack '
                  'your position the moment the screen locks, so the trail '
                  'stops at the start. Set Location to Always to track.',
              summary: 'Location was While Using',
              blocking: true,
              actionLabel: 'Set to Always',
              action: () async {
                // iOS offers "Change to Always Allow" once; after that only
                // Settings can change it.
                final LocationPermission now =
                    await Geolocator.requestPermission();
                if (now != LocationPermission.always) {
                  await Geolocator.openAppSettings();
                }
              },
            ),
          );
        case LocationPermission.always:
          break;
      }
    } catch (e) {
      BootLogger.logBreadcrumb('[Preflight] permission check failed: $e');
    }

    // Precise Location (iOS 14+). Android answers `precise` whenever fine
    // location is granted, which the permission check above already covers.
    if (ios) {
      try {
        final LocationAccuracyStatus acc =
            await Geolocator.getLocationAccuracy();
        if (acc == LocationAccuracyStatus.reduced) {
          issues.add(
            PreflightIssue(
              kind: PreflightIssueKind.reducedAccuracy,
              title: 'Precise Location is off',
              detail:
                  'Without it the phone reports where you are to within a '
                  'few kilometres, which draws no trail at all. Turn on '
                  'Precise Location for Harrier Central.',
              summary: 'Precise Location was off',
              actionLabel: 'Turn on Precise Location',
              action: () async {
                final LocationAccuracyStatus after =
                    await Geolocator.requestTemporaryFullAccuracy(
                      purposeKey: precisePurposeKey,
                    );
                if (after == LocationAccuracyStatus.reduced) {
                  await Geolocator.openAppSettings();
                }
              },
            ),
          );
        }
      } catch (e) {
        BootLogger.logBreadcrumb('[Preflight] accuracy check failed: $e');
      }
    }

    // Low Power Mode / Battery Saver — both slow the GPS down.
    final bool? lowPower = await _PowerChannel.lowPowerMode();
    if (lowPower == true) {
      issues.add(
        PreflightIssue(
          kind: PreflightIssueKind.lowPowerMode,
          title: ios ? 'Low Power Mode is on' : 'Battery Saver is on',
          detail: ios
              ? 'iOS slows location updates in Low Power Mode, so the trail '
                    'comes out coarse and jumpy. Turn it off in Control '
                    'Centre or Settings › Battery before you set off.'
              : 'Battery Saver can stop location updates while the screen is '
                    'off. Turn it off for the run.',
          summary: ios ? 'Low Power Mode was on' : 'Battery Saver was on',
          actionLabel: ios ? null : 'Open Battery Saver',
          action: ios ? null : _PowerChannel.openBatterySaverSettings,
        ),
      );
    }

    // Android battery optimisation: Doze pauses a non-exempt app's location
    // stream once the phone has been still in a pocket for a while.
    if (Platform.isAndroid) {
      final bool? exempt = await _PowerChannel.ignoringBatteryOptimisations();
      if (exempt == false) {
        issues.add(
          PreflightIssue(
            kind: PreflightIssueKind.batteryOptimisation,
            title: 'Battery optimisation is limiting Harrier Central',
            detail:
                'Android may pause the app in your pocket and leave gaps '
                'in the trail. Allow Harrier Central to run unrestricted.',
            summary: 'battery optimisation was on',
            actionLabel: 'Allow unrestricted',
            action: _PowerChannel.requestIgnoreBatteryOptimisations,
          ),
        );
      }
    }

    // The Power Saver tier is no longer a problem to warn about: since
    // 2026-10-01 every tier records the trail at Best and only uploads less
    // often in the pocket (James). [PreflightIssueKind.powerSaverTier] is
    // kept for older logs and never raised.

    return issues;
  }

  /// What went on the run summary when the runner started anyway: the
  /// findings' past-tense summaries, joined. Null when there were none.
  static String? summarise(List<PreflightIssue> issues) {
    if (issues.isEmpty) return null;
    return issues.map((PreflightIssue i) => i.summary).join(', ');
  }
}
