import 'package:harrier_central/imports.dart';
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

  /// The shared PackTrack map controller, if the map has been built. The
  /// canvas mode lives there (rose and list are the map's alternate
  /// canvases); this page only hosts it, so reach it by the same tag
  /// RunTrackerMap registers under.
  RunTrackerMapController? get _mapCtrl =>
      Get.isRegistered<RunTrackerMapController>(tag: run.event.eventId)
      ? Get.find<RunTrackerMapController>(tag: run.event.eventId)
      : null;

  /// True while an alternate canvas (radar or list) is showing. Reading
  /// `.value` inside the page's Obx registers the dependency, so the overlay
  /// rebuilds when it flips.
  bool get altCanvasActive =>
      (_mapCtrl?.canvasView.value ?? PackTrackCanvas.map) !=
      PackTrackCanvas.map;

  /// Back out of the radar/list to the map rather than out of the whole run.
  void exitToMap() => _mapCtrl?.canvasView.value = PackTrackCanvas.map;

  /// True while the list canvas is showing — it has no orientation, so the
  /// north-lock control is hidden there (it stays for map AND radar).
  bool get listActive => _mapCtrl?.canvasView.value == PackTrackCanvas.list;
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

        // Radar and list are canvas swaps, not routes, so the system back
        // button would otherwise pop the whole live run — the most likely way
        // someone tries to leave them. Intercept it and return to the map.
        return PopScope(
          canPop: !controller.altCanvasActive,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.exitToMap();
          },
          child: Stack(
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
              // North-lock still applies in radar view (it decides north-up vs
              // heading-up), so it stays on both — but not on the list, which
              // has no orientation to lock.
              if (!controller.listActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: MapOverlayButton(
                    icon: controller.trueNorthLock.value
                        ? Icons.explore_off
                        : Icons.explore,
                    tooltip: controller.trueNorthLock.value
                        ? 'Unlock rotation'
                        : 'Lock to North',
                    onTap: () {
                      controller.trueNorthLock.value =
                          !controller.trueNorthLock.value;
                    },
                  ),
                ),
              // Open the map full-screen.
              // Hidden in radar/list view: "full screen" opens a full-screen
              // MAP, which from those reads as a second, wrong way out.
              if (!controller.altCanvasActive)
                Positioned(
                  top: 12,
                  left: 12,
                  child: MapOverlayButton(
                    icon: Icons.fullscreen,
                    tooltip: 'Full screen',
                    onTap: () =>
                        Get.to<void>(() => PackTrackFullScreenMap(run: run)),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// PackTrackTrimController + TrimEditorOverlay moved to
// widgets/packtrack_trim_overlay.dart so the run-detail replay map can reuse
// them (a run is trimmed AFTER it finishes, once its live window has closed).
