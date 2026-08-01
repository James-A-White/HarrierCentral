import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// "Which way is the trail?" — a compass, not a route.
///
/// Finds the nearest point of the pack's live GPS tracks to the runner's
/// current position and shows an arrow (rotated by the device heading) plus a
/// straight-line distance. Deliberately NOT navigation: there is no path, no
/// route and no promise the direct line is passable — hashers cut through what
/// they like, which is exactly why a bearing beats turn-by-turn here.
///
/// Prefers OTHER runners' tracks (they are the trail). If nobody else is
/// tracking, it falls back to the runner's own earlier track — i.e. "backtrack
/// to where you left it" — and says so.
class LostCompassController extends GetxController {
  LostCompassController({required this.eventId});

  final String eventId;

  /// Points recorded within this window are "where I am now", not trail —
  /// excluded when falling back to the runner's own track.
  static const Duration _ownTrackIgnoreWindow = Duration(minutes: 2);

  /// Re-fetch cadence. Tracks move; so does the runner.
  static const Duration _refreshInterval = Duration(seconds: 20);

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  /// Bearing to the nearest trail point, degrees clockwise from true north.
  final RxnDouble bearingToTrail = RxnDouble();
  final RxnDouble distanceMeters = RxnDouble();

  /// Device heading from the magnetometer; null on devices without one (the
  /// arrow then points to the absolute bearing and the UI says so).
  final RxnDouble deviceHeading = RxnDouble();

  /// True when the nearest point came from the runner's own earlier track
  /// because nobody else is tracking — "backtrack" rather than "join the pack".
  final RxBool usingOwnTrack = false.obs;

  /// Number of other runners whose tracks were considered.
  final RxInt contributingRunners = 0.obs;

  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _refreshTimer;

  static const latlong.Distance _distance = latlong.Distance();

  @override
  void onInit() {
    super.onInit();
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null) return;
      final prev = deviceHeading.value;
      // Ignore sub-visible jitter so the arrow doesn't shiver.
      if (prev != null) {
        var diff = (h - prev).abs();
        if (diff > 180.0) diff = 360.0 - diff;
        if (diff < 2.0) return;
      }
      deviceHeading.value = h;
    });
    unawaited(refreshBearing());
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(refreshBearing()),
    );
  }

  @override
  void onClose() {
    unawaited(_compassSub?.cancel());
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshBearing() async {
    final String myUserId = currentUserId;
    final api = GetPositionsApi();
    try {
      final Position? me = Get.find<LocationService>().lastKnownPosition.value;
      if (me == null) {
        errorMessage.value =
            'Your location is not available yet. Make sure location is enabled '
            'and try again in a moment.';
        isLoading.value = false;
        return;
      }

      final payload = await api.fetchPositions(
        eventId: eventId,
        latestClientTimestampMs: '0000000000000000000',
      );

      final latlong.LatLng myPoint = latlong.LatLng(me.latitude, me.longitude);
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      // Pass 1: everyone else's tracks — that's the trail.
      final others = payload.users
          .where((u) => normalizeUuid(u.id) != normalizeUuid(myUserId))
          .toList(growable: false);
      contributingRunners.value = others.length;

      var best = _nearestAcross(
        tracks: others,
        from: myPoint,
        maxTimestampMs: null,
      );
      var fellBack = false;

      // Pass 2: nobody else out there — backtrack along my own earlier track.
      if (best == null) {
        final mine = payload.users
            .where((u) => normalizeUuid(u.id) == normalizeUuid(myUserId))
            .toList(growable: false);
        best = _nearestAcross(
          tracks: mine,
          from: myPoint,
          maxTimestampMs: nowMs - _ownTrackIgnoreWindow.inMilliseconds,
        );
        fellBack = best != null;
      }

      if (best == null) {
        errorMessage.value = contributingRunners.value == 0
            ? 'No live tracks yet for this run, so there is nothing to point '
                  'at. Ask in the chat — the pack has been notified.'
            : 'Could not read any track positions. Try again in a moment.';
        bearingToTrail.value = null;
        distanceMeters.value = null;
      } else {
        errorMessage.value = null;
        usingOwnTrack.value = fellBack;
        bearingToTrail.value = (_distance.bearing(myPoint, best) + 360) % 360;
        distanceMeters.value = _distance.as(
          latlong.LengthUnit.Meter,
          myPoint,
          best,
        );
      }
    } catch (e) {
      errorMessage.value =
          'Could not reach the tracking service. Check your signal and try again.';
      if (kDebugMode) debugPrint('[LostCompass] refresh failed: $e');
    } finally {
      isLoading.value = false;
      api.dispose();
    }
  }

  /// Nearest position to [from] across [tracks]. [maxTimestampMs] (when set)
  /// ignores points newer than that instant.
  latlong.LatLng? _nearestAcross({
    required List<UserTrack> tracks,
    required latlong.LatLng from,
    required int? maxTimestampMs,
  }) {
    latlong.LatLng? best;
    double bestMeters = double.infinity;

    for (final track in tracks) {
      for (final p in track.positions) {
        if (maxTimestampMs != null && p.timestampMs > maxTimestampMs) continue;
        // Drop wildly inaccurate fixes — pointing at GPS noise is worse than
        // pointing at nothing. Matches TrackPointFilter's accuracy gate.
        if (p.acc > 15.0) continue;
        final candidate = latlong.LatLng(p.lat, p.lng);
        final meters = _distance.as(latlong.LengthUnit.Meter, from, candidate);
        if (meters < bestMeters) {
          bestMeters = meters;
          best = candidate;
        }
      }
    }
    return best;
  }

  /// Compass point label ("NE", "SSW") for the absolute bearing — the fallback
  /// readout when the device has no magnetometer.
  String get compassPointLabel {
    final b = bearingToTrail.value;
    if (b == null) return '--';
    const names = <String>[
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    return names[(((b + 11.25) % 360) ~/ 22.5).toInt()];
  }

  String get distanceLabel {
    final m = distanceMeters.value;
    if (m == null) return '--';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(2)} km';
  }
}

