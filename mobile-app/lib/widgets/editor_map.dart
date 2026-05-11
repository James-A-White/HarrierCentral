import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

class EditorMap extends StatefulWidget {
  const EditorMap(
    this.eventLocation,
    this.mapCenter,
    this.kennelLocation,
    this.minZoom,
    this.maxZoom,
    this.zoom,
    this.trueNorthLock,
    Key key, {
    this.markerClicked,
    this.mapMoved,
  }) : super(key: key);

  final latlng.LatLng? eventLocation;
  final latlng.LatLng mapCenter;
  final latlng.LatLng kennelLocation;
  final double minZoom;
  final double maxZoom;
  final double zoom;
  final bool trueNorthLock;

  final Function? markerClicked;
  final Function? mapMoved;

  @override
  EditorMapState createState() => EditorMapState();
}

class EditorMapState extends State<EditorMap> {
  final MapController mapController = MapController();

  bool _oldTrueNorthLock = true;
  bool _mapControllerAvailable = false;

  @override
  void initState() {
    super.initState();
    _oldTrueNorthLock = widget.trueNorthLock;
    _mapControllerAvailable = false;
    // mapController.mapEventStream.listen((MapEvent event) {
    //   widget.mapMoved(event.center);
    // });
  }

  @override
  Widget build(BuildContext context) {
    // only move the map if the center has changed
    latlng.LatLng mapCenterPoint = widget.mapCenter;
    if ((mapCenterPoint.latitude == CLEAR_LATLONG) &&
        (mapCenterPoint.longitude == CLEAR_LATLONG)) {
      mapCenterPoint = widget.kennelLocation;
    }

    if (_mapControllerAvailable &&
        (mapController.camera.center != mapCenterPoint)) {
      mapController.move(mapCenterPoint, mapController.camera.zoom);
    }

    if (_mapControllerAvailable &&
        (_oldTrueNorthLock != widget.trueNorthLock)) {
      _oldTrueNorthLock = widget.trueNorthLock;
      if (widget.trueNorthLock) {
        mapController.rotate(0.0);
      }
    }

    _mapControllerAvailable = true;
    return FlutterMap(
      mapController: mapController,
      options: widget.trueNorthLock
          ? MapOptions(
              interactionOptions: InteractionOptions(
                flags: widget.trueNorthLock
                    ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                    : InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.rotate,
              ),
              initialCenter: mapCenterPoint,
              initialZoom: widget.zoom,
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
              initialRotation: 0.0,
            )
          : MapOptions(
              interactionOptions: InteractionOptions(
                flags: widget.trueNorthLock
                    ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                    : InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.rotate,
              ),
              initialCenter: mapCenterPoint,
              initialZoom: widget.zoom,
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
            ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          //subdomains: ['a', 'b', 'c']),
          subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
        ),
        MarkerLayer(
          markers: <Marker>[
            if ((appModel.hasLocationPermissions) &&
                (deviceInfo.deviceLat != null) &&
                (deviceInfo.deviceLon != null)) ...<Marker>[
              Marker(
                height: 50.0,
                width: 50.0,
                point: latlng.LatLng(
                  deviceInfo.deviceLat!,
                  deviceInfo.deviceLon!,
                ),
                child: GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.all(1.0),
                    height: 50.0,
                    width: 50.0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Image.asset(
                        'images/other/map_current_location.png',
                        height: 50.0,
                        width: 50.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.eventLocation != null) ...<Marker>[
              Marker(
                width: 120.0,
                height: 120.0,
                point: widget.eventLocation!,
                child: GestureDetector(
                  onTap: () {
                    if (widget.markerClicked != null) {
                      widget.markerClicked!();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 58.0),
                    child: Image.asset('images/icons/map_pin_foot.png'),
                    //child: FlutterLogo(colors: Colors.purple),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
