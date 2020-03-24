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

  RunLocationsViewMode viewMode = RunLocationsViewMode.all;

  String textDescription = 'Showing all runs';

  @override
  void initState() {
    loadEvents();
    super.initState();
  }

  Widget getFab() {
    return SpeedDial(
        // both default to 16
        marginRight: 18,
        marginBottom: 30,
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
            coalesce(hem.${hasherEventMapTableHelper.colIsHare},0) as isHare
            FROM ${eventsTableHelper.tableName} evt
            LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} hem on hem.${hasherEventMapTableHelper.colEventId} = evt.${eventsTableHelper.colEventId} AND hem.${hasherEventMapTableHelper.colUserId} = "$userId"
            WHERE evt.${eventsTableHelper.colIsVisible} = 1
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
                width: 50.0,
                height: 60.0,
                anchorPos: AnchorPos.exactly(Anchor(25.0, 0.0)),
                point: ll,
                builder: (BuildContext ctx) => buildMarker(
                      results[i]['eventId'],
                      dt,
                      results[i]['eventName'],
                      rsvpState: rsvpState,
                      attendenceState: attendenceState,
                      isHare: isHare,
                    ));

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

  Widget buildMarker(String eventId, DateTime eventStartDatetime, String eventName, {int attendenceState, int rsvpState, int isHare}) {
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
        child: Image.asset(getPin(eventStartDatetime, rsvpState, attendenceState, isHare)),
        //child: FlutterLogo(colors: Colors.purple),
      ),
    );
  }

  static int heroCounter = 0;

  String getPin(DateTime eventStartDatetime, int rsvpState, int attendenceState, int isHare) {
    String pinFileName = 'images/icons/map_purple_pin.png';

    if (eventStartDatetime.isAfter(DateTime.now())) {
      // run is in the future
      if ((attendenceState >= attendenceAtHash.value) || (rsvpState >= rsvpYes.value)) {
        if (isHare != 0) {
          pinFileName = 'images/icons/map_gold_star_pin.png';
        } else {
          pinFileName = 'images/icons/map_green_star_pin.png';
        }
      } else {
        pinFileName = 'images/icons/map_green_pin.png';
      }
    } else {
      // run is in the past
      if (attendenceState >= attendenceAtHash.value) {
        if (isHare != 0) {
          pinFileName = 'images/icons/map_gold_star_pin.png';
        } else {
          pinFileName = 'images/icons/map_purple_star_pin.png';
        }
      } else {
        pinFileName = 'images/icons/map_purple_pin.png';
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
            options: MapOptions(
              center: (widget.kennel?.kennelLatitude != null) ? LatLng(Utilities.unInt(widget.kennel.kennelLatitude), Utilities.unInt(widget.kennel.kennelLongitude)) : LatLng(Utilities.unInt(deviceLat), Utilities.unInt(deviceLon)),
              zoom: 15.0,
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
            left:10.0,right:10.0,
            top: 10.0,
            child: Container(
              padding: const EdgeInsets.only(top:5.0,bottom:5.0),
              child: Text(textDescription,textAlign: TextAlign.center,style:headingStyle20Black),
              
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                border: Border.all(width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(10.0) 
                    ),
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
