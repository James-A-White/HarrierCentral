// @dart=2.11

// import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

class LeaderboardModel {
  String displayName;
  int totalRunCount;
  int totalHaringCount;
  int ytdTotalRunCount;
  int ytdHaringCount;
  int rollingYearTotalRunCount;
  int rollingYearHaringCount;

  LeaderboardModel({this.displayName, this.totalRunCount, this.totalHaringCount, this.ytdTotalRunCount, this.ytdHaringCount, this.rollingYearTotalRunCount, this.rollingYearHaringCount});

  LeaderboardModel.fromJson(Map<String, dynamic> json) {
    displayName = json['displayName'];
    totalRunCount = json['totalRunCount'];
    totalHaringCount = json['totalHaringCount'];
    ytdTotalRunCount = json['ytdTotalRunCount'];
    ytdHaringCount = json['ytdHaringCount'];
    rollingYearTotalRunCount = json['rollingYearTotalRunCount'];
    rollingYearHaringCount = json['rollingYearHaringCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['displayName'] = displayName;
    data['totalRunCount'] = totalRunCount;
    data['totalHaringCount'] = totalHaringCount;
    data['ytdTotalRunCount'] = ytdTotalRunCount;
    data['ytdHaringCount'] = ytdHaringCount;
    data['rollingYearTotalRunCount'] = rollingYearTotalRunCount;
    data['rollingYearHaringCount'] = rollingYearHaringCount;
    return data;
  }
}

class RunTabs extends StatefulWidget {
  const RunTabs({Key key, @required this.futureRun}) : super(key: key);

  final RunDetailsAggregate futureRun;

  @override
  State<RunTabs> createState() {
    return RunTabsState();
  }
}

class PackListAggregate {
  PackListAggregate({
    this.hem,
    this.hasher,
    this.displayName,
  });

  final HasherEventMapModel hem;
  final HashersModel hasher;
  final String displayName;
}

class RunTabsState extends State<RunTabs> with TickerProviderStateMixin {
  final List<Tab> _tabs = <Tab>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //GlobalKey packListBox = GlobalKey();

  final ScrollController _scrollController = ScrollController();
  final ScrollController _leaderScrollController = ScrollController();

  bool isAdmin = true;
  //bool _isLoading = true;

  latlng.LatLng _mapCenter;

  bool _trueNorthLock = true;

  List<PackListAggregate> _thePackList;
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

    await _refreshPackListFromTable();
    await _refreshPackCountFromTable(true);
  }

  int _thisUserIndex = -1;

