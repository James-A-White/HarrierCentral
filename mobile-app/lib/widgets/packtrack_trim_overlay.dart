import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// Drives the admin PackTrack trim editor: sets the official start/end of a run
/// by dropping AST/AEN boundary markers at the map timeline's current scrub
/// position, and clears them. Reaches the run's [RunTrackerMapController] (keyed
/// by event id) for the scrub position, the current window, and to reload the
/// track after a change. Admin-gated on the run's `authCanManageRuns` flag.
///
/// Shared by the live-run map AND the run-detail replay map, so a run can be
/// trimmed after it finishes (its live-tracking window has closed by then).
class PackTrackTrimController extends GetxController {
  PackTrackTrimController({required this.run, this.mapControllerTag});

  final RunDetailsAggregate run;

  /// GetX tag of the [RunTrackerMapController] this editor drives. Defaults to
  /// the event id (the embedded map); the fullscreen map passes its own
  /// `-fullscreen` tag so the editor reads/reloads THAT map's controller.
  final String? mapControllerTag;

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

  String get _mapTag => mapControllerTag ?? _eventId;

  RunTrackerMapController? get _map =>
      Get.isRegistered<RunTrackerMapController>(tag: _mapTag)
      ? Get.find<RunTrackerMapController>(tag: _mapTag)
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
  const TrimEditorOverlay({
    super.key,
    required this.trimController,
    this.wide = false,
  });

  final PackTrackTrimController trimController;

  /// Spread-out full-width bottom-bar layout for the fullscreen map (which has
  /// room). Compact scissors-card layout otherwise.
  final bool wide;

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
      if (wide) return _buildWide(editing: editing, busy: busy);
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

  /// Fullscreen layout: a "Trim run" pill that expands to a full-width bar
  /// spreading the controls across the bottom. Tapping the pill also enters
  /// edit mode (the map shows the full untrimmed track while trimming).
  Widget _buildWide({required bool editing, required bool busy}) {
    if (!editing) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => trimController.toggleEditing(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.content_cut, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Trim run',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_cut, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Official window   ·   Start ${_fmt(trimController.officialStartMs)}   ·   End ${_fmt(trimController.officialEndMs)}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: busy ? null : () => trimController.setStart(),
            child: const Text('Set start'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: busy ? null : () => trimController.setEnd(),
            child: const Text('Set end'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: busy ? null : () => trimController.clear(),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Done',
            onPressed: busy ? null : () => trimController.toggleEditing(),
            icon: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
