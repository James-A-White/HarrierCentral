import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/export/gpx_export_service.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// Full-screen PackTrack map for a run, opened from the run's map view. Fills
/// the whole screen with an overlaid close button (top-left).
///
/// Uses its OWN [RunTrackerMapController] (a distinct `-fullscreen` tag) rather
/// than the embedded map's, because flutter_map can't bind one MapController to
/// two live maps at once — the embedded map stays mounted underneath this route.
/// The trade-off is a fresh view (re-fetch, playback at the live edge); trimming
/// stays on the embedded map.
class PackTrackFullScreenMap extends StatelessWidget {
  const PackTrackFullScreenMap({
    super.key,
    required this.run,
    this.focusPoint,
    this.initialCanvas = PackTrackCanvas.map,
  });

  final RunDetailsAggregate run;

  /// The canvas the embedded map was showing when "Full screen" was tapped.
  /// Opening on it means the button enlarges what you were looking at instead
  /// of dropping you back on the map.
  final PackTrackCanvas initialCanvas;

  /// When provided (e.g. opened from a run photo), the map opens centered and
  /// zoomed on this coordinate instead of the run's default center.
  final latlng.LatLng? focusPoint;

  /// EVERY control on this route lives in this one left-hand column, one
  /// style and one size — MapOverlayButton, the same control the run-detail
  /// and live-run maps use, so the three maps cannot drift apart again.
  ///
  /// Built per canvas: locate moves the map camera, which the radar and the
  /// list do not have. Close, share, GPX and trim are about the route or the
  /// run rather than the rendering, so they stay on all three.
  Widget _controls(
    BuildContext context,
    PackTrackCanvas canvas,
    String mapTag,
    PackTrackTrimController trimController,
    bool isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MapOverlayButton(
          tooltip: 'Close',
          icon: Icons.close,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 10),
        // Interactive-map / Trail TV chooser, then the OS share sheet — so
        // spectators can watch in a browser without the app. Same flow as
        // Run Tools and the run-detail map.
        MapOverlayButton(
          tooltip: 'Share this run',
          icon: Icons.ios_share,
          onTap: () => unawaited(RunShareLinks(run).showShareSheet(context)),
        ),
        if (canvas == PackTrackCanvas.map) ...<Widget>[
          const SizedBox(height: 10),
          MapOverlayButton(
            tooltip: 'My location',
            icon: Icons.near_me,
            onTap: () {
              if (Get.isRegistered<RunTrackerMapController>(tag: mapTag)) {
                Get.find<RunTrackerMapController>(tag: mapTag).recenterOnUser();
              }
            },
          ),
        ],
        // Hidden before the run opens: there is nothing to export from a run
        // that has not happened.
        if (trackingHasOpened(run.event.eventStartDatetimeGmt)) ...<Widget>[
          const SizedBox(height: 10),
          MapOverlayButton(
            tooltip: 'Export GPX',
            label: 'GPX',
            onTap: () => unawaited(_exportGpx(context, mapTag)),
          ),
        ],
        if (isAdmin) ...<Widget>[
          const SizedBox(height: 10),
          MapOverlayButton(
            tooltip: 'Trim run',
            icon: Icons.content_cut,
            onTap: trimController.toggleEditing,
          ),
        ],
      ],
    );
  }

  /// Exports the signed-in runner's own track. Looked up lazily at tap time:
  /// the map controller is created by RunTrackerMap below, so it does not
  /// exist yet while this widget is building.
  Future<void> _exportGpx(BuildContext context, String mapTag) async {
    if (!Get.isRegistered<RunTrackerMapController>(tag: mapTag)) return;
    final controller = Get.find<RunTrackerMapController>(tag: mapTag);
    final String? userId = getStringPref(StringPrefsEnum.userId);
    UserTrack? mine;
    if (userId != null && userId.isNotEmpty) {
      for (final UserTrack t in controller.userPositions) {
        if (t.id == userId && t.positions.isNotEmpty) mine = t;
      }
    }
    if (mine == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No track data available yet.')),
      );
      return;
    }
    try {
      await GpxExportService().exportTrack(
        context: context,
        track: mine,
        trackName: run.event.eventName,
      );
    } catch (error, st) {
      BootLogger.logError(
        '[PackTrackFullScreenMap._exportGpx] eventId=${run.event.eventId}',
        error,
        st,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final coords = Utilities.getLatLongFromString(<String>[
      run.event.locationOneLineDesc ?? '',
      run.event.eventDescription ?? '',
      run.event.eventName,
    ]);
    final double? evtLat = run.extensions.evtLat ?? coords[0];
    final double? evtLon = run.extensions.evtLon ?? coords[1];
    final latlng.LatLng? eventLoc = (evtLat == null || evtLon == null)
        ? null
        : latlng.LatLng(evtLat, evtLon);
    final latlng.LatLng? kennelLoc =
        (run.kennel.kennelLatitude == null ||
            run.kennel.kennelLongitude == null)
        ? null
        : latlng.LatLng(
            run.kennel.kennelLatitude!,
            run.kennel.kennelLongitude!,
          );
    // A photo focus point takes priority as the map center. When we only have a
    // focus point (no kennel/event location), fall back to it for the map's
    // required kennel-location arg so the map still renders.
    final latlng.LatLng? center = focusPoint ?? eventLoc ?? kennelLoc;
    final latlng.LatLng? kennelForMap = kennelLoc ?? focusPoint;
    final bool canRender = center != null && kennelForMap != null;
    // A photo focus opens zoomed in almost fully (map max is 22) so the photo's
    // marker — always at map centre — is easy to pick out even when several
    // photos were taken close together.
    final double initialZoom = focusPoint != null ? 20.0 : 14.0;

    // Own controller tag so this map doesn't fight the embedded map's MapController.
    final mapTag = '${run.event.eventId}-fullscreen';

    // Admin trim editor, targeting THIS fullscreen map's controller. Trimming
    // lives only here (the fullscreen view has room to spread the controls out).
    final trimTag = 'trim-$mapTag';
    final trimController =
        Get.isRegistered<PackTrackTrimController>(tag: trimTag)
        ? Get.find<PackTrackTrimController>(tag: trimTag)
        : Get.put(
            PackTrackTrimController(run: run, mapControllerTag: mapTag),
            tag: trimTag,
          );
    final bool isAdmin = trimController.isAdmin;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (canRender)
            Positioned.fill(
              child: RunTrackerMap(
                run.event,
                eventLoc,
                center,
                kennelForMap,
                1.0,
                22.0,
                initialZoom,
                true, // north-up by default in fullscreen
                controllerTag: mapTag,
                // Lift the playback panel above the trim bar for admins.
                // The playback panel sits at the bottom now that nothing
                // else is down there — the trim bar lifts itself above it
                // while editing rather than the panel permanently reserving
                // room for a pill that is no longer drawn.
                overlayBottomPadding: 12.0,
                showLocateButton: false,
                initialCanvas: initialCanvas,
                overlayControls: (BuildContext _, PackTrackCanvas canvas) =>
                    _controls(context, canvas, mapTag, trimController, isAdmin),
                // When focused on a photo location, don't let the load-time
                // auto-follow drag the camera to the run's end — stay on the
                // photo's coordinate.
                autoFollowOnLoad: focusPoint == null,
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Map not available for this run.',
                  style: ts_headingLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // The controls live inside RunTrackerMap (which is the only thing
          // that knows the canvas), so when the map cannot render there is
          // nothing on screen at all — including the way out.
          if (!canRender)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: MapOverlayButton(
                tooltip: 'Close',
                icon: Icons.close,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          // Admin trim bar (renders nothing for non-admins, and nothing at
          // all until editing starts — the scissors button in the column
          // above is the trigger now). Sits ABOVE the playback panel so the
          // panel can stay pinned to the bottom.
          if (canRender)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 132,
              child: TrimEditorOverlay(
                trimController: trimController,
                wide: true,
                showCollapsedPill: false,
              ),
            ),
        ],
      ),
    );
  }
}
