import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

class LiveRunMapController extends GetxController {
  LiveRunMapController({required this.run}) {
    LiveRunService.ensure();
  }

  final RunDetailsAggregate run;
  final RxBool trueNorthLock = true.obs;

  latlng.LatLng? get eventLocation {
    final lat = run.extensions.evtLat ?? run.event.hcLatitude;
    final lon = run.extensions.evtLon ?? run.event.hcLongitude;
    if (lat == null || lon == null) return null;
    return latlng.LatLng(lat, lon);
  }

  latlng.LatLng? get kennelLocation {
    final lat = run.kennel.kennelLatitude;
    final lon = run.kennel.kennelLongitude;
    if (lat == null || lon == null) return null;
    return latlng.LatLng(lat, lon);
  }

  latlng.LatLng? get mapCenter => eventLocation ?? kennelLocation;
}

class LiveRunMapPage extends StatelessWidget {
  LiveRunMapPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunMapController(run: run),
        tag: 'live-run-map-${run.event.eventId}',
      );

  final RunDetailsAggregate run;
  final LiveRunMapController controller;

  @override
  Widget build(BuildContext context) {
    // Admin-only trim editor state. Reuse the existing instance across rebuilds
    // (don't re-put, or the expanded/busy state resets). The overlay renders
    // nothing for non-admins, so this is cheap for everyone else.
    final trimTag = 'live-run-trim-${run.event.eventId}';
    final trimController = Get.isRegistered<LiveRunTrimController>(tag: trimTag)
        ? Get.find<LiveRunTrimController>(tag: trimTag)
        : Get.put(LiveRunTrimController(run: run), tag: trimTag);
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: Obx(() {
        final center = controller.mapCenter;
        final kennel = controller.kennelLocation;
        final eventLoc = controller.eventLocation;

        if (center == null || kennel == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Map not available for this run yet.',
                style: ts_headingLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: RunTrackerMap(
                run.event,
                eventLoc,
                center,
                kennel,
                1.0,
                22.0,
                14.0,
                controller.trueNorthLock.value,
                overlayBottomPadding: 50.0,
                mapMoved: (latlng.LatLng newCenter) {},
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                child: IconButton(
                  tooltip: controller.trueNorthLock.value
                      ? 'Unlock rotation'
                      : 'Lock to North',
                  icon: Icon(
                    controller.trueNorthLock.value
                        ? Icons.explore_off
                        : Icons.explore,
                    color: hc_blue,
                  ),
                  onPressed: () {
                    controller.trueNorthLock.value =
                        !controller.trueNorthLock.value;
                  },
                ),
              ),
            ),
            // Admin-only: set/clear the official start & end of the run. Renders
            // nothing for non-admins.
            Positioned(
              left: 12,
              bottom: 60,
              child: TrimEditorOverlay(trimController: trimController),
            ),
          ],
        );
      }),
    );
  }
}

/// Drives the admin PackTrack trim editor: sets the official start/end of a run
/// by dropping AST/AEN boundary markers at the map timeline's current scrub
/// position, and clears them. Reaches the run's [RunTrackerMapController] (keyed
/// by event id) for the scrub position, the current window, and to reload the
/// track after a change. Admin-gated on the run's `authCanManageRuns` flag.
class LiveRunTrimController extends GetxController {
  LiveRunTrimController({required this.run});

  final RunDetailsAggregate run;

  /// Whether the editor is expanded. While editing, the map shows the FULL
  /// (untrimmed) track so out-of-window points are visible and the boundaries
  /// can be dragged back outward.
  final RxBool editing = false.obs;
  final RxBool busy = false.obs;

  String get _eventId => run.event.eventId;
  String get _userId => getStringPref(StringPrefsEnum.userId) ?? '';

  bool get isAdmin {
    final access = AppAccess(run.extensions.appAccessFlags);
    return access.getAppAccess(authCanManageRuns) ||
        access.getAppAccess(authIsAdmin);
  }

  RunTrackerMapController? get _map =>
      Get.isRegistered<RunTrackerMapController>(tag: _eventId)
      ? Get.find<RunTrackerMapController>(tag: _eventId)
      : null;

  int? get officialStartMs => _map?.officialStartMs.value;
  int? get officialEndMs => _map?.officialEndMs.value;

