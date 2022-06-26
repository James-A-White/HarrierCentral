// @dart=2.11
import 'package:harrier_central/imports.dart';

final GlobalKey<FutureRunListPageState> futureRunsListPageKey = GlobalKey<FutureRunListPageState>();

class FutureRunsListPage extends StatefulWidget {
  FutureRunsListPage() : super(key: futureRunsListPageKey);

  @override
  State<FutureRunsListPage> createState() => FutureRunListPageState();
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  int pageIndex = 1;
  List<dynamic> _allRuns;
  List<dynamic> _filteredRuns;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchRunsText;
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 100.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _allRuns == null ? const HcCircularProgressIndicator(key: Key('16669020')) : _buildListView(),
    );
  }

  Future<void> forceRefreshFromTableExternal() async {
    await refreshFromTable(true);
  }

  Future<void> _refreshFromBackend({bool clearLocalTables = false}) async {
    if (clearLocalTables) {
      setState(() {
        _allRuns = null;
      });

      String query = 'DELETE FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }
    }

    await G0<TableModel>().syncUserDataService.updateFromBackend(
        SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable,
        //| SyncUserDataService.flagPaymentsTable,
        false);

    await refreshFromTable(true);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Events user data synchronized $resultStr');
  }

  @override
  void initState() {
    IveCoreUtilities.logTiming('initState called', G0<AppModel>().appStartTime);
    _searchController.text = '';
    _searchRunsText = '';

    _refreshFromBackend().then((void _) {
      refreshFromTable(true).then((void _) {
        setState(() {});
      });
    });
    super.initState();
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Row(
          //   children: <Widget>[
          //     Checkbox(
          //       value: _searchAllRuns,
          //       onChanged: (bool value) {
          //         _searchAllRuns = !_searchAllRuns;
          //         refreshFromTable(true).then((void _) {
          //           setState(() {});
          //         });
          //       },
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.only(top: 4.0),
          //       child: Text('Search all runs', style: headingStyleBlack.copyWith(fontSize: 18.0)),
          //     ),
          //   ],
          // ),
          const Divider(
            height: 2.0,
            thickness: 2.0,
          ),
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
                          _searchRunsText = text;
                          _filterRuns();
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
                      child: const Text('X'),
                      onPressed: () {
                        _searchController.text = '';
                        _searchRunsText = '';
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

  Future<void> refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (_allRuns == null) || (_allRuns.isEmpty)) {
      _allRuns = await QueryRuns.getRunDetailsAggregates(true);
      _filterRuns();

      setState(() {});
    }
    return;
  }

  /// filterRuns() provides a complex filtering (search) option
  /// where the plus sign (+) is used as a logical OR allowing
  /// query results to be added together and commas (,) to be used
  /// to separate query options and act as a logical AND function, thus
  /// limiting the query results. Finally the text 'not ' at the beginning
  /// of a search term will negate the resdults.
  ///
  /// For example: "AH3 + FILTH, not Wednesday + Thursday" will show all
  /// Amsterdam and FILTH hashes that are not on a Wednesday or Thursday
  ///
  void _filterRuns() {
    _filteredRuns = QueryRuns.doRunsFilter(_searchRunsText, _allRuns);

    _filteredRuns.sort((dynamic a, dynamic b) {
      // start by sorting by run classification, closest runs should be listed first, then runs
      // from Kennels the user is following, then the rest
      int result = a.extensions.runClassification.compareTo(b.extensions.runClassification);

      if (result == 0) {
        result = _toDateOnly(a.event.eventStartDatetime).compareTo(_toDateOnly(b.event.eventStartDatetime));
        // if the runs are on the same day then try to sort by distance
        // if there are no distances because location services are off, then sort by Kennel name
        if (result == 0) {
          if ((a.extensions.distToEvent != null) && (b.extensions.distToEvent != null)) {
            final num distA = a.extensions.latitude == null ? 99999999 : a.extensions.distToEvent;
            final num distB = b.extensions.latitude == null ? 99999999 : b.extensions.distToEvent;
            result = distA.compareTo(distB);
          } else {
            result = a.kennel.kennelName.compareTo(b.kennel.kennelName);
          }
        }
      }
      return result;
    });

    for (int i = _filteredRuns.length - 1; i > 0; i--) {
      if (_filteredRuns[i].extensions.runClassification != _filteredRuns[i - 1].extensions.runClassification) {
        _filteredRuns.insert(i, _filteredRuns[i].extensions.runClassification);
      }
    }

    if (_filteredRuns.isNotEmpty) {
      // make sure the "All runs within..." bar always shows
      if (_filteredRuns[0].extensions.runClassification != 1) {
        _filteredRuns.insert(0, _filteredRuns[0].extensions.runClassification);
        _filteredRuns.insert(0, 1);
      } else {
        _filteredRuns.insert(0, _filteredRuns[0].extensions.runClassification);
      }
    }

    setState(() {});
  }

  DateTime _toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: _allRuns.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25, bottom: 30),
                  child: Center(
                      child: Text(
                    'No Runs available.',
                    style: largeTitleStyle,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 30),
                  child: Center(
                      child: Text(
                    'You might not be following any Kennels with upcoming runs. Check the Kennels page, select several Kennels and then return to this page and hit the "Reload runs" button below.',
                    style: smallTitleStyle,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: TextButton(
                    child: Text('Reload runs', style: buttonLabelStyleMedium),
                    onPressed: () async {
                      await _refreshFromBackend(clearLocalTables: false);
                    },
                  ),
                ),
              ],
            )
          : NestedScrollView(
              controller: _scrollController,
              floatHeaderSlivers: true,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // SliverList(
                  //   delegate: SliverChildListDelegate(<Widget>[_searchBar()]),
                  // ),
                  SliverAppBar(
                    floating: true,
                    titleSpacing: 0.0,
                    title: Container(
                      height: 54.0,
                      child: _searchBar(),
                    ),
                  )
                ];
              },
              body: RefreshIndicator(
                onRefresh: () => _refreshFromBackend(clearLocalTables: true),
                displacement: 40.0,
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 50),
                  physics: const AlwaysScrollableScrollPhysics(),
                  //padding: const EdgeInsets.only( bottom: 40.0),
                  itemCount: _filteredRuns.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (_filteredRuns[index] is int) {
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(top: 2.0),
                        color: themeButtonColors,
                        height: 40.0,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if ((_filteredRuns[index] == 1) && (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected)) ...<Widget>[
                              const SizedBox(width: 36.0),
                            ],
                            Text(
                              _filteredRuns[index] == 1
                                  ? _getDistancePreferenceString()
                                  : _filteredRuns[index] == 2
                                      ? 'Runs from Kennels I follow'
                                      : 'All other upcoming runs',
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            ),
                            if ((_filteredRuns[index] == 1) && (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected)) ...<Widget>[
                              GestureDetector(
                                onTap: () {
                                  _showConfigureDistancePopup();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(FontAwesome.gear, size: 28.0),
                                ),
                              )
                            ]
                          ],
                        ),
                      );
                    } else {
                      return RunListItem(
                        futureRun: _filteredRuns[index],
                        onItemTapped: () {
                          Navigator.push<dynamic>(
                            this.context,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) => RunDetailsPage(
                                futureRun: _filteredRuns[index],
                                refreshPage: () async {
                                  // WARNING!!!!  We need to return the filtered run based
                                  // on it's ID and not the index

                                  //await _refreshFromBackend(clearLocalTables: false);
                                  await refreshFromTable(true);
                                  //filterRuns();
                                  return _filteredRuns[index];
                                },
                              ),
                            ),
                          ).then((void _) {
                            _refreshFromBackend(clearLocalTables: false).then((void _) {
                              setState(() {});
                            });
                          });
                        },
                      );
                    }
                  },
                ),
              ),
            ),
    );
  }

  void _showConfigureDistancePopup() {
    final String units = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn == 2 ? ' km' : ' miles';

    final String switchUnits = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn == 2 ? ' miles' : ' kilometers';

    const TextStyle ts = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 17.0);

    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Switch to ' + switchUnits,
        'icon': <Widget>[
          Container(height: 30, width: 45, decoration: BoxDecoration(color: Colors.green.shade800, shape: BoxShape.rectangle)),
          const Icon(MaterialCommunityIcons.map_marker_distance, color: Colors.white)
        ],
        'returnValue': 9999
      },
      <String, dynamic>{
        'title': 'Runs within 10' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('10', style: ts)
        ],
        'returnValue': hasherPref_10
      },
      <String, dynamic>{
        'title': 'Runs within 25' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('25', style: ts)
        ],
        'returnValue': hasherPref_25
      },
      <String, dynamic>{
        'title': 'Runs within 50' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('50', style: ts)
        ],
        'returnValue': hasherPref_50
      },
      <String, dynamic>{
        'title': 'Runs within 75' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('75', style: ts)
        ],
        'returnValue': hasherPref_75
      },
      <String, dynamic>{
        'title': 'Runs within 100' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('100', style: ts)
        ],
        'returnValue': hasherPref_100
      },
      <String, dynamic>{
        'title': 'Runs within 150' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('150', style: ts)
        ],
        'returnValue': hasherPref_150
      },
      <String, dynamic>{
        'title': 'Runs within 250' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('250', style: ts)
        ],
        'returnValue': hasherPref_250
      },
      <String, dynamic>{
        'title': 'Runs within 500' + units,
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          const Text('500', style: ts)
        ],
        'returnValue': hasherPref_500
      },
      <String, dynamic>{
        'title': 'Disable auto display',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.rectangle),
          ),
          Text('Off', style: ts.copyWith(color: Colors.white))
        ],
        'returnValue': hasherPref_0
      },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      key: const Key('5030202'),
      title: 'Auto display runs',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        }).then((dynamic retVal) async {
      if (retVal == 9999) {
        if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
          final HashersService srv = HashersService();

          final int hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences);
          final int distanceMeasuredIn = ((hasherPreferences & hasherPref_distanceMeasuredIn) == 3) ? 2 : 3;

          final int distance = hasherPreferences & hasherPref_distanceForAutoDisplay;

          await srv.addEditUser(
            targetUserId: getStringPref(StringPrefsEnum.userId),
            preferences: distanceMeasuredIn + distance,
          );

          await setIntPref(IntPrefsEnum.hasherPreferences, distanceMeasuredIn + distance);
          await refreshFromTable(true);
        }
      } else if ((!(retVal is EnumFollowType)) && (retVal >= hasherPref_0) && (retVal <= hasherPref_500)) {
        if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
          final HashersService srv = HashersService();

          final int hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences);
          final int distanceMeasuredIn = hasherPreferences & hasherPref_distanceMeasuredIn;
          //int _autoRunPreference = hasherPreferences & hasherPref_distanceForAutoDisplay;

          await srv.addEditUser(
            targetUserId: getStringPref(StringPrefsEnum.userId),
            preferences: distanceMeasuredIn + retVal,
          );

          await setIntPref(IntPrefsEnum.hasherPreferences, distanceMeasuredIn + retVal);

          await refreshFromTable(true);
        }
      }
    });
  }

  String _getDistancePreferenceString() {
    final int distance = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceForAutoDisplay;

    final String units = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn == 2 ? ' km' : ' miles';

    String result = 'Auto show runs ';

    switch (distance) {
      case hasherPref_0:
        result = 'Press gear to setup →';
        break;
      case hasherPref_10:
        result += '10' + units;
        break;
      case hasherPref_25:
        result += '25' + units;
        break;
      case hasherPref_50:
        result += '50' + units;
        break;
      case hasherPref_75:
        result += '75' + units;
        break;
      case hasherPref_100:
        result += '100' + units;
        break;
      case hasherPref_150:
        result += '150' + units;
        break;
      case hasherPref_250:
        result += '250' + units;
        break;
      case hasherPref_500:
        result += '500' + units;
        break;
      default:
        result = 'Distance not configured';
        break;
    }

    return result;
  }
}
