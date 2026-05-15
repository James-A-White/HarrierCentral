import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

class RunAndKennelMapController extends GetxController {
  RunAndKennelMapController({this.kennel});

  final KennelsModel? kennel;

  // ---------------------------------------------------------------------------
  // Map controller
  // ---------------------------------------------------------------------------
  final MapController mapController = MapController();

  // ---------------------------------------------------------------------------
  // Text / focus for the search bar
  // ---------------------------------------------------------------------------
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------
  final viewMode = RunLocationsViewMode.recent.obs;
  final mapCenterOption = centerOnCurrentLocation.value.obs;
  final homeKennelLat = RxnDouble();
  final homeKennelLon = RxnDouble();
  final textDescription = 'Showing recent runs'.obs;
  final showFilters = false.obs;
  final showKennels = true.obs;
  final trueNorthLock = true.obs;
  final searchText = ''.obs;

  // Marker lists — plain lists kept in sync; UI uses Obx via markersVersion
  final markersVersion = 0.obs; // bump to trigger Obx rebuild

  List<Marker> runLocationMarkers = <Marker>[];
  List<Marker> kennelMarkers = <Marker>[];

  // Raw data
  List<RunDetailsAggregate> _allRuns = <RunDetailsAggregate>[];
  List<RunDetailsAggregate> _preFilteredRuns = <RunDetailsAggregate>[];
  List<dynamic> _filteredRuns = <dynamic>[];
  List<Map<String, dynamic>> _allKennels = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredKennels = <Map<String, dynamic>>[];

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  static const double kennelPinSize = 100.0;
  static int heroCounter = 0;
  static const List<String> colors = <String>[
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

  // DataChangeService subscription
  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  // ---------------------------------------------------------------------------
  // Computed initial center (called once before onInit finishes so the map
  // widget can use it as initialCenter)
  // ---------------------------------------------------------------------------
  latlng.LatLng get initialMapCenter {
    final lat = homeKennelLat.value;
    final lon = homeKennelLon.value;
    if ((mapCenterOption.value == centerOnCurrentLocation.value) &&
        (deviceInfo.deviceLat != null) &&
        (deviceInfo.deviceLon != null)) {
      return latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!);
    }
    if ((mapCenterOption.value == centerOnHomeKennel.value) &&
        lat != null &&
        lon != null) {
      return latlng.LatLng(lat, lon);
    }
    if (kennel != null &&
        kennel!.kennelLatitude != null &&
        kennel!.kennelLongitude != null) {
      return latlng.LatLng(kennel!.kennelLatitude!, kennel!.kennelLongitude!);
    }
    return latlng.LatLng(
      deviceInfo.deviceLat ?? DEFAULT_LATITUDE,
      deviceInfo.deviceLon ?? DEFAULT_LONGITUDE,
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // Load persisted preferences synchronously
    homeKennelLat.value = getDoublePref(NumPrefsEnum.homeKennelLat);
    homeKennelLon.value = getDoublePref(NumPrefsEnum.homeKennelLon);
    showFilters.value = (getIntPref(IntPrefsEnum.mapShowSearchBar) ?? 0) != 0;
    showKennels.value = (getIntPref(IntPrefsEnum.mapShowKennels) ?? 1) != 0;
    mapCenterOption.value =
        getIntPref(IntPrefsEnum.mapCenterOption) ??
        centerOnCurrentLocation.value;

    // Prime FutureRunListPageController with initial camera bounds
    final camera = MapCamera(
      crs: Epsg3857(),
      center: initialMapCenter,
      zoom: 10.0,
      rotation: 0.0,
      nonRotatedSize: Size(Get.width, Get.height),
    );
    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().mapBounds = camera.visibleBounds;
    }

    // Subscribe to data-change events
    if (Get.isRegistered<DataChangeService>()) {
      _dataChangeSub = Get.find<DataChangeService>().stream.listen((event) {
        if (event.type == DataChangeType.runUpdated ||
            event.type == DataChangeType.runCreated) {
          unawaited(_loadEvents());
        }
      });
    }

    unawaited(_initAsync());
  }

