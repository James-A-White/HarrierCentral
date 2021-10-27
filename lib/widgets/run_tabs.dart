// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

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
  });

  final HasherEventMapModel hem;
  final HashersModel hasher;
}

class RunTabsState extends State<RunTabs> with SingleTickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey packListBox = GlobalKey();

  bool isAdmin = true;
  //bool _isLoading = true;

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

    await refreshPackListFromTable(false);
    await refreshPackCountFromTable(true);
  }

  int _thisUserIndex = -1;

  Future<void> refreshPackListFromTable(bool callSetState) async {
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
        _thePackList.add(PackListAggregate(hem: packItem, hasher: hasherItem));
        if (packItem.userId == userId) {
          _thisUserIndex = i;
        }
        if (callSetState && (i == results.length - 1)) {
          setState(() {});
        }
      }
    } catch (e) {
      //print(e);
    }
  }

  Future<void> refreshPackCountFromTable(bool callSetState) async {
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

  void _initTabs() {
    tabs.clear();
    tabs.add(const Tab(text: 'Details'));
    tabs.add(const Tab(text: 'RSVP'));
    tabs.add(const Tab(text: 'Map'));
  }

  TabController _tabController;

  //final GetPackService _getPackService = GetPackService();

  final String userId = getStringPref(StringPrefsEnum.userId);

  @override
  void initState() {
    _refreshHemTableFromBackend(false);
    _initTabs();
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() async {
      if (fabIsVisible != (tabs[_tabController.index].text.toLowerCase() == 'rsvp')) {
        setState(() {
          fabIsVisible = tabs[_tabController.index].text.toLowerCase() == 'rsvp';
          if (tabs[_tabController.index].text.toLowerCase() == 'rsvp') {
            //print('refreshing RSVP data from backend @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
            _refreshHemTableFromBackend(false);
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int flexLeft = 27;
  int flexRight = 73;

  num spaceBetweenColumns = 11.0;
  num spaceBetweenRows = 23.0;

  Widget buildRunDetailsView() {
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

  EnumRsvpState<int> rsvpRequested = rsvpUnknown;

  Container buildRsvpView() {
    //print('buildRsvpView() -  = ${DateTime.now().millisecondsSinceEpoch}');

    return Container(
      child: Center(
          child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
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
                                    : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && rsvpRequested == rsvpYes)
                                        ? Colors.blue
                                        : Colors.grey,
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 35.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              setRsvpState(rsvpYes);
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
                Container(
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
                                    : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && rsvpRequested == rsvpMaybe)
                                        ? Colors.blue
                                        : Colors.grey,
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 35.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              setRsvpState(rsvpMaybe);
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
                Container(
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
                                    : (_thePackList[_thisUserIndex].hem.rsvpState == -1 && rsvpRequested == rsvpNo)
                                        ? Colors.blue
                                        : Colors.grey,
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 35.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              setRsvpState(rsvpNo);
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
                Container(
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
                            onPressed: () {
                              _promptForHare(widget.futureRun.event.hares ?? '').then<dynamic>((bool willHare) {
                                if (willHare) {
                                  setState(() {
                                    if (_thisUserIndex >= 0) {
                                      _thePackList[_thisUserIndex].hem.rsvpState = -1;
                                      _thePackList[_thisUserIndex].hem.isHare = -1;
                                      rsvpRequested = rsvpYes;
                                    }
                                  });
                                  //final String userId = getStringPref(StringPrefsEnum.userId);

                                  final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
                                        widget.futureRun.event.eventId,
                                        userId,
                                        null,
                                        AppDomainType.user,
                                        rsvpState: rsvpYes.value,
                                        isHare: isHareYes.value,
                                      );

                                  retVal.then((List<dynamic> adHocData) async {
                                    await _refreshHemTableFromBackend(false);
                                  });
                                }
                              });

                              // model.setRsvpState(
                              //     rsvpHare.value, widget.futureRun);
                              //model.toggleFollowing(kennel);

                              // setState(() {
                              // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
                              // });
                            },
                          ),
                        ],
                      ),
                      Text(
                        (_packCount['isHareCount'] ?? 0) >= 0 ? (_packCount['isHareCount'] ?? 0).toString() : '',
                        style: rsvpTitlesView,
                      ),

                      // Text(
                      //   widget.futureRun.haresCount >= 0
                      //       ? widget.futureRun.haresCount.toString()
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
              ],
            ),
          ),
          Expanded(
            child: Container(
              key: packListBox,
              color: const Color.fromARGB(60, 255, 255, 255),
              margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 15.0),
              padding: const EdgeInsets.all(8.0),
              child: Scrollbar(
                child: RefreshIndicator(
                  onRefresh: () => _refreshHemTableFromBackend(true),
                  child: StaggeredGridView.countBuilder(
                    crossAxisCount: 4,
                    itemCount: _thePackList?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      // if (thePackList[index].hem.userId == userId) {
                      //   thePackList[index].hem.rsvpState = widget.futureRun.extensions.rsvpState;
                      //   thePackList[index].hem.isHare = widget.futureRun.extensions.isHare;
                      // }

                      return _thePackList.isEmpty
                          ? Container(
                              color: Colors.grey[300],
                              width: 70.0,
                              height: 70.0,
                              child: Padding(padding: const EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator(key: UniqueKey()))),
                            )
                          : GestureDetector(
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) => ZoomableImagePage2(
                                        key: UniqueKey(),
                                        pageTitle: _thePackList[index].hasher.dispName,
                                        imageUrl: _thePackList[index].hasher.photo.startsWith('http') ? _thePackList[index].hasher.photo : null,
                                        assetImage: _thePackList[index].hasher.photo.contains('bundle://')
                                            ? 'images/avatars/' + _thePackList[index].hasher.photo.replaceAll('bundle://', '') + '.jpg'
                                            : null,
                                        appBarBackgroundColor: themeAppBarBackground,
                                        background: Backgrounds.defaultHcBackground(),
                                        margin: 20.0),
                                  ),
                                );
                              },
                              // onTap: () {
                              //   String actionText = '';

                              //   if (_thePackList[index].hem.isHare == 1) {
                              //     actionText = ' will hare the Hash';
                              //   } else {
                              //     switch (_thePackList[index].hem.rsvpState) {
                              //       case 1:
                              //         actionText = ' will not join the Hash';
                              //         break;
                              //       case 2:
                              //         actionText = ' might join the Hash';
                              //         break;
                              //       case 3:
                              //       case 4:
                              //       case 5:
                              //       case 6:
                              //         actionText = ' will join the Hash';
                              //         break;
                              //       case 0:
                              //       default:
                              //         break;
                              //     }
                              //   }

                              //   final SnackBar snackBar = SnackBar(
                              //     duration: const Duration(seconds: 2),
                              //     content: Text(
                              //       (_thePackList[index].hasher.dispName ?? _thePackList[index].hem.displayName) + actionText,
                              //       style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
                              //     ),
                              //     backgroundColor: Theme.of(context).accentColor,
                              //   );

                              //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              // },
                              child: Stack(
                                children: <Widget>[
                                  _thePackList[index].hasher.photo.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: _thePackList[index].hasher.photo,
                                          fadeInDuration: const Duration(milliseconds: 0),
                                          width: 300.0,
                                          height: 300.0,
                                          fit: BoxFit.fill)
                                      : _thePackList[index].hasher.photo.startsWith('bundle')
                                          ? Image(
                                              width: 300.0,
                                              height: 300.0,
                                              fit: BoxFit.fill,
                                              image: AssetImage(
                                                  ('images/avatars/' + _thePackList[index].hasher.photo.toLowerCase().replaceFirst('bundle://', '') + '.jpg').toLowerCase()),
                                            )
                                          : const Image(
                                              width: 300.0,
                                              height: 300.0,
                                              fit: BoxFit.fill,
                                              image: AssetImage('images/avatars/avatar-2.jpg'),
                                            ),
                                  Positioned(
                                    right: 1.0,
                                    bottom: 1.0,
                                    child: Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: <Widget>[
                                        const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 11.0,
                                        ),
                                        (_thePackList[index].hem.rsvpState ?? 0) <= 0
                                            ? const CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                radius: 10.0,
                                              )
                                            : _thePackList[index].hem.rsvpState == 1
                                                ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 21.0)
                                                : _thePackList[index].hem.rsvpState == 2
                                                    ? const Icon(FontAwesome.question_circle, color: Colors.orange, size: 21.0)
                                                    : _thePackList[index].hem.isHare == 0
                                                        ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 21.0)
                                                        : Image.asset('images/icons/hare_icon.png', color: Colors.deepPurple, height: 18.0, width: 18.0),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ); // TODO(James): Replace this with another avatar for missing image
                    },
                    staggeredTileBuilder: (int index) {
                      return _thePackList[index].hem.isHare != 1 ? const StaggeredTile.count(1, 1) : const StaggeredTile.count(2, 2);
                    },
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  void setRsvpState(EnumRsvpState<int> rsvpState) {
    setState(() {
      if (_thisUserIndex >= 0) {
        _thePackList[_thisUserIndex].hem.rsvpState = -1;
        _thePackList[_thisUserIndex].hem.isHare = 0;
        rsvpRequested = rsvpState;
      }
    });
    //final String userId = getStringPref(StringPrefsEnum.userId);

    final int attendenceValue = rsvpState.value <= rsvpMaybe.value ? attendenceNo.value : attendenceNoChange.value;
    final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
          widget.futureRun.event.eventId,
          userId,
          null,
          AppDomainType.user,
          rsvpState: rsvpState.value,
          attendenceState: attendenceValue,
          isHare: isHareNo.value,
        );

    retVal.then((List<dynamic> adHocData) async {
      await _refreshHemTableFromBackend(false);
    });
  }

  Widget buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        // Map
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            FlutterMap(
              options: MapOptions(
                center: latlng.LatLng(
                  widget.futureRun.extensions.latitude ?? widget.futureRun.kennel.kennelLatitude + .0,
                  widget.futureRun.extensions.longitude ?? widget.futureRun.kennel.kennelLongitude + .0,
                ),
                zoom: 15.0,
                minZoom: 1.0,
                maxZoom: 18.0,
              ),
              layers: <LayerOptions>[
                TileLayerOptions(
                    urlTemplate:
                        //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    //subdomains: ['a', 'b', 'c']),
                    subdomains: <String>['mt0', 'mt1', 'mt2', 'mt3']),
                MarkerLayerOptions(
                  markers: <Marker>[
                    if (widget.futureRun.extensions.isMapAndDistanceValid) ...<Marker>[
                      Marker(
                        width: 120.0,
                        height: 120.0,
                        point: latlng.LatLng(
                          widget.futureRun.extensions.latitude ?? widget.futureRun.kennel.kennelLatitude + .0,
                          widget.futureRun.extensions.longitude ?? widget.futureRun.kennel.kennelLongitude + .0,
                        ),
                        builder: (BuildContext ctx) => GestureDetector(
                          onTap: () => _launchMaps(widget.futureRun),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 58.0),
                            child: Image.asset('images/icons/map_pin_foot.png'),
                            //child: FlutterLogo(colors: Colors.purple),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              ],
            ),
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

  bool fabIsVisible = false;

  @override
  Widget build(BuildContext context) {
    //getPack(false);

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: fabIsVisible ? 1.0 : 0.0,
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
              onTap: () {
                setRsvpState(rsvpNo);
              },
            ),
            SpeedDialChild(
              child: const Icon(AntDesign.question),
              backgroundColor: Colors.orange,
              label: 'I might come',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                setRsvpState(rsvpMaybe);
              },
            ),
            SpeedDialChild(
              child: const Icon(Feather.check),
              backgroundColor: Colors.green,
              label: 'I\'m coming',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () {
                setRsvpState(rsvpYes);
              },
            ),
            SpeedDialChild(
              child: const ImageIcon(AssetImage('images/icons/hare_icon.png'), color: Colors.purple),
              backgroundColor: Colors.white,
              label: 'I will hare',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                final bool willHare = await _promptForHare(widget.futureRun.event.hares ?? '');
                if (willHare) {
                  setState(() {
                    if (_thisUserIndex >= 0) {
                      _thePackList[_thisUserIndex].hem.rsvpState = -1;
                      _thePackList[_thisUserIndex].hem.isHare = -1;
                      rsvpRequested = rsvpYes;
                    }
                  });

                  //final String userId = getStringPref(StringPrefsEnum.userId);
                  await G0<TableModel>().hasherEventMapService.joinEvent(
                        widget.futureRun.event.eventId,
                        userId,
                        null,
                        AppDomainType.user,
                        rsvpState: rsvpYes.value,
                        attendenceState: attendenceNoChange.value,
                        isHare: isHareYes.value,
                      );

                  await _refreshHemTableFromBackend(false);
                }
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
                        tabs: tabs,
                        controller: _tabController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: <Widget>[
                buildRunDetailsView(),
                buildRsvpView(),
                buildMapView(),
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
    String latStr = '';
    String lonStr = '';
    String address = '';
    String url = '';

    if (rda.extensions.latitude != null) {
      latStr = rda.extensions.latitude.toString();
    }

    if (rda.extensions.longitude != null) {
      lonStr = rda.extensions.longitude.toString();
    }

    if (rda.event.locationStreet != null) {
      address = address + rda.event.locationStreet + ' ';
    }

    if (rda.event.locationCity != null) {
      address = address + rda.event.locationCity + ' ';
    }

    if (rda.event.locationPostCode != null) {
      address = address + rda.event.locationPostCode + ' ';
    }

    if (rda.event.locationCountry != null) {
      address = address + rda.event.locationCountry + ' ';
    }

    address = address.trim();

    if ((address.isEmpty) && (latStr.isEmpty || lonStr.isEmpty)) {
      address = rda.event.locationOneLineDesc;
    }

    if ((address != null) && (address.isNotEmpty)) {
      address = address.replaceAll(' ', '+');
      address = Uri.encodeComponent(address);
      url = address;
    } else if ((latStr != '') && (lonStr != '')) {
      url = latStr + ',' + lonStr;
    } else {
      await IveCoreUtilities.showAlert(
          context, 'No location information available', 'There is no location information available for this run and so we cannot display a map', 'OK');
    }

    final String googleWebUrl = 'https://www.google.com/maps/search/?api=1&query=$url';
    final String googleAppUrl = 'comgooglemaps://?q=$url';
    String appleUrl = '';
    if ((latStr.isNotEmpty) && (lonStr.isNotEmpty)) {
      appleUrl = 'https://maps.apple.com/?sll=$latStr,$lonStr';
    }

    if (await canLaunch('comgooglemaps://')) {
      //print('launching com googleUrl');
      await launch(googleAppUrl);
    } else if (await canLaunch(googleWebUrl)) {
      //print('launching Google web url');
      await launch(googleWebUrl);
    } else if ((appleUrl.isNotEmpty) && (await canLaunch(appleUrl))) {
      //print('launching apple url');
      await launch(appleUrl);
    } else {
      throw 'Could not launch url';
    }
  }

  Future<bool> _promptForHare(String hareList) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Will you Hare this run?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please confirm that you are signing up to hare this run' + ((hareList == null) ? '.' : ' with ' + hareList)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No Thanks!'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes, I\'ll Hare!'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
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
