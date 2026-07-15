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
  const PackTrackFullScreenMap({super.key, required this.run});

  final RunDetailsAggregate run;

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
    final latlng.LatLng? center = eventLoc ?? kennelLoc;

    // Own controller tag so this map doesn't fight the embedded map's MapController.
    final mapTag = '${run.event.eventId}-fullscreen';

    // Admin trim editor, targeting THIS fullscreen map's controller. Trimming
    // lives only here (the fullscreen view has room to spread the controls out).
    final trimTag = 'trim-$mapTag';
    final trimController = Get.isRegistered<PackTrackTrimController>(tag: trimTag)
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
          if (center != null && kennelLoc != null)
            Positioned.fill(
              child: RunTrackerMap(
                run.event,
                eventLoc,
                center,
                kennelLoc,
                1.0,
                22.0,
                14.0,
                true, // north-up by default in fullscreen
                controllerTag: mapTag,
                // Lift the playback panel above the trim bar for admins.
                overlayBottomPadding: isAdmin ? 96.0 : 50.0,
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          // Admin trim bar, spread across the bottom (renders nothing for
          // non-admins). Sits below the lifted playback panel.
          if (center != null && kennelLoc != null)
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
