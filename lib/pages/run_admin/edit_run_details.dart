import 'package:harrier_central/imports.dart';
import 'package:latlong/latlong.dart';

class EditRunDetailsPage extends StatefulWidget {
  const EditRunDetailsPage(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _EditRunDetailsPageState createState() => _EditRunDetailsPageState();
}

class _EditRunDetailsPageState extends State<EditRunDetailsPage> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Edit run details',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Positioned(
            //     top: 30,
            //     left: 0,
            //     right: 0,
            //     child: Text(
            //       'QR Code Scanner',
            //       textAlign: TextAlign.center,
            //       style: const TextStyle(
            //           fontFamily: 'AvenirNextRegular',
            //           fontStyle: FontStyle.normal,
            //           color: Colors.white,
            //           fontSize: 24.0,
            //           height: 1.0),
            //     )),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                width: 340.0,
                height: 45.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: TabBar(
                    physics: const NeverScrollableScrollPhysics(),
                    labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Theme.of(context).buttonColor,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      indicatorRadius: 20.0,
                    ),
                    tabs: tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Positioned(
                top: 80,
                bottom: 0,
                child: Container(
                  key: tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[DetailsTab(), LocationTab(widget.eventAggregate, widget.getUpdatedEventAggregate), OtherInfoTab()],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    _tabController = TabController(vsync: this, length: tabs.length);
  }

  Color left = Colors.white;
  Color right = Colors.white;

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Description'));
      tabs.add(const Tab(text: 'Location'));
      tabs.add(const Tab(text: 'Date/Time'));
    }
  }

  // void _onSwitchToQrCode() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSwitchToQrScanner() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }
}

class DetailsTab extends StatefulWidget {
  const DetailsTab({Key key}) : super(key: key);

  @override
  _DetailsTabState createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(color: Colors.blue);
  }
}

class LocationTab extends StatefulWidget {
  const LocationTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _LocationTabState createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;
  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final MapController mapController = MapController();

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return runLocationsBody();
    // return Stack(children: <Widget>[
    //   Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
    //   Positioned(top: 0, left: 0, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, child: runLocationsBody()),
    //   OfflineModeRibbon(
    //     showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
    //     lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
    //     ribbonImage: 'images/icons/offline_mode.png',
    //   ),
    // ]);
  }

  Widget runLocationsBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              // Container(
              //   //decoration: Backgrounds.defaultHcBackground(),
              //   height: MediaQuery.of(context).size.height - 300,
              //   child:

              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(_updatedEventAggregate.event.narrowEventLatitude, _updatedEventAggregate.event.narrowEventLongitude),
                  zoom: 14.0,
                  minZoom: 1.0,
                  maxZoom: 18.0,
                  plugins: <MarkerClusterPlugin>[
                    MarkerClusterPlugin(),
                  ],
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
                      Marker(
                        width: 120.0,
                        height: 120.0,
                        point: LatLng(_updatedEventAggregate.event.narrowEventLatitude + .0, _updatedEventAggregate.event.narrowEventLongitude + .0),
                        builder: (BuildContext ctx) => GestureDetector(
                          //onTap: () => _launchMaps(widget.futureRun.event),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 58.0),
                            child: Image.asset('images/icons/map_pin_foot.png'),
                            //child: FlutterLogo(colors: Colors.purple),
                          ),
                        ),
                      ),
                    ],
                  )
                  // MarkerClusterLayerOptions(
                  //   maxClusterRadius: 60,
                  //   size: const Size(40, 40),
                  //   fitBoundsOptions: const FitBoundsOptions(
                  //     padding: EdgeInsets.all(50),
                  //   ),
                  //   markers: runLocationMarkers,
                  //   polygonOptions: const PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
                  //   builder: (BuildContext context, List<Marker> markers) {
                  //     heroCounter++;
                  //     return FloatingActionButton(
                  //       backgroundColor: Colors.blue[800],
                  //       child: Text(markers.length.toString()),
                  //       onPressed: null,
                  //       heroTag: 'btn_$heroCounter',
                  //     );
                  //   },
                  // ),

                  // MarkerClusterLayerOptions(
                  //   maxClusterRadius: 60,
                  //   size: const Size(50, 50),
                  //   fitBoundsOptions: const FitBoundsOptions(
                  //     padding: EdgeInsets.all(50),
                  //   ),
                  //   markers: showKennels == true ? kennelMarkers : <Marker>[],
                  //   polygonOptions: const PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
                  //   builder: (BuildContext context, List<Marker> markers) {
                  //     heroCounter++;
                  //     return FloatingActionButton(
                  //       backgroundColor: Colors.purple[600],
                  //       child: Text(markers.length.toString()),
                  //       onPressed: null,
                  //       heroTag: 'btn_$heroCounter',
                  //     );
                  //   },
                  // ),

                  // MarkerLayerOptions(
                  //   markers: <Marker>[for (MapMarker item in runLocations) mapMarker(item)],
                  // )
                ],
              ),

              IgnorePointer(
                ignoring: true,
                child: Image.asset('images/other/map_center_target.png', height: 300.0, width: 300.0),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                top: 10.0,
                child: Container(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  child: Text(_updatedEventAggregate.event.useFbLatLon == 1 ? 'Using Facebook Location' : 'Using Harrier Central Location',
                      textAlign: TextAlign.center, style: headingStyle20Black),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border.all(width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 35.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _isUpdating
                        ? Container(
                            height: 70.0,
                            width: 70.0,
                            child: HcCircularProgressIndicator(key: UniqueKey()),
                          )
                        : ElevatedButton(
                            child: Text('Set Location', style: buttonLabelStyleMedium),
                            onPressed: () {
                              setState(() {
                                _isUpdating = true;
                                final EventsService nSvc = EventsService();
                                nSvc
                                    .addEditEvent(
                                  eventId: widget.eventAggregate.event.eventId,
                                  lat: mapController.center.latitude,
                                  lon: mapController.center.longitude,
                                  useFbLatLon: 0,
                                )
                                    .then((void dummy) async {
                                  _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                });

                                //_showEventPopup(_calendarController.selectedDay);
                              });
                            },
                          ),
                    if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                      ElevatedButton(
                        child: Text('Use Facebook', style: buttonLabelStyleMedium),
                        onPressed: () {
                          setState(() {
                            _isUpdating = true;
                            final EventsService nSvc = EventsService();
                            nSvc
                                .addEditEvent(
                              eventId: widget.eventAggregate.event.eventId,
                              useFbLatLon: 1,
                            )
                                .then((void dummy) async {
                              _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                              setState(() {
                                _isUpdating = false;
                              });
                            });
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OtherInfoTab extends StatefulWidget {
  const OtherInfoTab({Key key}) : super(key: key);

  @override
  _OtherInfoTabState createState() => _OtherInfoTabState();
}

class _OtherInfoTabState extends State<OtherInfoTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(color: Colors.teal);
  }
}
