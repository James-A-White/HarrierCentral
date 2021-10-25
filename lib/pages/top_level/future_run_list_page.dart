// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

final GlobalKey<FutureRunListPageState> futureRunsListPageKey = GlobalKey<FutureRunListPageState>();

class FutureRunsListPage extends StatefulWidget {
  FutureRunsListPage() : super(key: futureRunsListPageKey);

  @override
  State<FutureRunsListPage> createState() => FutureRunListPageState();
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  int pageIndex = 1;
  List<RunDetailsAggregate> allRuns;
  List<RunDetailsAggregate> filteredRuns;

  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();
  String searchText;
  bool searchAllRuns = false;
  ScrollController scrollController = ScrollController(initialScrollOffset: 100.0);
  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allRuns == null ? HcCircularProgressIndicator(key: UniqueKey()) : _buildListView(),
    );
  }

  Future<void> forceRefreshFromTableExternal() async {
    await refreshFromTable(true);
  }

  Future<void> _refreshFromBackend({bool clearLocalTables = false}) async {
    if (clearLocalTables) {
      setState(() {
        allRuns = null;
      });

      String query = 'DELETE FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        print(e);
      }
    }

    final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(
        SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable,
        //| SyncUserDataService.flagPaymentsTable,
        false);

    await refreshFromTable(true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Events user data synchronized $resultStr');
  }

  @override
  void initState() {
    IveCoreUtilities.logTiming('initState called', G0<AppModel>().appStartTime);
    searchController.text = '';
    searchText = '';

    _refreshFromBackend().then((void _) {
      refreshFromTable(true).then((void _) {
        setState(() {});
      });
    });
    super.initState();
  }

  Widget searchBar() {
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
                value: searchAllRuns,
                onChanged: (bool value) {
                  searchAllRuns = !searchAllRuns;
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
                          searchText = text;
                          filterRuns();
                        });
                      },
                      focusNode: searchFocusNode,
                      controller: searchController,
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
                  Container(
                    width: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
                      child: const Text('X'),
                      onPressed: () {
                        searchController.text = '';
                        searchText = '';
                        setState(() {
                          filterRuns();
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
    if (forceRefresh || (allRuns == null) || (allRuns.isEmpty)) {
      //final Geolocator locator = Geolocator();

      IveCoreUtilities.logTiming('Run query start', G0<AppModel>().appStartTime);
      final List<Map<String, dynamic>> results = await QueryRuns.queryRuns(EnumRunQueryType.topRunsPage, EnumRunQueryContext.user, searchAllRuns: searchAllRuns);

      IveCoreUtilities.logTiming('Run query end', G0<AppModel>().appStartTime);
      allRuns = <RunDetailsAggregate>[];
      for (int i = 0; i < results.length; i++) {
        final EventModel eventItem = G0<TableModel>().eventsTableHelper.fromMap(results[i]);
        final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[i]);

        num dist;
        if ((results[i]['latitude'] != null) && (results[i]['longitude'] != null)) {
          dist = Geolocator.distanceBetween(
            G0<DeviceInfo>().deviceLat,
            G0<DeviceInfo>().deviceLon,
            results[i]['latitude'] + .0,
            results[i]['longitude'] + .0,
          );
        } else {
          dist = Geolocator.distanceBetween(
            G0<DeviceInfo>().deviceLat,
            G0<DeviceInfo>().deviceLon,
            kennelItem.kennelLatitude + .0,
            kennelItem.kennelLongitude + .0,
          );
        }

        final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[i], eventItem.eventStartDatetime);
        extensionsItem.distToEvent = dist;

        String paymentLinkUrl = '';

        if (((eventItem.eventPaymentUrl ?? '') != '') && ((eventItem.eventPaymentUrlExpires == null) || (eventItem.eventPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = eventItem.eventPaymentUrl;
        } else if (((kennelItem.kennelPaymentUrl ?? '') != '') && ((kennelItem.kennelPaymentUrlExpires == null) || (kennelItem.kennelPaymentUrlExpires.isAfter(DateTime.now())))) {
          paymentLinkUrl = kennelItem.kennelPaymentUrl;
        }

        final num julianNow = results[i]['nowJulian'];
        final num eventJulian = results[i]['eventJulian'];

        print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

        num meters = 0;
        final int userDistPrefs = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceForAutoDisplay;

        switch (userDistPrefs) {
          case hasherPref_0:
            meters = 0;
            break;
          case hasherPref_10:
            meters = 10000;
            break;
          case hasherPref_25:
            meters = 25000;
            break;
          case hasherPref_50:
            meters = 50000;
            break;
          case hasherPref_75:
            meters = 75000;
            break;
          case hasherPref_100:
            meters = 100000;
            break;
          case hasherPref_150:
            meters = 150000;
            break;
          case hasherPref_200:
            meters = 200000;
            break;
          default:
            meters = 50000;
            break;
        }

        // if the user has set their preferences to miles or
        // the user has set their preferences to "auto" and the
        // distance preference associated with the kennel is miles
        // then convert our range for runs from meters to miles.
        if (((userDistPrefs & 0x00000003) == 3) || (((userDistPrefs & 0x00000003) == 0) && (extensionsItem.distanceUnitsPref == 1))) {
          meters = meters * MILES_TO_METERS / 1000;
        }

        if ((searchAllRuns == true) || (extensionsItem.following >= 1) || ((extensionsItem.following == 0) && (dist < meters))) {
          final RunDetailsAggregate item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem, paymentUrl: paymentLinkUrl);
          allRuns.add(item);
        }
        if (i == results.length - 1) {
          IveCoreUtilities.logTiming('Filter start', G0<AppModel>().appStartTime);
          filterRuns();
          setState(() {});
          IveCoreUtilities.logTiming('Filter end', G0<AppModel>().appStartTime);
        }
      }
    }
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
  void filterRuns() {
    filteredRuns = QueryRuns.doFilter(searchText, allRuns);

    //buildRunMarkers();
    setState(() {});
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: allRuns.isEmpty
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
              controller: scrollController,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(<Widget>[searchBar()]),
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
                  itemCount: filteredRuns.length,
                  itemBuilder: (BuildContext context, int index) {
                    return RunListItem(
                      futureRun: filteredRuns[index],
                      onItemTapped: () {
                        Navigator.push<dynamic>(
                          this.context,
                          MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => RunDetailsPage(
                              futureRun: filteredRuns[index],
                              refreshPage: () async {
                                // WARNING!!!!  We need to return the filtered run based
                                // on it's ID and not the index

                                //await _refreshFromBackend(clearLocalTables: false);
                                await refreshFromTable(true);
                                //filterRuns();
                                return filteredRuns[index];
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
                  },
                ),
              ),
            ),
    );
  }
}
