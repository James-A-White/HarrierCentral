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
  const RunAndKennelMapPage({super.key, this.kennel});

  final KennelsModel? kennel;

  @override
  RunAndKennelMapPageState createState() => RunAndKennelMapPageState();
}

class RunAndKennelMapPageState extends State<RunAndKennelMapPage> {
  List<Marker> _runLocationMarkers = <Marker>[];
  List<Marker> _kennelMarkers = <Marker>[];

  RunLocationsViewMode _viewMode = RunLocationsViewMode.recent;

  int _mapCenterOption = centerOnCurrentLocation.value;

  double? _homeKennelLat;
  double? _homeKennelLon;

  final MapController _mapController = MapController();

  String _textDescription = 'Showing recent runs';

  List<RunDetailsAggregate> _allRuns = <RunDetailsAggregate>[];
  List<RunDetailsAggregate> _preFilteredRuns = <RunDetailsAggregate>[];

  List<dynamic> _filteredRuns = <dynamic>[];
  List<Map<String, dynamic>> _allKennels = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredKennels = <Map<String, dynamic>>[];

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchRunsAndKennelsText = '';
  bool _showFilters = false;
  bool _showKennels = true;
  bool _trueNorthLock = true;

  // ignore: non_constant_identifier_names
  static double KENNEL_PIN_SIZE = 100.0;

  @override
  void initState() {
    super.initState();

    _homeKennelLat = getDoublePref(NumPrefsEnum.homeKennelLat);
    _homeKennelLon = getDoublePref(NumPrefsEnum.homeKennelLon);
    _showFilters = (getIntPref(IntPrefsEnum.mapShowSearchBar) ?? 0) == 0
        ? false
        : true;
    _showKennels = (getIntPref(IntPrefsEnum.mapShowKennels) ?? 1) == 0
        ? false
        : true;

    _mapCenterOption =
        getIntPref(IntPrefsEnum.mapCenterOption) ??
        centerOnCurrentLocation.value;

    unawaited(initStateAsync());

    final camera = MapCamera(
      crs: Epsg3857(),
      center:
          ((_mapCenterOption == centerOnCurrentLocation.value) &&
              (deviceInfo.deviceLat != null) &&
              (deviceInfo.deviceLon != null))
          ? latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!)
          : ((_mapCenterOption == centerOnHomeKennel.value) &&
                (_homeKennelLat != null) &&
                (_homeKennelLat != null))
          ? latlng.LatLng(_homeKennelLat!, _homeKennelLon!)
          : ((widget.kennel != null) &&
                (widget.kennel!.kennelLatitude != null) &&
                (widget.kennel!.kennelLongitude != null))
          ? latlng.LatLng(
              widget.kennel!.kennelLatitude!,
              widget.kennel!.kennelLongitude!,
            )
          : latlng.LatLng(
              deviceInfo.deviceLat ?? DEFAULT_LATITUDE,
              deviceInfo.deviceLon ?? DEFAULT_LONGITUDE,
            ),
      zoom: 10.0,
      rotation: 0.0,
      nonRotatedSize: Size(Get.width, Get.height),
    );

