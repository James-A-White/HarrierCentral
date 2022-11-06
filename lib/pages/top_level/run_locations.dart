// @dart=2.11

import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

// class MapMarker extends Marker {
//   MapMarker({@required this.eventId, @required this.eventName, @required this.eventStartDatetime, num width, num height, LatLng point, WidgetBuilder builder}) : super(width: width, height: height, point: point, builder: builder);

//   String eventName;
//   String eventId;
//   DateTime eventStartDatetime;
// }

enum RunLocationsViewMode { all, past, recent, myRuns }

class RunAndKennelMapPage extends StatefulWidget {
  const RunAndKennelMapPage({Key key, this.kennel}) : super(key: key);

  final KennelsModel kennel;

  @override
  RunAndKennelMapPageState createState() => RunAndKennelMapPageState();
}

class RunAndKennelMapPageState extends State<RunAndKennelMapPage> {
  List<Marker> _runLocationMarkers = <Marker>[];
  List<Marker> _kennelMarkers = <Marker>[];

  RunLocationsViewMode _viewMode = RunLocationsViewMode.recent;

  int _mapCenterOption;

  num _homeKennelLat;
  num _homeKennelLon;

  final MapController _mapController = MapController();

  String _textDescription = 'Showing recent runs';

  List<dynamic> _allRuns;
  List<dynamic> _filteredRuns;
  List<Map<String, dynamic>> _allKennels;
  List<Map<String, dynamic>> _filteredKennels;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchRunsAndKennelsText;
  bool _showFilters = false;
  bool _showKennels = true;
  bool _trueNorthLock = true;

  // ignore: non_constant_identifier_names
  static double KENNEL_PIN_SIZE = 100.0;

