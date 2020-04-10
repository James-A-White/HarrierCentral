import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:ive_flutter_core/database/base_service.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/util/enums.dart';

import 'package:ive_flutter_core/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/database/query_runs.dart';
import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/pages/detail_pages/run_details_page.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/pages/detail_pages/kennel_admin_main.dart';
import 'package:harrier_central/database/query_kennels.dart';
import 'package:ive_flutter_core/util/connection.dart';

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
                    child: FlatButton(
                      //color: Colors.red,
                      child: const Text('X'),
                      textColor: Colors.grey[700],
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
        marginRight: 18,
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
          // _scaffoldKey.currentState.hideCurrentSnackBar();
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
                mapController.move(((homeKennelLat != null) && (homeKennelLon != null)) ? LatLng(CoreUtilities.unInt(homeKennelLat), CoreUtilities.unInt(homeKennelLon)) : LatLng(CoreUtilities.unInt(deviceLat), CoreUtilities.unInt(deviceLon)), mapController.zoom);
                Scaffold.of(context).showSnackBar(SnackBar(
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
                mapController.move(LatLng(CoreUtilities.unInt(deviceLat), CoreUtilities.unInt(deviceLon)), mapController.zoom);

                Scaffold.of(context).showSnackBar(SnackBar(
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
        CoreUtilities.unInt(deviceLat),
        CoreUtilities.unInt(deviceLon),
        CoreUtilities.unInt(results[0]['narrowEventLatitude']),
        CoreUtilities.unInt(
          results[0]['narrowEventLongitude'],
        ),
      );
      final EventModel eventItem = eventsTableHelper.fromMap(results[0]);
      final KennelsModel kennelItem = kennelsTableHelper.fromMap(results[0]);
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
            evt.${eventsTableHelper.colEventId} as eventId,
            evt.${eventsTableHelper.colEventName} as eventName,
            evt.${eventsTableHelper.colIsCountedRun} as isCountedRun,
            evt.${eventsTableHelper.colNarrowEventLatitude} as lat,
            evt.${eventsTableHelper.colNarrowEventLongitude} as lon,
            evt.${eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
            evt.${eventsTableHelper.colEventGeographicScope} as eventGeographicScope,
            coalesce(hem.${hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            coalesce(hem.${hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${hasherEventMapTableHelper.colIsHare},0) as isHare,
            coalesce(k.${kennelsTableHelper.colKennelPinColor},0) as kennelPinColor,
            ${QueryRuns.searchField}
            FROM ${eventsTableHelper.tableName} evt
            INNER JOIN ${kennelsTableHelper.tableName} k on evt.${eventsTableHelper.colKennelId} = k.${kennelsTableHelper.colKennelId}
            INNER JOIN ${countriesTableHelper.tableName} n on n.${countriesTableHelper.colCountryId} = k.${kennelsTableHelper.colCountryId}
            LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} hem on hem.${hasherEventMapTableHelper.colEventId} = evt.${eventsTableHelper.colEventId} AND hem.${hasherEventMapTableHelper.colUserId} = "$userId"
            WHERE evt.${eventsTableHelper.colIsVisible} = 1
            
          ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            AND evt.${eventsTableHelper.colKennelId} = "${widget.kennel.kennelId}"
          ''';
    }

    query = query +
        '''
    ORDER BY evt.${eventsTableHelper.colEventStartDatetime}
    ''';

    try {
      final List<Map<String, dynamic>> results = await internalSqlDb.rawQuery(query);
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
                extensions: RunDetailsQueryExtensions(rsvpState: results[i]['rsvpState'], attendenceState: results[i]['attendenceState'], isHare: results[i]['isHare'], searchText: results[i]['searchText'] + RunDetailsQueryExtensions.getSearchDateString(dt)),
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

      final LatLng ll = LatLng(CoreUtilities.unInt(run.event.narrowEventLatitude), CoreUtilities.unInt(run.event.narrowEventLongitude));
      final DateTime dt = run.event.eventStartDatetime;

      final Marker marker = Marker(
          width: 45.0,
          height: 55.0,
          anchorPos: AnchorPos.exactly(Anchor(27.0, 0.0)),
          point: ll,
          builder: (BuildContext ctx) => buildRunMarker(run.event.eventId, dt, run.event.eventName,
              rsvpState: run.extensions.rsvpState, attendenceState: run.extensions.attendenceState, isHare: run.extensions.isHare, kennelPinColor: run.kennel.kennelPinColor, eventScope: run.event.eventGeographicScope, isCountedRun: run.event.isCountedRun));

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
            k.${kennelsTableHelper.colKennelId} as kennelId,
            k.${kennelsTableHelper.colKennelLogo} as logo,
            k.${kennelsTableHelper.colKennelShortName} as shortName,
            k.${kennelsTableHelper.colKennelLatitude} as lat,
            k.${kennelsTableHelper.colKennelLongitude} as lon,
            h.${hashersTableHelper.colHomeKennelId} as homeKennelId
            FROM ${kennelsTableHelper.tableName} k 
            LEFT OUTER JOIN ${hashersTableHelper.tableName} h on k.${kennelsTableHelper.colKennelId} = h.${hashersTableHelper.colHomeKennelId} AND h.${hashersTableHelper.colHasherId} = "$userId"
          ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            WHERE k.${kennelsTableHelper.colKennelId} = "${widget.kennel.kennelId}"''';
    }

    try {
      final List<Map<String, dynamic>> results = await internalSqlDb.rawQuery(query);
      kennelMarkers = <Marker>[];
      if ((results != null) && (results.isNotEmpty)) {
        for (int i = 0; i < results.length; i++) {
          final num lat = results[i]['lat'];
          final num lon = results[i]['lon'];

          if (results[i]['homeKennelId'] != null) {
            homeKennelLat = lat;
            homeKennelLon = lon;

            setNumPref(NumPrefsEnum.homeKennelLat, homeKennelLat);
            setNumPref(NumPrefsEnum.homeKennelLon, homeKennelLon);

            if ((mapCenterOption == centerOnHomeKennel.value) && (homeKennelLat != null) && (homeKennelLon != null)) {
              mapController.move(LatLng(CoreUtilities.unInt(homeKennelLat), CoreUtilities.unInt(homeKennelLon)), mapController.zoom);
            }
          }

          if ((lat != null) && (lon != null) && (lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
            final LatLng ll = LatLng(CoreUtilities.unInt(lat), CoreUtilities.unInt(lon));
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

  Widget buildRunMarker(String eventId, DateTime eventStartDatetime, String eventName, {int attendenceState, int rsvpState, int isHare, int kennelPinColor, int eventScope, int isCountedRun}) {
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
    return GestureDetector(
      onTap: () async {
        final Geolocator locator = Geolocator();

        final String hasherId = getStringPref(StringPrefsEnum.userId);
        final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(EnumKennelQueryType.singleKennel, EnumKennelQueryContext.user, hasherId: hasherId, kennelId: kennelId);

        if (results.isNotEmpty) {
          final num dist = await locator.distanceBetween(CoreUtilities.unInt(deviceLat), CoreUtilities.unInt(deviceLon), CoreUtilities.unInt(results[0]['cityLat']), CoreUtilities.unInt(results[0]['cityLon']));

          final KennelsModel kennelItem = kennelsTableHelper.fromMap(results[0]);
          final HasherKennelMapModel hkmItem = hasherKennelMapTableHelper.fromMap(results[0]);
          final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[0]);
          extensionsItem.distToKennel = dist;
          extensionsItem.followingRequested = -1;
          extensionsItem.notificationsRequested = -1;
          extensionsItem.emailAlertRequested = -1;

          final KennelListAggregate kennel = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem);

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
                        ? LatLng(CoreUtilities.unInt(widget.kennel.kennelLatitude), CoreUtilities.unInt(widget.kennel.kennelLongitude))
                        : ((mapCenterOption == centerOnCurrentLocation.value) || (homeKennelLat == null) || (homeKennelLon == null)) ? LatLng(CoreUtilities.unInt(deviceLat), CoreUtilities.unInt(deviceLon)) : LatLng(CoreUtilities.unInt(homeKennelLat), CoreUtilities.unInt(homeKennelLon)),
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
                      polygonOptions: PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
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
                      polygonOptions: PolygonOptions(borderColor: Colors.blueAccent, color: Colors.black12, borderStrokeWidth: 3),
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
        showRibbon: globalConnectionStatus == connectionStatus_notConnected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
      ),
    ]);
  }
}
