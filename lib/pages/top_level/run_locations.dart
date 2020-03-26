import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:latlong/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/database/query_runs.dart';
import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/pages/detail_pages/run_details_page.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

// class MapMarker extends Marker {
//   MapMarker({@required this.eventId, @required this.eventName, @required this.eventStartDatetime, num width, num height, LatLng point, WidgetBuilder builder}) : super(width: width, height: height, point: point, builder: builder);

//   String eventName;
//   String eventId;
//   DateTime eventStartDatetime;
// }

enum RunLocationsViewMode { all, future, past, recent, myRuns, myHaring }

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

  @override
  void initState() {

    homeKennelLat = getNumPref(NumPrefsEnum.homeKennelLat);
    homeKennelLon = getNumPref(NumPrefsEnum.homeKennelLon);

    mapCenterOption = getIntPref(IntPrefsEnum.mapCenterOption);
    if (mapCenterOption == null) {
      mapCenterOption = centerOnCurrentLocation.value;
      setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption);
    }

    loadEvents();
    loadKennels().then((void dummy) {
      setState(() {
        
      });
    });

    super.initState();
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
        onClose: () => print('DIAL CLOSED'),
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
            child: const Icon(Entypo.cw),
            backgroundColor: Colors.blue[900],
            label: 'Show all future runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing all future runs';
              viewMode = RunLocationsViewMode.future;
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
            child: const Icon(Entypo.time_slot),
            backgroundColor: Colors.blue[900],
            label: 'Show recent runs',
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
            child: const Icon(MaterialCommunityIcons.run_fast, color: Colors.black),
            backgroundColor: Colors.orange[400],
            label: 'Show my haring',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              textDescription = 'Showing runs you\'ve hared';
              viewMode = RunLocationsViewMode.myHaring;
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
                mapController.move(((homeKennelLat != null) && (homeKennelLon != null)) ? LatLng(Utilities.unInt(homeKennelLat),Utilities.unInt(homeKennelLon)) : LatLng(Utilities.unInt(deviceLat), Utilities.unInt(deviceLon)),mapController.zoom);
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
            mapController.move(LatLng(Utilities.unInt(deviceLat), Utilities.unInt(deviceLon)),mapController.zoom);
   
                
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
        ]);
  }

  Future<RunDetailsAggregate> getSingleRun(String eventId) async {
    final Geolocator locator = Geolocator();
    RunDetailsAggregate item;

    final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(EnumRunQueryType.singleRun, EnumRunQueryContext.kennelAdmin, eventId: eventId);
    if (results.isNotEmpty) {
      final num dist = await locator.distanceBetween(Utilities.unInt(deviceLat), Utilities.unInt(deviceLon), Utilities.unInt(results[0]['narrowEventLatitude']), Utilities.unInt(results[0]['narrowEventLongitude']));
      final EventModel eventItem = eventsTableHelper.fromMap(results[0]);
      final KennelsModel kennelItem = kennelsTableHelper.fromMap(results[0]);
      final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[0]);
      extensionsItem.distToEvent = dist;

      String paymentLinkUrl = '';

      if (((eventItem.eventPaymentUrl ?? '') != '') && (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now()))) {
        paymentLinkUrl = eventItem.eventPaymentUrl;
      } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now()))) {
        paymentLinkUrl = kennelItem.kennelPaymentUrl;
      }

      final num julianNow = results[0]['nowJulian'];
      final num eventJulian = results[0]['eventJulian'];

      print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

      item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
    }
    return item;
  }

  Future<void> loadEvents() async {
    final Database db = await DBProvider.db.database;

    final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
            evt.${eventsTableHelper.colEventId} as eventId,
            evt.${eventsTableHelper.colEventName} as eventName,
            evt.${eventsTableHelper.colNarrowEventLatitude} as lat,
            evt.${eventsTableHelper.colNarrowEventLongitude} as lon,
            evt.${eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
            coalesce(hem.${hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            coalesce(hem.${hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${hasherEventMapTableHelper.colIsHare},0) as isHare,
            coalesce(k.${kennelsTableHelper.colKennelPinColor},0) as kennelPinColor
            FROM ${eventsTableHelper.tableName} evt
            INNER JOIN ${kennelsTableHelper.tableName} k on evt.${eventsTableHelper.colKennelId} = k.${kennelsTableHelper.colKennelId}
            LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} hem on hem.${hasherEventMapTableHelper.colEventId} = evt.${eventsTableHelper.colEventId} AND hem.${hasherEventMapTableHelper.colUserId} = "$userId"
            WHERE evt.${eventsTableHelper.colIsVisible} = 1
            ORDER BY evt.${eventsTableHelper.colEventStartDatetime}
          ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            AND evt.${eventsTableHelper.colKennelId} = "${widget.kennel.kennelId}"''';
    }

    try {
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
      runLocationMarkers = <Marker>[];
      if ((results != null) && (results.isNotEmpty)) {
        for (int i = 0; i < results.length; i++) {
          final num lat = results[i]['lat'];
          final num lon = results[i]['lon'];

          if ((lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
            final DateTime dt = DateTime.parse(results[i]['eventStartDatetime'].substring(0, 19));
            final int rsvpState = results[i]['rsvpState'];
            final int attendenceState = results[i]['attendenceState'];
            final int isHare = results[i]['isHare'];

            final LatLng ll = LatLng(Utilities.unInt(lat), Utilities.unInt(lon));
            final Marker marker = Marker(
                width: 54.0,
                height: 66.0,
                anchorPos: AnchorPos.exactly(Anchor(27.0, 0.0)),
                point: ll,
                builder: (BuildContext ctx) => buildRunMarker(results[i]['eventId'], dt, results[i]['eventName'], rsvpState: rsvpState, attendenceState: attendenceState, isHare: isHare, kennelPinColor: results[i]['kennelPinColor']));

            if ((viewMode == RunLocationsViewMode.all) ||
                ((viewMode == RunLocationsViewMode.past) && (dt.isBefore(DateTime.now()))) ||
                ((viewMode == RunLocationsViewMode.future) && (dt.isAfter(DateTime.now()))) ||
                ((viewMode == RunLocationsViewMode.recent) && (dt.isAfter(DateTime.now().subtract(const Duration(days: 90))))) ||
                ((viewMode == RunLocationsViewMode.myRuns) && (attendenceState >= attendenceAtHash.value)) ||
                ((viewMode == RunLocationsViewMode.myHaring) && (attendenceState >= attendenceAtHash.value) && (isHare != 0))) {
              runLocationMarkers.add(marker);
            }
          }
        }
      }

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadKennels() async {
    final Database db = await DBProvider.db.database;

    final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
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
      final List<Map<String, dynamic>> results = await db.rawQuery(query);
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

            if ((mapCenterOption == centerOnHomeKennel.value) && (homeKennelLat != null) && (homeKennelLon != null))
            {
              mapController.move(LatLng(Utilities.unInt(homeKennelLat), Utilities.unInt(homeKennelLon)), mapController.zoom);
            }
          }

          if ((lat != null) && (lon != null) && (lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
            final LatLng ll = LatLng(Utilities.unInt(lat), Utilities.unInt(lon));
            final Marker marker = Marker(width: 120.0, height: 120.0, anchorPos: AnchorPos.exactly(Anchor(60.0, 0.0)), point: ll, builder: (BuildContext ctx) => buildKennelMarker(results[i]['logo'], results[i]['shortName']));

            kennelMarkers.add(marker);
          }
        }
      }

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Widget buildRunMarker(
    String eventId,
    DateTime eventStartDatetime,
    String eventName, {
    int attendenceState,
    int rsvpState,
    int isHare,
    int kennelPinColor,
  }) {
    return GestureDetector(
      onTap: () {
        getSingleRun(eventId).then((RunDetailsAggregate run) {
          print(run.event.eventName + ' + ' + run.event.eventId);
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
        child: Image.asset(getPin(eventStartDatetime, rsvpState, attendenceState, isHare, kennelPinColor)),
        //child: FlutterLogo(colors: Colors.purple),
      ),
    );
  }

  Widget buildKennelMarker(
    String kennelLogo,
    String kennelShortName,
  ) {
    return GestureDetector(
      onTap: () {},
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
  static List<String> colors = ['red', 'orange', 'yellow', 'green', 'teal', 'baby_blue', 'blue', 'purple', 'pink'];

  String getPin(DateTime eventStartDatetime, int rsvpState, int attendenceState, int isHare, int kennelPinColor) {
    String pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_no_rsvp.png';

    if (eventStartDatetime.isAfter(DateTime.now())) {
      // run is in the future
      if ((attendenceState >= attendenceAtHash.value) || (rsvpState >= rsvpYes.value)) {
        if (isHare != 0) {
          pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_rsvp_hare.png';
        } else {
          pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_rsvp_yes.png';
        }
      } else {
        pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_no_rsvp.png';
      }
    } else {
      // run is in the past
      if (attendenceState >= attendenceAtHash.value) {
        if (isHare != 0) {
          pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_hared.png';
        } else {
          pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_ran.png';
        }
      } else {
        pinFileName = 'images/map_pins/pin_${colors[kennelPinColor]}_past_run.png';
      }
    }

    return pinFileName;
  }

  Widget runLocationsBody() {
    return Stack(
      children: <Widget>[
        Container(
          //decoration: Backgrounds.defaultHcBackground(),
          //height: MediaQuery.of(context).size.height,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: (widget.kennel?.kennelLatitude != null)
                  ? LatLng(Utilities.unInt(widget.kennel.kennelLatitude), Utilities.unInt(widget.kennel.kennelLongitude))
                  : ((mapCenterOption == centerOnCurrentLocation.value) || (homeKennelLat == null) || (homeKennelLon == null)) ? LatLng(Utilities.unInt(deviceLat), Utilities.unInt(deviceLon)) : LatLng(Utilities.unInt(homeKennelLat), Utilities.unInt(homeKennelLon)),
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
                markers: kennelMarkers,
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
      const OfflineModeRibbon(),
    ]);
  }
}
