import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

enum RunLocationsViewMode { all, past, recent, myRuns }

class RunAndKennelMapPage extends StatelessWidget {
  const RunAndKennelMapPage({super.key, this.kennel});

  final KennelsModel? kennel;

  String get _tag => kennel?.kennelId ?? 'global';

  RunAndKennelMapController get controller =>
      Get.find<RunAndKennelMapController>(tag: _tag);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RunAndKennelMapController(kennel: kennel), tag: _tag);

    return AppScaffold(
      floatingActionButton: kennel == null ? _MapFab(controller: ctrl) : null,
      body: kennel == null
          ? _RunLocationsBody(controller: ctrl)
          : AppScaffold(
              floatingActionButton: _MapFab(controller: ctrl),
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
                title: Text('Explore Runs', style: ts_appBarTitle),
              ),
              body: _RunLocationsBody(controller: ctrl),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Speed-dial FAB — extracted so main_navigation_page can also use it
// ---------------------------------------------------------------------------
class _MapFab extends StatelessWidget {
  const _MapFab({required this.controller});

  final RunAndKennelMapController controller;

  @override
  Widget build(BuildContext context) {
    return ConnectedWidget(
      child: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag-7753253',
        backgroundColor: hc_red,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: const Icon(Ionicons.ios_globe),
            backgroundColor: Colors.green[700],
            label: 'Show all runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.selectViewModeAll()),
          ),
          SpeedDialChild(
            child: const Icon(Entypo.time_slot),
            backgroundColor: hc_blue,
            label: 'Show recent+future runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.selectViewModeRecent()),
          ),
          SpeedDialChild(
            child: const Icon(Entypo.ccw),
            backgroundColor: hc_blue,
            label: 'Show all past runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.selectViewModePast()),
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.run, color: Colors.black),
            backgroundColor: Colors.orange[400],
            label: 'Show my runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.selectViewModeMyRuns()),
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.target),
            backgroundColor: Colors.purple[700],
            label: 'Change map center',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.toggleMapCenter()),
          ),
          SpeedDialChild(
            child: const Icon(
              MaterialCommunityIcons.map_search_outline,
              color: Colors.white,
            ),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide search bar',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.toggleSearchBar()),
          ),
          SpeedDialChild(
            child: const Icon(FontAwesome.home, color: Colors.white),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide kennels',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => unawaited(controller.toggleShowKennels()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final RunAndKennelMapController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      onChanged: controller.onSearchTextChanged,
                      focusNode: controller.searchFocusNode,
                      controller: controller.searchController,
                      keyboardType: TextInputType.text,
                      style: ts_titleMediumBlack,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(
                          FontAwesome.search,
                          color: Colors.black,
                        ),
                        hintText: 'Search...',
                        hintStyle: ts_searchLabel,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        textStyle: TextStyle(color: Colors.grey.shade700),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: controller.clearSearch,
                      child: Text(
                        'X',
                        style: ts_headingBlack.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------
class _RunLocationsBody extends StatelessWidget {
  const _RunLocationsBody({required this.controller});

  final RunAndKennelMapController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Obx(() {
          return controller.showFilters.value
              ? _SearchBar(controller: controller)
              : const SizedBox(height: 0.0);
        }),
        Expanded(
          child: ConnectedWidget(
            refreshFunction: () {},
            showConnectButton: true,
            showHcBackground: true,
            padding: const EdgeInsets.only(bottom: 120),
            disconnectedChild: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Map functions require a connection to the Internet',
                  style: ts_headingLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            child: Stack(
              children: <Widget>[
                Obx(() {
                  // Reading markersVersion, showKennels, trueNorthLock forces
                  // rebuild when markers change or interaction flags change.
                  final _ = controller.markersVersion.value;
                  final showKennels = controller.showKennels.value;
                  final trueNorthLock = controller.trueNorthLock.value;

                  return FlutterMap(
                    mapController: controller.mapController,
                    options: MapOptions(
                      onMapEvent: (MapEvent mapEvent) {
                        if (mapEvent is MapEventMoveEnd) {
                          controller.onMapMoveEnd(
                            controller.mapController.camera.visibleBounds,
                          );
                        }
                      },
                      interactionOptions: InteractionOptions(
                        flags: trueNorthLock
                            ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                            : InteractiveFlag.pinchZoom |
                                  InteractiveFlag.drag |
                                  InteractiveFlag.rotate,
                      ),
                      initialCenter: controller.initialMapCenter,
                      initialZoom: 10.0,
                      minZoom: 1.0,
                      maxZoom: 18.0,
                    ),
                    children: <Widget>[
                      TileLayer(
                        urlTemplate:
                            'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
                      ),
                      MarkerLayer(
                        // Pins stay upright when the map is rotated.
                        rotate: true,
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
                          ],
                        ],
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 40,
                          size: const Size(40, 40),
                          spiderfyCircleRadius: 100,
                          markers: showKennels
                              ? controller.kennelMarkers
                              : <Marker>[],
                          polygonOptions: const PolygonOptions(
                            borderColor: Colors.blueAccent,
                            color: Colors.black12,
                            borderStrokeWidth: 3,
                          ),
                          builder: (BuildContext context, List<Marker> markers) {
                            RunAndKennelMapController.heroCounter++;
                            return FloatingActionButton(
                              backgroundColor: Colors.purple[600],
                              onPressed: null,
                              heroTag:
                                  'btn_${RunAndKennelMapController.heroCounter}',
                              child: AutoSizeText(
                                markers.length.toString(),
                                maxLines: 1,
                                style: ts_button,
                              ),
                            );
                          },
                        ),
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 40,
                          size: const Size(30, 30),
                          markers: controller.runLocationMarkers,
                          polygonOptions: const PolygonOptions(
                            borderColor: Colors.blueAccent,
                            color: Colors.black12,
                            borderStrokeWidth: 3,
                          ),
                          builder: (BuildContext context, List<Marker> markers) {
                            RunAndKennelMapController.heroCounter++;
                            return FloatingActionButton(
                              backgroundColor: hc_blue,
                              onPressed: null,
                              heroTag:
                                  'btn_${RunAndKennelMapController.heroCounter}',
                              child: AutoSizeText(
                                markers.length.toString(),
                                maxLines: 1,
                                style: ts_button,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
                // Center-on-location button
                if ((appModel.hasLocationPermissions) &&
                    (deviceInfo.deviceLat != null) &&
                    (deviceInfo.deviceLon != null)) ...<Widget>[
                  Positioned(
                    left: 10.0,
                    top: 74.0,
                    child: GestureDetector(
                      onTap: controller.centerOnCurrentDevice,
                      child: SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: Image.asset(
                          'images/other/set_map_to_current_location.png',
                        ),
                      ),
                    ),
                  ),
                ],
                // True-north lock button
                Positioned(
                  left: 70.0,
                  top: 74.0,
                  child: Obx(() {
                    return GestureDetector(
                      onTap: controller.toggleTrueNorthLock,
                      child: SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: Image.asset(
                          controller.trueNorthLock.value
                              ? 'images/other/set_map_to_true_north_lock.png'
                              : 'images/other/set_map_rotation_enabled.png',
                        ),
                      ),
                    );
                  }),
                ),
                // Show List button
                Positioned(
                  right: -2.0,
                  top: 74.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0),
                    width: 135,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                      ),
                      onPressed: () async {
                        final runsListController =
                            Get.find<FutureRunListPageController>();
                        await runsListController.openList();
                      },
                      child: Text(
                        'Show List',
                        textAlign: TextAlign.center,
                        style: ts_button,
                      ),
                    ),
                  ),
                ),
                // Status label
                Positioned(
                  left: 10.0,
                  right: 10.0,
                  top: 25.0,
                  child: Obx(() {
                    return Container(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        controller.textDescription.value,
                        textAlign: TextAlign.center,
                        style: ts_headingBlack,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
