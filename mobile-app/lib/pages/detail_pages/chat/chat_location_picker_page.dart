import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// "Drop a pin" for a chat location (E9.F1.S12, 2026-09-29).
///
/// The map moves under a fixed pin in the middle; whatever is under the pin
/// when the hasher taps Send is the location. Pops with a [ChatLocation], or
/// null when they back out.
///
/// Its own small page rather than the run editor's EditorMap: that widget is
/// built around a run's event and kennel markers and moves a marker on tap,
/// where this wants the camera centre and nothing else.
class ChatLocationPickerPage extends StatelessWidget {
  const ChatLocationPickerPage({super.key});

  static const double _pinSize = 48;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatLocationPickerController>(
      init: ChatLocationPickerController(),
      global: false,
      dispose: (state) => state.controller?.onDelete(),
      builder: (ChatLocationPickerController c) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          foregroundColor: Colors.white,
          title: Text('Drop a pin', style: ts_appBarTitle),
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      FlutterMap(
                        mapController: c.mapController,
                        options: MapOptions(
                          initialCenter: c.initialCentre,
                          initialZoom: c.initialZoom,
                          minZoom: 2,
                          maxZoom: 19,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag |
                                InteractiveFlag.doubleTapZoom,
                          ),
                          onPositionChanged:
                              (MapCamera camera, bool hasGesture) =>
                                  c.centre.value = camera.center,
                        ),
                        children: <Widget>[
                          TileLayer(
                            urlTemplate:
                                'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                            subdomains: const <String>[
                              'mt0',
                              'mt1',
                              'mt2',
                              'mt3',
                            ],
                          ),
                        ],
                      ),
                      // The pin's TIP marks the spot, so the icon sits one
                      // height above the centre line.
                      IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: _pinSize),
                            child: Icon(
                              Icons.location_on,
                              size: _pinSize,
                              color: hc_red,
                              shadows: const <Shadow>[
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Obx(
                        () => Text(
                          ChatLocation(
                            c.centre.value.latitude,
                            c.centre.value.longitude,
                          ).display,
                          style: ts_body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hc_red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: c.send,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: Text(
                          'Send this location',
                          style: ts_button,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatLocationPickerController extends GetxController {
  ChatLocationPickerController() {
    // Start where the phone last was, if the location stream has a fix; it
    // is read, never started — the stream is the app's ONE geolocator
    // subscription (memory: lost-compass-local-track). No fix: the world.
    Position? last;
    try {
      last = LocationService.ensure().lastKnownPosition.value;
    } catch (_) {}
    if (last != null && (last.latitude != 0 || last.longitude != 0)) {
      initialCentre = latlng.LatLng(last.latitude, last.longitude);
      initialZoom = 16;
    } else {
      initialCentre = const latlng.LatLng(20, 0);
      initialZoom = 2;
    }
    centre = initialCentre.obs;
  }

  final MapController mapController = MapController();
  late final latlng.LatLng initialCentre;
  late final double initialZoom;
  late final Rx<latlng.LatLng> centre;

  void send() {
    final latlng.LatLng p = centre.value;
    // Wrap the longitude: a map dragged round the world reports values past
    // ±180, which the server (rightly) refuses.
    final double lng = ((p.longitude + 180) % 360 + 360) % 360 - 180;
    hcPop<ChatLocation>(result: ChatLocation(p.latitude, lng));
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}