  @override
  void initState() {
    _homeKennelLat = getNumPref(NumPrefsEnum.homeKennelLat);
    _homeKennelLon = getNumPref(NumPrefsEnum.homeKennelLon);
    _showFilters = (getIntPref(IntPrefsEnum.mapShowSearchBar) ?? 0) == 0 ? false : true;
    _showKennels = (getIntPref(IntPrefsEnum.mapShowKennels) ?? 1) == 0 ? false : true;

    _mapCenterOption = getIntPref(IntPrefsEnum.mapCenterOption);
    if (_mapCenterOption == null) {
      _mapCenterOption = centerOnCurrentLocation.value;
      setIntPref(IntPrefsEnum.mapCenterOption, _mapCenterOption);
    }

    _loadEvents();
    _loadKennels().then((void _) {
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
                          _searchRunsAndKennelsText = text;
                          _filterRuns();
                          _filterKennels();
                        });
                      },
                      focusNode: _searchFocusNode,
                      controller: _searchController,
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
                  SizedBox(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
                      child: Text('X', style: headingStyle20Black.copyWith(color: Colors.grey.shade700)),
                      onPressed: () {
                        _searchController.text = '';
                        _searchRunsAndKennelsText = '';
                        setState(() {
                          _filterRuns();
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

  void _filterRuns() {
    _filteredRuns = QueryRuns.doRunsFilter(_searchRunsAndKennelsText, _allRuns);
    _buildRunMarkers();
    setState(() {});
  }

  List<Map<String, dynamic>> _doKennelFilter(String searchKennelsText) {
    _filteredKennels = <Map<String, dynamic>>[];
    if (_allKennels != null) {
      _filteredKennels.addAll(_allKennels);

      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if ((searchKennelsText != null) && (searchKennelsText.isNotEmpty)) {
        final List<String> searchItems = searchKennelsText.trim().toLowerCase().split(',');
        for (String st in searchItems) {
          if (st.trim().isEmpty) {
            continue;
          }
          bool negate = false;
          if (st.trim().toLowerCase().startsWith('not ')) {
            negate = true;
            st = st.substring(4);
          }
          final List<String> orItems = st.split('+');

          ////print('filtered at: ${DateTime.now().millisecondsSinceEpoch}');

          _filteredKennels = _filteredKennels.where((Map<String, dynamic> a) {
            for (String orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ' + orItem.trim().toLowerCase();
              if (a['searchKennelsText'].toLowerCase().contains(orItem)) {
                return !negate;
              }
            }
            return negate;
          }).toList();
        }
      }
    }
    return _filteredKennels;
  }

  void _filterKennels() {
    _filteredKennels = _doKennelFilter(_searchRunsAndKennelsText);
    _buildKennelMarkers();
    setState(() {});
  }

  Widget getMapFab() {
    return SpeedDial(
        // marginEnd: 18,
        // marginBottom: 10,
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
        //onClose: () => //print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.red.shade900,
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
              _textDescription = 'Showing all runs';
              _viewMode = RunLocationsViewMode.all;
              _loadEvents().then((void _) {
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
              _textDescription = 'Showing runs in last 90 days';
              _viewMode = RunLocationsViewMode.recent;
              _loadEvents().then((void _) {
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
              _textDescription = 'Showing all past runs';
              _viewMode = RunLocationsViewMode.past;
              _loadEvents().then((void _) {
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
              _textDescription = 'Showing runs you\'ve been at';
              _viewMode = RunLocationsViewMode.myRuns;
              _loadEvents().then((void _) {
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
              if (_mapCenterOption == centerOnCurrentLocation.value) {
                _mapCenterOption = centerOnHomeKennel.value;
                setIntPref(IntPrefsEnum.mapCenterOption, _mapCenterOption);
                _mapController.move(
                    ((_homeKennelLat != null) && (_homeKennelLon != null))
                        ? latlng.LatLng(_homeKennelLat + .0, _homeKennelLon + .0)
                        : latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon),
                    _mapController.zoom);
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
                _mapCenterOption = centerOnCurrentLocation.value;
                setIntPref(IntPrefsEnum.mapCenterOption, _mapCenterOption);
                _mapController.move(latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon), _mapController.zoom);

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
              _showFilters = !_showFilters;
              if (!_showFilters) {
                _searchController.text = '';
                _searchRunsAndKennelsText = '';
              }
              setIntPref(IntPrefsEnum.mapShowSearchBar, _showFilters == false ? 0 : 1);
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(FontAwesome.home, color: Colors.white),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide kennels',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              _showKennels = !_showKennels;
              setIntPref(IntPrefsEnum.mapShowKennels, _showKennels == false ? 0 : 1);
              setState(() {});
            },
          ),
        ]);
  }

  Future<void> _loadEvents() async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
            evt.${G0<TableModel>().eventsTableHelper.colEventId} as eventId,
            evt.${G0<TableModel>().eventsTableHelper.colEventName} as eventName,
            evt.${G0<TableModel>().eventsTableHelper.colIsCountedRun} as isCountedRun,
            
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLatitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLatitude}) end as lat,
          case when evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 then evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} else coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLongitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) end as lon,
          case when ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 0 AND evt.${G0<TableModel>().eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${G0<TableModel>().eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${G0<TableModel>().eventsTableHelper.colFbLatitude},evt.${G0<TableModel>().eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,
            
            evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
            evt.${G0<TableModel>().eventsTableHelper.colEventGeographicScope} as eventGeographicScope,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare,
            coalesce(k.${G0<TableModel>().kennelsTableHelper.colKennelPinColor},0) as kennelPinColor,
            ${QueryRuns.searchRunsField}
            FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt
            INNER JOIN ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k on evt.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
            INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
            INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.${G0<TableModel>().regionsTableHelper.colRegionId} = k.${G0<TableModel>().kennelsTableHelper.colRegionId}
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
      _allRuns = <RunDetailsAggregate>[];

      _runLocationMarkers = <Marker>[];
      if ((results != null) && (results.isNotEmpty)) {
        for (int i = 0; i < results.length; i++) {
          final num lat = results[i]['lat'] == null ? null : results[i]['lat'] + .0;
          final num lon = results[i]['lon'] == null ? null : results[i]['lon'] + .0;
          if ((lat != null) && (lon != null)) {
            if ((lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
              final DateTime dt = DateTime.parse(results[i]['eventStartDatetime'].substring(0, 19));
              final RunDetailsAggregate item = RunDetailsAggregate(
                  event: EventModel(
                    eventStartDatetime: dt,
                    eventId: results[i]['eventId'],
                    isCountedRun: results[i]['isCountedRun'],
                    eventGeographicScope: results[i]['eventGeographicScope'],
                  ),
                  extensions: RunDetailsQueryExtensions(
                      latitude: lat,
                      longitude: lon,
                      isMapAndDistanceValid: results[i]['isMapAndDistanceValid'] == 1,
                      rsvpState: results[i]['rsvpState'],
                      attendenceState: results[i]['attendenceState'],
                      isHare: results[i]['isHare'],
                      searchRunsText: results[i]['searchRunsText'] + RunDetailsQueryExtensions.getSearchDateString(dt)),
                  kennel: KennelsModel(kennelPinColor: results[i]['kennelPinColor']));
              _allRuns.add(item);
            }
          }
        }
      }
      _filterRuns();
      setState(() {});
    } catch (e) {
      //print(e);
    }
  }

  void _buildRunMarkers() {
    _runLocationMarkers = <Marker>[];

    for (int i = 0; i < _filteredRuns.length; i++) {
      final RunDetailsAggregate run = _filteredRuns[i];

      final latlng.LatLng ll = latlng.LatLng(
        run.extensions.latitude,
        run.extensions.longitude,
      );
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

      if ((_viewMode == RunLocationsViewMode.all) ||
          ((_viewMode == RunLocationsViewMode.past) && (dt.isBefore(DateTime.now()))) ||
          ((_viewMode == RunLocationsViewMode.recent) && (dt.isAfter(DateTime.now().subtract(const Duration(days: 90))))) ||
          ((_viewMode == RunLocationsViewMode.myRuns) && (run.extensions.attendenceState >= attendenceAtHash.value))) {
        _runLocationMarkers.add(marker);
      }
    }
  }

  Future<void> _loadKennels() async {
    //final String userId = getStringPref(StringPrefsEnum.userId);

    String query = ''' 

          SELECT 
            k.${G0<TableModel>().kennelsTableHelper.colKennelId} as kennelId,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLogo} as logo,
            k.${G0<TableModel>().kennelsTableHelper.colKennelShortName} as shortName,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLatitude} as lat,
            k.${G0<TableModel>().kennelsTableHelper.colKennelLongitude} as lon,
            ${QueryKennels.searchKennelsField}
            FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k 
            INNER JOIN ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} c on c.${G0<TableModel>().citiesTableHelper.colCityId} = k.${G0<TableModel>().kennelsTableHelper.colCityId}
            INNER JOIN ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} r on r.${G0<TableModel>().regionsTableHelper.colRegionId} = k.${G0<TableModel>().kennelsTableHelper.colRegionId}
            INNER JOIN ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} n on n.${G0<TableModel>().countriesTableHelper.colCountryId} = k.${G0<TableModel>().kennelsTableHelper.colCountryId}

           ''';

    if ((widget.kennel?.kennelId != null) && (widget.kennel.kennelId.isNotEmpty)) {
      query = query +
          '''
            WHERE k.${G0<TableModel>().kennelsTableHelper.colKennelId} = "${widget.kennel.kennelId}"''';
    }

    _allKennels = await G0<Database>().rawQuery(query);

    _filterKennels();
    _buildKennelMarkers();
  }

  void _buildKennelMarkers() {
    try {
      _kennelMarkers = <Marker>[];

      final String homeKennelId = getStringPref(StringPrefsEnum.homeKennelId);
      if ((_filteredKennels != null) && (_filteredKennels.isNotEmpty)) {
        for (int i = 0; i < _filteredKennels.length; i++) {
          final num lat = _filteredKennels[i]['lat'] == null ? null : _filteredKennels[i]['lat'] + .0;
          final num lon = _filteredKennels[i]['lon'] == null ? null : _filteredKennels[i]['lon'] + .0;

          if ((lat != null) && (lon != null)) {
            if (_filteredKennels[i]['kennelId'] == homeKennelId) {
              _homeKennelLat = lat;
              _homeKennelLon = lon;

              //await setNumPref(NumPrefsEnum.homeKennelLat, _homeKennelLat);
              //await setNumPref(NumPrefsEnum.homeKennelLon, _homeKennelLon);

              if ((_mapCenterOption == centerOnHomeKennel.value) && (_homeKennelLat != null) && (_homeKennelLon != null)) {
                _mapController.move(latlng.LatLng(_homeKennelLat + .0, _homeKennelLon + .0), _mapController.zoom);
              }
            }

            if ((lat != null) && (lon != null) && (lat <= 90.0) && (lat >= -90.0) && (lon <= 180.0) && (lon >= -180.0)) {
              final latlng.LatLng ll = latlng.LatLng(lat + .0, lon + .0);
              final Marker marker = Marker(
                  width: KENNEL_PIN_SIZE,
                  height: KENNEL_PIN_SIZE,
                  anchorPos: AnchorPos.exactly(Anchor(KENNEL_PIN_SIZE / 2.0, 0.0)),
                  point: ll,
                  builder: (BuildContext ctx) => buildKennelMarker(
                        _filteredKennels[i]['logo'],
                        _filteredKennels[i]['shortName'],
                        _filteredKennels[i]['kennelId'],
                      ));

              _kennelMarkers.add(marker);
            }
          }
        }
      }

      setState(() {});
    } catch (e) {
      //print(e);
    }
  }

  Widget buildRunMarker(String eventId, DateTime eventStartDatetime, String eventName, {int attendenceState, int rsvpState, int isHare, int kennelPinColor, int eventScope, int isCountedRun}) {
    return GestureDetector(
      onTap: () async {
        final RunDetailsAggregate run = await G0<TableModel>().eventsService.getSingleRun(eventId);

        await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => RunDetailsPage(futureRun: run),
          ),
        );
      },
      child: Image.asset(getPin(eventStartDatetime, rsvpState, attendenceState, isHare, kennelPinColor, eventScope, isCountedRun)),
    );
  }

  Widget buildKennelMarker(String kennelLogo, String kennelShortName, String kennelId) {
    bool isHomeKennel = false;
    if (kennelId == getStringPref(StringPrefsEnum.homeKennelId)) {
      isHomeKennel = true;
    }
    return GestureDetector(
      onTap: () async {
        //final Geolocator locator = Geolocator();

        final String hasherId = getStringPref(StringPrefsEnum.userId);
        final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(EnumKennelQueryType.singleKennel, EnumKennelQueryContext.user, hasherId: hasherId, kennelId: kennelId);

        if (results.isNotEmpty) {
          final num dist = Geolocator.distanceBetween(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon, results[0]['cityLat'] + .0, results[0]['cityLon'] + .0);

          final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[0]);
          final HasherKennelMapModel hkmItem = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[0]);
          final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[0]);
          extensionsItem.distToKennel = dist;
          extensionsItem.followingRequested = -1;
          extensionsItem.notificationsRequested = -1;
          extensionsItem.emailAlertRequested = -1;

          final KennelListAggregate kennel = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem, isHomeKennel: isHomeKennel);

          await Navigator.of(context).push<dynamic>(
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
            ),
          );
        }
      },
      child: Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
        Image.asset('images/icons/grey_square_pin.png'),
        Positioned(
          top: KENNEL_PIN_SIZE / 13.3333333,
          child: KennelLogo(
            kennelId: kennelId,
            kennelLogoUrl: kennelLogo,
            kennelShortName: kennelShortName,
            logoHeight: KENNEL_PIN_SIZE / 2.0,
            leftPadding: 0.0,
            zoomGesture: KennelLogoZoomGesture.none,
          ),
        ),
      ]),
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
    if ((eventScope ?? 0) > 1) {
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

    ////print(pinFileName);
    return pinFileName;
  }

  Widget runLocationsBody() {
    return Column(
      children: <Widget>[
        _showFilters == false ? const SizedBox(height: 0.0) : searchBar(),
        Expanded(
          child: Stack(
            children: <Widget>[
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  interactiveFlags: _trueNorthLock ? InteractiveFlag.pinchZoom | InteractiveFlag.drag : InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.rotate,
                  center: (widget.kennel?.kennelLatitude != null)
                      ? latlng.LatLng(widget.kennel.kennelLatitude + .0, widget.kennel.kennelLongitude + .0)
                      : ((_mapCenterOption == centerOnCurrentLocation.value) || (_homeKennelLat == null) || (_homeKennelLon == null))
                          ? latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon)
                          : latlng.LatLng(_homeKennelLat + .0, _homeKennelLon + .0),
                  zoom: 10.0,
                  minZoom: 1.0,
                  maxZoom: 18.0,
                  // plugins: <MarkerClusterPlugin>[
                  //   MarkerClusterPlugin(),
                  // ],
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
                      if (G0<AppModel>().hasLocationPermissions) ...<Marker>[
                        Marker(
                          height: 50.0,
                          width: 50.0,
                          point: latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon),
                          builder: (BuildContext ctx) => Container(
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
                      maxClusterRadius: 60,
                      size: const Size(40, 40),
                      fitBoundsOptions: const FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                      markers: _runLocationMarkers,
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
                  ),

                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 20,
                      size: const Size(50, 50),
                      fitBoundsOptions: const FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                      markers: _showKennels == true ? _kennelMarkers : <Marker>[],
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
                  ),

                  // MarkerLayerOptions(
                  //   markers: <Marker>[for (MapMarker item in runLocations) mapMarker(item)],
                  // )
                ],
              ),
              if (G0<AppModel>().hasLocationPermissions) ...<Widget>[
                Positioned(
                  right: 10.0,
                  top: 60.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mapController.move(
                          latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon),
                          13.0,
                        );
                      });
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset('images/other/set_map_to_current_location.png'),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: 10.0,
                top: 60.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _trueNorthLock = !_trueNorthLock;
                      if (_trueNorthLock) {
                        _mapController.rotate(0.0);
                      }
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset(_trueNorthLock ? 'images/other/set_map_to_true_north_lock.png' : 'images/other/set_map_rotation_enabled.png'),
                  ),
                ),
              ),
              Positioned(
                  left: 10.0,
                  right: 10.0,
                  top: 10.0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Text(_textDescription, textAlign: TextAlign.center, style: headingStyle20Black),
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
      SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
      Positioned(
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: widget.kennel == null
            ? runLocationsBody()
            : Scaffold(
                floatingActionButton: getMapFab(),
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
      // OfflineModeRibbon(
      //   showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
      //   lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
      //   ribbonImage: 'images/icons/offline_mode.png',
      // ),
    ]);
  }
}
