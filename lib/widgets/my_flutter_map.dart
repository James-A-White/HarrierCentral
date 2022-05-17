// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

class MyFlutterMap extends StatefulWidget {
  const MyFlutterMap(
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

  final latlng.LatLng eventLocation;
  final latlng.LatLng mapCenter;
  final latlng.LatLng kennelLocation;
  final num minZoom;
  final num maxZoom;
  final num zoom;
  final bool trueNorthLock;

  final Function markerClicked;
  final Function mapMoved;

  @override
  MyFlutterMapState createState() => MyFlutterMapState();
}

class MyFlutterMapState extends State<MyFlutterMap> {
  final MapController mapController = MapController();

  bool _oldTrueNorthLock = true;
  bool _mapControllerAvailable = false;

  @override
  void initState() {
    _oldTrueNorthLock = widget.trueNorthLock;
    _mapControllerAvailable = false;
    // mapController.mapEventStream.listen((MapEvent event) {
    //   widget.mapMoved(event.center);
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // only move the map if the center has changed
    latlng.LatLng mapCenterPoint = widget.mapCenter;
    if ((mapCenterPoint.latitude == CLEAR_LATLONG) && (mapCenterPoint.longitude == CLEAR_LATLONG)) {
      mapCenterPoint = widget.kennelLocation;
    }

    if (_mapControllerAvailable && (mapController.center != mapCenterPoint)) {
      mapController.move(mapCenterPoint, mapController.zoom);
    }

    if (_mapControllerAvailable && (_oldTrueNorthLock != widget.trueNorthLock)) {
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
              interactiveFlags: widget.trueNorthLock ? InteractiveFlag.pinchZoom | InteractiveFlag.drag : InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.rotate,
              center: mapCenterPoint,
              zoom: widget.zoom,
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
              rotation: 0.0,
            )
          : MapOptions(
              interactiveFlags: widget.trueNorthLock ? InteractiveFlag.pinchZoom | InteractiveFlag.drag : InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.rotate,
              center: mapCenterPoint,
              zoom: widget.zoom,
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
            ),
      layers: <LayerOptions>[
        TileLayerOptions(
            urlTemplate:
                //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
            //subdomains: ['a', 'b', 'c']),
            subdomains: <String>['mt0', 'mt1', 'mt2', 'mt3']),
        MarkerLayerOptions(
          markers: <Marker>[
            if (G0<AppModel>().hasLocationPermissions) ...<Marker>[
              Marker(
                height: 50.0,
                width: 50.0,
                point: latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon),
                builder: (BuildContext ctx) => GestureDetector(
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
                point: widget.eventLocation,
                builder: (BuildContext ctx) => GestureDetector(
                  onTap: () {
                    if (widget.markerClicked != null) {
                      widget.markerClicked();
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
        )
      ],
    );
  }
}