    if (Get.isRegistered<FutureRunListPageController>()) {
      final ctrl = Get.find<FutureRunListPageController>();
      ctrl.mapBounds = camera.visibleBounds;
    }
  }

  Future<void> initStateAsync() async {
    if (getIntPref(IntPrefsEnum.mapCenterOption) == null) {
      _mapCenterOption = centerOnCurrentLocation.value;
      await setIntPref(IntPrefsEnum.mapCenterOption, _mapCenterOption);
    }

    await _loadEvents();
    await _loadKennels();
    setState(() {});
  }

  Widget _searchBar() {
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
                          _filterRuns(true);
                          _filterKennels();
                        });
                      },
                      focusNode: _searchFocusNode,
                      controller: _searchController,
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
                      child: Text(
                        'X',
                        style: ts_headingBlack.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      onPressed: () {
                        _searchController.text = '';
                        _searchRunsAndKennelsText = '';
                        setState(() {
                          _filterRuns(true);
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

  void _filterRuns(bool searchTextChanged) {
    if ((!searchTextChanged) || (_preFilteredRuns.isEmpty)) {
      _preFilteredRuns = QueryRuns.doRunsFilter(
        _allRuns,
        RunsToDisplay.allRuns,
        RunsTimeScope.all,
      );
    }

    _filteredRuns = QueryRuns.doRunsSearchTextFilter(
      _searchRunsAndKennelsText,
      _preFilteredRuns,
    );

    _buildRunMarkers();
    setState(() {});
  }

  List<Map<String, dynamic>> _doKennelFilter(String searchKennelsText) {
    // searchKennelsText = '$searchKennelsText , ${removeDiacritics(searchKennelsText)}';
    _filteredKennels = <Map<String, dynamic>>[];
    if (_allKennels.isNotEmpty) {
      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if (searchKennelsText.isNotEmpty) {
        final List<String> searchItems = searchKennelsText
            .trim()
            .toLowerCase()
            .split(',');
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
              orItem = ' ${orItem.trim().toLowerCase()}';
              if ((a['searchKennelsText'].toLowerCase().contains(orItem)) ||
                  (removeDiacritics(
                    a['searchKennelsText'].toLowerCase(),
                  ).contains(orItem))) {
                return !negate;
              }
            }
            return negate;
          }).toList();
        }
      } else {
        _filteredKennels.addAll(_allKennels);
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
    return ConnectedWidget(
      child: SpeedDial(
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
            onTap: () async {
              _textDescription = 'Showing all runs';
              _viewMode = RunLocationsViewMode.all;
              await _loadEvents();
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(Entypo.time_slot),
            backgroundColor: hc_blue,
            label: 'Show recent+future runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _textDescription = 'Showing runs in last 90 days';
              _viewMode = RunLocationsViewMode.recent;
              await _loadEvents();
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(Entypo.ccw),
            backgroundColor: hc_blue,
            label: 'Show all past runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _textDescription = 'Showing all past runs';
              _viewMode = RunLocationsViewMode.past;
              await _loadEvents();
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.run, color: Colors.black),
            backgroundColor: Colors.orange[400],
            label: 'Show my runs',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _textDescription = 'Showing runs you\'ve been at';
              _viewMode = RunLocationsViewMode.myRuns;
              await _loadEvents();
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.target),
            backgroundColor: Colors.purple[700],
            label: 'Change map center',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              if (_mapCenterOption == centerOnCurrentLocation.value) {
                _mapCenterOption = centerOnHomeKennel.value;
                await setIntPref(
                  IntPrefsEnum.mapCenterOption,
                  _mapCenterOption,
                );

                if ((_homeKennelLat != null) && (_homeKennelLon != null)) {
                  _mapController.move(
                    latlng.LatLng(_homeKennelLat!, _homeKennelLon!),
                    _mapController.camera.zoom,
                  );
                } else if ((deviceInfo.deviceLat != null) &&
                    (deviceInfo.deviceLon != null)) {
                  _mapController.move(
                    latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!),
                    _mapController.camera.zoom,
                  );
                }

                if (navigatorKey.currentContext != null) {
                  ScaffoldMessenger.of(
                    navigatorKey.currentContext!,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Map will center on home kennel\r\n\r\n',
                        style: ts_title,
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: hc_blue,
                      elevation: 200.0,
                    ),
                  );
                }
              } else {
                _mapCenterOption = centerOnCurrentLocation.value;
                await setIntPref(
                  IntPrefsEnum.mapCenterOption,
                  _mapCenterOption,
                );

                if ((deviceInfo.deviceLat != null) &&
                    (deviceInfo.deviceLon != null)) {
                  _mapController.move(
                    latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!),
                    _mapController.camera.zoom,
                  );
                }

                if (navigatorKey.currentContext != null) {
                  ScaffoldMessenger.of(
                    navigatorKey.currentContext!,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Map will center on current location\r\n\r\n',
                        style: ts_title,
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: hc_blue,
                      elevation: 200.0,
                    ),
                  );
                }
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(
              MaterialCommunityIcons.map_search_outline,
              color: Colors.white,
            ),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide search bar',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _showFilters = !_showFilters;
              if (!_showFilters) {
                _searchController.text = '';
                _searchRunsAndKennelsText = '';
              }
              await setIntPref(
                IntPrefsEnum.mapShowSearchBar,
                _showFilters == false ? 0 : 1,
              );
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(FontAwesome.home, color: Colors.white),
            backgroundColor: Colors.purple[700],
            label: 'Show / hide kennels',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _showKennels = !_showKennels;
              await setIntPref(
                IntPrefsEnum.mapShowKennels,
                _showKennels == false ? 0 : 1,
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadEvents() async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    String query =
        '''

          SELECT 
            evt.*,
            case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLatitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLatitude}) end as lat,
            case when evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 then evt.${tableModel.eventsTableHelper.colHcLongitude} else coalesce(evt.${tableModel.eventsTableHelper.colFbLongitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) end as lon,
            case when ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 0 AND evt.${tableModel.eventsTableHelper.colHcLongitude} IS NOT NULL) OR ((evt.${tableModel.eventsTableHelper.colUseFbLatLon} = 1 AND coalesce(evt.${tableModel.eventsTableHelper.colFbLatitude},evt.${tableModel.eventsTableHelper.colHcLongitude}) IS NOT NULL))) THEN 1 ELSE 0 END as isMapAndDistanceValid,
            coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
            coalesce(hem.${tableModel.hasherEventMapTableHelper.colRsvpState},0) as rsvpState,
            coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
            k.*,
            ${QueryRuns.searchRunsField}
            FROM ${EnumDataTables.events.commonTableName} evt
            INNER JOIN ${EnumDataTables.kennels.commonTableName} k on evt.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
            INNER JOIN ${EnumDataTables.cities.commonTableName} c on c.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
            INNER JOIN ${EnumDataTables.regions.commonTableName} r on r.${tableModel.regionsTableHelper.colRegionId} = k.${tableModel.kennelsTableHelper.colRegionId}
            INNER JOIN ${EnumDataTables.countries.commonTableName} n on n.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
            LEFT OUTER JOIN ${EnumDataTables.hasherEventMap.commonTableName} hem on hem.${tableModel.hasherEventMapTableHelper.colEventId} = evt.${tableModel.eventsTableHelper.colEventId} AND hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId"
            WHERE evt.${tableModel.eventsTableHelper.colIsVisible} = 1
            
          ''';

    if ((widget.kennel != null) && (widget.kennel!.kennelId.isNotEmpty)) {
      query =
          '''$query AND evt.${tableModel.eventsTableHelper.colKennelId} = "${widget.kennel!.kennelId}"
          ''';
    }

    query =
        '''$query ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime}
    ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      _allRuns = <RunDetailsAggregate>[];

      _runLocationMarkers = <Marker>[];

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final double? lat = (results[i]['lat'] as num?)?.toDouble();
          final double? lon = (results[i]['lon'] as num?)?.toDouble();

          if ((lat != null) && (lon != null)) {
            if ((lat <= 90.0) &&
                (lat >= -90.0) &&
                (lon <= 180.0) &&
                (lon >= -180.0)) {
              EventModel em = EventModel.fromJson(results[i]);
              final DateTime dt = DateTime.parse(
                results[i]['eventStartDatetime'].substring(0, 19),
              );

              var diff = em.eventStartDatetimeGmt.difference(
                DateTime.now().toUtc(),
              );

              final RunDetailsAggregate item = RunDetailsAggregate(
                event: em,
                extensions: RunQueryExtensionsModel(
                  latitude: lat,
                  longitude: lon,
                  evtLat: lat,
                  evtLon: lon,
                  showAsFutureEvent: diff >= Duration(hours: 4) ? 1 : 0,
                  showAsPastEvent: diff <= Duration(hours: 4) ? 1 : 0,
                  isMapAndDistanceValid: results[i]['isMapAndDistanceValid'],
                  rsvpState: results[i]['rsvpState'],
                  attendenceState: results[i]['attendenceState'],
                  isHare: results[i]['isHare'],
                  searchRunsText:
                      results[i]['searchRunsText'] +
                      RunQueryExtensionsModel.getSearchDateString(dt),
                ),
                kennel: KennelsModel.fromJson(results[i]),
              );
              _allRuns.add(item);
            }
          }
        }
      }
      _filterRuns(false);
      setState(() {});
    } catch (e) {
      //print(e);
    }
  }

  void _buildRunMarkers() {
    _runLocationMarkers = <Marker>[];

    for (int i = 0; i < _filteredRuns.length; i++) {
      final RunDetailsAggregate run = _filteredRuns[i];

      if ((run.extensions.evtLat == null) || (run.extensions.evtLon == null)) {
        continue;
      }

      final latlng.LatLng ll = latlng.LatLng(
        run.extensions.evtLat!,
        run.extensions.evtLon!,
      );
      final DateTime dt = run.event.eventStartDatetimeGmt;

      final Marker marker = Marker(
        width: 45.0,
        height: 55.0,
        alignment: Alignment.topCenter,
        //anchorPos: AnchorPos.exactly(Anchor(27.0, 0.0)),
        point: ll,
        child: Opacity(
          opacity: dt.isBefore(DateTime.now()) ? 0.66 : 1.0,
          child: _buildRunMarker(
            run.event.eventId,
            dt,
            run.event.eventName,
            rsvpState: run.extensions.rsvpState,
            attendenceState: run.extensions.attendenceState,
            isHare: run.extensions.isHare,
            kennelPinColor: run.kennel.kennelPinColor,
            eventScope: run.event.eventGeographicScope,
            isCountedRun: run.event.isCountedRun,
          ),
        ),
      );

      if ((_viewMode == RunLocationsViewMode.all) ||
          ((_viewMode == RunLocationsViewMode.past) &&
              (dt.isBefore(DateTime.now()))) ||
          ((_viewMode == RunLocationsViewMode.recent) &&
              (dt.isAfter(
                DateTime.now().subtract(const Duration(days: 90)),
              ))) ||
          ((_viewMode == RunLocationsViewMode.myRuns) &&
              ((run.extensions.attendenceState) >= attendenceAtHash.value))) {
        _runLocationMarkers.add(marker);
      }
    }
  }

  Future<void> _loadKennels() async {
    //final String userId = getStringPref(StringPrefsEnum.userId);

    String query =
        '''

          SELECT 
            k.${tableModel.kennelsTableHelper.colKennelId} as kennelId,
            k.${tableModel.kennelsTableHelper.colKennelLogo} as logo,
            k.${tableModel.kennelsTableHelper.colKennelShortName} as shortName,
            k.${tableModel.kennelsTableHelper.colKennelLatitude} as lat,
            k.${tableModel.kennelsTableHelper.colKennelLongitude} as lon,
            ${QueryKennels.searchKennelsField}
            FROM ${EnumDataTables.kennels.commonTableName} k 
            INNER JOIN ${EnumDataTables.cities.commonTableName} c on c.${tableModel.citiesTableHelper.colCityId} = k.${tableModel.kennelsTableHelper.colCityId}
            INNER JOIN ${EnumDataTables.regions.commonTableName} r on r.${tableModel.regionsTableHelper.colRegionId} = k.${tableModel.kennelsTableHelper.colRegionId}
            INNER JOIN ${EnumDataTables.countries.commonTableName} n on n.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}

           ''';

    if ((widget.kennel != null) && (widget.kennel!.kennelId.isNotEmpty)) {
      query =
          '''$query WHERE k.${tableModel.kennelsTableHelper.colKennelId} = "${widget.kennel!.kennelId}"''';
    }

    _allKennels = await database.rawQuery(query);

    _filterKennels();
    _buildKennelMarkers();
  }

  void _buildKennelMarkers() {
    try {
      _kennelMarkers = <Marker>[];

      final String? homeKennelId = getStringPref(
        StringPrefsEnum.homeKennelId,
      )?.toLowerCase();
      if (_filteredKennels.isNotEmpty) {
        for (int i = 0; i < _filteredKennels.length; i++) {
          final double? lat = _filteredKennels[i]['lat'];
          final double? lon = _filteredKennels[i]['lon'];

          if ((lat != null) && (lon != null)) {
            if (_filteredKennels[i]['kennelId'] == homeKennelId) {
              _homeKennelLat = lat;
              _homeKennelLon = lon;

              //await setNumPref(NumPrefsEnum.homeKennelLat, _homeKennelLat);
              //await setNumPref(NumPrefsEnum.homeKennelLon, _homeKennelLon);

              if ((_mapCenterOption == centerOnHomeKennel.value) &&
                  (_homeKennelLat != null) &&
                  (_homeKennelLon != null)) {
                _mapController.move(
                  latlng.LatLng(_homeKennelLat!, _homeKennelLon!),
                  _mapController.camera.zoom,
                );
              }
            }

            if ((lat <= 90.0) &&
                (lat >= -90.0) &&
                (lon <= 180.0) &&
                (lon >= -180.0)) {
              final latlng.LatLng ll = latlng.LatLng(lat, lon);
              final Marker marker = Marker(
                width: KENNEL_PIN_SIZE,
                height: KENNEL_PIN_SIZE,
                //anchorPos: AnchorPos.exactly(Anchor(KENNEL_PIN_SIZE / 2.0, 0.0)),
                point: ll,
                child: _buildKennelMarker(
                  _filteredKennels[i]['logo'],
                  _filteredKennels[i]['shortName'],
                  _filteredKennels[i]['kennelId'],
                ),
              );

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

  Widget _buildRunMarker(
    String eventId,
    DateTime? eventStartDatetimeGmt,
    String eventName, {
    int? attendenceState,
    int? rsvpState,
    int? isHare,
    required int kennelPinColor,
    int? eventScope,
    int? isCountedRun,
  }) {
    return GestureDetector(
      onTap: () async {
        final RunDetailsAggregate? run = await tableModel.eventsService
            .getSingleRun(eventId);

        if ((!mounted) || (run == null)) return;
        await Navigator.push<dynamic>(
          navigatorKey.currentContext!,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => RunDetailsPage(futureRun: run),
          ),
        );
      },
      child: Image.asset(
        _getPin(
          eventStartDatetimeGmt ?? DateTime.now(),
          rsvpState,
          attendenceState,
          isHare,
          kennelPinColor,
          eventScope,
          isCountedRun,
        ),
      ),
    );
  }

  Widget _buildKennelMarker(
    String kennelLogo,
    String kennelShortName,
    String kennelId,
  ) {
    bool isHomeKennel = false;
    if (kennelId.toLowerCase() ==
        getStringPref(StringPrefsEnum.homeKennelId)?.toLowerCase()) {
      isHomeKennel = true;
    }
    return GestureDetector(
      onTap: () async {
        //final Geolocator locator = Geolocator();

        final String hasherId = getStringPref(StringPrefsEnum.userId)!;
        final List<Map<String, dynamic>> results =
            await QueryKennels.queryKennels(
              EnumKennelQueryType.singleKennel,
              EnumKennelQueryContext.user,
              hasherId: hasherId,
              kennelId: kennelId,
            );

        if (results.isNotEmpty) {
          double? dist;

          if ((deviceInfo.deviceLat != null) &&
              (deviceInfo.deviceLon != null)) {
            dist = Geolocator.distanceBetween(
              deviceInfo.deviceLat!,
              deviceInfo.deviceLon!,
              results[0]['cityLat'],
              results[0]['cityLon'],
            );
          }

          final KennelsModel kennelItem = tableModel.kennelsTableHelper.fromMap(
            results[0],
          );

          HasherKennelMapModel? hkmItem;

          if (results[0]['hkmId'] != null) {
            hkmItem = tableModel.hasherKennelMapTableHelper.fromMap(results[0]);
          }

          final KennelListQueryExtenstions extensionsItem =
              KennelListQueryExtenstions.fromMap(results[0]);
          extensionsItem.distToKennel = dist;
          extensionsItem.followingRequested = -1;
          extensionsItem.notificationsRequested = -1;
          extensionsItem.emailAlertRequested = -1;

          final KennelListAggregate kennel = KennelListAggregate(
            kennel: kennelItem,
            extensions: extensionsItem,
            hkm: hkmItem,
            isHomeKennel: isHomeKennel,
          );

          if (!mounted) return;
          await Navigator.of(context).push<dynamic>(
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) =>
                  KennelAdminMainPage(kennelAggregateItem: kennel),
            ),
          );
        }
      },
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: <Widget>[
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
        ],
      ),
    );
  }

  static int heroCounter = 0;
  static List<String> colors = <String>[
    'red',
    'orange',
    'yellow',
    'green',
    'teal',
    'baby_blue',
    'blue',
    'purple',
    'pink',
  ];

  String _getPin(
    DateTime eventStartDatetimeGmt,
    int? rsvpState,
    int? attendenceState,
    int? isHare,
    int kennelPinColor,
    int? eventScope,
    int? isCountedRun,
  ) {
    String pinFileName =
        'images/map_pins/${colors[kennelPinColor]}/past_run_no_rsvp.png';

    String isEvent = 'run';

    if (isCountedRun == 0) {
      isEvent = 'activity';
    }
    if ((eventScope ?? 0) > 1) {
      isEvent = 'event';
    }

    if (eventStartDatetimeGmt.isAfter(DateTime.now())) {
      // run is in the future
      if (((attendenceState ?? 0) >= attendenceAtHash.value) ||
          ((rsvpState ?? 0) >= rsvpYes.value)) {
        if (isHare != 0) {
          pinFileName =
              'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_hare.png';
        } else {
          pinFileName =
              'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_yes.png';
        }
      } else {
        pinFileName =
            'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_none.png';
      }
    } else {
      // run is in the past
      if ((attendenceState ?? 0) >= attendenceAtHash.value) {
        if (isHare != 0) {
          pinFileName =
              'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_hare.png';
        } else {
          pinFileName =
              'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_yes.png';
        }
      } else {
        pinFileName =
            'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_none.png';
      }
    }

    ////print(pinFileName);
    return pinFileName;
  }

  Widget _runLocationsBody() {
    return Column(
      children: <Widget>[
        _showFilters == false ? const SizedBox(height: 0.0) : _searchBar(),
        Expanded(
          child: ConnectedWidget(
            refreshFunction: () {
              setState(() {});
            },
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
            child:
                //decoration: Backgrounds.defaultHcBackground(),
                Stack(
                  children: <Widget>[
                    FlutterMap(
                      mapController: _mapController,

                      options: MapOptions(
                        onMapEvent: (MapEvent mapEvent) {
                          // Listen for movement events
                          if (mapEvent is MapEventMoveEnd) {
                            _updateMapLocationForRunList();
                          }
                        },

                        interactionOptions: InteractionOptions(
                          flags: (_trueNorthLock
                              ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                              : InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag |
                                    InteractiveFlag.rotate),
                        ),
                        initialCenter:
                            ((_mapCenterOption ==
                                    centerOnCurrentLocation.value) &&
                                (deviceInfo.deviceLat != null) &&
                                (deviceInfo.deviceLon != null))
                            ? latlng.LatLng(
                                deviceInfo.deviceLat!,
                                deviceInfo.deviceLon!,
                              )
                            : ((_mapCenterOption == centerOnHomeKennel.value) &&
                                  (_homeKennelLat != null) &&
                                  (_homeKennelLat != null))
                            ? latlng.LatLng(_homeKennelLat!, _homeKennelLon!)
                            : ((widget.kennel != null) &&
                                  (widget.kennel!.kennelLatitude != null) &&
                                  (widget.kennel!.kennelLongitude != null))
                            ? latlng.LatLng(
                                widget.kennel!.kennelLatitude!,
                                widget.kennel!.kennelLongitude!,
                              )
                            : latlng.LatLng(
                                deviceInfo.deviceLat ?? DEFAULT_LATITUDE,
                                deviceInfo.deviceLon ?? DEFAULT_LONGITUDE,
                              ),

                        initialZoom: 10.0,
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
                          subdomains: const <String>[
                            'mt0',
                            'mt1',
                            'mt2',
                            'mt3',
                          ],
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
                            // fitBoundsOptions: const FitBoundsOptions(
                            //   padding: EdgeInsets.all(50),
                            // ),
                            markers: _showKennels == true
                                ? _kennelMarkers
                                : <Marker>[],
                            polygonOptions: const PolygonOptions(
                              borderColor: Colors.blueAccent,
                              color: Colors.black12,
                              borderStrokeWidth: 3,
                            ),
                            builder:
                                (BuildContext context, List<Marker> markers) {
                                  heroCounter++;
                                  return FloatingActionButton(
                                    backgroundColor: Colors.purple[600],
                                    onPressed: null,
                                    heroTag: 'btn_$heroCounter',
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
                            // fitBoundsOptions: const FitBoundsOptions(
                            //   padding: EdgeInsets.all(50),
                            // ),
                            markers: _runLocationMarkers,
                            polygonOptions: const PolygonOptions(
                              borderColor: Colors.blueAccent,
                              color: Colors.black12,
                              borderStrokeWidth: 3,
                            ),
                            builder:
                                (BuildContext context, List<Marker> markers) {
                                  heroCounter++;
                                  return FloatingActionButton(
                                    backgroundColor: hc_blue,
                                    onPressed: null,
                                    heroTag: 'btn_$heroCounter',
                                    child: AutoSizeText(
                                      markers.length.toString(),
                                      maxLines: 1,
                                      style: ts_button,
                                    ),
                                  );
                                },
                          ),
                        ),

                        // MarkerLayerOptions(
                        //   markers: <Marker>[for (MapMarker item in runLocations) mapMarker(item)],
                        // )
                      ],
                    ),
                    if ((appModel.hasLocationPermissions) &&
                        (deviceInfo.deviceLat != null) &&
                        (deviceInfo.deviceLon != null)) ...<Widget>[
                      Positioned(
                        left: 10.0,
                        top: 74.0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mapController.move(
                                latlng.LatLng(
                                  deviceInfo.deviceLat!,
                                  deviceInfo.deviceLon!,
                                ),
                                13.0,
                              );
                              _updateMapLocationForRunList();
                            });
                          },
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
                    Positioned(
                      left: 70.0,
                      top: 74.0,
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
                          child: Image.asset(
                            _trueNorthLock
                                ? 'images/other/set_map_to_true_north_lock.png'
                                : 'images/other/set_map_rotation_enabled.png',
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: -2.0,
                      top: 74.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13.0),
                        width: 135,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.only(
                              top: 0.0,
                              bottom: 0.0,
                            ),
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

                    Positioned(
                      left: 10.0,
                      right: 10.0,
                      top: 25.0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          border: Border.all(width: 2.0),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          _textDescription,
                          textAlign: TextAlign.center,
                          style: ts_headingBlack,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: widget.kennel == null
          ? _runLocationsBody()
          : AppScaffold(
              floatingActionButton: getMapFab(),
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
                title: Text('Explore Runs', style: ts_appBarTitle),
              ),
              body: _runLocationsBody(),
            ),
    );
  }

  void _updateMapLocationForRunList() {
    final camera = _mapController.camera;

    if (Get.isRegistered<FutureRunListPageController>()) {
      final ctrl = Get.find<FutureRunListPageController>();
      ctrl.mapBounds = camera.visibleBounds;
    }
  }
}
