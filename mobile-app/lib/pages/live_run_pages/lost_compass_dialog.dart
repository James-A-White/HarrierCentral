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
  static const Duration _refreshInterval = Duration(seconds: 5);

  /// How far BEFORE a runner's distress mark their track stops being trusted
  /// as trail. Someone typically wanders off-trail for a while before they
  /// admit it and press the button, so cutting exactly at the mark would still
  /// leave their wandering in the candidate set.
  static const Duration _lostLookBack = Duration(minutes: 5);

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

  /// Display name of the runner whose track is nearest, so the user knows
  /// whose line they're being pointed at.
  final RxnString nearestRunnerName = RxnString();

  /// Number of other runners whose tracks were considered.
  final RxInt contributingRunners = 0.obs;

  /// How many otherwise-eligible runners were skipped because they had marked
  /// themselves lost. Surfaced so "no trail found" is never mysterious.
  final RxInt excludedLostRunners = 0.obs;

  /// Cache of userId → display name, read from the local common DB.
  final Map<String, String> _nameCache = <String, String>{};

  /// Accumulated tracks for the run. The first poll pulls everything; later
  /// polls fetch only what is new (see [_afterTimestampMs]) and append.
  List<UserTrack> _tracks = const <UserTrack>[];
  String? _afterTimestampMs;
  bool _fetching = false;

  /// Runner whose trail the arrow currently points at, so a switch to a nearer
  /// one can be announced rather than silently swinging the needle.
  String? _targetRunnerId;

  /// Set briefly when the arrow retargets to a closer trail.
  final RxnString retargetNotice = RxnString();
  Timer? _retargetNoticeTimer;

  /// The trail point currently being pointed at. Chosen on the slow loop and
  /// held between polls: re-picking it on every GPS fix would make the arrow
  /// and distance jump around as near-equal candidates traded places.
  latlong.LatLng? _targetPoint;

  /// Freshest fix from our own stream; falls back to the shared service value
  /// until the first one arrives.
  Position? _lastPosition;

  StreamSubscription<Position>? _positionSub;
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
    // Own high-rate position stream for the lifetime of the dialog. The app's
    // shared idle stream only reports every 250m, which is useless here, and a
    // runner who is lost may not be tracking at all. Distance/bearing to the
    // held target cost nothing to recompute — no network, just trigonometry —
    // so the readout moves with each fix rather than once per poll.
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0, // every fix the OS gives us
          ),
        ).listen(
          (pos) {
            _lastPosition = pos;
            _updateReadout(pos);
          },
          onError: (Object e) {
            if (kDebugMode) debugPrint('[LostCompass] position stream: $e');
          },
        );

    unawaited(refreshBearing());
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(refreshBearing()),
    );
  }

  /// Recomputes bearing and distance to the CURRENTLY HELD target. Cheap and
  /// purely local; safe to run on every GPS fix.
  void _updateReadout(Position me) {
    final target = _targetPoint;
    if (target == null) return;
    final from = latlong.LatLng(me.latitude, me.longitude);
    bearingToTrail.value = (_distance.bearing(from, target) + 360) % 360;
    distanceMeters.value = _distance.as(latlong.LengthUnit.Meter, from, target);
  }

  @override
  void onClose() {
    unawaited(_positionSub?.cancel());
    unawaited(_compassSub?.cancel());
    _refreshTimer?.cancel();
    _retargetNoticeTimer?.cancel();
    super.onClose();
  }

  /// One tick of the refresh loop: poll the server for the pack's newest
  /// positions, then recompute the bearing from those plus the runner's own
  /// current position. Runs every [_refreshInterval] — someone who is lost gets
  /// live data, and if the pack moves a trail closer, the arrow follows it.
  Future<void> refreshBearing({bool forceFetch = false}) async {
    final Position? me =
        _lastPosition ?? Get.find<LocationService>().lastKnownPosition.value;
    if (me == null) {
      errorMessage.value =
          'Your location is not available yet. Make sure location is enabled '
          'and try again in a moment.';
      isLoading.value = false;
      return;
    }

    await _fetchTracks();

    // No data yet (first fetch failed) — keep whatever error _fetchTracks set.
    if (_tracks.isEmpty && errorMessage.value != null) {
      isLoading.value = false;
      return;
    }

    _recompute(me);
    isLoading.value = false;
  }

  /// Polls the tracking service and merges the result into [_tracks].
  ///
  /// The first call pulls the whole run; every later call sends the server's
  /// own `latestServerTimestampMs` back as `AfterTimestamp` so only NEW points
  /// come down and are appended. At a 5-second cadence that keeps the data
  /// live without re-downloading every runner's entire history twelve times a
  /// minute — which matters on the phone of someone who is already lost and
  /// burning battery. Guarded so a slow poll can't pile up behind the tick.
  Future<void> _fetchTracks() async {
    if (_fetching) return;
    _fetching = true;
    final api = GetPositionsApi();
    try {
      final bool isFirst = _afterTimestampMs == null;
      final payload = await api.fetchPositions(
        eventId: eventId,
        latestClientTimestampMs: _afterTimestampMs ?? '0000000000000000000',
      );
      if (isFirst) {
        _tracks = payload.users;
      } else {
        _mergeTracks(payload.users);
      }
      // Keep the previous watermark if the server didn't return a new one,
      // otherwise the next poll would re-request the whole run.
      _afterTimestampMs = payload.latestServerTimestampMs ?? _afterTimestampMs;
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value =
          'Could not reach the tracking service. Check your signal and try again.';
      if (kDebugMode) debugPrint('[LostCompass] fetch failed: $e');
    } finally {
      _fetching = false;
      api.dispose();
    }
  }

  /// Appends an incremental payload's points to the tracks already held.
  void _mergeTracks(List<UserTrack> incoming) {
    if (incoming.isEmpty) return;
    final byId = <String, UserTrack>{for (final t in _tracks) t.id: t};
    for (final t in incoming) {
      final existing = byId[t.id];
      byId[t.id] = existing == null
          ? t
          : existing.copyWith(
              positions: <TrackPoint>[...existing.positions, ...t.positions],
            );
    }
    _tracks = byId.values.toList(growable: false);
  }

  /// Recomputes the bearing/distance from cached tracks and [me].
  void _recompute(Position me) {
    final String myUserId = currentUserId;
    final latlong.LatLng myPoint = latlong.LatLng(me.latitude, me.longitude);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // Pass 1: everyone else's tracks — that's the trail. But NOT the track of
    // anyone who has marked themselves lost: their line left the trail, and
    // pointing one lost hasher at another's wandering just makes two lost
    // hashers in the same wrong place. Their pre-lost track is still good
    // trail, so we cut each lost runner's points at their distress mark
    // (minus a look-back) rather than discarding the whole track.
    final others = _tracks
        .where((u) => normalizeUuid(u.id) != normalizeUuid(myUserId))
        .toList(growable: false);
    contributingRunners.value = others.length;

    int excluded = 0;
    final candidates = <({UserTrack track, int? cutoffMs})>[];
    for (final u in others) {
      final int? lostAtMs = _earliestDistressMs(u);
      if (lostAtMs == null) {
        candidates.add((track: u, cutoffMs: null));
      } else {
        excluded++;
        candidates.add((
          track: u,
          cutoffMs: lostAtMs - _lostLookBack.inMilliseconds,
        ));
      }
    }
    excludedLostRunners.value = excluded;

    var best = _nearestAcross(candidates: candidates, from: myPoint);
    var fellBack = false;

    // Pass 2: nobody else usable out there — backtrack along my own earlier
    // track. Recent points are just where I'm standing, so they're cut too.
    if (best == null) {
      final mine = _tracks
          .where((u) => normalizeUuid(u.id) == normalizeUuid(myUserId))
          .map(
            (u) => (
              track: u,
              cutoffMs: nowMs - _ownTrackIgnoreWindow.inMilliseconds,
            ),
          )
          .toList(growable: false);
      best = _nearestAcross(candidates: mine, from: myPoint);
      fellBack = best != null;
    }

    if (best == null) {
      errorMessage.value = contributingRunners.value == 0
          ? 'No live tracks yet for this run, so there is nothing to point '
                'at. Ask in the chat — the pack has been notified.'
          : excluded > 0
          ? 'The only other tracks belong to hashers who are also lost, so '
                'there is no trail to point at. Ask in the chat — the pack '
                'has been notified.'
          : 'Could not read any track positions. Try again in a moment.';
      _targetPoint = null;
      bearingToTrail.value = null;
      distanceMeters.value = null;
      nearestRunnerName.value = null;
    } else {
      errorMessage.value = null;
      usingOwnTrack.value = fellBack;
      // Latch the chosen point. Bearing and distance are then recomputed
      // against it on every GPS fix (see _updateReadout) rather than only
      // here, so the numbers move as you walk instead of once per poll.
      _targetPoint = best.point;
      _updateReadout(me);
      final String nearestId = best.userId;
      nearestRunnerName.value = null;
      if (!fellBack) {
        final cached = _nameCache[nearestId];
        if (cached != null) {
          nearestRunnerName.value = cached;
        } else {
          // Not cached yet — resolve in the background and fill it in.
          unawaited(
            _displayName(nearestId).then((n) {
              if (n != null) nearestRunnerName.value = n;
            }),
          );
        }
        // The nearest trail is recomputed from scratch every tick, so a track
        // that has come closer simply wins. Announce the switch — the needle
        // swinging to a different trail should never be a silent surprise.
        if (_targetRunnerId != null && _targetRunnerId != nearestId) {
          unawaited(
            _displayName(nearestId).then((n) {
              retargetNotice.value = n == null
                  ? 'Switched to a closer trail'
                  : "Switched to $n's trail — it's closer";
              _retargetNoticeTimer?.cancel();
              _retargetNoticeTimer = Timer(
                const Duration(seconds: 8),
                () => retargetNotice.value = null,
              );
            }),
          );
        }
        _targetRunnerId = nearestId;
      } else {
        _targetRunnerId = null;
      }
    }
  }

  /// Timestamp of the runner's earliest distress mark, or null if they have
  /// never called for help. Marks carry `LST::…` / `SOS::…` in the type field.
  int? _earliestDistressMs(UserTrack track) {
    int? earliest;
    for (final p in track.positions) {
      final type = (p.type ?? '').trim();
      if (type.isEmpty) continue;
      final key = type.split('::').first.trim();
      if (key != HashRunPointTypes.lostRunner.key &&
          key != HashRunPointTypes.helpNeeded.key) {
        continue;
      }
      if (earliest == null || p.timestampMs < earliest) {
        earliest = p.timestampMs;
      }
    }
    return earliest;
  }

  /// Nearest position to [from] across [candidates], with the id of the runner
  /// whose track it belongs to. Each candidate's `cutoffMs` (when set) ignores
  /// that runner's points at or after that instant.
  ({latlong.LatLng point, String userId})? _nearestAcross({
    required List<({UserTrack track, int? cutoffMs})> candidates,
    required latlong.LatLng from,
  }) {
    ({latlong.LatLng point, String userId})? best;
    double bestMeters = double.infinity;

    for (final candidate in candidates) {
      final cutoff = candidate.cutoffMs;
      for (final p in candidate.track.positions) {
        if (cutoff != null && p.timestampMs >= cutoff) continue;
        // Drop wildly inaccurate fixes — pointing at GPS noise is worse than
        // pointing at nothing. Matches TrackPointFilter's accuracy gate.
        if (p.acc > 15.0) continue;
        final latlong.LatLng at = latlong.LatLng(p.lat, p.lng);
        final meters = _distance.as(latlong.LengthUnit.Meter, from, at);
        if (meters < bestMeters) {
          bestMeters = meters;
          best = (point: at, userId: candidate.track.id);
        }
      }
    }
    return best;
  }

  /// Display name for a runner, read from the local common DB (same preference
  /// order the map uses: hash name, then display name, then real name).
  Future<String?> _displayName(String userId) async {
    final cached = _nameCache[userId];
    if (cached != null) return cached;
    try {
      final rows = await QueryUsers.querySingleUser(userId);
      if (rows.isEmpty) return null;
      final r = rows.first;
      String pick(String? v) =>
          (v != null && v.trim().isNotEmpty) ? v.trim() : '';
      final candidates = <String>[
        pick(r[tableModel.hashersTableHelper.colHashName] as String?),
        pick(r[tableModel.hashersTableHelper.colDispName] as String?),
        [
          pick(r[tableModel.hashersTableHelper.colFirstName] as String?),
          pick(r[tableModel.hashersTableHelper.colLastName] as String?),
        ].where((p) => p.isNotEmpty).join(' '),
      ];
      final name = candidates.firstWhere((n) => n.isNotEmpty, orElse: () => '');
      if (name.isEmpty) return null;
      _nameCache[userId] = name;
      return name;
    } catch (e) {
      if (kDebugMode) debugPrint('[LostCompass] name lookup failed: $e');
      return null;
    }
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
              controller.usingOwnTrack.value
                  ? 'Back towards your own earlier track'
                  : controller.nearestRunnerName.value != null
                  ? "Towards ${controller.nearestRunnerName.value}'s trail"
                  : "Towards the nearest runner's trail",
              style: ts_alertDialogBody.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (heading == null)
              Text(
                'Bearing ${controller.bearingToTrail.value?.round() ?? 0}° (${controller.compassPointLabel}) — no compass on this device',
                style: ts_alertDialogBody.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            if (controller.retargetNotice.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: hc_blue,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    controller.retargetNotice.value!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (controller.excludedLostRunners.value > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  controller.excludedLostRunners.value == 1
                      ? '1 hasher who is also lost was left out'
                      : '${controller.excludedLostRunners.value} hashers who are also lost were left out',
                  style: ts_alertDialogBody.copyWith(
                    fontSize: 11,
                    color: Colors.deepOrange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
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
