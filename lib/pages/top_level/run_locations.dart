import 'package:harrier_central/imports.dart';

import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';

// class MapMarker extends Marker {
//   MapMarker({@required this.eventId, @required this.eventName, @required this.eventStartDatetime, num width, num height, LatLng point, WidgetBuilder builder}) : super(width: width, height: height, point: point, builder: builder);

//   String eventName;
//   String eventId;
//   DateTime eventStartDatetime;
// }

enum RunLocationsViewMode { all, past, recent, myRuns }

class RunLocationsPage extends StatefulWidget {
  const RunLocationsPage({Key key, this.kennel}) : super(key: key);

  final KennelsModel kennel;

  @override
  RunLocationsPageState createState() => RunLocationsPageState();
}

class RunLocationsPageState extends State<RunLocationsPage> {
  List<Marker> runLocationMarkers = <Marker>[];
  List<Marker> kennelMarkers = <Marker>[];

  RunLocationsViewMode viewMode = RunLocationsViewMode.recent;

  int mapCenterOption;

  num homeKennelLat;
  num homeKennelLon;

  final MapController mapController = MapController();

  String textDescription = 'Showing recent runs';

  List<RunDetailsAggregate> allRuns;
  List<RunDetailsAggregate> filteredRuns;

  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();
  String searchText;
  bool searchAllRuns = false;
  ScrollController scrollController = ScrollController(initialScrollOffset: 100.0);
  bool showFilters = false;
  bool showKennels = true;

  @override
  void initState() {
    homeKennelLat = getNumPref(NumPrefsEnum.homeKennelLat);
    homeKennelLon = getNumPref(NumPrefsEnum.homeKennelLon);
    showFilters = (getIntPref(IntPrefsEnum.mapShowSearchBar) ?? 0) == 0 ? false : true;
    showKennels = (getIntPref(IntPrefsEnum.mapShowKennels) ?? 1) == 0 ? false : true;

    mapCenterOption = getIntPref(IntPrefsEnum.mapCenterOption);
    if (mapCenterOption == null) {
      mapCenterOption = centerOnCurrentLocation.value;
      setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption);
    }

    loadEvents();
    loadKennels().then((void dummy) {
      setState(() {});
    });