  Future<void> _initAsync() async {
    if (getIntPref(IntPrefsEnum.mapCenterOption) == null) {
      mapCenterOption.value = centerOnCurrentLocation.value;
      await setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption.value);
    }

    await _loadEvents();
    await _loadKennels();
    _bumpMarkers();
  }

  @override
  void onClose() {
    unawaited(_dataChangeSub?.cancel());
    searchController.dispose();
    searchFocusNode.dispose();
    mapController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Marker rebuild helper
  // ---------------------------------------------------------------------------
  void _bumpMarkers() {
    markersVersion.value++;
  }

  // ---------------------------------------------------------------------------
  // View-mode selection (speed dial callbacks)
  // ---------------------------------------------------------------------------
  Future<void> selectViewModeAll() async {
    textDescription.value = 'Showing all runs';
    viewMode.value = RunLocationsViewMode.all;
    await _loadEvents();
    _bumpMarkers();
  }

  Future<void> selectViewModeRecent() async {
    textDescription.value = 'Showing runs in last 90 days';
    viewMode.value = RunLocationsViewMode.recent;
    await _loadEvents();
    _bumpMarkers();
  }

  Future<void> selectViewModePast() async {
    textDescription.value = 'Showing all past runs';
    viewMode.value = RunLocationsViewMode.past;
    await _loadEvents();
    _bumpMarkers();
  }

  Future<void> selectViewModeMyRuns() async {
    textDescription.value = 'Showing runs you\'ve been at';
    viewMode.value = RunLocationsViewMode.myRuns;
    await _loadEvents();
    _bumpMarkers();
  }

  // ---------------------------------------------------------------------------
  // Map center option toggle
  // ---------------------------------------------------------------------------
  Future<void> toggleMapCenter() async {
    if (mapCenterOption.value == centerOnCurrentLocation.value) {
      mapCenterOption.value = centerOnHomeKennel.value;
      await setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption.value);

      final lat = homeKennelLat.value;
      final lon = homeKennelLon.value;
      if (lat != null && lon != null) {
        mapController.move(
          latlng.LatLng(lat, lon),
          mapController.camera.zoom,
        );
      } else if (deviceInfo.deviceLat != null && deviceInfo.deviceLon != null) {
        mapController.move(
          latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!),
          mapController.camera.zoom,
        );
      }

      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
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
      mapCenterOption.value = centerOnCurrentLocation.value;
      await setIntPref(IntPrefsEnum.mapCenterOption, mapCenterOption.value);

      if (deviceInfo.deviceLat != null && deviceInfo.deviceLon != null) {
        mapController.move(
          latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!),
          mapController.camera.zoom,
        );
      }

      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
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
  }

  // ---------------------------------------------------------------------------
  // Show/hide search bar
  // ---------------------------------------------------------------------------
  Future<void> toggleSearchBar() async {
    showFilters.value = !showFilters.value;
    if (!showFilters.value) {
      searchController.text = '';
      searchText.value = '';
    }
    await setIntPref(
      IntPrefsEnum.mapShowSearchBar,
      showFilters.value ? 1 : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Show/hide kennels
  // ---------------------------------------------------------------------------
  Future<void> toggleShowKennels() async {
    showKennels.value = !showKennels.value;
    await setIntPref(
      IntPrefsEnum.mapShowKennels,
      showKennels.value ? 1 : 0,
    );
    _bumpMarkers();
  }

  // ---------------------------------------------------------------------------
  // True-north lock
  // ---------------------------------------------------------------------------
  void toggleTrueNorthLock() {
    trueNorthLock.value = !trueNorthLock.value;
    if (trueNorthLock.value) {
      mapController.rotate(0.0);
    }
  }

  // ---------------------------------------------------------------------------
  // Search text changed
  // ---------------------------------------------------------------------------
  void onSearchTextChanged(String text) {
    searchText.value = text;
    _filterRuns(true);
    _filterKennels();
    _bumpMarkers();
  }

  void clearSearch() {
    searchController.text = '';
    searchText.value = '';
    _filterRuns(true);
    _filterKennels();
    _bumpMarkers();
  }

  // ---------------------------------------------------------------------------
  // MapEventMoveEnd handler
  // ---------------------------------------------------------------------------
  void onMapMoveEnd(LatLngBounds bounds) {
    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().mapBounds = bounds;
    }
  }

  // ---------------------------------------------------------------------------
  // Center-on-location button
  // ---------------------------------------------------------------------------
  void centerOnCurrentDevice() {
    if (deviceInfo.deviceLat != null && deviceInfo.deviceLon != null) {
      mapController.move(
        latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!),
        13.0,
      );
      onMapMoveEnd(mapController.camera.visibleBounds);
    }
  }

  // ---------------------------------------------------------------------------
  // Run marker tap
  // ---------------------------------------------------------------------------
  Future<void> onRunMarkerTap(String eventId) async {
    final RunDetailsAggregate? run =
        await tableModel.eventsService.getSingleRun(eventId);
    if (run == null) return;
    if (navigatorKey.currentContext == null) return;
    await Navigator.push<dynamic>(
      navigatorKey.currentContext!,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => RunDetailsPage(futureRun: run),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kennel marker tap
  // ---------------------------------------------------------------------------
  Future<void> onKennelMarkerTap(String kennelId) async {
    final bool isHomeKennel =
        kennelId.toLowerCase() ==
        getStringPref(StringPrefsEnum.homeKennelId)?.toLowerCase();

    final String hasherId = getStringPref(StringPrefsEnum.userId)!;
    final List<Map<String, dynamic>> results =
        await QueryKennels.queryKennels(
          EnumKennelQueryType.singleKennel,
          EnumKennelQueryContext.user,
          hasherId: hasherId,
          kennelId: kennelId,
        );

    if (results.isEmpty) return;

    double? dist;
    if (deviceInfo.deviceLat != null && deviceInfo.deviceLon != null) {
      dist = Geolocator.distanceBetween(
        deviceInfo.deviceLat!,
        deviceInfo.deviceLon!,
        results[0]['cityLat'],
        results[0]['cityLon'],
      );
    }

    final KennelsModel kennelItem =
        tableModel.kennelsTableHelper.fromMap(results[0]);

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

    final KennelListAggregate kennelAggregate = KennelListAggregate(
      kennel: kennelItem,
      extensions: extensionsItem,
      hkm: hkmItem,
      isHomeKennel: isHomeKennel,
    );

    if (navigatorKey.currentContext == null) return;
    await Navigator.of(navigatorKey.currentContext!).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) =>
            KennelAdminMainPage(kennelAggregateItem: kennelAggregate),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Load events from local DB
  // ---------------------------------------------------------------------------
  Future<void> _loadEvents() async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    String query = '''
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

    if (kennel != null && kennel!.kennelId.isNotEmpty) {
      query =
          '''$query AND evt.${tableModel.eventsTableHelper.colKennelId} = "${kennel!.kennelId}"
      ''';
    }

    query =
        '''$query ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime}
    ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      _allRuns = <RunDetailsAggregate>[];
      runLocationMarkers = <Marker>[];

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          final double? lat = (results[i]['lat'] as num?)?.toDouble();
          final double? lon = (results[i]['lon'] as num?)?.toDouble();

          if (lat != null && lon != null) {
            if (lat <= 90.0 && lat >= -90.0 && lon <= 180.0 && lon >= -180.0) {
              final EventModel em = EventModel.fromJson(results[i]);
              final DateTime dt = DateTime.parse(
                results[i]['eventStartDatetime'].substring(0, 19),
              );
              final diff = em.eventStartDatetimeGmt.difference(
                DateTime.now().toUtc(),
              );

              final RunDetailsAggregate item = RunDetailsAggregate(
                event: em,
                extensions: RunQueryExtensionsModel(
                  latitude: lat,
                  longitude: lon,
                  evtLat: lat,
                  evtLon: lon,
                  showAsFutureEvent: diff >= const Duration(hours: 4) ? 1 : 0,
                  showAsPastEvent: diff <= const Duration(hours: 4) ? 1 : 0,
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
    } catch (e) {
      // ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Filter runs
  // ---------------------------------------------------------------------------
  void _filterRuns(bool searchTextChanged) {
    if (!searchTextChanged || _preFilteredRuns.isEmpty) {
      _preFilteredRuns = QueryRuns.doRunsFilter(
        _allRuns,
        RunsToDisplay.allRuns,
        RunsTimeScope.all,
      );
    }

    _filteredRuns = QueryRuns.doRunsSearchTextFilter(
      searchText.value,
      _preFilteredRuns,
    );

    _buildRunMarkers();
  }

  void _buildRunMarkers() {
    runLocationMarkers = <Marker>[];

    for (int i = 0; i < _filteredRuns.length; i++) {
      final RunDetailsAggregate run = _filteredRuns[i];

      if (run.extensions.evtLat == null || run.extensions.evtLon == null) {
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
        point: ll,
        child: Opacity(
          opacity: dt.isBefore(DateTime.now()) ? 0.66 : 1.0,
          child: _buildRunMarkerWidget(
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

      final RunLocationsViewMode mode = viewMode.value;
      if ((mode == RunLocationsViewMode.all) ||
          (mode == RunLocationsViewMode.past && dt.isBefore(DateTime.now())) ||
          (mode == RunLocationsViewMode.recent &&
              dt.isAfter(
                DateTime.now().subtract(const Duration(days: 90)),
              )) ||
          (mode == RunLocationsViewMode.myRuns &&
              (run.extensions.attendenceState) >= attendenceAtHash.value)) {
        runLocationMarkers.add(marker);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Load kennels from local DB
  // ---------------------------------------------------------------------------
  Future<void> _loadKennels() async {
    String query = '''
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

    if (kennel != null && kennel!.kennelId.isNotEmpty) {
      query =
          '''$query WHERE k.${tableModel.kennelsTableHelper.colKennelId} = "${kennel!.kennelId}"''';
    }

    _allKennels = await database.rawQuery(query);
    _filterKennels();
    _buildKennelMarkers();
  }

  // ---------------------------------------------------------------------------
  // Filter kennels
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> _doKennelFilter(String searchKennelsText) {
    _filteredKennels = <Map<String, dynamic>>[];
    if (_allKennels.isNotEmpty) {
      if (searchKennelsText.isNotEmpty) {
        final List<String> searchItems =
            searchKennelsText.trim().toLowerCase().split(',');
        _filteredKennels.addAll(_allKennels);
        for (String st in searchItems) {
          if (st.trim().isEmpty) continue;
          bool negate = false;
          String term = st;
          if (term.trim().toLowerCase().startsWith('not ')) {
            negate = true;
            term = term.substring(4);
          }
          final List<String> orItems = term.split('+');

          _filteredKennels = _filteredKennels
              .where((Map<String, dynamic> a) {
                for (String orItem in orItems) {
                  if (orItem.trim().isEmpty) continue;
                  final String needle = ' ${orItem.trim().toLowerCase()}';
                  final String haystack = a['searchKennelsText'].toLowerCase();
                  if (haystack.contains(needle) ||
                      removeDiacritics(haystack).contains(needle)) {
                    return !negate;
                  }
                }
                return negate;
              })
              .toList();
        }
      } else {
        _filteredKennels.addAll(_allKennels);
      }
    }
    return _filteredKennels;
  }

  void _filterKennels() {
    _filteredKennels = _doKennelFilter(searchText.value);
    _buildKennelMarkers();
  }

  void _buildKennelMarkers() {
    try {
      kennelMarkers = <Marker>[];

      final String? homeKennelId =
          getStringPref(StringPrefsEnum.homeKennelId)?.toLowerCase();

      if (_filteredKennels.isNotEmpty) {
        for (int i = 0; i < _filteredKennels.length; i++) {
          final double? lat =
              (_filteredKennels[i]['lat'] as num?)?.toDouble();
          final double? lon =
              (_filteredKennels[i]['lon'] as num?)?.toDouble();

          if (lat == null || lon == null) continue;

          final String kId = _filteredKennels[i]['kennelId'] as String;
          if (kId == homeKennelId) {
            homeKennelLat.value = lat;
            homeKennelLon.value = lon;

            if (mapCenterOption.value == centerOnHomeKennel.value) {
              mapController.move(
                latlng.LatLng(lat, lon),
                mapController.camera.zoom,
              );
            }
          }

          if (lat <= 90.0 && lat >= -90.0 && lon <= 180.0 && lon >= -180.0) {
            final latlng.LatLng ll = latlng.LatLng(lat, lon);
            final Marker marker = Marker(
              width: kennelPinSize,
              height: kennelPinSize,
              point: ll,
              child: _buildKennelMarkerWidget(
                _filteredKennels[i]['logo'] as String,
                _filteredKennels[i]['shortName'] as String,
                kId,
              ),
            );
            kennelMarkers.add(marker);
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Marker widget builders (pure widget factories — no setState needed)
  // ---------------------------------------------------------------------------
  Widget _buildRunMarkerWidget(
    String eventId,
    DateTime eventStartDatetimeGmt,
    String eventName, {
    int? attendenceState,
    int? rsvpState,
    int? isHare,
    required int kennelPinColor,
    int? eventScope,
    int? isCountedRun,
  }) {
    return GestureDetector(
      onTap: () => unawaited(onRunMarkerTap(eventId)),
      child: Image.asset(
        _getPin(
          eventStartDatetimeGmt,
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

  Widget _buildKennelMarkerWidget(
    String kennelLogo,
    String kennelShortName,
    String kennelId,
  ) {
    return GestureDetector(
      onTap: () => unawaited(onKennelMarkerTap(kennelId)),
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: <Widget>[
          Image.asset('images/icons/grey_square_pin.png'),
          Positioned(
            top: kennelPinSize / 13.3333333,
            child: KennelLogo(
              kennelId: kennelId,
              kennelLogoUrl: kennelLogo,
              kennelShortName: kennelShortName,
              logoHeight: kennelPinSize / 2.0,
              leftPadding: 0.0,
              zoomGesture: KennelLogoZoomGesture.none,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pin selector
  // ---------------------------------------------------------------------------
  String _getPin(
    DateTime eventStartDatetimeGmt,
    int? rsvpState,
    int? attendenceState,
    int? isHare,
    int kennelPinColor,
    int? eventScope,
    int? isCountedRun,
  ) {
    String isEvent = 'run';
    if (isCountedRun == 0) isEvent = 'activity';
    if ((eventScope ?? 0) > 1) isEvent = 'event';

    if (eventStartDatetimeGmt.isAfter(DateTime.now())) {
      if (((attendenceState ?? 0) >= attendenceAtHash.value) ||
          ((rsvpState ?? 0) >= rsvpYes.value)) {
        if (isHare != 0) {
          return 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_hare.png';
        } else {
          return 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_yes.png';
        }
      } else {
        return 'images/map_pins/${colors[kennelPinColor]}/future_${isEvent}_rsvp_none.png';
      }
    } else {
      if ((attendenceState ?? 0) >= attendenceAtHash.value) {
        if (isHare != 0) {
          return 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_hare.png';
        } else {
          return 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_yes.png';
        }
      } else {
        return 'images/map_pins/${colors[kennelPinColor]}/past_${isEvent}_rsvp_none.png';
      }
    }
  }
}
