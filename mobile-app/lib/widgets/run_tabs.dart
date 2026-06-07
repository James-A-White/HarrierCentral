// import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

import 'package:harrier_central/widgets/run_photo_gallery.dart';
import 'package:badges/badges.dart' as badges;
import 'package:eventide/eventide.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/export/gpx_export_service.dart';
import 'package:harrier_central/widgets/beta_ribbon.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

// import 'package:manage_calendar_events/manage_calendar_events.dart' as calendar;

/// Chat tabs with their corresponding integer IDs.
enum RunTab {
  details(0),
  rsvp(1),
  map(2),
  stats(3),
  chat(4),
  photos(5);

  /// The integer ID associated with this tab.
  final int id;

  const RunTab(this.id);

  /// Lookup a ChatTab by its [id]. Throws if not found.
  factory RunTab.fromId(int id) {
    return RunTab.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No ChatTab with id $id'),
    );
  }
}

class RunTabs extends StatefulWidget {
  const RunTabs({
    super.key,
    required this.futureRun,
    required this.relayActiveTab,
    this.openToTab = RunTab.details,
  });

  final RunDetailsAggregate futureRun;
  final RunTab openToTab;
  final Function relayActiveTab;

  @override
  State<RunTabs> createState() {
    return RunTabsState();
  }
}

class PackListAggregate {
  PackListAggregate({
    required this.hem,
    required this.hasher,
    required this.displayName,
    this.homeKennelName,
  });

  final HasherEventMapModel hem;
  final HashersModel hasher;
  final String displayName;
  final String? homeKennelName;
}

class RunTabsState extends State<RunTabs> with TickerProviderStateMixin {
  static const String LABEL_DETAILS = 'Details';
  static const String LABEL_MAP = 'Map';
  static const String LABEL_RSVP = 'RSVP';
  static const String LABEL_STATS = 'Stats';
  static const String LABEL_CHAT = 'Chat';
  static const String LABEL_PHOTOS = 'Photos';

  final LiveRunService _liveRunService = LiveRunService.ensure();
  LiveRunButtonStatus _liveRunStatus = LiveRunButtonStatus.hidden;
  bool _liveRunLoading = false;

  final List<Tab> _tabs = <Tab>[
    const Tab(text: LABEL_DETAILS),
    const Tab(text: LABEL_RSVP),
    const Tab(text: LABEL_MAP),
    const Tab(text: LABEL_STATS),
    const Tab(text: LABEL_CHAT),
    const Tab(text: LABEL_PHOTOS),
  ];

  //GlobalKey packListBox = GlobalKey();

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _saveUserMapPreference = ValueNotifier<bool>(false);

  bool isAdmin = false;
  //bool _isLoading = true;

  latlng.LatLng _mapCenter = latlng.LatLng(
    deviceInfo.deviceLat ?? DEFAULT_LATITUDE,
    deviceInfo.deviceLon ?? DEFAULT_LONGITUDE,
  );

  bool _trueNorthLock = true;
  bool _isExportingTrack = false;

  Future<List<PackListAggregate>?> _thePackList =
      Future<List<PackListAggregate>?>.value(null);