  Future<void> _refreshPackListFromTable() async {
    final String query = ''' 
        SELECT  
          hem.*,
          h.*
          FROM hasherEventMapForRunAdmin hem
          LEFT OUTER JOIN hashers h on h.${G0<TableModel>().hashersTableHelper.colHasherId} = hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId}
          WHERE hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = "${widget.futureRun.event.eventId}"
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${G0<TableModel>().hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    _thePackList = <PackListAggregate>[];
    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final HasherEventMapModel packItem = G0<TableModel>().hasherEventMapTableHelper.fromMap(results[i]);
        final HashersModel hasherItem = HashersModel.fromJson(results[i]);
        String displayName = hasherItem.dispName;
        if (packItem.virginVisitorType != 0) {
          displayName = packItem.displayName;
        }
        _thePackList.add(PackListAggregate(hem: packItem, hasher: hasherItem, displayName: displayName));
      }
    } catch (e) {
      //print(e);
    }

    _thePackList.sort(
      (PackListAggregate a, PackListAggregate b) => a.displayName.compareTo(b.displayName),
    );

    _thisUserIndex = -1;

    for (int i = 0; i < _thePackList.length; i++) {
      if (_thePackList[i].hasher.hasherId == _userId) {
        _thisUserIndex = i;
        break;
      }
    }
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

  // ignore: non_constant_identifier_names
  final String LABEL_DETAILS = 'Details';
  // ignore: non_constant_identifier_names
  final String LABEL_MAP = 'Map';
  // ignore: non_constant_identifier_names
  final String LABEL_RSVP = 'RSVP';
  // ignore: non_constant_identifier_names
  final String LABEL_GETALIFE = 'Get A Life';

  void _initTabs() {
    _tabs.clear();
    _tabs.add(Tab(text: LABEL_DETAILS));
    _tabs.add(Tab(text: LABEL_RSVP));
    _tabs.add(Tab(text: LABEL_MAP));
    _tabs.add(Tab(text: LABEL_GETALIFE));
  }

  TabController _tabController;
  TabController _gridListTabController;
  TabController _leaderboardTabController;

  List<LeaderboardModel> _leaderboardList;

  //final GetPackService _getPackService = GetPackService();

  final String _userId = getStringPref(StringPrefsEnum.userId);

  int _currentTabIndex = -1;

  @override
  void initState() {
    //_scrollController.createScrollPosition(physics, context, oldPosition) = 0;
    //_refreshHemTableFromBackend(false);
    _initTabs();
    _tabController = TabController(vsync: this, length: _tabs.length);
    _gridListTabController = TabController(vsync: this, length: 2);
    _leaderboardTabController = TabController(vsync: this, length: 3);

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

      if ((_tabController.index != _currentTabIndex) && (_tabs[_tabController.index].text == LABEL_GETALIFE)) {
        if (_leaderboardList == null) {
          _getLeaderboard().then(
            (value) {
              setState(() {
                _leaderboardSortColumnIndex = 0;
                _sortOrderDesc = true;
                _sortLeaderboard(_leaderboardSortColumnIndex);
              });
            },
          );
        }
      }

      setState(() {});

      _currentTabIndex = _tabController.index;
    });

    final List<double> coords = Utilities.getLatLongFromString(<String>[widget.futureRun.event.locationOneLineDesc, widget.futureRun.event.eventDescription, widget.futureRun.event.eventName]);

    _mapCenter = latlng.LatLng(widget.futureRun.extensions.latitude ?? coords[0] ?? widget.futureRun.kennel.kennelLatitude + .0,
        widget.futureRun.extensions.longitude ?? coords[1] ?? widget.futureRun.kennel.kennelLongitude + .0);

    if ((widget.futureRun.extensions.rsvpState ?? 0) == 0) {
      _tabController.animateTo(1);
    }
    super.initState();
  }

  Future<void> _getLeaderboard() async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'getLeaderboard');

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': widget.futureRun.kennel.kennelId,
    });

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_get_leaderboard', body);

    List<dynamic> jsonResults = json.decode(responseBody);

    _leaderboardList = <LeaderboardModel>[];

    jsonResults[0].forEach((element) {
      _leaderboardList.add(LeaderboardModel.fromJson(element));
    });

    return;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gridListTabController.dispose();
    _leaderScrollController.dispose();
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
      widget.futureRun.extensions.isMapAndDistanceValid,
      eventUrlWithKennelBackup: widget.futureRun.event.eventUrl ?? widget.futureRun.kennel.kennelEventsUrl,
      isMember: widget.futureRun.extensions.isMember,
      isPaid: widget.futureRun.extensions.isPaid,
      rsvpState: widget.futureRun.extensions.rsvpState,
      processPayment: (int r, int p) {
        widget.futureRun.extensions.rsvpState = r;
        if (p != -1) {
          widget.futureRun.extensions.isPaid = p;
        }
        setState(() {});
      },
    );
  }

  TextStyle rsvpTitlesView =
      TextStyle(color: Colors.white, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1);

  EnumRsvpState<int> _rsvpRequested = rsvpUnknown;

  Widget _buildRsvpView() {
    //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');

    return Center(
        child: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
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
                              : _thePackList[_thisUserIndex].hem.rsvpState == rsvpYes.value
                                  ? Colors.green
                                  : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpYes)
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
                              : _thePackList[_thisUserIndex].hem.rsvpState == rsvpMaybe.value
                                  ? Colors.orange
                                  : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpMaybe)
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
                              : _thePackList[_thisUserIndex].hem.rsvpState == rsvpNo.value
                                  ? Colors.red
                                  : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && _rsvpRequested == rsvpNo)
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
                              : _thePackList[_thisUserIndex].hem.isHare == isHareYes.value
                                  ? Colors.deepPurple
                                  : _thePackList[_thisUserIndex].hem.isHare == -1
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
          child: _thePackList == null
              ? const SizedBox(
                  //color: Colors.grey[300],
                  width: 70.0,
                  height: 70.0,
                  child: Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: Key('22030392')))),
                )
              : _thePackList.isEmpty
                  ? Column(
                      children: <Widget>[
                        const Expanded(flex: 40, child: SizedBox()),
                        Text(
                          'Be the first to RSVP\r\nfor this run!',
                          style: largeTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                        if (_thisUserIndex == -1) ..._getRsvpButtons(),
                        const Expanded(flex: 100, child: SizedBox()),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        if (_thisUserIndex == -1) ..._getRsvpButtons(),
                        if (_thisUserIndex == -1) ...<Widget>[const SizedBox(height: 10)],
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          width: 140.0,
                          child: TabBar(
                            onTap: (void _) {
                              setState(() {});
                            },
                            labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 22.0),
                            unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 22.0),
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
                                        itemCount: _thePackList.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final PackListAggregate e = _thePackList[index];

                                          return GestureDetector(
                                            onTap: () {
                                              _getHasherZoomablePhoto(e);
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
                                                  child: Text(e.displayName ?? '<unknown>',
                                                      style: const TextStyle(
                                                        fontFamily: 'AvenirNextCondensedMedium',
                                                        fontStyle: FontStyle.normal,
                                                        fontSize: 25.0,
                                                        height: 1.0,
                                                        color: Colors.white,
                                                      )),
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
                                              children: _thePackList.map((PackListAggregate e) {
                                                return StaggeredGridTile.count(
                                                  crossAxisCellCount: (e.hem.isHare != 0) ? 2 : 1,
                                                  mainAxisCellCount: (e.hem.isHare != 0) ? 2 : 1,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _getHasherZoomablePhoto(e);
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
    ));
  }

  Future<void> _getHasherZoomablePhoto(PackListAggregate e) async {
    if (e.hasher.hasherId != null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ZoomableImagePage2(
              key: const Key('39392001'),
              pageTitle: e.hasher.dispName,
              imageUrl: e.hasher.photo.startsWith('http') ? e.hasher.photo : null,
              assetImage: e.hasher.photo.contains('bundle://') ? 'images/avatars/${e.hasher.photo.replaceAll('bundle://', '')}.jpg' : null,
              appBarBackgroundColor: themeAppBarBackground,
              background: Backgrounds.defaultHcBackground(),
              margin: 20.0),
        ),
      );
    }
  }

  Stack _hasherPhoto(PackListAggregate e, bool isGrid) {
    return Stack(
      children: <Widget>[
        e.hasher.hasherId == null
            ? const Image(
                width: 300.0,
                height: 300.0,
                fit: BoxFit.fill,
                image: AssetImage(
                  'images/avatars/avatar-0.jpg',
                ))
            : e.hasher.photo.startsWith('http')
                ? CachedNetworkImage(imageUrl: e.hasher.photo, fadeInDuration: const Duration(milliseconds: 0), width: 300.0, height: 300.0, fit: BoxFit.fill)
                : e.hasher.photo.startsWith('bundle')
                    ? Image(
                        width: 300.0,
                        height: 300.0,
                        fit: BoxFit.fill,
                        image: AssetImage(('images/avatars/${e.hasher.photo.toLowerCase().replaceFirst('bundle://', '')}.jpg').toLowerCase()),
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
        (e?.hem?.rsvpState ?? 0) <= 0
            ? const CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 10.0,
              )
            : (e?.hem?.rsvpState ?? 0) == 1
                ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 21.0)
                : (e?.hem?.rsvpState ?? 0) == 2
                    ? const Icon(FontAwesome.question_circle, color: Colors.orange, size: 21.0)
                    : (e?.hem?.isHare ?? 0) == 0
                        ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 21.0)
                        : Image.asset('images/icons/hare_icon.png', color: Colors.deepPurple, height: 18.0, width: 18.0),
      ],
    );
  }

  Future<void> _setRsvpHare() async {
    final bool willHare = await Utilities.promptForHare(context, widget.futureRun.event.hares ?? '');
    if (willHare) {
      setState(() {
        if (_thisUserIndex >= 0) {
          _thePackList[_thisUserIndex].hem.rsvpState = -1;
          _thePackList[_thisUserIndex].hem.isHare = -1;
          _rsvpRequested = rsvpYes;
        }
      });

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
        await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'RSVP Result', serverMessage, 'OK');
      }
    }
  }

  Future<void> _setRsvpState(EnumRsvpState<int> rsvpState) async {
    setState(() {
      if (_thisUserIndex >= 0) {
        _thePackList[_thisUserIndex].hem.rsvpState = -1;
        _thePackList[_thisUserIndex].hem.isHare = 0;
      }
      _rsvpRequested = rsvpState;
    });
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
      await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'RSVP Result', serverMessage, 'OK');
    }
  }

  Future<void> _openMapsSheet(BuildContext context, String title, maps.Coords coords, String address) async {
    try {
      final List<maps.AvailableMap> availableMaps = await maps.MapLauncher.installedMaps;

      await showModalBottomSheet<dynamic>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: (availableMaps.length * 64.0) + 170,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14.0, top: 14.0),
                    child: Center(
                      child: Text('Select map provider',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24.0,
                          )),
                    ),
                  ),
                  const Divider(height: 1.0, color: Colors.black87),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        for (maps.AvailableMap map in availableMaps)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              onTap: () async {
                                if (_saveUserMapPreference.value) {
                                  await setStringPref(StringPrefsEnum.mapPreference, map.mapName);
                                }
                                if (!mounted) return;
                                Navigator.of(context).pop();

                                await Future<void>.delayed(const Duration(milliseconds: 200));

                                // BUG in plugin - doesn't work when sending a title with Google maps
                                await map.showMarker(
                                  coords: coords,
                                  title: map.mapName.contains('Google') ? '' : title,
                                  description: address,
                                );
                              },
                              title: Text(map.mapName,
                                  style: const TextStyle(
                                    fontFamily: 'AvenirNextDemiBold',
                                    color: Colors.black,
                                    fontSize: 26.0,
                                  )),
                              leading: SvgPicture.asset(
                                map.icon,
                                height: 60.0,
                                width: 60.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30.0),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SnackContent(_saveUserMapPreference, (bool x) {
                        setState(() {
                          _saveUserMapPreference.value = x;
                        });
                      }),
                      const Text(
                        'Always use this option',
                        style: TextStyle(
                          fontFamily: 'AvenirNextDemiBold',
                          color: Colors.black,
                          fontSize: 22.0,
                        ),
                      ),
                      const SizedBox(width: 20.0)
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // ignore: constant_identifier_names
  static const double LEADER_FONT_SIZE = 22.0;

  int _leaderboardSortColumnIndex = 0;

  Widget _buildLeaderboardView() {
    //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');

    return Center(
        child: Column(
      children: <Widget>[
        Expanded(
          child: _leaderboardList == null
              ? const SizedBox(
                  //color: Colors.grey[300],
                  width: 70.0,
                  height: 70.0,
                  child: Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: Key('22030392')))),
                )
              : _leaderboardList.isEmpty
                  ? Column(
                      children: <Widget>[
                        const Expanded(flex: 40, child: SizedBox()),
                        Text(
                          'No run counts\r\nregistered for\r\nthis Kennel.',
                          style: largeTitleStyle,
                          textAlign: TextAlign.center,
                        ),
                        const Expanded(flex: 100, child: SizedBox()),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          //width: 140.0,
                          child: TabBar(
                            onTap: (void _) {
                              setState(() {});
                            },
                            labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 22.0),
                            unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 22.0),
                            isScrollable: false,
                            unselectedLabelColor: Colors.white,
                            labelColor: Colors.white,
                            //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BubbleTabIndicator(
                              indicatorHeight: 30.0,
                              indicatorColor: Colors.red.shade900,
                              tabBarIndicatorSize: TabBarIndicatorSize.label,
                              indicatorRadius: 20.0,
                            ),
                            tabs: const <Tab>[
                              Tab(text: 'Total'),
                              Tab(text: '365 days'),
                              Tab(text: 'This year'),
                            ],
                            controller: _leaderboardTabController,
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Expanded(
                          child: Container(
                            //key: packListBox,
                            color: const Color.fromARGB(60, 255, 255, 255),
                            margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
                            padding: const EdgeInsets.all(8.0),
                            width: MediaQuery.of(context).size.width,
                            child: Scrollbar(
                                controller: _leaderScrollController,
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _sortLeaderboard(0);
                                              },
                                            );
                                          },
                                          child: const SizedBox(
                                            width: 50.0,
                                            child: Text(
                                              'Runs',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _sortLeaderboard(1);
                                              },
                                            );
                                          },
                                          child: const SizedBox(
                                            width: 70.0,
                                            child: Text(
                                              'Hared',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(2);
                                              });
                                            },
                                            child: const Text(
                                              'Hasher',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'AvenirNextCondensedMedium',
                                                fontStyle: FontStyle.normal,
                                                fontSize: LEADER_FONT_SIZE,
                                                height: 1.0,
                                                color: Colors.yellow,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _sortLeaderboard(0);
                                            });
                                          },
                                          child: SizedBox(
                                            width: 50.0,
                                            child: _leaderboardSortColumnIndex != 0
                                                ? null
                                                : Icon(
                                                    _sortOrderDesc ? AntDesign.caretup : AntDesign.caretdown,
                                                    size: 20.0,
                                                    color: Colors.yellow,
                                                  ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _sortLeaderboard(1);
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: 70.0,
                                            child: _leaderboardSortColumnIndex != 1
                                                ? null
                                                : Icon(
                                                    _sortOrderDesc ? AntDesign.caretup : AntDesign.caretdown,
                                                    size: 20.0,
                                                    color: Colors.yellow,
                                                  ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _sortLeaderboard(2);
                                              });
                                            },
                                            child: SizedBox(
                                              child: _leaderboardSortColumnIndex != 2
                                                  ? null
                                                  : Icon(
                                                      _sortOrderDesc ? AntDesign.caretup : AntDesign.caretdown,
                                                      size: 20.0,
                                                      color: Colors.yellow,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                      ],
                                    ),
                                    const SizedBox(height: 7.0),
                                    Expanded(
                                      child: ListView.separated(
                                          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 3.0),
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          controller: _leaderScrollController,
                                          itemCount: _leaderboardList.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final LeaderboardModel e = _leaderboardList[index];

                                            return Row(
                                              children: <Widget>[
                                                SizedBox(
                                                    width: 50.0,
                                                    child: Text(
                                                        (_leaderboardTabController.index == 0
                                                                ? e.totalRunCount
                                                                : _leaderboardTabController.index == 1
                                                                    ? e.rollingYearTotalRunCount
                                                                    : e.ytdTotalRunCount)
                                                            .toString(),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
                                                SizedBox(
                                                    width: 70.0,
                                                    child: Text(
                                                        (_leaderboardTabController.index == 0
                                                                ? e.totalHaringCount
                                                                : _leaderboardTabController.index == 1
                                                                    ? e.rollingYearHaringCount
                                                                    : e.ytdHaringCount)
                                                            .toString(),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
                                                Expanded(
                                                    child: Text(e.displayName ?? '<unknown>',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'AvenirNextCondensedMedium',
                                                          fontStyle: FontStyle.normal,
                                                          fontSize: LEADER_FONT_SIZE,
                                                          height: 1.0,
                                                          color: Colors.white,
                                                        ))),
                                              ],
                                            );
                                          }),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    ));
  }

  bool _sortOrderDesc = false;

  void _sortLeaderboard(int columnIndex) {
    if (columnIndex == _leaderboardSortColumnIndex) {
      _sortOrderDesc = !_sortOrderDesc;
    }

    _leaderboardSortColumnIndex = columnIndex;

    switch (_leaderboardSortColumnIndex) {
      // sort runs
      case 0:
        switch (_leaderboardTabController.index) {
          case 0:
            _leaderboardList.sort((a, b) {
              int cmp = a.totalRunCount.compareTo(b.totalRunCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case 1:
            _leaderboardList.sort((a, b) {
              int cmp = a.rollingYearTotalRunCount.compareTo(b.rollingYearTotalRunCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;

          case 2:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdTotalRunCount.compareTo(b.ytdTotalRunCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort haring
      case 1:
        switch (_leaderboardTabController.index) {
          case 0:
            _leaderboardList.sort((a, b) {
              int cmp = a.totalHaringCount.compareTo(b.totalHaringCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case 1:
            _leaderboardList.sort((a, b) {
              int cmp = a.rollingYearHaringCount.compareTo(b.rollingYearHaringCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
          case 2:
            _leaderboardList.sort((a, b) {
              int cmp = a.ytdHaringCount.compareTo(b.ytdHaringCount);
              if (cmp != 0) return _sortOrderDesc ? cmp : -cmp;
              return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
            });
            break;
        }
        break;
      // sort by name
      case 2:
        _sortOrderDesc
            ? _leaderboardList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()))
            : _leaderboardList.sort((b, a) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
    }
  }

  Widget _buildMapView() {
    final List<double> coords = Utilities.getLatLongFromString(<String>[widget.futureRun.event.locationOneLineDesc, widget.futureRun.event.eventDescription, widget.futureRun.event.eventName]);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        // Map
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            MyFlutterMap(
              (widget.futureRun.extensions.latitude ?? coords[0]) == null
                  ? null
                  : latlng.LatLng((widget.futureRun.extensions.latitude ?? coords[0]) + .0, (widget.futureRun.extensions.longitude ?? coords[1]) + .0),
              _mapCenter,
              latlng.LatLng(widget.futureRun.kennel.kennelLatitude + .0, widget.futureRun.kennel.kennelLongitude + .0),
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
            if (widget.futureRun.extensions.isMapAndDistanceValid) ...<Widget>[
              Positioned(
                right: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    _mapCenter = latlng.LatLng(
                        widget.futureRun.extensions.latitude ?? widget.futureRun.kennel.kennelLatitude + .0, widget.futureRun.extensions.longitude ?? widget.futureRun.kennel.kennelLongitude + .0);

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
                      _mapCenter = latlng.LatLng(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon);
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
            if (!widget.futureRun.extensions.isMapAndDistanceValid) ...<Widget>[
              Container(color: Colors.black54),
              Container(
                margin: const EdgeInsets.only(bottom: 60.0),
                child: Text(
                  'No location provided',
                  textAlign: TextAlign.center,
                  style: largeTitleStyle,
                ),
              ),
            ]
          ],
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
              style: textStyleButton,
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
              child: Padding(
                padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 15),
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
                      child: TabBar(
                        labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                        unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
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
                _buildLeaderboardView(),
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
    num lat;
    num lon;
    String address = '';

    if (rda.extensions.latitude != null) {
      lat = rda.extensions.latitude;
    }

    if (rda.extensions.longitude != null) {
      lon = rda.extensions.longitude;
    }

    if ((lat == null) || (lon == null)) {
      // try to get lat/lons from other sources
      final List<double> coords = Utilities.getLatLongFromString(<String>[rda.event.locationOneLineDesc, rda.event.eventDescription, rda.event.eventName]);

      if ((coords[0] != null) && (coords[1] != null)) {
        lat = coords[0];
        lon = coords[1];
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
      address = rda.event.locationOneLineDesc;
    }

    // use the native map provider for the selected platform
    if ((lat != null) && (lon != null)) {
      final String mapName = getStringPref(StringPrefsEnum.mapPreference);
      if (mapName == null) {
        await _openMapsSheet(context, address, maps.Coords(lat, lon), rda.event.eventName ?? '');
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
      await IveCoreUtilities.showAlert(
          navigatorKey.currentContext, 'No location information available', 'There is no location information available for this run and so we cannot display a map', 'OK');
    }
  }

  final ValueNotifier<bool> _saveUserMapPreference = ValueNotifier<bool>(false);
}

/// The ValueListenableBuilder rebuilds whenever [snackMsg] changes.
class SnackContent extends StatelessWidget {
  const SnackContent(this.snackState, this.snackOnClick, {Key key}) : super(key: key);

  final ValueNotifier<bool> snackState;
  final Function snackOnClick;

  @override
  Widget build(BuildContext context) {
    /// ValueListenableBuilder rebuilds whenever snackMsg value changes.
    /// i.e. this "listens" to changes of ValueNotifier "snackMsg".
    /// "msg" in builder below is the value of "snackMsg" ValueNotifier.
    /// We don't use the other builder args for this example so they are
    /// set to _ & __ just for readability.
    return ValueListenableBuilder<bool>(
        valueListenable: snackState,
        builder: (_, bool msg, __) {
          return Checkbox(
              value: msg,
              onChanged: (bool x) {
                snackOnClick(x);
              });
        });
  }
}

// class _Tile extends StatelessWidget {
//   const _Tile(this.source, this.index);

//   final String source;
//   final int index;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: <Widget>[
//           Image.network(source),
//           Padding(
//             padding: const EdgeInsets.all(4.0),
//             child: Column(
//               children: <Widget>[
//                 Text(
//                   'Image number $index',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const Text(
//                   'Vincent Van Gogh',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

class RectClipper extends CustomClipper<Rect> {
  RectClipper({@required this.width, @required this.height});

  num width;
  num height;

  @override
  Rect getClip(Size size) {
    final Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
