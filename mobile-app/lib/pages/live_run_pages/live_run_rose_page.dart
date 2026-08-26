import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// "Where is everybody?" — a radar rose with the viewer at the centre.
///
/// Distance is the radius: a blip halfway out is halfway to the ring's range.
/// The initial range is the 90th-percentile distance, so the one hasher who has
/// gone properly rogue can't squash the whole pack into the middle; anyone
/// beyond the range is pinned to the rim as a hollow marker so you still know
/// they are out there. Pinch to change the range.
class LiveRunRoseController extends GetxController {
  LiveRunRoseController({required this.run});

  final RunDetailsAggregate run;

  /// Matches the map's own cadence — the rose is a second view of the same data.
  static const Duration _refreshInterval = Duration(seconds: 15);

  /// A position older than this is flagged: the hasher may have lost signal or
  /// stopped tracking, and their blip is a guess.
  static const Duration _staleAfter = Duration(minutes: 5);

  /// Fraction of the pack the initial range is sized to hold.
  static const double _initialCoverage = 0.90;

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxList<RoseBlip> blips = <RoseBlip>[].obs;

  /// Outer-ring range in metres. Driven by the pinch gesture.
  final RxDouble ringMetres = 500.0.obs;
  bool _rangeInitialised = false;

  final RxnDouble deviceHeading = RxnDouble();

  List<UserTrack> _tracks = const <UserTrack>[];
  String? _afterTimestampMs;
  bool _fetching = false;
  final Map<String, String> _nameCache = <String, String>{};

  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _timer;

  static const latlong.Distance _distance = latlong.Distance();

  @override
  void onInit() {
    super.onInit();
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null) return;
      final prev = deviceHeading.value;
      if (prev != null) {
        var diff = (h - prev).abs();
        if (diff > 180.0) diff = 360.0 - diff;
        if (diff < 2.0) return; // sub-visible — don't shiver the rose
      }
      deviceHeading.value = h;
    });
    unawaited(refreshBlips());
    _timer = Timer.periodic(_refreshInterval, (_) => unawaited(refreshBlips()));
  }

  @override
  void onClose() {
    unawaited(_compassSub?.cancel());
    _timer?.cancel();
    super.onClose();
  }

  /// Pinch handler. Pinching apart zooms IN, which means a SMALLER range.
  void applyScale(double scale) {
    if (scale <= 0) return;
    final double next = ringMetres.value / scale;
    final double maxRange = blips.isEmpty
        ? 5000.0
        : blips.map((b) => b.distanceMeters).reduce(math.max) * 2.0;
    ringMetres.value = next.clamp(25.0, math.max(100.0, maxRange));
  }

  /// Back to the range that holds [_initialCoverage] of the pack.
  void resetRange() {
    _rangeInitialised = false;
    _sizeRange();
  }

  Future<void> refreshBlips() async {
    final Position? me = Get.find<LocationService>().lastKnownPosition.value;
    if (me == null) {
      errorMessage.value =
          'Your location is not available yet. Make sure location is enabled.';
      isLoading.value = false;
      return;
    }

    await _fetchTracks();
    if (_tracks.isEmpty && errorMessage.value != null) {
      isLoading.value = false;
      return;
    }

    _rebuildBlips(me);
    _sizeRange();
    isLoading.value = false;
  }

  /// Polls the tracking service. First call pulls the run; later calls send the
  /// server's watermark back so only new points come down and are appended.
  Future<void> _fetchTracks() async {
    if (_fetching) return;
    _fetching = true;
    final api = GetPositionsApi();
    try {
      final bool isFirst = _afterTimestampMs == null;
      final payload = await api.fetchPositions(
        eventId: run.event.eventId,
        latestClientTimestampMs: _afterTimestampMs ?? '0000000000000000000',
      );
      if (isFirst) {
        _tracks = payload.users;
      } else {
        _mergeTracks(payload.users);
      }
      _afterTimestampMs = payload.latestServerTimestampMs ?? _afterTimestampMs;
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value =
          'Could not reach the tracking service. Check your signal.';
      if (kDebugMode) debugPrint('[Rose] fetch failed: $e');
    } finally {
      _fetching = false;
      api.dispose();
    }
  }

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

  /// Per-runner track colours, assigned by order of first appearance in the
  /// loaded set — the same rule (and the same palette) as
  /// RunTrackerMapController and public-web, so a hasher keeps one colour on
  /// the map, the radar and the list. Assigned over the FULL track list
  /// (including the viewer's own) so skipping self below can't shift anyone
  /// else's colour relative to the map.
  final Map<String, Color> _colorById = <String, Color>{};

  void _assignColors() {
    for (final t in _tracks) {
      _colorById.putIfAbsent(
        t.id,
        () =>
            RunTrackerMapController.trackColors[_colorById.length %
                RunTrackerMapController.trackColors.length],
      );
    }
  }

  void _rebuildBlips(Position me) {
    final String myId = currentUserId;
    final latlong.LatLng myPoint = latlong.LatLng(me.latitude, me.longitude);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final next = <RoseBlip>[];
    _assignColors();

    for (final track in _tracks) {
      if (normalizeUuid(track.id) == normalizeUuid(myId)) continue;

      // Their CURRENT position is the newest usable fix, not the newest point:
      // marks and rough fixes shouldn't decide where their blip sits.
      TrackPoint? latest;
      for (final p in track.positions) {
        if (p.acc > 25.0) continue;
        if (latest == null || p.timestampMs > latest.timestampMs) latest = p;
      }
      if (latest == null) continue;

      final at = latlong.LatLng(latest.lat, latest.lng);
      next.add(
        RoseBlip(
          userId: track.id,
          name: _nameCache[track.id] ?? 'Hasher',
          bearing: (_distance.bearing(myPoint, at) + 360) % 360,
          distanceMeters: _distance.as(latlong.LengthUnit.Meter, myPoint, at),
          isLost: _hasDistressMark(track),
          isStale: nowMs - latest.timestampMs > _staleAfter.inMilliseconds,
          color:
              _colorById[track.id] ?? RunTrackerMapController.trackColors.first,
        ),
      );

      if (!_nameCache.containsKey(track.id)) {
        unawaited(_resolveName(track.id));
      }
    }

    next.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    blips.value = next;
  }

  /// Sizes the ring to hold [_initialCoverage] of the pack, so a lone straggler
  /// kilometres away doesn't compress everyone else into the centre. Runs once;
  /// after that the range belongs to the user's fingers.
  void _sizeRange() {
    if (_rangeInitialised || blips.isEmpty) return;
    final ds = blips.map((b) => b.distanceMeters).toList()..sort();
    final idx = ((ds.length - 1) * _initialCoverage).floor();
    final double p90 = ds[idx.clamp(0, ds.length - 1)];
    // A little headroom so the furthest included blip isn't welded to the rim.
    ringMetres.value = math.max(50.0, p90 * 1.15);
    _rangeInitialised = true;
  }

  bool _hasDistressMark(UserTrack track) {
    for (final p in track.positions) {
      final type = (p.type ?? '').trim();
      if (type.isEmpty) continue;
      final key = type.split('::').first.trim();
      if (key == HashRunPointTypes.lostRunner.key ||
          key == HashRunPointTypes.helpNeeded.key) {
        return true;
      }
    }
    return false;
  }

  Future<void> _resolveName(String userId) async {
    try {
      final rows = await QueryUsers.querySingleUser(userId);
      if (rows.isEmpty) return;
      final r = rows.first;
      String pick(String? v) =>
          (v != null && v.trim().isNotEmpty) ? v.trim() : '';
      final ordered = <String>[
        pick(r[tableModel.hashersTableHelper.colHashName] as String?),
        pick(r[tableModel.hashersTableHelper.colDispName] as String?),
        [
          pick(r[tableModel.hashersTableHelper.colFirstName] as String?),
          pick(r[tableModel.hashersTableHelper.colLastName] as String?),
        ].where((p) => p.isNotEmpty).join(' '),
      ];
      final name = ordered.firstWhere((n) => n.isNotEmpty, orElse: () => '');
      if (name.isEmpty) return;
      _nameCache[userId] = name;
      // Re-label in place without waiting for the next poll.
      final i = blips.indexWhere((b) => b.userId == userId);
      if (i != -1) {
        final b = blips[i];
        blips[i] = RoseBlip(
          userId: b.userId,
          name: name,
          bearing: b.bearing,
          distanceMeters: b.distanceMeters,
          isLost: b.isLost,
          isStale: b.isStale,
          color: b.color,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Rose] name lookup failed: $e');
    }
  }

  String get rangeLabel {
    final m = ringMetres.value;
    return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(2)} km';
  }

  int get beyondRangeCount =>
      blips.where((b) => b.distanceMeters > ringMetres.value).length;
}