  Map<String, dynamic> _packCount = <String, dynamic>{};

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setStateIfMounted(fn);
  }

  Future<void> _refreshHemTableFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      _safeSetState(() {
        //_isLoading = true;
      });
    }

    if (isAdmin) {
      await tableModel.syncEventAdminService.updateFromBackend(
        EnumDataTables.hasherEventMap.flag,
        true,
        widget.futureRun.event.eventId,
      );
    } else {
      await tableModel.syncEventAdminService.updateRsvpsFromBackend(
        widget.futureRun.event.eventId,
      );
    }
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Pack member data synchronized $resultStr');

    final Future<List<PackListAggregate>> packListFuture =
        _refreshPackListFromTable();
    _thePackList = packListFuture;
    await packListFuture;
    await _refreshPackCountFromTable(true);
  }

  int _thisUserIndex = -1;

  Future<List<PackListAggregate>> _refreshPackListFromTable() async {
    List<PackListAggregate> pla = <PackListAggregate>[];

    final String query =
        '''
        SELECT
          hem.*,
          h.*,
          ken.${tableModel.kennelsTableHelper.colKennelName} as kennelName
          FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
          LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} h on h.${tableModel.hashersTableHelper.colHasherId} = hem.${tableModel.hasherEventMapTableHelper.colUserId}
          LEFT OUTER JOIN ${EnumDataTables.kennels.commonTableName} ken on h.${tableModel.hashersTableHelper.colHomeKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
          WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = "${widget.futureRun.event.eventId}"
          AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final HasherEventMapModel packItem = tableModel
            .hasherEventMapTableHelper
            .fromMap(results[i]);

        final HashersModel hasherItem = HashersModel.fromJson(results[i]);
        String displayName = hasherItem.dispName;
        if (packItem.virginVisitorType != 0) {
          displayName = packItem.displayName ?? 'Virgin / Visitor';
        }

        pla.add(
          PackListAggregate(
            hem: packItem,
            hasher: hasherItem,
            displayName: displayName,
            homeKennelName: results[i]['kennelName'] as String?,
          ),
        );
        //}
      }
    } catch (e, s) {
      BootLogger.logError('[RunTabs._refreshPackListFromTable] eventId=${widget.futureRun.event.eventId}', e, s);
    }

    pla.sort(
      (PackListAggregate a, PackListAggregate b) =>
          (a.hem.hemKennelHashName ?? a.displayName).compareTo(
            b.hem.hemKennelHashName ?? b.displayName,
          ),
    );

    _thisUserIndex = -1;

    for (int i = 0; i < pla.length; i++) {
      if (pla[i].hasher.hasherId == _userId) {
        _thisUserIndex = i;
        break;
      }
    }

    return pla;
  }

  Future<void> _refreshPackCountFromTable(bool callSetState) async {
    _packCount = <String, dynamic>{};

    final String query =
        '''
        SELECT
          count(case when hem.rsvpState = 3 then 1 else null end) as rsvpYesCount,
          count(case when hem.rsvpState = 2 then 1 else null end) as rsvpMaybeCount,
          count(case when hem.rsvpState = 1 then 1 else null end) as rsvpNoCount,
          count(case when hem.isHare = 1 then 1 else null end) as isHareCount
          FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
          WHERE hem.eventId = "${widget.futureRun.event.eventId}"
          AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      if (results.isNotEmpty) {
        _packCount = results[0];
      }
      if (callSetState) {
        _safeSetState(() {});
      }
    } catch (e, s) {
      BootLogger.logError('[RunTabs._refreshPackCountFromTable] eventId=${widget.futureRun.event.eventId}', e, s);
    }
  }

  late TabController _tabController;
  late TabController _gridListTabController;
  bool _isTabControllerReady = false;

  //final GetPackService _getPackService = GetPackService();

  final String _userId = currentUserId;

  //int _currentTabIndex = -1;

  bool _showTopWidget = true;
  bool _slideTopWidget = false;

  static int DISPLAY_LOGO_IN_RSVP_DURATION = 15;

  @override
  void initState() {
    super.initState();

    isAdmin = AppAccess(widget.futureRun.extensions.appAccessFlags).isAdmin;

    //print('Current time in GMT: ${DateTime.now().toUtc().toString()}');
    unawaited(_refreshLiveRunButton());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _safeSetState(() {
        _tabController = TabController(vsync: this, length: _tabs.length);
        _gridListTabController = TabController(vsync: this, length: 2);
        _isTabControllerReady = true;

        if (widget.openToTab != RunTab.details) {
          // switch to the chat tab if a notification was tapped to open the app
          _tabController.animateTo(widget.openToTab.id);
        }

        // else if ((widget.futureRun.extensions.rsvpState == 0) &&
        //     (widget.futureRun.event.eventStartDatetime.isAfter(
        //       DateTime.now().subtract(const Duration(hours: 6)),
        //     )) &&
        //     ((widget.futureRun.extensions.distToEvent ?? 9999999.0) < 250000)) {
        //   _tabController.animateTo(1);
        // }

        _tabController.addListener(() async {
          if (!mounted) return;

          FocusScope.of(context).unfocus();

          if (_fabIsVisible !=
              (_tabs[_tabController.index].text == LABEL_RSVP)) {
            _fabIsVisible = _tabs[_tabController.index].text == LABEL_RSVP;
          }

          if (_tabs[_tabController.index].text == LABEL_RSVP) {
            await _refreshHemTableFromBackend(false);
            if (!mounted) return;

            _showTopWidget = true;
            _slideTopWidget = false;
            _safeSetState(() {});

            await Future.delayed(
              Duration(seconds: DISPLAY_LOGO_IN_RSVP_DURATION),
            );
            if (!mounted) return;

            _showTopWidget = false;

            _safeSetState(() {});
            //print('refreshing RSVP data from backend @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          }
          if (_tabs[_tabController.index].text == LABEL_CHAT) {
            _showTopWidget = true;
            _slideTopWidget = false;
            _safeSetState(() {});
            unawaited(
              Future.delayed(
                Duration(seconds: DISPLAY_LOGO_IN_RSVP_DURATION),
              ).then((_) {
                if (!mounted) return;

                _showTopWidget = false;
                _safeSetState(() {});
              }),
            );
          }

          if ((_tabController.previousIndex == 4) ||
              (_tabController.index == 4)) {
            if (Get.isRegistered<NotificationService>()) {
              final controller = Get.find<NotificationService>();
              await controller.markEventMessagesAsViewed(
                widget.futureRun.event.publicEventId,
              );
            }
          }

          if (!mounted) return;
          widget.relayActiveTab(_tabController.index);

          _safeSetState(() {});
        });
      });
    });

    // _tabController = TabController(vsync: this, length: _tabs.length);
    // _gridListTabController = TabController(vsync: this, length: 2);

    final List<double?> coords = Utilities.getLatLongFromString(<String?>[
      widget.futureRun.event.locationOneLineDesc,
      widget.futureRun.event.eventDescription,
      widget.futureRun.event.eventName,
    ]);

    double xLat =
        widget.futureRun.extensions.evtLat ??
        coords[0] ??
        widget.futureRun.kennel.kennelLatitude ??
        deviceInfo.deviceLon ??
        DEFAULT_LATITUDE;

    double xLon =
        widget.futureRun.extensions.evtLon ??
        coords[1] ??
        widget.futureRun.kennel.kennelLongitude ??
        deviceInfo.deviceLon ??
        DEFAULT_LONGITUDE;

    _mapCenter = latlng.LatLng(xLat, xLon);
    _saveUserMapPreference.addListener(() {
      _safeSetState(() {});
    });

    // Future.delayed(const Duration(seconds: 7)).then((value) {
    //   setStateIfMounted(() {
    //     _showTopWidget = false;
    //   });
    // });
  }

  Future<void> _clearEventTables() async {
    for (final table in EnumDataTables.values.where((t) => t.hasEventTable)) {
      final helper = table.helperFrom(tableModel);
      await tableModel.baseService.clearTable(database, helper, table.eventTableName);
    }
    await setStringPref(StringPrefsEnum.adminEventId, '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gridListTabController.dispose();
    _saveUserMapPreference.dispose();

    //('run tabs disposedd');

    unawaited(_clearEventTables());
    unawaited(Get.delete<ChatPageController>());

    super.dispose();
  }

  int flexLeft = 27;
  int flexRight = 73;

  num spaceBetweenColumns = 11.0;
  num spaceBetweenRows = 23.0;

  Widget _buildRunDetailsView() {
    return RunDetails(
      widget.futureRun.event,
      widget.futureRun.kennel,
      widget.futureRun.extensions.digitsAfterDecimal,
      widget.futureRun.extensions.currencySymbol,
      widget.futureRun.extensions.distanceUnitsPref,
      widget.futureRun.extensions.distToEvent,
      widget.futureRun.paymentUrl,
      true,
      widget.futureRun.extensions.isMapAndDistanceValid == 1,
      eventUrlWithKennelBackup:
          widget.futureRun.event.eventUrl ??
          widget.futureRun.kennel.kennelEventsUrl,
      isMember: widget.futureRun.extensions.isMember,
      isPaid: widget.futureRun.extensions.isPaid,
      rsvpState: widget.futureRun.extensions.rsvpState,
      processPayment: (int r, int p) {
        widget.futureRun.extensions = widget.futureRun.extensions.copyWith(
          rsvpState: r,
          isPaid: p != -1 ? p : widget.futureRun.extensions.isPaid,
        );
        setStateIfMounted(() {});
      },
    );
  }

  TextStyle rsvpTitlesView = ts_tileText.copyWith(
    fontSize: 20.0 * deviceInfo.deviceWidthScaleFactor,
    color: Colors.white,
  );

  EnumRsvpState _rsvpRequested = rsvpUnknown;

  Widget _buildRsvpView() {
    return FutureBuilder(
        future: _thePackList,
        builder: (BuildContext context, AsyncSnapshot<List<PackListAggregate>?> snapshot) {
          if ((!snapshot.hasData) || (snapshot.data == null)) {
            return const HcAppCircularProgressIndicator(key: Key('42223995'));
          } else {
            final List<PackListAggregate> packList =
                snapshot.data ?? <PackListAggregate>[];
            final PackListAggregate? currentUser =
                (_thisUserIndex >= 0 && _thisUserIndex < packList.length)
                ? packList[_thisUserIndex]
                : null;

            return Center(
              child: Column(
                //mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedSize(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: !_slideTopWidget
                        ? AnimatedOpacity(
                            opacity: _showTopWidget ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 400),
                            onEnd: () {
                              if (!mounted) return;

                              _safeSetState(() {
                                _slideTopWidget = true;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: 15,
                                left: 20,
                                bottom: 0,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      KennelLogo(
                                        kennelLogoUrl:
                                            widget.futureRun.kennel.kennelLogo,
                                        kennelShortName: widget
                                            .futureRun
                                            .kennel
                                            .kennelShortName,
                                        logoHeight: 70,
                                      ),
                                      SizedBox(width: 30),
                                      Expanded(
                                        child: _getRunDetails(Colors.white),
                                      ),
                                      SizedBox(width: 20),
                                    ],
                                  ),
                                  SizedBox(height: 25),
                                  FancyDivider(
                                    key: ValueKey('divider2342'),
                                    innerColor: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(),
                  ), // Collapses cleanly

                  StyleForConnected(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width / 5.5,
                          child: Column(
                            children: <Widget>[
                              Text('Going', style: rsvpTitlesView),
                              Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Positioned(
                                    // top: 6.5,
                                    // left: 6.5,
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(FontAwesome.check_circle),
                                    color: currentUser == null
                                        ? Colors.grey
                                        : currentUser.hem.rsvpState ==
                                              rsvpYes.value
                                        ? Colors.green
                                        : (currentUser.hem.rsvpState == -1 &&
                                              _rsvpRequested == rsvpYes)
                                        ? hc_blue
                                        : Colors.grey,
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 35.0,
                                    alignment: Alignment.topCenter,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () async {
                                      await _setRsvpState(rsvpYes);
                                    },
                                    // ),
                                    // Text(
                                    //   widget.futureRun.attendingEvent +
                                    //               widget.futureRun.haresCount >=
                                    //           0
                                    //       ? (widget.futureRun.attendingEvent +
                                    //               widget.futureRun.haresCount)
                                    //           .toString()
                                    //       : '',
                                    //   style: const TextStyle(
                                    //       fontFamily: 'AvenirNext',
                                    //       fontStyle: FontStyle.normal,
                                    //       fontSize: 20.0,
                                    //       height: 0.85),
                                  ),
                                ],
                              ),
                              Text(
                                (_packCount['rsvpYesCount'] ?? 0) >= 0
                                    ? (_packCount['rsvpYesCount'] ?? 0)
                                          .toString()
                                    : '',
                                style: rsvpTitlesView,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width / 5.5,
                          child: Column(
                            children: <Widget>[
                              Text(
                                //'Maybe: ' + (widget.futureRun.rsvpMaybeCount >= 0 ? widget.futureRun.rsvpMaybeCount.toString() : ''),
                                'Maybe',
                                style: rsvpTitlesView,
                              ),
                              Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Positioned(
                                    // top: 6.5,
                                    // left: 6.5,
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      FontAwesome.question_circle,
                                    ),
                                    color: currentUser == null
                                        ? Colors.grey
                                        : currentUser.hem.rsvpState ==
                                              rsvpMaybe.value
                                        ? Colors.orange
                                        : (currentUser.hem.rsvpState == -1 &&
                                              _rsvpRequested == rsvpMaybe)
                                        ? hc_blue
                                        : Colors.grey,
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 35.0,
                                    alignment: Alignment.topCenter,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () async {
                                      await _setRsvpState(rsvpMaybe);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                (_packCount['rsvpMaybeCount'] ?? 0) >= 0
                                    ? (_packCount['rsvpMaybeCount'] ?? 0)
                                          .toString()
                                    : '',
                                style: rsvpTitlesView,
                              ),
                              // Text(
                              //   widget.futureRun.maybeAttendingEvent >= 0
                              //       ? widget.futureRun.maybeAttendingEvent
                              //           .toString()
                              //       : '',
                              //   style: const TextStyle(
                              //       fontFamily: 'AvenirNext',
                              //       fontStyle: FontStyle.normal,
                              //       fontSize: 20.0,
                              //       height: 0.85),
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width / 5.5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                //'Not go: ' + (widget.futureRun.rsvpNoCount >= 0 ? widget.futureRun.rsvpNoCount.toString() : ''),
                                'Not go',
                                style: rsvpTitlesView,
                              ),
                              Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Positioned(
                                    // top: 6.5,
                                    // left: 6.5,
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(FontAwesome.times_circle),
                                    color: currentUser == null
                                        ? Colors.grey
                                        : currentUser.hem.rsvpState ==
                                              rsvpNo.value
                                        ? hc_red
                                        : (currentUser.hem.rsvpState == -1 &&
                                              _rsvpRequested == rsvpNo)
                                        ? hc_blue
                                        : Colors.grey,
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 35.0,
                                    alignment: Alignment.topCenter,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () async {
                                      await _setRsvpState(rsvpNo);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                (_packCount['rsvpNoCount'] ?? 0) >= 0
                                    ? (_packCount['rsvpNoCount'] ?? 0)
                                          .toString()
                                    : '',
                                style: rsvpTitlesView,
                              ),

                              // Text(
                              //   widget.futureRun.notAttendingEvent >= 0
                              //       ? widget.futureRun.notAttendingEvent
                              //           .toString()
                              //       : '',
                              //   style: const TextStyle(
                              //       fontFamily: 'AvenirNext',
                              //       fontStyle: FontStyle.normal,
                              //       fontSize: 20.0,
                              //       height: 0.85),
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width / 5.5,
                          child: Column(
                            children: <Widget>[
                              Text(
                                // 'Hares: ' + (widget.futureRun.haresCount >= 0 ? widget.futureRun.haresCount.toString() : ''),
                                'Hares',
                                style: rsvpTitlesView,
                              ),
                              Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Positioned(
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const ImageIcon(
                                      AssetImage('images/icons/hare_icon.png'),
                                    ),
                                    color: currentUser == null
                                        ? Colors.grey
                                        : currentUser.hem.isHare ==
                                              isHareYes.value
                                        ? Colors.deepPurple
                                        : currentUser.hem.isHare == -1
                                        ? hc_blue
                                        : Colors.grey,
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 30.0,
                                    alignment: Alignment.center,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () async {
                                      //await _setRsvpHare();
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                (_packCount['isHareCount'] ?? 0) >= 0
                                    ? (_packCount['isHareCount'] ?? 0)
                                          .toString()
                                    : '',
                                style: rsvpTitlesView,
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: !snapshot.hasData
                        ? const SizedBox(
                            //color: Colors.grey[300],
                            width: 70.0,
                            height: 70.0,
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Center(
                                child: HcAppCircularProgressIndicator(
                                  key: Key('22030392'),
                                ),
                              ),
                            ),
                          )
                        : ((snapshot.data!.isEmpty) &&
                              (widget.futureRun.event.eventStartDatetime
                                  .isAfter(
                                    DateTime.now().subtract(
                                      const Duration(hours: 6),
                                    ),
                                  )))
                        ? Column(
                            children: <Widget>[
                              const Expanded(flex: 40, child: SizedBox()),
                              Text(
                                'Be the first to RSVP\r\nfor this run!',
                                style: ts_headingVeryLarge,
                                textAlign: TextAlign.center,
                              ),
                              if (currentUser == null) ..._getRsvpButtons(),
                              if (currentUser == null) ...<Widget>[
                                const Expanded(flex: 40, child: SizedBox()),
                              ],
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              if ((currentUser == null) &&
                                  (widget.futureRun.event.eventStartDatetime
                                      .isAfter(
                                        DateTime.now().subtract(
                                          const Duration(hours: 6),
                                        ),
                                      )))
                                ..._getRsvpButtons(),
                              if (currentUser == null) ...<Widget>[
                                const SizedBox(height: 10),
                              ],
                              if ((currentUser != null) &&
                                  (currentUser.hem.rsvpState >=
                                      rsvpMaybe.value)) ...<Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    child: SizedBox(
                                      width: 230.0,
                                      height: 40.0,
                                      child: Row(
                                        children: <Widget>[
                                          Stack(
                                            alignment:
                                                AlignmentDirectional.center,
                                            children: <Widget>[
                                              Container(
                                                height: 24,
                                                width: 24,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 22.0,
                                                width: 22.0,
                                                child: Icon(
                                                  Icons.calendar_month,
                                                  size: 22.0,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 15.0),
                                          Text(
                                            'Add to calendar',
                                            style: ts_button,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onPressed: () async {
                                      // THIS IS A H@CK: strip the "Z" timezone character off of the time so it imports as local time and not GMT
                                      String url =
                                          '$BASE_HASHRUNS_DOT_ORG_URL${widget.futureRun.kennel.kennelUniqueShortName}/${widget.futureRun.event.eventNumber}';

                                      String startTime = widget
                                          .futureRun
                                          .event
                                          .eventStartDatetime
                                          .toString();
                                      startTime = startTime.substring(
                                        0,
                                        startTime.length - 1,
                                      );
                                      DateTime localTime = DateTime.tryParse(startTime) ?? DateTime.now();

                                      String? oneLineLocForDesc = widget
                                          .futureRun
                                          .event
                                          .locationOneLineDesc;

                                      String? oneLineLocForTitle;

                                      if ((oneLineLocForDesc != null) &&
                                          (oneLineLocForDesc.isNotEmpty)) {
                                        oneLineLocForTitle =
                                            ' @ $oneLineLocForDesc';
                                        oneLineLocForDesc =
                                            'Location: $oneLineLocForDesc\r\n\r\n';
                                      } else {
                                        oneLineLocForDesc = '';
                                        oneLineLocForTitle = '';
                                      }

                                      var eventide = Eventide();

                                      // Create an event in the default calendar (iOS write-only access)
                                      await eventide
                                          .createEventInDefaultCalendar(
                                            title:
                                                widget
                                                    .futureRun
                                                    .event
                                                    .eventName +
                                                oneLineLocForTitle,
                                            description:
                                                oneLineLocForDesc +
                                                (widget
                                                        .futureRun
                                                        .event
                                                        .eventDescription ??
                                                    ''),
                                            location: Utilities.buildMapLocation(
                                                widget.futureRun.event,
                                            ),
                                            startDate: localTime,
                                            endDate: localTime.add(
                                              Duration(hours: 4),
                                            ),
                                            url: url,
                                          );

                                      Get.closeAllSnackbars();

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.blue,
                                          content: Text(
                                            '${widget.futureRun.event.eventName}$oneLineLocForTitle has been added to your calendar',
                                          ),
                                        ),
                                      );

                                      // if (success) {

                                      // calendar.CalendarEvent
                                      // newEvent = calendar.CalendarEvent(
                                      //   title:
                                      //       widget.futureRun.event.eventName +
                                      //       oneLineLocForTitle,
                                      //   description:
                                      //       oneLineLocForDesc +
                                      //       (widget
                                      //               .futureRun
                                      //               .event
                                      //               .eventDescription ??
                                      //           ''),
                                      //   startDate: localTime,
                                      //   endDate: localTime.add(
                                      //     const Duration(hours: 4),
                                      //   ),
                                      //   location:
                                      //       widget
                                      //           .futureRun
                                      //           .extensions
                                      //           .userFriendlyLocation,
                                      //   url:
                                      //       'https://www.hashruns.org/#/RID?publicEventId=${widget.futureRun.event.publicEventId}&textTheme=light',
                                      // );

                                      // final calendar.CalendarPlugin
                                      // calendarPlugIn =
                                      //     calendar.CalendarPlugin();
                                      // var calendars =
                                      //     await calendarPlugIn.getCalendars();

                                      // if ((calendars?.isNotEmpty ?? false) &&
                                      //     (calendars![0].id != null)) {
                                      //   calendarPlugIn
                                      //       .createEvent(
                                      //         calendarId: calendars[0].id!,
                                      //         event: newEvent,
                                      //       )
                                      //       .then((evenId) {
                                      //         setStateIfMounted(() {
                                      //           debugPrint(
                                      //             'Event Id is: $evenId',
                                      //           );
                                      //         });
                                      //       });
                                      // }

                                      // Event event = Event(
                                      //   title:
                                      //       widget.futureRun.event.eventName +
                                      //       oneLineLocForTitle,
                                      //   description:
                                      //       oneLineLocForDesc +
                                      //       (widget
                                      //               .futureRun
                                      //               .event
                                      //               .eventDescription ??
                                      //           ''),
                                      //   location:
                                      //       widget
                                      //           .futureRun
                                      //           .extensions
                                      //           .userFriendlyLocation,
                                      //   startDate: localTime,
                                      //   endDate: localTime.add(
                                      //     const Duration(hours: 4),
                                      //   ),
                                      //   iosParams: IOSParams(
                                      //     reminder: const Duration(
                                      //       hours: 4,
                                      //     ), // on iOS, you can set alarm notification after your event.
                                      //     url:
                                      //         'https://www.hashruns.org/#/RID?publicEventId=${widget.futureRun.event.publicEventId}&textTheme=light', // on iOS, you can set url to your event.
                                      //   ),
                                      //   // androidParams: AndroidParams(
                                      //   //   emailInvites: [], // on Android, you can add invite emails to your event.
                                      //   // ),
                                      // );

                                      // PermissionStatus ps;

                                      // if (!await Permission.calendarFullAccess.isGranted) {
                                      //   ps = await Permission.calendarReadOnly.request();
                                      //   if (ps.isGranted) {
                                      //     ps = await Permission.calendarFullAccess.request();
                                      //   }
                                      // }

                                      // await Add2Calendar.addEvent2Cal(event);

                                      // bool success = await Add2Calendar.addEvent2Cal(event);

                                      // if (success) {
                                      //   await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'Calendar', '${widget.futureRun.event.eventName} has been added to your calendar', 'OK');
                                      // } else {
                                      //   await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'Calendar', '${widget.futureRun.event.eventName} was not added to your calendar', 'OK');
                                      // }
                                    },
                                  ),
                                ),
                              ],
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                width: 140.0,
                                // Reviewed for 2.0+
                                child: TabBar(
                                  onTap: (void _) {
                                    setStateIfMounted(() {});
                                  },
                                  isScrollable:
                                      true, // <-- required for labelPadding
                                  tabAlignment: TabAlignment
                                      .center, // Flutter 3.13+ to keep centered

                                  unselectedLabelColor: Colors.white,
                                  labelColor: Colors.white,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  // labelPadding: EdgeInsets.symmetric(
                                  //   horizontal: 20.0,
                                  // ),
                                  indicatorPadding: EdgeInsets.symmetric(
                                    horizontal: -5.0,
                                    vertical: 3.0,
                                  ),
                                  indicator: BoxDecoration(
                                    color: hc_red,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  tabs: const <Tab>[
                                    Tab(
                                      icon: Icon(
                                        MaterialCommunityIcons
                                            .format_list_bulleted_square,
                                      ),
                                    ),
                                    Tab(
                                      icon: Icon(
                                        MaterialCommunityIcons
                                            .view_grid_outline,
                                      ),
                                    ),
                                  ],
                                  controller: _gridListTabController,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  //key: packListBox,
                                  color: const Color.fromARGB(
                                    60,
                                    255,
                                    255,
                                    255,
                                  ),
                                  margin: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 16.0,
                                    bottom: 15.0,
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  width: MediaQuery.sizeOf(context).width,
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    child: RefreshIndicator(
                                      onRefresh: () =>
                                          _refreshHemTableFromBackend(true),
                                      child: _gridListTabController.index == 0
                                          ? ListView.separated(
                                              separatorBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) => const Divider(
                                                    height: 3.0,
                                                    color: Colors.black45,
                                                    thickness: 1.5,
                                                  ),
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              controller: _scrollController,
                                              itemCount: snapshot.data!.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final PackListAggregate e =
                                                    snapshot.data![index];

                                                return GestureDetector(
                                                  onTap: () async {
                                                    if (e.hasher.photo !=
                                                        null) {
                                                      await _getHasherZoomablePhoto(
                                                        e.hasher.photo!,
                                                        e.displayName,
                                                      );
                                                    }
                                                  },
                                                  child: Row(
                                                    children: <Widget>[
                                                      _rsvpIcon(e),
                                                      const SizedBox(
                                                        width: 6.0,
                                                      ),
                                                      Container(
                                                        height: 60,
                                                        width: 60,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        child: _hasherPhoto(
                                                          e,
                                                          false,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 8.0,
                                                      ),
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 1.0,
                                                              ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                e.hem.hemKennelHashName ??
                                                                    e.displayName,
                                                                style:
                                                                    ts_condensedLarge,
                                                              ),
                                                              if (e.homeKennelName !=
                                                                  null)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top:
                                                                            4.0,
                                                                      ),
                                                                  child: Text(
                                                                    e.homeKennelName!,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        ts_bodySmall,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : SingleChildScrollView(
                                              controller: _scrollController,
                                              child: Column(
                                                children: <Widget>[
                                                  StaggeredGrid.count(
                                                    mainAxisSpacing: 8.0,
                                                    crossAxisSpacing: 8.0,
                                                    crossAxisCount: 4,
                                                    axisDirection:
                                                        AxisDirection.down,
                                                    children: snapshot.data!.map((
                                                      PackListAggregate e,
                                                    ) {
                                                      return StaggeredGridTile.count(
                                                        crossAxisCellCount:
                                                            (e.hem.isHare != 0)
                                                            ? 2
                                                            : 1,
                                                        mainAxisCellCount:
                                                            (e.hem.isHare != 0)
                                                            ? 2
                                                            : 1,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            if (e
                                                                    .hasher
                                                                    .photo !=
                                                                null) {
                                                              await _getHasherZoomablePhoto(
                                                                e.hasher.photo!,
                                                                e.displayName,
                                                              );
                                                            }
                                                          },
                                                          child: _hasherPhoto(
                                                            e,
                                                            true,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                  const SizedBox(height: 100.0),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          }
        },
      );
  }

  Future<void> _getHasherZoomablePhoto(String photo, String dispName) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ZoomableImagePage2(
          key: const Key('39392001'),
          pageTitle: dispName,
          imageUrl: photo.startsWith('http') ? photo : null,
          assetImage: photo.contains('bundle://')
              ? 'images/avatars/${photo.replaceAll('bundle://', '')}.jpg'
              : null,
          appBarBackgroundColor: themeAppBarBackground,
          background: Backgrounds.defaultHcBackground(),
          margin: 20.0,
        ),
      ),
    );
  }

  Stack _hasherPhoto(PackListAggregate e, bool isGrid) {
    return Stack(
      children: <Widget>[
        (e.hem.hemKennelUserPhoto ?? e.hasher.photo!).startsWith('http')
            ? CachedNetworkImage(
                imageUrl: (e.hem.hemKennelUserPhoto ?? e.hasher.photo!),
                fadeInDuration: const Duration(milliseconds: 0),
                width: 300.0,
                height: 300.0,
                fit: BoxFit.fill,
              )
            : (e.hem.hemKennelUserPhoto ?? e.hasher.photo!).startsWith('bundle')
            ? Image(
                width: 300.0,
                height: 300.0,
                fit: BoxFit.fill,
                image: AssetImage(
                  ('images/avatars/${(e.hem.hemKennelUserPhoto ?? e.hasher.photo!).toLowerCase().replaceFirst('bundle://', '')}.jpg')
                      .toLowerCase(),
                ),
              )
            : const Image(
                width: 300.0,
                height: 300.0,
                fit: BoxFit.fill,
                image: AssetImage('images/avatars/avatar-2.jpg'),
              ),
        if (isGrid) ...<Widget>[
          Positioned(right: 1.0, bottom: 1.0, child: _rsvpIcon(e)),
        ],
      ],
    );
  }

  Widget _getRunDetails(Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          widget.futureRun.event.eventName,
          maxLines: 3,
          style: ts_tileTextLarge.copyWith(color: textColor),
        ),
        Text(
          DateFormat(
            'E, MMM d, yyyy, h:mm a',
          ).format(widget.futureRun.event.eventStartDatetime),
          style: ts_listValueStyle.copyWith(color: textColor),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if ((widget.futureRun.event.locationOneLineDesc ?? '') != '')
          Text(
            widget.futureRun.event.locationOneLineDesc!,
            style: ts_listValueStyle.copyWith(color: textColor),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if ((widget.futureRun.event.hares ?? '') != '')
          Text(
            'Hares: ${widget.futureRun.event.hares!}',
            style: ts_listValueStyle.copyWith(color: textColor),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Stack _rsvpIcon(PackListAggregate e) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        const CircleAvatar(backgroundColor: Colors.white, radius: 11.0),
        (e.hem.rsvpState <= 0)
            ? CircleAvatar(backgroundColor: hc_blue, radius: 10.0)
            : (e.hem.rsvpState == 1)
            ? Icon(FontAwesome.times_circle, color: hc_red, size: 21.0)
            : (e.hem.rsvpState == 2)
            ? const Icon(
                FontAwesome.question_circle,
                color: Colors.orange,
                size: 21.0,
              )
            : (e.hem.isHare == 0)
            ? const Icon(
                FontAwesome.check_circle,
                color: Colors.green,
                size: 21.0,
              )
            : Image.asset(
                'images/icons/hare_icon.png',
                color: Colors.deepPurple,
                height: 18.0,
                width: 18.0,
              ),
      ],
    );
  }

  // Future<void> _setRsvpHare() async {
  //   final bool willHare =
  //       await Utilities.promptForHare(widget.futureRun.event.hares ?? '') ??
  //           false;
  //   if (willHare) {
  //     List<PackListAggregate>? lPla = await _thePackList;
  //     if (lPla != null) {
  //       setStateIfMounted(() {
  //         if (_thisUserIndex >= 0) {
  //           PackListAggregate a = lPla[_thisUserIndex];
  //           lPla[_thisUserIndex] = PackListAggregate(
  //               hasher: a.hasher,
  //               displayName: a.displayName,
  //               hem: a.hem.copyWith(rsvpState: -1, isHare: -1));

  //           // _thePackList[_thisUserIndex].hem.rsvpState = -1;
  //           // _thePackList[_thisUserIndex].hem.isHare = -1;
  //           _rsvpRequested = rsvpYes;
  //         }
  //       });
  //     }

  //     //final String userId = getStringPref(StringPrefsEnum.userId);
  //     final List<dynamic> adHocData =
  //         await tableModel.hasherEventMapService.setEventRsvp(
  //               widget.futureRun.event.eventId,
  //               _userId,
  //               AppDomainType.user,
  //               rsvpYes.value,
  //               isHareYes.value,
  //             );

  //     await _refreshHemTableFromBackend(false);
  //     final String serverMessage = adHocData[0]['serverMessage'] ?? '';

  //     if (serverMessage.isNotEmpty) {
  //       await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
  //     }
  //   }
  // }

  Widget _buildPhotosView() {
    return RunPhotoGallery(
      eventName: widget.futureRun.event.eventName,
      loader: () => KennelPhotoService().getRunPhotosForGallery(
        eventId: widget.futureRun.event.eventId,
      ),
    );
  }

  Future<void> _setRsvpState(EnumRsvpState rsvpState) async {
    List<PackListAggregate>? lPla = await _thePackList;
    if (lPla != null) {
      setStateIfMounted(() {
        if (_thisUserIndex >= 0 && _thisUserIndex < lPla.length) {
          // _thePackList[_thisUserIndex].hem.rsvpState = -1;
          // _thePackList[_thisUserIndex].hem.isHare = 0;

          PackListAggregate a = lPla[_thisUserIndex];
          lPla[_thisUserIndex] = PackListAggregate(
            hasher: a.hasher,
            displayName: a.displayName,
            hem: a.hem.copyWith(rsvpState: -1, isHare: 0),
          );
        }
        _rsvpRequested = rsvpState;
      });
    }
    //final String userId = getStringPref(StringPrefsEnum.userId);

    final List<dynamic> adHocData = await tableModel.hasherEventMapService
        .setEventRsvp(
          widget.futureRun.event.eventId,
          _userId,
          AppDomainType.user,
          rsvpState.value,
        );

    await _refreshHemTableFromBackend(false);
    if (kDebugMode) debugPrint('[_setRsvpState] adHocData length: ${adHocData.length}, contents: $adHocData');
    final String serverMessage = adHocData[0]['serverMessage'] ?? '';

    if (serverMessage.isNotEmpty) {
      await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
    }
  }

  Widget _buildChatView() {
    return ColoredBox(
      color: Colors.yellow.shade100,
      child: Column(
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_slideTopWidget
                ? AnimatedOpacity(
                    opacity: _showTopWidget ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 400),
                    onEnd: () {
                      if (!mounted) return;

                      _safeSetState(() {
                        _slideTopWidget = true;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top: 15, left: 20, bottom: 15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              KennelLogo(
                                kennelLogoUrl:
                                    widget.futureRun.kennel.kennelLogo,
                                kennelShortName:
                                    widget.futureRun.kennel.kennelShortName,
                                logoHeight: 70,
                              ),
                              SizedBox(width: 30),
                              Expanded(
                                child: _getRunDetails(themeAppBarBackground),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                          // SizedBox(height: 20),
                          // FancyDivider(
                          //   key: ValueKey('divider2342'),
                          //   innerColor: Colors.black,
                          // ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(),
            //: SizedBox.expand(child: ColoredBox(color: Colors.white)),
          ), // Collapses cleanly

          Expanded(
            child: Stack(
              children: [
                ChatPage(
                  eventId: widget.futureRun.event.eventId,
                  publicEventId: widget.futureRun.event.publicEventId,
                ),
                BetaRibbon(
                  title: 'Trail Chat',
                  text:
                      'Trail Chat is a brand-new feature currently in beta. Over the next few releases, we’ll be continuing to improve and expand it — fixing any bugs and adding new functionality based on your feedback.\r\n\r\nYou may encounter occasional glitches as we refine the experience, but rest assured we’re actively working on updates in each release.\r\n\r\nOnce Trail Chat reaches full stability and feature completeness, this beta label will be removed.\r\n\r\nWe appreciate your patience and support as we make Trail Chat the best way to stay connected on the trail!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final List<double?> coords = Utilities.getLatLongFromString(<String>[
      widget.futureRun.event.locationOneLineDesc ?? '',
      widget.futureRun.event.eventDescription ?? '',
      widget.futureRun.event.eventName,
    ]);

    final locService = Get.find<LocationService>();

    return ConnectedWidget(
      refreshFunction: () {
        setStateIfMounted(() {});
      },
      showConnectButton: true,
      disconnectedChild: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'Maps require a connection to the Internet',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                // Map
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[
                      RunTrackerMap(
                        widget.futureRun.event,

                        (widget.futureRun.extensions.evtLat ?? coords[0]) ==
                                null
                            ? null
                            : latlng.LatLng(
                                (widget.futureRun.extensions.evtLat ??
                                    coords[0]!),
                                (widget.futureRun.extensions.evtLon ??
                                    coords[1])!,
                              ),
                        _mapCenter,
                        latlng.LatLng(
                          widget.futureRun.kennel.kennelLatitude!,
                          widget.futureRun.kennel.kennelLongitude!,
                        ),
                        1.0,
                        22.0,
                        14.0,
                        _trueNorthLock,
                        mapMoved: (latlng.LatLng newPosition) {
                          _mapCenter = newPosition;
                        },
                        markerClicked: () async {
                          await _launchMaps(widget.futureRun);
                        },
                      ),
                      Positioned(
                        left: 10.0,
                        top: 10.0,
                        child: GestureDetector(
                          onTap: () {
                            setStateIfMounted(() {
                              _trueNorthLock = !_trueNorthLock;
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
                      if (widget.futureRun.extensions.isMapAndDistanceValid ==
                          0) ...<Widget>[
                        Positioned(
                          right: 10.0,
                          top: 10.0,
                          child: GestureDetector(
                            onTap: () {
                              _mapCenter = latlng.LatLng(
                                widget.futureRun.extensions.evtLat ??
                                    widget.futureRun.kennel.kennelLatitude ??
                                    DEFAULT_LATITUDE,
                                widget.futureRun.extensions.evtLon ??
                                    widget.futureRun.kennel.kennelLongitude ??
                                    DEFAULT_LONGITUDE,
                              );

                              setStateIfMounted(() {});
                            },
                            child: SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: Image.asset(
                                'images/other/set_map_to_event_location.png',
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 70.0,
                          top: 10.0,
                          child: GestureDetector(
                            onTap: () {
                              setStateIfMounted(() {
                                if ((deviceInfo.deviceLat != null) &&
                                    (deviceInfo.deviceLon != null)) {
                                  _mapCenter = latlng.LatLng(
                                    deviceInfo.deviceLat!,
                                    deviceInfo.deviceLon!,
                                  );
                                }
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
                      if (widget.futureRun.extensions.isMapAndDistanceValid !=
                          1) ...<Widget>[
                        Container(color: Colors.black54),
                        Container(
                          margin: const EdgeInsets.only(bottom: 60.0),
                          child: Text(
                            'No location provided',
                            textAlign: TextAlign.center,
                            style: ts_headingVeryLarge,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          BetaRibbon(
            feature: BetaFeatures.runTracking,
            showRibbon: false,
            ribbonTopMargin: 15,
            child: Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              child: Obx(() {
                final bool isTracking = locService.joinRunTracking.value;
                final controller =
                    Get.isRegistered<RunTrackerMapController>(
                      tag: widget.futureRun.event.eventId,
                    )
                    ? Get.find<RunTrackerMapController>(
                        tag: widget.futureRun.event.eventId,
                      )
                    : null;
                final hasTrack = controller != null
                    ? _hasCurrentUserTrack(controller)
                    : false;
                final showExport = !isTracking && hasTrack;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (DateTime.now().toUtc().isBefore(
                              widget.futureRun.event.eventStartDatetimeGmt
                                  .subtract(const Duration(hours: 15)),
                            ) ||
                            DateTime.now().toUtc().isAfter(
                              widget.futureRun.event.eventStartDatetimeGmt.add(
                                const Duration(hours: 6),
                              ),
                            ))
                        ? SizedBox()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.only(
                                top: 2.0,
                                left: 0.0,
                                bottom: 0.0,
                              ),
                              backgroundColor: isTracking
                                  ? Colors.green.shade900
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 3,
                              ),
                              child: Text(
                                !isTracking ? 'Track my run' : 'Stop tracking',
                                style: ts_button,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            onPressed: () {
                              setStateIfMounted(() {
                                locService.joinRunTracking.value =
                                    !locService.joinRunTracking.value;
                                locService.eventId =
                                    widget.futureRun.event.eventId;
                                locService.userId = getStringPref(
                                  StringPrefsEnum.userId,
                                );
                              });
                            },
                          ),
                    if (showExport) ...[
                      const SizedBox(width: 10),
                      _buildExportButton(controller),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasCurrentUserTrack(RunTrackerMapController controller) {
    final userId = getStringPref(StringPrefsEnum.userId);
    if (userId == null || userId.isEmpty) return false;
    for (final track in controller.userPositions) {
      if (track.id == userId && track.positions.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  UserTrack? _currentUserTrack(RunTrackerMapController controller) {
    final userId = getStringPref(StringPrefsEnum.userId);
    if (userId == null || userId.isEmpty) return null;
    for (final track in controller.userPositions) {
      if (track.id == userId && track.positions.isNotEmpty) {
        return track;
      }
    }
    return null;
  }

  Widget _buildExportButton(RunTrackerMapController controller) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.ios_share),
      label: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 3.0),
        child: Text('Export GPX', style: ts_button),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        backgroundColor: _isExportingTrack ? Colors.grey.shade700 : null,
      ),
      onPressed: _isExportingTrack
          ? null
          : () => _exportCurrentUserTrack(controller),
    );
  }

  Future<void> _exportCurrentUserTrack(
    RunTrackerMapController controller,
  ) async {
    final track = _currentUserTrack(controller);
    if (track == null) {
      _showExportMessage('No track data available yet.');
      return;
    }

    setStateIfMounted(() {
      _isExportingTrack = true;
    });

    try {
      final exporter = GpxExportService();
      final trackName = widget.futureRun.event.eventName;
      await exporter.exportTrack(
        context: context,
        track: track,
        trackName: trackName,
      );
    } catch (error, s) {
      BootLogger.logError('[RunTabs._exportTrack] trackName=${widget.futureRun.event.eventName} eventId=${widget.futureRun.event.eventId}', error, s);
      _showExportMessage('Export failed: $error');
    } finally {
      if (mounted) {
        setStateIfMounted(() {
          _isExportingTrack = false;
        });
      }
    }
  }

  void _showExportMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _fabIsVisible = false;

  Widget _getRsvpButton(
    IconData iconData,
    Color iconColor,
    String text,
    EnumRsvpState rsvpState,
  ) {
    return StyleForConnected(
      child: ElevatedButton(
        child: SizedBox(
          width: 200.0,
          child: Row(
            children: <Widget>[
              Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  Container(
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    height: 22.0,
                    width: 22.0,
                    child: Icon(iconData, size: 22.0, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(width: 15.0),
              Text(text, style: ts_button),
            ],
          ),
        ),
        onPressed: () async {
          await _setRsvpState(rsvpState);
        },
      ),
    );
  }

  List<Widget> _getRsvpButtons() {
    if (_rsvpRequested != rsvpUnknown) {
      return <Widget>[
        const HcAppCircularProgressIndicator(key: Key('3920394')),
      ];
    } else {
      return <Widget>[
        const SizedBox(height: 30.0),
        _getRsvpButton(
          FontAwesome.check_circle,
          Colors.green,
          'I\'ll be there!',
          rsvpYes,
        ),
        _getRsvpButton(
          FontAwesome.check_circle,
          Colors.orange,
          'I might come',
          rsvpMaybe,
        ),
        _getRsvpButton(
          FontAwesome.check_circle,
          hc_red,
          'I will not come',
          rsvpNo,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTabControllerReady) {
      return const SizedBox(); // or a loading spinner
    }

    return Stack(
      children: <Widget>[
        AppScaffold(
          floatingActionButton: (!_fabIsVisible)
              ? null
              : StyleForConnected(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _fabIsVisible ? 1.0 : 0.0,
                    child: SpeedDial(
                    // both default to 16
                    // marginEnd: 18,
                    // marginBottom: 20,
                    animatedIcon: AnimatedIcons.menu_close,
                    animatedIconTheme: const IconThemeData(size: 22.0),
                    // this is ignored if animatedIcon is non null
                    // child:const  Icon(Icons.add),
                    visible: true,
                    curve: Curves.bounceIn,
                    overlayColor: Colors.black,
                    overlayOpacity: 0.5,
                    onOpen: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    //onClose: () => //print('DIAL CLOSED'),
                    tooltip: 'Speed Dial',
                    heroTag: 'speed-dial-hero-tag-722526',
                    backgroundColor: hc_red,
                    foregroundColor: Colors.white,
                    elevation: 8.0,
                    shape: const CircleBorder(),
                    children: <SpeedDialChild>[
                      SpeedDialChild(
                        child: const Icon(Feather.x),
                        backgroundColor: hc_red,
                        label: 'I\'m not coming',
                        labelStyle: const TextStyle(fontSize: 18.0),
                        onTap: () async {
                          await _setRsvpState(rsvpNo);
                        },
                      ),
                      SpeedDialChild(
                        child: const Icon(AntDesign.question),
                        backgroundColor: Colors.orange,
                        label: 'I might come',
                        labelStyle: const TextStyle(fontSize: 18.0),
                        onTap: () async {
                          await _setRsvpState(rsvpMaybe);
                        },
                      ),
                      SpeedDialChild(
                        child: const Icon(Feather.check),
                        backgroundColor: Colors.green,
                        label: 'I\'m coming',
                        labelStyle: const TextStyle(fontSize: 18.0),
                        onTap: () async {
                          await _setRsvpState(rsvpYes);
                        },
                      ),
                      // SpeedDialChild(
                      //   child: const ImageIcon(
                      //       AssetImage('images/icons/hare_icon.png'),
                      //       color: Colors.deepPurple),
                      //   backgroundColor: Colors.white,
                      //   label: 'I will hare',
                      //   labelStyle: const TextStyle(fontSize: 18.0),
                      //   onTap: () async {
                      //     await _setRsvpHare();
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),
          body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                    ),
                    child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                              vertical: 2.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: TabBar(
                                      labelStyle: ts_tabSelected,
                                      unselectedLabelStyle: ts_tabUnselected,
                                      isScrollable: false,
                                      labelPadding: const EdgeInsets.only(top: 3.0, left: 6.0, right: 6.0),
                                      dividerHeight: 0,
                                      unselectedLabelColor: Colors.black,
                                      labelColor: Colors.white,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicatorPadding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 4.0,
                                      ),
                                      indicator: BoxDecoration(
                                        color: hc_red,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      tabs: _tabs,
                                      controller: _tabController,
                                    ),
                                  ),
                                ),

                                Builder(builder: (_) {
                                  if (!Get.isRegistered<NotificationService>()) {
                                    return const SizedBox();
                                  }
                                  return Obx(() {
                                    final count = notificationService
                                            .unreadEventCounts[widget
                                                .futureRun
                                                .event
                                                .publicEventId]
                                            ?.value ??
                                        0;
                                    if (count == 0) return const SizedBox();
                                    return badges.Badge(
                                      position: badges.BadgePosition.topEnd(
                                        top: -5,
                                        end: 0,
                                      ),
                                      badgeContent: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        width: 30,
                                        height: 13,
                                        child: AutoSizeText(
                                          count.toString(),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          minFontSize: 10,
                                          maxFontSize: 13,
                                          style: ts_badge,
                                        ),
                                      ),
                                      badgeStyle: badges.BadgeStyle(
                                        badgeColor: Colors.red.shade800,
                                        padding: const EdgeInsets.all(6),
                                      ),
                                    );
                                  });
                                }),

                                // if ((chatCount > 0) &&
                                //     (_tabController.index != 4)) ...<Widget>[
                                //   badges.Badge(
                                //     position: badges.BadgePosition.topEnd(
                                //       top: 0,
                                //       end: 0,
                                //     ),
                                //     badgeContent: Container(
                                //       //color: Colors.pink,
                                //       padding: EdgeInsets.symmetric(
                                //         horizontal: 2,
                                //       ),
                                //       width: 30,
                                //       height: 13,
                                //       child: AutoSizeText(
                                //         chatCount.toString(),
                                //         textAlign: TextAlign.center,
                                //         maxLines: 1,
                                //         minFontSize: 10,
                                //         maxFontSize: 13,
                                //         style: ts_badge,
                                //       ),
                                //     ),
                                //     badgeStyle: badges.BadgeStyle(
                                //       badgeColor: Colors.red.shade800,
                                //       padding: const EdgeInsets.all(6),
                                //     ),
                                //   ),
                                // ],
                              ],
                            ),
                    ),
                  ),
                ),
                _buildLiveRunButton(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildRunDetailsView(),
                      _buildRsvpView(),
                      _buildMapView(),
                      ConnectedWidget(
                        refreshFunction: () {
                          setStateIfMounted(() {});
                        },
                        showConnectButton: true,
                        disconnectedChild: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              '"Get a life" leaderboards require a connection to the Internet',
                              style: ts_headingLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        child: Leaderboard(
                          kennelId: widget.futureRun.kennel.kennelId,
                        ),
                      ),
                      _buildChatView(),
                      _buildPhotosView(),
                    ],
                    // children: tabs.map((Tab tab) {
                    //   return Center(
                    //       child: Text(
                    //     tab.text,
                    //     style: const TextStyle(fontSize: 20.0),
                    //   ));
                    // }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {},
          //refreshFunction: () => controller.initialize(),
        ),
      ],
    );
  }

  // List<Widget> kiddies() {
  //   final List<Widget> kiddies = <Widget>[];

  //   if (widget.futureRun.mmAuthAllowCheckInAndOut || widget.futureRun.mmAuthAllowEditRsvp) {
  //     kiddies.add(rsvpRow());
  //   }

  //   if (widget.futureRun.mmAuthAllowCheckInAndOut) {
  //     kiddies.add(attendenceRow());
  //   }

  //   kiddies.add(paymentRow());

  //   kiddies.add(receiptsRow());

  //   return kiddies;
  // }

  // Row rsvpRow() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: <Widget>[
  //       !widget.futureRun.mmAuthAllowEditRsvp
  //           ? Container()
  //           : Container(
  //               margin: const EdgeInsets.only(left: 10, right: 10),
  //               width: 150.0,
  //               height: 100.0,
  //               child: ElevatedButton(
  //                 child: const Text(
  //                   'Check in Pack',
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //                 onPressed: () {
  //                   Navigator.push<dynamic>(
  //                     context,
  //                     MaterialPageRoute<dynamic>(
  //                       builder: (BuildContext context) => CheckInPackPage(futureRun: widget.futureRun),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //       !widget.futureRun.mmAuthAllowHashCash
  //           ? Container()
  //           : Container(
  //               margin: const EdgeInsets.only(left: 10, right: 10),
  //               width: 150.0,
  //               height: 100.0,
  //               child: ElevatedButton(
  //                 child: const Text(
  //                   'Hash Cash',
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //                 onPressed: () {
  //                   Navigator.push<dynamic>(
  //                     context,
  //                     MaterialPageRoute<dynamic>(
  //                       builder: (BuildContext context) => PaymentReportPage(
  //                             eventId: widget.futureRun.event.eventId,
  //                             currencySymbol: widget.futureRun.currencySymbol,
  //                             digitsAfterDecimal: widget.futureRun.digitsAfterDecimal,
  //                             eventName: widget.futureRun.eventName,
  //                           ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),

  //       // Container(
  //       //   width: 150.0,
  //       //   child: ElevatedButton(
  //       //       child: const Text(
  //       //         'Edit Run',
  //       //         style:
  //       //             TextStyle(color: Colors.white),
  //       //       ),
  //       //       onPressed: () {
  //       //         //int i = 0;
  //       //       }),
  //       // ),
  //     ],
  //   );
  // }

  // Row attendenceRow() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: <Widget>[
  //       Container(
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         width: 150.0,
  //         height: 100.0,
  //         child: ElevatedButton(
  //           child: const Text(
  //             'Scan at Run Start',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //           onPressed: () {
  //             Navigator.push<dynamic>(
  //               context,
  //               MaterialPageRoute<dynamic>(
  //                 builder: (BuildContext context) => CheckInScannerPage(
  //                       kennelShortName: widget.futureRun.kennelShortName,
  //                       eventId: widget.futureRun.event.eventId,
  //                       eventName: widget.futureRun.eventName,
  //                       eventNumber: widget.futureRun.eventNumber,
  //                       isRunStart: 1,
  //                     ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       Container(
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         width: 150.0,
  //         height: 100.0,
  //         child: ElevatedButton(
  //           child: const Text(
  //             'Scan at Run End',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //           onPressed: () {
  //             Navigator.push<dynamic>(
  //               context,
  //               MaterialPageRoute<dynamic>(
  //                 builder: (BuildContext context) => CheckInScannerPage(
  //                       kennelShortName: widget.futureRun.kennelShortName,
  //                       eventId: widget.futureRun.event.eventId,
  //                       eventName: widget.futureRun.eventName,
  //                       eventNumber: widget.futureRun.eventNumber,
  //                       isRunStart: 0,
  //                     ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Row paymentRow() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: <Widget>[
  //       Container(
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         width: 150.0,
  //         height: 100.0,
  //         child: ElevatedButton(
  //             child: const Text(
  //               'Run Start QR',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             onPressed: () {
  //               Navigator.push<dynamic>(
  //                   context,
  //                   MaterialPageRoute<dynamic>(
  //                       builder: (BuildContext context) => RunStartEndQrCodes(
  //                             kennelShortName: widget.futureRun.kennelShortName,
  //                             eventId: widget.futureRun.event.eventId,
  //                             eventName: widget.futureRun.eventName,
  //                             eventNumber: widget.futureRun.eventNumber,
  //                             eventStartDatetime: widget.futureRun.eventStartDatetime,
  //                             isStart: true,
  //                           )));
  //             }),
  //       ),
  //       Container(
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         width: 150.0,
  //         height: 100.0,
  //         child: ElevatedButton(
  //             child: const Text(
  //               'Run End QR',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             onPressed: () {
  //               Navigator.push<dynamic>(
  //                   context,
  //                   MaterialPageRoute<dynamic>(
  //                       builder: (BuildContext context) => RunStartEndQrCodes(
  //                             kennelShortName: widget.futureRun.kennelShortName,
  //                             eventId: widget.futureRun.event.eventId,
  //                             eventName: widget.futureRun.eventName,
  //                             eventNumber: widget.futureRun.eventNumber,
  //                             eventStartDatetime: widget.futureRun.eventStartDatetime,
  //                             isStart: false,
  //                           )));
  //             }),
  //       ),
  //     ],
  //   );
  // }

  // Row receiptsRow() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: <Widget>[
  //       Container(
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         width: 150.0,
  //         height: 100.0,
  //         child: ElevatedButton(
  //             child: const Text(
  //               'Manage receipts',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             onPressed: () {
  //               Navigator.push<dynamic>(
  //                   context,
  //                   MaterialPageRoute<dynamic>(
  //                       builder: (BuildContext context) => ReceiptsList(
  //                             eventName: widget.futureRun.eventName,
  //                             eventId: widget.futureRun.event.eventId,
  //                             digitsAfterDecimal: widget.futureRun.digitsAfterDecimal,
  //                             currencySymbol: widget.futureRun.currencySymbol
  //                           )));
  //             }),
  //       ),

  //       // Container(
  //       //   margin: const EdgeInsets.only(left: 10, right: 10),
  //       //   width: 150.0,
  //       //   height: 100.0,
  //       //   child: ElevatedButton(
  //       //       child: const Text(
  //       //         'Run End QR',
  //       //         style: TextStyle(color: Colors.white),
  //       //       ),
  //       //       onPressed: () {
  //       //         Navigator.push<dynamic>(
  //       //             context,
  //       //             MaterialPageRoute<dynamic>(
  //       //                 builder: (BuildContext context) => RunStartEndQrCodes(
  //       //                       kennelShortName: widget.futureRun.kennelShortName,
  //       //                       eventId: widget.futureRun.event.eventId,
  //       //                       eventName: widget.futureRun.eventName,
  //       //                       eventNumber: widget.futureRun.eventNumber,
  //       //                       eventStartDatetime:
  //       //                           widget.futureRun.eventStartDatetime,
  //       //                       isStart: false,
  //       //                     )));
  //       //       }),
  //       // ),
  //     ],
  //   );
  // }

  Future<void> _launchMaps(RunDetailsAggregate rda) async {
    double? lat;
    double? lon;
    String address = '';

    if (rda.extensions.evtLat != null) {
      lat = rda.extensions.evtLat;
    }

    if (rda.extensions.evtLon != null) {
      lon = rda.extensions.evtLon;
    }

    if ((lat == null) || (lon == null)) {
      // try to get lat/lons from other sources
      final List<double?> coords = Utilities.getLatLongFromString(<String>[
        rda.event.locationOneLineDesc ?? '',
        rda.event.eventDescription ?? '',
        rda.event.eventName,
      ]);

      if ((coords[0] != null) && (coords[1] != null)) {
        lat = coords[0]!;
        lon = coords[1]!;
      }
    }

    if (rda.event.locationStreet != null) {
      address = '$address${rda.event.locationStreet} ';
    }

    if (rda.event.locationCity != null) {
      address = '$address${rda.event.locationCity} ';
    }

    if (rda.event.locationPostCode != null) {
      address = '$address${rda.event.locationPostCode} ';
    }

    if (rda.event.locationCountry != null) {
      address = '$address${rda.event.locationCountry} ';
    }

    address = address.trim();

    if ((address.isEmpty) && (lat == null || lon == null)) {
      address = rda.event.locationOneLineDesc ?? '';
    }

    // use the native map provider for the selected platform
    if ((lat != null) && (lon != null)) {
      final String? mapName = getStringPref(StringPrefsEnum.mapPreference);
      if (mapName == null) {
        await Utilities.openMapsSheet(
          context,
          address,
          maps.Coords(lat, lon),
          rda.event.eventName,
          _saveUserMapPreference,
        );
      } else {
        final List<maps.AvailableMap> availableMaps =
            await maps.MapLauncher.installedMaps;
        final maps.AvailableMap? activeMap = availableMaps
            .where((maps.AvailableMap map) => map.mapName == mapName)
            .firstOrNull;
        if (activeMap == null) return;

        // BUG in plugin - doesn't work when sending a title with Google maps
        await activeMap.showMarker(
          coords: maps.Coords(lat, lon),
          title: activeMap.mapName.contains('Google') ? '' : address,
          description: address,
        );
      }
    } else {
      await Utilities.showAlert(
        'No location information available',
        'There is no location information available for this run and so we cannot display a map',
        'OK',
      );
    }
  }

  Widget _buildLiveRunButton(BuildContext context) {
    final state = _liveRunStatus;
    final loading = _liveRunLoading;
    final bool isActiveRun = state == LiveRunButtonStatus.active;

    if (state == LiveRunButtonStatus.hidden) return const SizedBox.shrink();

    final String label = isActiveRun
        ? 'Return to Live Run Tools'
        : 'Show Live Run Tools';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.directions_run),
          label: Text(label, style: ts_button),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActiveRun ? hc_blue : hc_red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: loading
              ? null
              : () async {
                  if (!isActiveRun) {
                    _liveRunService.startRun(
                      eventId: widget.futureRun.event.eventId,
                      eventName: widget.futureRun.event.eventName,
                    );
                    setStateIfMounted(() {
                      _liveRunStatus = LiveRunButtonStatus.active;
                    });
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LiveRunShell(run: widget.futureRun),
                    ),
                  );
                  await _refreshLiveRunButton();
                },
        ),
      ),
    );
  }

  Future<void> _refreshLiveRunButton() async {
    _safeSetState(() => _liveRunLoading = true);
    try {
      final now = DateTime.now();
      final eventStart = widget.futureRun.event.eventStartDatetime;
      final windowStart = eventStart.subtract(const Duration(minutes: 30));
      final windowEnd = eventStart.add(const Duration(hours: 6));

      final String eventId = widget.futureRun.event.eventId;
      final String? activeId = _liveRunService.activeRunEventId.value;

      if (activeId != null) {
        _liveRunStatus = activeId == eventId
            ? LiveRunButtonStatus.active
            : LiveRunButtonStatus.hidden;
        return;
      }

      if (now.isBefore(windowStart) || now.isAfter(windowEnd)) {
        _liveRunStatus = LiveRunButtonStatus.hidden;
        return;
      }

      final bool isCheckedIn =
          widget.futureRun.extensions.attendenceState >= attendenceAtHash.value;
      final bool hasRsvpYes =
          widget.futureRun.extensions.rsvpState == rsvpYes.value;

      if (isCheckedIn) {
        _liveRunStatus = LiveRunButtonStatus.eligible;
        return;
      }

      if (!hasRsvpYes) {
        _liveRunStatus = LiveRunButtonStatus.hidden;
        return;
      }

      final results = await CommonQueries.isAtRunStart(eventId: eventId);
      final bool atStart = results.any((item) => item.eventId == eventId);
      _liveRunStatus = atStart
          ? LiveRunButtonStatus.eligible
          : LiveRunButtonStatus.hidden;
    } catch (e, s) {
      debugPrint('Live run button check failed: $e');
      BootLogger.logError('[RunTabs._checkLiveRunStatus] eventId=${widget.futureRun.event.eventId}', e, s);
      _liveRunStatus = LiveRunButtonStatus.hidden;
    } finally {
      _safeSetState(() => _liveRunLoading = false);
    }
  }
}