    super.initState();
  }

  Widget searchBar() {
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
                      onChanged: (String text) {
                        setState(() {
                          searchText = text;
                          filterRuns();
                        });
                      },
                      focusNode: searchFocusNode,
                      controller: searchController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          FontAwesome.search,
                          color: Colors.black,
                        ),
                        hintText: 'Search...',
                        hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
                      child: const Text('X'),
                      onPressed: () {
                        searchController.text = '';
                        searchText = '';
                        setState(() {
                          filterRuns();
                        });
                      },
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

  void filterRuns() {
    filteredRuns = QueryRuns.doFilter(searchText, allRuns);
    buildRunMarkers();
    setState(() {});
  }

  Widget getFab() {
    return SpeedDial(
        marginEnd: 18,
        marginBottom: 10,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child:const  Icon(Icons.add),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () {
          // ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // searchFocusNode.unfocus();
        },
        //onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).accentColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: const Icon(Ionicons.ios_globe),
            backgroundColor: Colors.green[700],
            label: 'Show all runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing all runs';
              viewMode = RunLocationsViewMode.all;
              loadEvents().then((void dummy) {
                setState(() {});
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Entypo.time_slot),
            backgroundColor: Colors.blue[900],
            label: 'Show recent+future runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing runs in last 90 days';
              viewMode = RunLocationsViewMode.recent;
              loadEvents().then((void dummy) {
                setState(() {});
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Entypo.ccw),
            backgroundColor: Colors.blue[900],
            label: 'Show all past runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing all past runs';
              viewMode = RunLocationsViewMode.past;
              loadEvents().then((void dummy) {
                setState(() {});
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.run, color: Colors.black),
            backgroundColor: Colors.orange[400],
            label: 'Show my runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing runs you\'ve been at';
              viewMode = RunLocationsViewMode.myRuns;
              loadEvents().then((void dummy) {
                setState(() {});
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.target),
            backgroundColor: Colors.purple[700],
            label: 'Change map center',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              if (mapCenterOption == centerOnCurrentLocation.value) {
                mapCenterOption = centerOnHomeKennel.value;
                setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption);
                mapController.move(
                    ((homeKennelLat != null) && (homeKennelLon != null))
                        ? LatLng(IveCoreUtilities.unInt(homeKennelLat), IveCoreUtilities.unInt(homeKennelLon))
                        : LatLng(IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat), IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon)),
                    mapController.zoom);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    'Map will center on home kennel\r\n\r\n',
                    style: smallTitleStyle,
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.blue[700],
                  elevation: 200.0,
                ));
              } else {
                mapCenterOption = centerOnCurrentLocation.value;
                setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption);
                mapController.move(LatLng(IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat), IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon)), mapController.zoom);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    'Map will center on current location\r\n\r\n',
                    style: smallTitleStyle,
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.blue[700],
                  elevation: 200.0,
                ));
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.map_search_outline, color: Colors.white),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide search bar',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              showFilters = !showFilters;
              if (!showFilters) {
                searchController.text = '';
                searchText = '';
              }
              setIntPref(IntPrefsEnum.mapShowSearchBar, showFilters == false ? 0 : 1);
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(FontAwesome.home, color: Colors.white),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide kennels',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              showKennels = !showKennels;
              setIntPref(IntPrefsEnum.mapShowKennels, showKennels == false ? 0 : 1);
              setState(() {});
            },
          ),
        ]);
  }

  Future<RunDetailsAggregate> getSingleRun(String eventId) async {
    final Geolocator locator = Geolocator();
    RunDetailsAggregate item;

    final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(EnumRunQueryType.singleRun, EnumRunQueryContext.kennelAdmin, eventId: eventId);
    if (results.isNotEmpty) {
      final num dist = await locator.distanceBetween(
        IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat),
        IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon),
        IveCoreUtilities.unInt(results[0]['narrowEventLatitude']),
        IveCoreUtilities.unInt(
          results[0]['narrowEventLongitude'],
        ),
      );
      final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[0]);
      final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
      final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[0], eventItem.eventStartDatetime);
      extensionsItem.distToEvent = dist;

      String paymentLinkUrl = '';

      if (((eventItem.eventPaymentUrl ?? '') != '') && (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now()))) {
        paymentLinkUrl = eventItem.eventPaymentUrl;
      } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now()))) {
        paymentLinkUrl = kennelItem.kennelPaymentUrl;
      }

      // final num julianNow = results[0]['nowJulian'];
      // final num eventJulian = results[0]['eventJulian'];

      //print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

      item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
    }
    return item;
  }

  Future<void> loadEvents() async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
            evt.${G0<TableModel>().eventsTableHelper.colEventId} as eventId,
            evt.${G0<TableModel>().eventsTableHelper.colEventName} as eventName,
            evt.${G0<TableModel>().eventsTableHelper.colIsCountedRun} as isCountedRun,
            evt.${G0<TableModel>().eventsTableHelper.colNarrowEventLatitude} as lat,
            evt.${G0<TableModel>().eventsTableHelper.colNarrowEventLongitude} as lon,
            evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
            evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} as eventGeographicScope,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare,
            coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelPinColor},0) as kennelPinColor,
            ${QueryRuns.searchField}
            FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt
            INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on evt.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
            INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}
            LEFT OUTER JOIN ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = evt.${G0<TableModel>().eventsTableHelper.colEventId} AND hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = "$userId"
            WHERE evt.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1
            
          ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            AND evt.${G0<TableModel>().eventsTableHelper.colKennelId} = "${widget.kennel.kennelId}"
          ''';
    }

    query = query +
        '''
    ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime}
    ''';

    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      allRuns = <RunDetailsAggregate>[];

      runLocationMarkers = <Marker>[];
      if ((results != null) && (results.isNotEmpty)) {
        for (int i = 0; i < results.length; i++) {
          final num lat = results[i]['lat'];
          final num lon = results[i]['lon'];

          if ((lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
            final DateTime dt = DateTime.parse(results[i]['eventStartDatetime'].substring(0, 19));
            final RunDetailsAggregate item = RunDetailsAggregate(
                event: EventModel(
                  narrowEventLatitude: lat,
                  narrowEventLongitude: lon,
                  eventStartDatetime: dt,
                  eventId: results[i]['eventId'],
                  isCountedRun: results[i]['isCountedRun'],
                  eventGeographicScope: results[i]['eventGeographicScope'],
                ),
                extensions: RunDetailsQueryExtensions(
                    rsvpState: results[i]['rsvpState'],
                    attendenceState: results[i]['attendenceState'],
                    isHare: results[i]['isHare'],
                    searchText: results[i]['searchText'] + RunDetailsQueryExtensions.getSearchDateString(dt)),
                kennel: KennelsModel(kennelPinColor: results[i]['kennelPinColor']));
            allRuns.add(item);
          }
        }
      }
      filterRuns();

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  void buildRunMarkers() {
    runLocationMarkers = <Marker>[];

    for (int i = 0; i < filteredRuns.length; i++) {
      final RunDetailsAggregate run = filteredRuns[i];

      final LatLng ll = LatLng(IveCoreUtilities.unInt(run.event.narrowEventLatitude), IveCoreUtilities.unInt(run.event.narrowEventLongitude));
      final DateTime dt = run.event.eventStartDatetime;

      final Marker marker = Marker(
          width: 45.0,
          height: 55.0,
          anchorPos: AnchorPos.exactly(Anchor(27.0, 0.0)),
          point: ll,
          builder: (BuildContext ctx) => buildRunMarker(run.event.eventId, dt, run.event.eventName,
              rsvpState: run.extensions.rsvpState,
              attendenceState: run.extensions.attendenceState,
              isHare: run.extensions.isHare,
              kennelPinColor: run.kennel.kennelPinColor,
              eventScope: run.event.eventGeographicScope,
              isCountedRun: run.event.isCountedRun));

      if ((viewMode == RunLocationsViewMode.all) ||
          ((viewMode == RunLocationsViewMode.past) && (dt.isBefore(DateTime.now()))) ||
          ((viewMode == RunLocationsViewMode.recent) && (dt.isAfter(DateTime.now().subtract(const Duration(days: 90))))) ||
          ((viewMode == RunLocationsViewMode.myRuns) && (run.extensions.attendenceState >= attendenceAtHash.value))) {
        runLocationMarkers.add(marker);
      }
    }
  }

  Future<void> loadKennels() async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
            k.${G0<TableModel>().kennelsTableHelper.colKennelId} as kennelId,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLogo} as logo,
            k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} as shortName,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude} as lat,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude} as lon
            FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k 
           ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "${widget.kennel.kennelId}"''';
    }

    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      kennelMarkers = <Marker>[];
      final String homeKennelId = getStringPref(StringPrefsEnum.homeKennelId);
      if ((results != null) && (results.isNotEmpty)) {
        for (int i = 0; i < results.length; i++) {
          final num lat = results[i]['lat'];
          final num lon = results[i]['lon'];

          if (results[i]['kennelId'] == homeKennelId) {
            homeKennelLat = lat;
            homeKennelLon = lon;

            setNumPref(NumPrefsEnum.homeKennelLat, homeKennelLat);
            setNumPref(NumPrefsEnum.homeKennelLon, homeKennelLon);

            if ((mapCenterOption == centerOnHomeKennel.value) && (homeKennelLat != null) && (homeKennelLon != null)) {
              mapController.move(LatLng(IveCoreUtilities.unInt(homeKennelLat), IveCoreUtilities.unInt(homeKennelLon)), mapController.zoom);
            }
          }

          if ((lat != null) && (lon != null) && (lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
            final LatLng ll = LatLng(IveCoreUtilities.unInt(lat), IveCoreUtilities.unInt(lon));
            final Marker marker = Marker(
                width: 120.0,
                height: 120.0,
                anchorPos: AnchorPos.exactly(Anchor(60.0, 0.0)),
                point: ll,
                builder: (BuildContext ctx) => buildKennelMarker(
                      results[i]['logo'],
                      results[i]['shortName'],
                      results[i]['kennelId'],
                    ));

            kennelMarkers.add(marker);
          }
        }
      }

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Widget buildRunMarker(String eventId, DateTime eventStartDatetime, String eventName,
      {int attendenceState, int rsvpState, int isHare, int kennelPinColor, int eventScope, int isCountedRun}) {
    return GestureDetector(
      onTap: () {
        getSingleRun(eventId).then((RunDetailsAggregate run) {
          //print(run.event.eventName + ' + ' + run.event.eventId);
          Navigator.push<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => RunDetailsPage(futureRun: run),
            ),
          ).then((void dummy) {
            // _refreshFromBackend(clearLocalTables: false).then((void dummy) {
            //   setState(() {});
            // });
          });
        });
      },
      child: Container(
        //padding: const EdgeInsets.only(bottom: 58.0),
        //color: Colors.red,
        child: Image.asset(getPin(eventStartDatetime, rsvpState, attendenceState, isHare, kennelPinColor, eventScope, isCountedRun)),
        //child: FlutterLogo(colors: Colors.purple),
      ),
    );
  }

  Widget buildKennelMarker(String kennelLogo, String kennelShortName, String kennelId) {
    bool isHomeKennel = false;
    if (kennelId == getStringPref(StringPrefsEnum.homeKennelId))
    {
      isHomeKennel = true;
    }
    return GestureDetector(
      onTap: () async {
        final Geolocator locator = Geolocator();

        final String hasherId = getStringPref(StringPrefsEnum.userId);
        final List<Map<String, dynamic>> results =
            await QueryKennels.queryKennels(EnumKennelQueryType.singleKennel, EnumKennelQueryContext.user, hasherId: hasherId, kennelId: kennelId);

        if (results.isNotEmpty) {
          final num dist = await locator.distanceBetween(IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat), IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon),
              IveCoreUtilities.unInt(results[0]['cityLat']), IveCoreUtilities.unInt(results[0]['cityLon']));

          final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
          final HasherKennelMapModel hkmItem = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
          final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[0]);
          extensionsItem.distToKennel = dist;
          extensionsItem.followingRequested = -1;
          extensionsItem.notificationsRequested = -1;
          extensionsItem.emailAlertRequested = -1;


          final KennelListAggregate kennel = KennelListAggregate(
            kennel: kennelItem,
            extensions: extensionsItem,
            hkm: hkmItem,
            isHomeKennel: isHomeKennel
          );

          Navigator.of(context).push<dynamic>(
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
            ),
          );
        }
      },
      child: Container(
        //padding: const EdgeInsets.only(bottom: 58.0),
        //color: Colors.red,
        child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
          Image.asset('images/icons/grey_square_pin.png'),
          Positioned(
            top: 9,
            child: KennelLogo(
              kennelLogoUrl: kennelLogo,
              kennelShortName: kennelShortName,
              logoHeight: 60.0,
              leftPadding: 0.0,
            ),
          ),
        ]),
      ),
    );
  }

  static int heroCounter = 0;
  static List<String> colors = <String>['red', 'orange', 'yellow', 'green', 'teal', 'baby_blue', 'blue', 'purple', 'pink'];

  String getPin(DateTime eventStartDatetime, int rsvpState, int attendenceState, int isHare, int kennelPinColor, int eventScope, int isCountedRun) {
    String pinFileName = 'images/map_pins/${colors[kennelPinColor]}/past_run_no_rsvp.png';

    String isEvent = 'run';

    if (isCountedRun == 0) {
      isEvent = 'activity';
    }
    if ((eventScope ?? 0) != 0) {
      isEvent = 'event';
    }

    if (eventStartDatetime.isAfter(DateTime.now())) {
      // run is in the future
      if ((attendenceState >= attendenceAtHash.value) || (rsvpState >= rsvpYes.value)) {
        if (isHare != 0) {
          pinFileName = 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_hare.png';
        } else {
          pinFileName = 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_yes.png';
        }
      } else {
        pinFileName = 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_none.png';
      }
    } else {
      // run is in the past
      if (attendenceState >= attendenceAtHash.value) {
        if (isHare != 0) {
          pinFileName = 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_hare.png';
        } else {
          pinFileName = 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_yes.png';
        }
      } else {
        pinFileName = 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_none.png';
      }
    }

    //print(pinFileName);
    return pinFileName;
  }

  Widget runLocationsBody() {
    return Column(
      children: <Widget>[
        showFilters == false ? const SizedBox(height: 0.0) : searchBar(),
        Expanded(
          child: Stack(
            children: <Widget>[
              Container(
                //decoration: Backgrounds.defaultHcBackground(),
                //height: MediaQuery.of(context).size.height,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: (widget.kennel?.kennelLatitude != null)
                        ? LatLng(IveCoreUtilities.unInt(widget.kennel.kennelLatitude), IveCoreUtilities.unInt(widget.kennel.kennelLongitude))
                        : ((mapCenterOption == centerOnCurrentLocation.value) || (homeKennelLat == null) || (homeKennelLon == null))
                            ? LatLng(IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLat), IveCoreUtilities.unInt(G0<DeviceInfo>().deviceLon))
                            : LatLng(IveCoreUtilities.unInt(homeKennelLat), IveCoreUtilities.unInt(homeKennelLon)),
                    zoom: 10.0,
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

                    MarkerClusterLayerOptions(
                      maxClusterRadius: 60,
                      size: const Size(40, 40),
                      fitBoundsOptions: const FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                      markers: runLocationMarkers,
                      polygonOptions: const PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
                      builder: (BuildContext context, List<Marker> markers) {
                        heroCounter++;
                        return FloatingActionButton(
                          backgroundColor: Colors.blue[800],
                          child: Text(markers.length.toString()),
                          onPressed: null,
                          heroTag: 'btn_$heroCounter',
                        );
                      },
                    ),

                    MarkerClusterLayerOptions(
                      maxClusterRadius: 60,
                      size: const Size(50, 50),
                      fitBoundsOptions: const FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                      markers: showKennels == true ? kennelMarkers : <Marker>[],
                      polygonOptions: const PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
                      builder: (BuildContext context, List<Marker> markers) {
                        heroCounter++;
                        return FloatingActionButton(
                          backgroundColor: Colors.purple[600],
                          child: Text(markers.length.toString()),
                          onPressed: null,
                          heroTag: 'btn_$heroCounter',
                        );
                      },
                    ),

                    // MarkerLayerOptions(
                    //   markers: <Marker>[for (MapMarker item in runLocations) mapMarker(item)],
                    // )
                  ],
                ),
              ),
              Positioned(
                  left: 10.0,
                  right: 10.0,
                  top: 10.0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Text(textDescription, textAlign: TextAlign.center, style: headingStyle20Black),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      border: Border.all(width: 2.0),
                      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
      Positioned(
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: widget.kennel == null
            ? runLocationsBody()
            : Scaffold(
                floatingActionButton: getFab(),
                appBar: AppBar(
                  centerTitle: true,
                  backgroundColor: themeAppBarBackground,
                  title: const Text(
                    'Explore Runs',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                body: runLocationsBody()),
      ),
      OfflineModeRibbon(
        showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
      ),
    ]);
  }
}