class LiveRunRosePage extends StatelessWidget {
  LiveRunRosePage({super.key, required this.run})
    : controller = Get.put(
        LiveRunRoseController(run: run),
        tag: 'live-run-rose-${run.event.eventId}',
      );

  final RunDetailsAggregate run;
  final LiveRunRoseController controller;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Where is everyone?', style: ts_appBarTitle),
        actions: [
          IconButton(
            tooltip: 'Reset range',
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
            onPressed: controller.resetRange,
          ),
        ],
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: HcAppCircularProgressIndicator(key: Key('rose-loading')),
              );
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.blips.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    error,
                    style: ts_body,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (controller.blips.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    'Nobody else is tracking this run yet, so there is nothing '
                    'to show. The rose fills in as hashers start PackTrack.',
                    style: ts_body,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final beyond = controller.beyondRangeCount;
            return Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onScaleUpdate: (d) {
                      if (d.pointerCount >= 2) controller.applyScale(d.scale);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: RoseCanvas(
                        blips: controller.blips.toList(growable: false),
                        ringMetres: controller.ringMetres.value,
                        heading: controller.deviceHeading.value,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    children: [
                      Text(
                        'Ring = ${controller.rangeLabel}'
                        '${beyond > 0 ? '  ·  $beyond beyond the ring' : ''}',
                        style: ts_button.copyWith(
                          color: Colors.yellow,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.deviceHeading.value == null
                            ? 'North is up — this phone has no compass. '
                                  'Pinch to change range.'
                            : 'Top of the ring is straight ahead. '
                                  'Pinch to change range.',
                        style: ts_body.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
