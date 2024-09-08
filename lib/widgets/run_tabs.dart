// import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

class RunTabs extends StatefulWidget {
  const RunTabs({
    super.key,
    required this.futureRun,
  });

  final RunDetailsAggregate futureRun;

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
  });

  final HasherEventMapModel hem;
  final HashersModel hasher;
  final String displayName;
}

class RunTabsState extends State<RunTabs> with TickerProviderStateMixin {
  static const String LABEL_DETAILS = 'Details';
  static const String LABEL_MAP = 'Map';
  static const String LABEL_RSVP = 'RSVP';
  static const String LABEL_GETALIFE = 'Get A Life';

  final List<Tab> _tabs = <Tab>[
    const Tab(text: LABEL_DETAILS),
    const Tab(text: LABEL_RSVP),
    const Tab(text: LABEL_MAP),
    const Tab(text: LABEL_GETALIFE),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //GlobalKey packListBox = GlobalKey();

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _saveUserMapPreference = ValueNotifier<bool>(false);

  bool isAdmin = true;
  //bool _isLoading = true;

  latlng.LatLng _mapCenter = latlng.LatLng(G0<DeviceInfo>().deviceLat ?? DEFAULT_LATITUDE, G0<DeviceInfo>().deviceLon ?? DEFAULT_LONGITUDE);

  bool _trueNorthLock = true;

  Future<List<PackListAggregate>?> _thePackList = Future<List<PackListAggregate>?>.value(null);

  Map<String, dynamic> _packCount = <String, dynamic>{};

  Future<void> _refreshHemTableFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      setState(() {
        //_isLoading = true;
      });
    }

    await G0<TableModel>().syncEventAdminService.updateFromBackend(SyncEventAdminService.flagHasherEventMapTable, true, widget.futureRun.event.eventId);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Pack member data synchronized $resultStr');

