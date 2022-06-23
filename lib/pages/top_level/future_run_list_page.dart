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
  List<RunDetailsAggregate> _allRuns;
  List<dynamic> _filteredRuns;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchRunsText;
  bool _searchAllRuns = false;
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
      height: 100,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: _searchAllRuns,
                onChanged: (bool value) {
                  _searchAllRuns = !_searchAllRuns;
                  refreshFromTable(true).then((void _) {
                    setState(() {});
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Search all runs', style: headingStyleBlack.copyWith(fontSize: 18.0)),
              ),
            ],
          ),
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

    _filteredRuns.insert(0, _filteredRuns[0].extensions.runClassification);

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
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(<Widget>[_searchBar()]),
                  ),
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
                        child: Text(
                          _filteredRuns[index] == 1
                              ? 'All runs within ' + _getDistancePreferenceString()
                              : _filteredRuns[index] == 2
                                  ? 'Runs from Kennels I follow'
                                  : 'All other upcoming runs',
                          textAlign: TextAlign.center,
                          style: titleStyle,
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

  String _getDistancePreferenceString() {
    final int distance = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceForAutoDisplay;

    final String units = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn == 2 ? ' km' : ' miles';

    String result = 'No distance';

    switch (distance) {
      case hasherPref_10:
        result = '10' + units;
        break;
      case hasherPref_25:
        result = '25' + units;
        break;
      case hasherPref_50:
        result = '50' + units;
        break;
      case hasherPref_75:
        result = '75' + units;
        break;
      case hasherPref_100:
        result = '100' + units;
        break;
      case hasherPref_150:
        result = '150' + units;
        break;
      case hasherPref_200:
        result = '200' + units;
        break;
    }

    return result;
  }
}