Future<void> showLostCompassDialog(BuildContext context, String eventId) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => LostCompassDialog(eventId: eventId),
  );
}

class LostCompassDialog extends StatelessWidget {
  LostCompassDialog({super.key, required this.eventId})
    : controller = Get.put(
        LostCompassController(eventId: eventId),
        tag: 'lost-compass-$eventId',
      );

  final String eventId;
  final LostCompassController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Where is the trail?', style: ts_alertDialogTitle),
      content: Obx(() {
        if (controller.isLoading.value) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: HcAppCircularProgressIndicator(key: Key('lost-compass')),
            ),
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                error,
                style: ts_alertDialogBody,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final bearing = controller.bearingToTrail.value ?? 0;
        final heading = controller.deviceHeading.value;
        // With a compass the arrow is relative to how the phone is held; without
        // one it shows the absolute bearing (paired with the N/NE/… readout).
        final double arrowDegrees = heading == null
            ? bearing
            : (bearing - heading + 360) % 360;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 170,
              width: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueGrey.shade50,
                      border: Border.all(
                        color: Colors.blueGrey.shade200,
                        width: 2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    child: Text(
                      heading == null ? 'N' : '▲',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: arrowDegrees * math.pi / 180.0,
                    child: Icon(
                      Icons.navigation,
                      size: 104,
                      color: controller.usingOwnTrack.value
                          ? Colors.deepOrange.shade700
                          : hc_blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.distanceLabel,
              style: ts_titleCondensedVeryLargeBlack.copyWith(fontSize: 34),
            ),
            Text(
              heading == null
                  ? 'Bearing ${controller.bearingToTrail.value?.round() ?? 0}° (${controller.compassPointLabel}) — no compass on this device'
                  : controller.usingOwnTrack.value
                  ? 'Back towards your own earlier track'
                  : 'Towards the nearest runner\'s track',
              style: ts_alertDialogBody.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Straight-line direction only — not a route. Watch for roads, '
              'water and fences.',
              style: ts_alertDialogBody.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
      actions: [
        TextButton(
          onPressed: () => unawaited(controller.refreshBearing()),
          style: text_button_style,
          child: Text('Refresh', style: ts_button),
        ),
        ElevatedButton(
          onPressed: () {
            Get.delete<LostCompassController>(tag: 'lost-compass-$eventId');
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: hc_red,
            foregroundColor: Colors.white,
          ),
          child: Text('Close', style: ts_button),
        ),
      ],
    );
  }
}