    _thePackList = _refreshPackListFromTable();
    await _refreshPackCountFromTable(true);
  }

  int _thisUserIndex = -1;

  Future<List<PackListAggregate>> _refreshPackListFromTable() async {
    List<PackListAggregate> pla = <PackListAggregate>[];

    final String query = '''
        SELECT  
          hem.*,
          h.*
          FROM hasherEventMapForRunAdmin hem
          LEFT OUTER JOIN hashers h on h.${G0<TableModel>().hashersTableHelper.colHasherId} = hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId}
          WHERE hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = "${widget.futureRun.event.eventId}"
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final HasherEventMapModel packItem = G0<TableModel>().hasherEventMapTableHelper.fromMap(results[i]);

        final HashersModel hasherItem = HashersModel.fromJson(results[i]);
        String displayName = hasherItem.dispName;
        if (packItem.virginVisitorType != 0) {
          displayName = packItem.displayName ?? 'Virgin / Visitor';
        }

        // NULLSAFEDONE
        //if (_thePackList != null) {
        pla.add(PackListAggregate(hem: packItem, hasher: hasherItem, displayName: displayName));
        //}
      }
    } catch (e) {
      //print(e);
    }

    pla.sort(
      (PackListAggregate a, PackListAggregate b) => (a.hem.hemKennelHashName ?? a.displayName).compareTo(b.hem.hemKennelHashName ?? b.displayName),
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

    final String query = '''
        SELECT  
          count(case when hem.rsvpState = 3 then 1 else null end) as rsvpYesCount,
          count(case when hem.rsvpState = 2 then 1 else null end) as rsvpMaybeCount,
          count(case when hem.rsvpState = 1 then 1 else null end) as rsvpNoCount,
          count(case when hem.isHare = 1 then 1 else null end) as isHareCount
          FROM hasherEventMapForRunAdmin hem
          WHERE hem.eventId = "${widget.futureRun.event.eventId}"
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      if (results.isNotEmpty) {
        _packCount = results[0];
      }
      if (callSetState) {
        setState(() {});
      }
    } catch (e) {
      //print(e);
    }
  }

  late TabController _tabController;
  late TabController _gridListTabController;

  //final GetPackService _getPackService = GetPackService();

  final String _userId = getStringPref(StringPrefsEnum.userId)!;

  //int _currentTabIndex = -1;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: _tabs.length);
    _gridListTabController = TabController(vsync: this, length: 2);

    final List<double?> coords = Utilities.getLatLongFromString(
      <String?>[
        widget.futureRun.event.locationOneLineDesc,
        widget.futureRun.event.eventDescription,
        widget.futureRun.event.eventName,
      ],
    );

    double xLat = widget.futureRun.extensions.latitude ?? coords[0] ?? widget.futureRun.kennel.kennelLatitude ?? G0<DeviceInfo>().deviceLon ?? DEFAULT_LATITUDE;

    double xLon = widget.futureRun.extensions.longitude ?? coords[1] ?? widget.futureRun.kennel.kennelLongitude ?? G0<DeviceInfo>().deviceLon ?? DEFAULT_LONGITUDE;

    _mapCenter = latlng.LatLng(xLat, xLon);

    _saveUserMapPreference.addListener(
      () {
        setState(() {});
      },
    );

    _tabController.addListener(() async {
      if (_fabIsVisible != (_tabs[_tabController.index].text == LABEL_RSVP)) {
        _fabIsVisible = _tabs[_tabController.index].text == LABEL_RSVP;
        if (_tabs[_tabController.index].text == LABEL_RSVP) {
          //print('refreshing RSVP data from backend @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
          _refreshHemTableFromBackend(false).then(
            (value) {
              setState(() {});
            },
          );
        }
      }

      setState(() {});
    });

    if ((widget.futureRun.extensions.rsvpState == 0) &&
        (widget.futureRun.event.eventStartDatetime.isAfter(
          DateTime.now().subtract(
            const Duration(hours: 6),
          ),
        )) &&
        ((widget.futureRun.extensions.distToEvent ?? 9999999.0) < 250000)) {
      _tabController.animateTo(1);
    }
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gridListTabController.dispose();
    _saveUserMapPreference.dispose();

    super.dispose();
  }

  final GlobalKey<MyFlutterMapState> _mapKey = GlobalKey<MyFlutterMapState>();

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
      eventUrlWithKennelBackup: widget.futureRun.event.eventUrl ?? widget.futureRun.kennel.kennelEventsUrl,
      isMember: widget.futureRun.extensions.isMember,
      isPaid: widget.futureRun.extensions.isPaid,
      rsvpState: widget.futureRun.extensions.rsvpState,
      // NULLSAFETODO1
      processPayment: (int r, int p) {
        // widget.futureRun.extensions.rsvpState = r;
        // if (p != -1) {
        //   widget.futureRun.extensions.isPaid = p;
        // }
        // setState(() {});
      },
    );
  }

  TextStyle rsvpTitlesView = ts_tileText.copyWith(
    fontSize: 20.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
  );

  EnumRsvpState<int> _rsvpRequested = rsvpUnknown;

  Widget _buildRsvpView() {
    return ConnectedWidget(
        refreshFunction: () {
          setState(() {});
        },
        showConnectButton: true,
        disconnectedChild: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
              child: Text(
            'RSVPs require a connection to the Internet',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          )),
        ),
        child: FutureBuilder(
            future: _thePackList,
            builder: (BuildContext context, AsyncSnapshot<List<PackListAggregate>?> snapshot) {
              if ((!snapshot.hasData) || (snapshot.data == null)) {
                return const HcCircularProgressIndicator(key: Key('42223995'));
              } else {
                return Center(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 5.5,
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    'Going',
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
                                        icon: const Icon(FontAwesome.check_circle),
                                        color: _thisUserIndex == -1
                                            ? Colors.grey
                                            : snapshot.data![_thisUserIndex].hem.rsvpState == rsvpYes.value
                                                ? Colors.green
                                                : (snapshot.data![_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpYes)
                                                    ? Colors.blue
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
                                    (_packCount['rsvpYesCount'] ?? 0) >= 0 ? (_packCount['rsvpYesCount'] ?? 0).toString() : '',
                                    style: rsvpTitlesView,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 5.5,
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
                                        icon: const Icon(FontAwesome.question_circle),
                                        color: _thisUserIndex == -1
                                            ? Colors.grey
                                            : snapshot.data![_thisUserIndex].hem.rsvpState == rsvpMaybe.value
                                                ? Colors.orange
                                                : (snapshot.data![_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpMaybe)
                                                    ? Colors.blue
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
                                    (_packCount['rsvpMaybeCount'] ?? 0) >= 0 ? (_packCount['rsvpMaybeCount'] ?? 0).toString() : '',
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
                              width: MediaQuery.of(context).size.width / 5.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                      //'Not go: ' + (widget.futureRun.rsvpNoCount >= 0 ? widget.futureRun.rsvpNoCount.toString() : ''),
                                      'Not go',
                                      style: rsvpTitlesView),
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
                                        color: _thisUserIndex == -1
                                            ? Colors.grey
                                            : snapshot.data![_thisUserIndex].hem.rsvpState == rsvpNo.value
                                                ? Colors.red
                                                : (snapshot.data![_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpNo)
                                                    ? Colors.blue
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
                                    (_packCount['rsvpNoCount'] ?? 0) >= 0 ? (_packCount['rsvpNoCount'] ?? 0).toString() : '',
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
                              width: MediaQuery.of(context).size.width / 5.5,
                              child: Column(
                                children: <Widget>[
                                  Text(
                                      // 'Hares: ' + (widget.futureRun.haresCount >= 0 ? widget.futureRun.haresCount.toString() : ''),
                                      'Hares',
                                      style: rsvpTitlesView),
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
                                        icon: const ImageIcon(AssetImage('images/icons/hare_icon.png')),
                                        color: _thisUserIndex == -1
                                            ? Colors.grey
                                            : snapshot.data![_thisUserIndex].hem.isHare == isHareYes.value
                                                ? Colors.deepPurple
                                                : snapshot.data![_thisUserIndex].hem.isHare == -1
                                                    ? Colors.blue
                                                    : Colors.grey,
                                        //tooltip: 'Select to follow a Kennel',
                                        iconSize: 30.0,
                                        alignment: Alignment.center,
                                        splashColor: Colors.greenAccent,
                                        onPressed: () async {
                                          await _setRsvpHare();
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    (_packCount['isHareCount'] ?? 0) >= 0 ? (_packCount['isHareCount'] ?? 0).toString() : '',
                                    style: rsvpTitlesView,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: !snapshot.hasData
                            ? const SizedBox(
                                //color: Colors.grey[300],
                                width: 70.0,
                                height: 70.0,
                                child: Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: Key('22030392')))),
                              )
                            : ((snapshot.data!.isEmpty) && (widget.futureRun.event.eventStartDatetime.isAfter(DateTime.now().subtract(const Duration(hours: 6)))))
                                ? Column(
                                    children: <Widget>[
                                      const Expanded(flex: 40, child: SizedBox()),
                                      Text(
                                        'Be the first to RSVP\r\nfor this run!',
                                        style: ts_headingVeryLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_thisUserIndex == -1) ..._getRsvpButtons(),
                                      const Expanded(flex: 100, child: SizedBox()),
                                    ],
                                  )
                                : Column(
                                    children: <Widget>[
                                      if ((_thisUserIndex == -1) &&
                                          (widget.futureRun.event.eventStartDatetime.isAfter(
                                            DateTime.now().subtract(
                                              const Duration(hours: 6),
                                            ),
                                          )))
                                        ..._getRsvpButtons(),
                                      if (_thisUserIndex == -1) ...<Widget>[const SizedBox(height: 10)],
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        width: 140.0,
                                        child: TabBar(
                                          onTap: (void _) {
                                            setState(() {});
                                          },
                                          labelStyle: ts_condensedMediumBlack,
                                          unselectedLabelStyle: ts_condensedMediumBlack,
                                          isScrollable: false,
                                          unselectedLabelColor: Colors.white,
                                          labelColor: Colors.white,
                                          //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
                                          indicatorSize: TabBarIndicatorSize.label,
                                          indicator: BubbleTabIndicator(
                                            indicatorHeight: 40.0,
                                            indicatorColor: Colors.red.shade900,
                                            tabBarIndicatorSize: TabBarIndicatorSize.label,
                                            indicatorRadius: 20.0,
                                          ),
                                          tabs: const <Tab>[
                                            Tab(icon: Icon(MaterialCommunityIcons.format_list_bulleted_square)),
                                            Tab(icon: Icon(MaterialCommunityIcons.view_grid_outline)),
                                          ],
                                          controller: _gridListTabController,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          //key: packListBox,
                                          color: const Color.fromARGB(60, 255, 255, 255),
                                          margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
                                          padding: const EdgeInsets.all(8.0),
                                          width: MediaQuery.of(context).size.width,
                                          child: Scrollbar(
                                            controller: _scrollController,
                                            child: RefreshIndicator(
                                              onRefresh: () => _refreshHemTableFromBackend(true),
                                              child: _gridListTabController.index == 0
                                                  ? ListView.separated(
                                                      separatorBuilder: (BuildContext context, int index) => const Divider(
                                                            height: 3.0,
                                                            color: Colors.black45,
                                                            thickness: 1.5,
                                                          ),
                                                      physics: const AlwaysScrollableScrollPhysics(),
                                                      controller: _scrollController,
                                                      itemCount: snapshot.data!.length,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        final PackListAggregate e = snapshot.data![index];

                                                        return GestureDetector(
                                                          onTap: () {
                                                            if (e.hasher.photo != null) {
                                                              _getHasherZoomablePhoto(e.hasher.photo!, e.displayName);
                                                            }
                                                          },
                                                          child: Row(
                                                            children: <Widget>[
                                                              _rsvpIcon(e),
                                                              const SizedBox(width: 6.0),
                                                              Container(height: 60, width: 60, padding: const EdgeInsets.all(4), child: _hasherPhoto(e, false)),
                                                              const SizedBox(width: 8.0),
                                                              Expanded(
                                                                  child: Container(
                                                                padding: const EdgeInsets.only(top: 7.0),
                                                                child: Text(
                                                                  e.hem.hemKennelHashName ?? e.displayName,
                                                                  style: ts_condensedLarge,
                                                                ),
                                                              )),
                                                            ],
                                                          ),
                                                        );
                                                      })
                                                  : SingleChildScrollView(
                                                      controller: _scrollController,
                                                      child: Column(
                                                        children: <Widget>[
                                                          StaggeredGrid.count(
                                                            mainAxisSpacing: 8.0,
                                                            crossAxisSpacing: 8.0,
                                                            crossAxisCount: 4,
                                                            axisDirection: AxisDirection.down,
                                                            children: snapshot.data!.map((PackListAggregate e) {
                                                              return StaggeredGridTile.count(
                                                                crossAxisCellCount: (e.hem.isHare != 0) ? 2 : 1,
                                                                mainAxisCellCount: (e.hem.isHare != 0) ? 2 : 1,
                                                                child: GestureDetector(
                                                                  onTap: () {
                                                                    if (e.hasher.photo != null) {
                                                                      _getHasherZoomablePhoto(e.hasher.photo!, e.displayName);
                                                                    }
                                                                  },
                                                                  child: _hasherPhoto(e, true),
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
            }));
  }

  Future<void> _getHasherZoomablePhoto(String photo, String dispName) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ZoomableImagePage2(
            key: const Key('39392001'),
            pageTitle: dispName,
            imageUrl: photo.startsWith('http') ? photo : null,
            assetImage: photo.contains('bundle://') ? 'images/avatars/${photo.replaceAll('bundle://', '')}.jpg' : null,
            appBarBackgroundColor: themeAppBarBackground,
            background: Backgrounds.defaultHcBackground(),
            margin: 20.0),
      ),
    );
  }

  Stack _hasherPhoto(PackListAggregate e, bool isGrid) {
    return Stack(
      children: <Widget>[
        (e.hem.hemKennelUserPhoto ?? e.hasher.photo!).startsWith('http')
            ? CachedNetworkImage(imageUrl: (e.hem.hemKennelUserPhoto ?? e.hasher.photo!), fadeInDuration: const Duration(milliseconds: 0), width: 300.0, height: 300.0, fit: BoxFit.fill)
            : (e.hem.hemKennelUserPhoto ?? e.hasher.photo!).startsWith('bundle')
                ? Image(
                    width: 300.0,
                    height: 300.0,
                    fit: BoxFit.fill,
                    image: AssetImage(('images/avatars/${(e.hem.hemKennelUserPhoto ?? e.hasher.photo!).toLowerCase().replaceFirst('bundle://', '')}.jpg').toLowerCase()),
                  )
                : const Image(
                    width: 300.0,
                    height: 300.0,
                    fit: BoxFit.fill,
                    image: AssetImage('images/avatars/avatar-2.jpg'),
                  ),
        if (isGrid) ...<Widget>[
          Positioned(
            right: 1.0,
            bottom: 1.0,
            child: _rsvpIcon(e),
          ),
        ],
      ],
    );
  }

  Stack _rsvpIcon(PackListAggregate e) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 11.0,
        ),
        (e.hem.rsvpState <= 0)
            ? const CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 10.0,
              )
            : (e.hem.rsvpState == 1)
                ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 21.0)
                : (e.hem.rsvpState == 2)
                    ? const Icon(FontAwesome.question_circle, color: Colors.orange, size: 21.0)
                    : (e.hem.isHare == 0)
                        ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 21.0)
                        : Image.asset('images/icons/hare_icon.png', color: Colors.deepPurple, height: 18.0, width: 18.0),
      ],
    );
  }

  Future<void> _setRsvpHare() async {
    final bool willHare = await Utilities.promptForHare(widget.futureRun.event.hares ?? '') ?? false;
    if (willHare) {
      List<PackListAggregate>? lPla = await _thePackList;
      if (lPla != null) {
        setState(() {
          if (_thisUserIndex >= 0) {
            PackListAggregate a = lPla[_thisUserIndex];
            lPla[_thisUserIndex] = PackListAggregate(hasher: a.hasher, displayName: a.displayName, hem: a.hem.copyWith(rsvpState: -1, isHare: -1));

            // _thePackList[_thisUserIndex].hem.rsvpState = -1;
            // _thePackList[_thisUserIndex].hem.isHare = -1;
            _rsvpRequested = rsvpYes;
          }
        });
      }

      //final String userId = getStringPref(StringPrefsEnum.userId);
      final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventRsvp(
            widget.futureRun.event.eventId,
            _userId,
            AppDomainType.user,
            rsvpYes.value,
            isHareYes.value,
          );

      await _refreshHemTableFromBackend(false);
      final String serverMessage = adHocData[0]['serverMessage'] ?? '';

      if (serverMessage.isNotEmpty) {
        await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
      }
    }
  }

  Future<void> _setRsvpState(EnumRsvpState<int> rsvpState) async {
    List<PackListAggregate>? lPla = await _thePackList;
    if (lPla != null) {
      setState(() {
        if (_thisUserIndex >= 0) {
          // _thePackList[_thisUserIndex].hem.rsvpState = -1;
          // _thePackList[_thisUserIndex].hem.isHare = 0;

          PackListAggregate a = lPla[_thisUserIndex];
          lPla[_thisUserIndex] = PackListAggregate(hasher: a.hasher, displayName: a.displayName, hem: a.hem.copyWith(rsvpState: -1, isHare: 0));
        }
        _rsvpRequested = rsvpState;
      });
    }
    //final String userId = getStringPref(StringPrefsEnum.userId);

    final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventRsvp(
          widget.futureRun.event.eventId,
          _userId,
          AppDomainType.user,
          rsvpState.value,
          isHareNo.value,
        );

    await _refreshHemTableFromBackend(false);
    final String serverMessage = adHocData[0]['serverMessage'] ?? '';

    if (serverMessage.isNotEmpty) {
      await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
    }
  }

  Widget _buildMapView() {
    final List<double?> coords =
        Utilities.getLatLongFromString(<String>[widget.futureRun.event.locationOneLineDesc ?? '', widget.futureRun.event.eventDescription ?? '', widget.futureRun.event.eventName]);

    return ConnectedWidget(
      refreshFunction: () {
        setState(() {});
      },
      showConnectButton: true,
      disconnectedChild: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
            child: Text(
          'Maps require a connection to the Internet',
          style: ts_headingLarge,
          textAlign: TextAlign.center,
        )),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          // Map
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              MyFlutterMap(
                (widget.futureRun.extensions.latitude ?? coords[0]) == null
                    ? null
                    : latlng.LatLng((widget.futureRun.extensions.latitude ?? coords[0]!), (widget.futureRun.extensions.longitude ?? coords[1])!),
                _mapCenter,
                latlng.LatLng(widget.futureRun.kennel.kennelLatitude!, widget.futureRun.kennel.kennelLongitude!),
                1.0,
                18.0,
                14.0,
                _trueNorthLock,
                _mapKey,
                mapMoved: (latlng.LatLng newPosition) {
                  _mapCenter = newPosition;
                },
                markerClicked: () {
                  _launchMaps(widget.futureRun);
                },
              ),
              Positioned(
                left: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _trueNorthLock = !_trueNorthLock;
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset(_trueNorthLock ? 'images/other/set_map_to_true_north_lock.png' : 'images/other/set_map_rotation_enabled.png'),
                  ),
                ),
              ),
              if (widget.futureRun.extensions.isMapAndDistanceValid == 0) ...<Widget>[
                Positioned(
                  right: 10.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      _mapCenter = latlng.LatLng(widget.futureRun.extensions.latitude ?? widget.futureRun.kennel.kennelLatitude ?? DEFAULT_LATITUDE,
                          widget.futureRun.extensions.longitude ?? widget.futureRun.kennel.kennelLongitude ?? DEFAULT_LONGITUDE);

                      setState(() {});
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset('images/other/set_map_to_event_location.png'),
                    ),
                  ),
                ),
                Positioned(
                  right: 70.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if ((G0<DeviceInfo>().deviceLat != null) && (G0<DeviceInfo>().deviceLon != null)) {
                          _mapCenter = latlng.LatLng(G0<DeviceInfo>().deviceLat!, G0<DeviceInfo>().deviceLon!);
                        }
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
              if (widget.futureRun.extensions.isMapAndDistanceValid != 1) ...<Widget>[
                Container(color: Colors.black54),
                Container(
                  margin: const EdgeInsets.only(bottom: 60.0),
                  child: Text(
                    'No location provided',
                    textAlign: TextAlign.center,
                    style: ts_headingVeryLarge,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  bool _fabIsVisible = false;

  Widget _getRsvpButton(IconData iconData, Color iconColor, String text, EnumRsvpState<int> rsvpState) {
    return ElevatedButton(
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
                )
              ],
            ),
            const SizedBox(width: 15.0),
            Text(
              text,
              style: ts_button,
            ),
          ],
        ),
      ),
      onPressed: () async {
        await _setRsvpState(rsvpState);
      },
    );
  }

  List<Widget> _getRsvpButtons() {
    if (_rsvpRequested != rsvpUnknown) {
      return <Widget>[const HcCircularProgressIndicator(key: Key('3920394'))];
    } else {
      return <Widget>[
        const SizedBox(height: 30.0),
        _getRsvpButton(FontAwesome.check_circle, Colors.green, 'I\'ll be there!', rsvpYes),
        _getRsvpButton(FontAwesome.check_circle, Colors.orange, 'I might come!', rsvpMaybe),
        _getRsvpButton(FontAwesome.check_circle, Colors.red, 'I will not come', rsvpNo),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    //getPack(false);

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: AnimatedOpacity(
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
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: const CircleBorder(),
          children: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Feather.x),
              backgroundColor: Colors.red[800],
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
            SpeedDialChild(
              child: const ImageIcon(AssetImage('images/icons/hare_icon.png'), color: Colors.deepPurple),
              backgroundColor: Colors.white,
              label: 'I will hare',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                await _setRsvpHare();
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Column(
          children: <Widget>[
            PreferredSize(
              preferredSize: const Size.fromHeight(120.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(0.0)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    child: TextScaleFactorClamper(
                      textScaleFactor: G0<DeviceInfo>().textClamp15,
                      child: TabBar(
                        labelStyle: ts_condensedBoldBlack,
                        unselectedLabelStyle: ts_condensedMediumBlack,
                        isScrollable: true,
                        labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                        unselectedLabelColor: Colors.black,
                        labelColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BubbleTabIndicator(
                          indicatorHeight: 30.0,
                          indicatorColor: Colors.red.shade900,
                          tabBarIndicatorSize: TabBarIndicatorSize.tab,
                          indicatorRadius: 20.0,
                          // bubblePadding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                          // insets: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
                        ),
                        tabs: _tabs,
                        controller: _tabController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: <Widget>[
                _buildRunDetailsView(),
                _buildRsvpView(),
                _buildMapView(),
                ConnectedWidget(
                  refreshFunction: () {
                    setState(() {});
                  },
                  showConnectButton: true,
                  disconnectedChild: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                        child: Text(
                      '"Get a life" leaderboards require a connection to the Internet',
                      style: ts_headingLarge,
                      textAlign: TextAlign.center,
                    )),
                  ),
                  child: Leaderboard(
                    kennelId: widget.futureRun.kennel.kennelId,
                  ),
                ),
              ]
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

    if (rda.extensions.latitude != null) {
      lat = rda.extensions.latitude;
    }

    if (rda.extensions.longitude != null) {
      lon = rda.extensions.longitude;
    }

    if ((lat == null) || (lon == null)) {
      // try to get lat/lons from other sources
      final List<double?> coords = Utilities.getLatLongFromString(<String>[rda.event.locationOneLineDesc ?? '', rda.event.eventDescription ?? '', rda.event.eventName]);

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
        final List<maps.AvailableMap> availableMaps = await maps.MapLauncher.installedMaps;
        final maps.AvailableMap activeMap = availableMaps.where((maps.AvailableMap map) => map.mapName == mapName).first;

        // BUG in plugin - doesn't work when sending a title with Google maps
        activeMap.showMarker(
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
}