  Future<void> toggleEditing() async {
    editing.value = !editing.value;
    final map = _map;
    if (map == null) return;
    // Show the full track while editing; back to the trimmed view when done.
    map.adminEditMode = editing.value;
    await map.loadPositions(reset: true);
  }

  Future<void> setStart() => _setBoundary(HashRunPointTypes.adminStart);
  Future<void> setEnd() => _setBoundary(HashRunPointTypes.adminEnd);

  Future<void> _setBoundary(HashRunPointTypes type) async {
    final map = _map;
    final ts = map?.currentTimestampMs.value;
    if (map == null || ts == null) {
      _snack('Scrub the timeline to the moment you want, then tap again.');
      return;
    }
    if (_userId.isEmpty) return;
    busy.value = true;
    try {
      await Get.find<LocationService>().markBoundaryAt(
        boundaryType: type,
        timestampMs: ts.round(),
        overrideEventId: _eventId,
        overrideUserId: _userId,
        lat: run.extensions.evtLat ?? 0.0,
        lng: run.extensions.evtLon ?? 0.0,
      );
      await map.loadPositions(reset: true);
      _snack(
        type == HashRunPointTypes.adminStart
            ? 'Official start set.'
            : 'Official end set.',
      );
    } catch (e) {
      _snack('Could not set the boundary — try again when online.');
    } finally {
      busy.value = false;
    }
  }

  /// Removes the current start/end markers. Scoped to the caller's own userId
  /// (the endpoint never touches another runner's points), so this clears
  /// boundaries THIS admin placed; a boundary set by a different admin is moved
  /// rather than cleared by dropping a fresh marker (newest wins).
  Future<void> clear() async {
    final map = _map;
    if (map == null || _userId.isEmpty) return;
    final ts = <int>[
      if (map.officialStartMs.value != null) map.officialStartMs.value!,
      if (map.officialEndMs.value != null) map.officialEndMs.value!,
    ];
    if (ts.isEmpty) return;
    busy.value = true;
    final api = DeletePositionsApi();
    try {
      await api.deletePoints(
        eventId: _eventId,
        userId: _userId,
        timestampsMs: ts,
      );
      await map.loadPositions(reset: true);
      _snack('Official window cleared.');
    } catch (e) {
      _snack('Could not clear the window — try again when online.');
    } finally {
      api.dispose();
      busy.value = false;
    }
  }

  void _snack(String msg) {
    Get.snackbar(
      'PackTrack',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: hc_blue,
      colorText: Colors.white,
    );
  }
}

/// Compact admin overlay for setting the official start/end of a run. Collapsed
/// to a single scissors button; expands to Set Start / Set End / Clear plus a
/// readout of the current window. Renders nothing for non-admins.
class TrimEditorOverlay extends StatelessWidget {
  const TrimEditorOverlay({super.key, required this.trimController});

  final LiveRunTrimController trimController;

  String _fmt(int? ms) => ms == null
      ? '—'
      : DateFormat(
          'h:mm:ss a',
        ).format(DateTime.fromMillisecondsSinceEpoch(ms).toLocal());

  @override
  Widget build(BuildContext context) {
    if (!trimController.isAdmin) return const SizedBox.shrink();
    return Obx(() {
      final editing = trimController.editing.value;
      final busy = trimController.busy.value;
      if (!editing) {
        return Material(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          child: IconButton(
            tooltip: 'Set official start/end',
            icon: Icon(Icons.content_cut, color: hc_blue),
            onPressed: () => trimController.toggleEditing(),
          ),
        );
      }
      return Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.content_cut, color: hc_blue, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Official window', style: ts_tileText),
                ),
                GestureDetector(
                  onTap: busy ? null : () => trimController.toggleEditing(),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Start: ${_fmt(trimController.officialStartMs)}\n'
              'End:   ${_fmt(trimController.officialEndMs)}',
              style: ts_footnoteBlack,
            ),
            const SizedBox(height: 4),
            Text(
              'Scrub the timeline, then set a boundary at that moment.',
              style: ts_footnoteBlack.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => trimController.setStart(),
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => trimController.setEnd(),
                    child: const Text('End'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: busy ? null : () => trimController.clear(),
              child: const Text('Clear window'),
            ),
          ],
        ),
      );
    });
  }
}
