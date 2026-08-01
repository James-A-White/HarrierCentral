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

  /// The shared PackTrack map controller, if the map has been built. The rose
  /// flag lives there (it's the map's alternate canvas); this page only hosts
  /// it, so reach it by the same tag RunTrackerMap registers under.
  RunTrackerMapController? get _mapCtrl =>
      Get.isRegistered<RunTrackerMapController>(tag: run.event.eventId)
      ? Get.find<RunTrackerMapController>(tag: run.event.eventId)
      : null;

  /// True while the radar canvas is showing. Reading `.value` inside the page's
  /// Obx registers the dependency, so the overlay rebuilds when it flips.
  bool get roseActive => _mapCtrl?.roseView.value ?? false;

  /// Back out of the radar to the map rather than out of the whole run.
  void exitRose() => _mapCtrl?.roseView.value = false;
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

        // Radar is a canvas swap, not a route, so the system back button would
        // otherwise pop the whole live run — the most likely way someone tries
        // to leave the radar. Intercept it and return to the map instead.
        return PopScope(
          canPop: !controller.roseActive,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.exitRose();
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
              // heading-up), so it stays on both.
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
              // Hidden in radar view: "full screen" opens a full-screen MAP,
              // which from the radar reads as a second, wrong way out.
              if (!controller.roseActive)
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
