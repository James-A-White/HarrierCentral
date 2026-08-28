import 'package:harrier_central/imports.dart';
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
  const PackTrackFullScreenMap({super.key, required this.run, this.focusPoint});

  final RunDetailsAggregate run;

  /// When provided (e.g. opened from a run photo), the map opens centered and
  /// zoomed on this coordinate instead of the run's default center.
  final latlng.LatLng? focusPoint;

  Widget _overlayButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
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
                overlayBottomPadding: isAdmin ? 96.0 : 50.0,
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
          // Overlay controls run down the LEFT edge. RunTrackerMap owns the
          // right-hand column — its locate/north-lock button sits at top 66,
          // which is where a top-right button on this route lands once the
          // status bar inset is added, so share used to cover it completely.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _overlayButton(
                  tooltip: 'Close',
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 10),
                // Interactive-map / Trail TV chooser, then the OS share
                // sheet — so spectators can watch in a browser without the
                // app. Same flow as Run Tools and the run-detail map.
                _overlayButton(
                  tooltip: 'Share this run',
                  icon: Icons.ios_share,
                  onPressed: () =>
                      unawaited(RunShareLinks(run).showShareSheet(context)),
                ),
              ],
            ),
          ),
          // Admin trim bar, spread across the bottom (renders nothing for
          // non-admins). Sits below the lifted playback panel.
          if (canRender)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 10,
              child: TrimEditorOverlay(
                trimController: trimController,
                wide: true,
              ),
            ),
        ],
      ),
    );
  }
}
