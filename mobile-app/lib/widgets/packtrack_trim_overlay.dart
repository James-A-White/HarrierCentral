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

  /// Event-level "tracking ended" flag (EndEventTracking). null = not yet
  /// fetched; the button shows once the status is known.
  final RxnBool trackingEnded = RxnBool();

  @override
  void onInit() {
    super.onInit();
    unawaited(_refreshTrackingEnded());
  }

  Future<void> _refreshTrackingEnded() async {
    final api = EndEventTrackingApi();
    try {
      final status = await api.setEnded(eventId: _eventId, ended: null);
      trackingEnded.value = status.ended;
    } catch (_) {
      // Status is cosmetic (button label) — stay unknown when offline.
    } finally {
      api.dispose();
    }
  }

  /// Ends (or re-opens) tracking for EVERYONE on this run. While the flag is
  /// set, every phone still uploading points stops its tracking loop within
  /// one flush interval — the delivery rides the StorePositions responses, so
  /// no push is involved and it reaches exactly the phones still transmitting
  /// (docs/packtrack_auto_stop_plan.md). A runner who deliberately restarts
  /// tracking afterwards is left alone (client-side staleness guard).
  Future<void> toggleEveryonesTracking() async {
    final bool ending = trackingEnded.value != true;
    if (ending) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Stop everyone's tracking?", style: ts_alertDialogTitle),
          content: Text(
            'Every phone still sending points for this run will stop '
            'tracking within a minute or so. Anyone still out on trail can '
            'simply start tracking again — they will not be stopped twice.',
            style: ts_alertDialogBody,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(result: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Cancel', style: ts_button, textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_red,
                foregroundColor: Colors.white,
              ),
              child: Text('Stop tracking', style: ts_button, textAlign: TextAlign.center),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      if (confirmed != true) return;
    }
    busy.value = true;
    final api = EndEventTrackingApi();
    try {
      final status = await api.setEnded(eventId: _eventId, ended: ending);
      trackingEnded.value = status.ended;
      _snack(
        ending
            ? "Tracking ended for everyone — phones still sending will stop "
                  'within a minute.'
            : 'Tracking re-opened.',
      );
    } catch (e) {
      _snack('Could not update tracking — try again when online.');
    } finally {
      api.dispose();
      busy.value = false;
    }
  }

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
      final bool sent = await LocationService.ensure().markBoundaryAt(
        boundaryType: type,
        timestampMs: ts.round(),
        overrideEventId: _eventId,
        overrideUserId: _userId,
        lat: run.extensions.evtLat ?? 0.0,
        lng: run.extensions.evtLon ?? 0.0,
      );
      if (!sent) {
        // The buffer is one-shot here, so a refused send means the boundary was
        // never set. Saying otherwise is what made this look like a display bug.
        _snack('Could not reach the server — the boundary was not set.');
        return;
      }

      // Show it NOW. The point is stored, so this is the truth; waiting for it
      // to come back round the loop is what made the panel look broken.
      //
      // GetPositions caches the official window per event for five minutes.
      // The API now drops that entry when a boundary is written, but the cache
      // is per Function INSTANCE, so a poll answered by a different instance
      // can still serve a stale window for a while. Setting the value locally
      // makes the UI correct regardless, and the next successful load either
      // confirms it or corrects it (James, 2026-09-13).
      final int tsMs = ts.round();
      if (type == HashRunPointTypes.adminStart) {
        map.officialStartMs.value = tsMs;
      } else {
        map.officialEndMs.value = tsMs;
      }

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
      // Clear the panel NOW, for the same reason the setters do: the points
      // are deleted, so this is the truth, and waiting for a poll to agree is
      // what made the button look inert.
      map.officialStartMs.value = null;
      map.officialEndMs.value = null;

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
/// One style for every button in this overlay.
///
/// The app theme gives ElevatedButton a red background, radius 10 and no text
/// size, and gives TextButton a red background with NO shape at all. So a panel
/// mixing the two rendered two different corner radii and two different font
/// sizes side by side, which is exactly what it looked like. Setting both
/// explicitly here — and using ts_button, the app's canonical button text —
/// makes these match every other button in the app.
///
/// foregroundColor is white and is NOT overridden per button. Red text on a red
/// button is invisible, which is how "Stop everyone's tracking" shipped as a
/// blank red bar (James, 2026-09-13). CLAUDE.md flags this as a recurring
/// mistake; the fix is one shared style rather than a colour per call site.
/// Exposed for the widget test that guards the red-on-red regression.
@visibleForTesting
ButtonStyle trimButtonStyleForTest() => _trimButtonStyle();

ButtonStyle _trimButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: hc_red,
  foregroundColor: Colors.white,
  disabledBackgroundColor: hc_red.withValues(alpha: 0.45),
  disabledForegroundColor: Colors.white70,
  // Height only. A minimum WIDTH would force the Wrap group to full width.
  minimumSize: const Size(0, 44),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: ts_button,
  elevation: 0,
  shadowColor: Colors.transparent,
);

class TrimEditorOverlay extends StatelessWidget {
  const TrimEditorOverlay({
    super.key,
    required this.trimController,
    this.showCollapsedPill = true,
  });

  final PackTrackTrimController trimController;

  /// Spread-out full-width bottom-bar layout for the fullscreen map (which has
  /// room). Compact scissors-card layout otherwise.

  /// Whether the collapsed "Trim run" pill is drawn. Both the run Map tab and
  /// the fullscreen route set false, because each puts a scissors button in
  /// its own control column — the bar still appears here once editing starts.
  final bool showCollapsedPill;

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
        // The caller may already offer a scissors of its own (the run Map tab
        // and the fullscreen route both put one in their control column), in
        // which case the collapsed card here is a second one on the same map.
        if (!showCollapsedPill) return const SizedBox.shrink();
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
                Expanded(child: Text('Official window', style: ts_tileText)),
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
                    style: _trimButtonStyle(),
                    onPressed: busy ? null : () => trimController.setStart(),
                    child: const Text('Start', textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    style: _trimButtonStyle(),
                    onPressed: busy ? null : () => trimController.setEnd(),
                    child: const Text('End', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _trimButtonStyle(),
                onPressed: busy ? null : () => trimController.clear(),
                child: const Text('Clear window', textAlign: TextAlign.center),
              ),
            ),
            if (trimController.trackingEnded.value != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: _trimButtonStyle(),
                  onPressed: busy
                      ? null
                      : () =>
                            unawaited(trimController.toggleEveryonesTracking()),
                  // Shortened from "Stop everyone's tracking", which no longer
                  // fits on one line at the standard button size. It matches
                  // the confirmation dialog, which already says "Stop tracking".
                  child: Text(
                    trimController.trackingEnded.value == true
                        ? 'Re-open tracking'
                        : 'Stop tracking',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Fullscreen layout: a "Trim run" pill that expands to a full-width bar
  /// spreading the controls across the bottom. Tapping the pill also enters
  /// edit mode (the map shows the full untrimmed track while trimming).
}
