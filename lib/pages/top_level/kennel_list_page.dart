import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

class KennelsListPage extends StatefulWidget {
  const KennelsListPage({Key key}) : super(key: key);

  @override
  KennelsListPageState createState() => KennelsListPageState();
}

class KennelsListPageState extends State<KennelsListPage> {
  KennelsListPageState();

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchText;
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 57);

  List<KennelListAggregate> _filteredList = <KennelListAggregate>[];

  @override
  void initState() {
    _searchController.text = '';
    _searchText = '';

    // NOTE: refreshFromTable will run asynchronously so don't expect the
    // tables to be populated immediately when this call returns.
    _refreshFromTable(false).then((void dummy) {
      setState(() {});
    });

    //print('initState called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

    super.initState();
  }

  Container _searchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              autocorrect: false,
              onChanged: (String text) {
                setState(() {
                  _searchText = text;
                  _filterResults();
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
          Container(
            width: 40,
            child: TextButton(
              style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
              child: const Text('X'),
              onPressed: () {
                _searchController.text = '';
                _searchText = '';
                setState(() {
                  _filterResults();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (G0<TableModel>().globalKennelMainPageList == null) || (G0<TableModel>().globalKennelMainPageList.isEmpty)) {
      final Geolocator locator = Geolocator();
      if (G0<TableModel>().globalKennelMainPageList != null) {
        G0<TableModel>().globalKennelMainPageList.clear();
      }

      final String hasherId = getStringPref(StringPrefsEnum.userId);

      G0<TableModel>().globalKennelMainPageList = <KennelListAggregate>[];
      try {
        final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(EnumKennelQueryType.topKennelPage, EnumKennelQueryContext.user, hasherId: hasherId);

        for (int i = 0; i < results.length; i++) {
          final num dist = await locator.distanceBetween(G0<DeviceInfo>().deviceLat + .0, G0<DeviceInfo>().deviceLon + .0, results[i]['cityLat'] + .0, results[i]['cityLon'] + .0);

          final KennelsModel kennelItem = G0<TableModel>().kennelsTableHelper.fromMap(results[i]);
          final HasherKennelMapModel hkmItem = G0<TableModel>().hasherKennelMapTableHelper.fromMap(results[i]);
          final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[i]);
          extensionsItem.distToKennel = dist;
          extensionsItem.followingRequested = -1;
          extensionsItem.notificationsRequested = -1;
          extensionsItem.emailAlertRequested = -1;

          bool isHomeKennel = false;
          if (kennelItem.kennelId == getStringPref(StringPrefsEnum.homeKennelId)) {
            isHomeKennel = true;
          }

          final KennelListAggregate item = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem, isHomeKennel: isHomeKennel);

          G0<TableModel>().globalKennelMainPageList.add(item);
        }

        if (G0<AppModel>().hasLocationPermissions) {
          G0<TableModel>().globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => a.extensions.distToKennel.compareTo(b.extensions.distToKennel));
        } else {
          G0<TableModel>().globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => a.kennel.kennelName.compareTo(b.kennel.kennelName));
        }

        G0<TableModel>().globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (a.hkm.following == 1
                ? 0
                : a.hkm.following == 2
                    ? 1
                    : 2)
            .compareTo(b.hkm.following == 1
                ? 0
                : b.hkm.following == 2
                    ? 1
                    : 2));

        G0<TableModel>().globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (b.isHomeKennel ? 1 : 0).compareTo(a.isHomeKennel ? 1 : 0));

        setState(() {
          _filterResults();
        });
      } catch (e) {
        print(e);
      }
    } else {
      // if the global list is already loaded,
      // go ahead and call filterResults to make sure that the
      // filtered list is also populated, otherwise we might
      // end up with an empty list.
      setState(() {
        _filterResults();
      });
    }
  }

  void _filterResults() {
    if (G0<TableModel>().globalKennelMainPageList != null) {
      if (_searchController.text.isEmpty) {
        _filteredList = <KennelListAggregate>[];
        _filteredList.addAll(G0<TableModel>().globalKennelMainPageList);
      } else {
        _filteredList = QueryKennels.doFilter(_searchText, G0<TableModel>().globalKennelMainPageList);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: G0<TableModel>().globalKennelMainPageList == null
          ? Center(
              child: HcCircularProgressIndicator(key: UniqueKey()),
            )
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              padding: const EdgeInsets.only(top: 0.0),
              child: ((G0<TableModel>().globalKennelMainPageList == null) || (G0<TableModel>().globalKennelMainPageList.isEmpty))
                  ? Center(child: Text('Loading Kennels.', style: headingStyle))
                  : NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (BuildContext context, bool innerBoxScrolled) => <Widget>[
                        SliverAppBar(
                          floating: false,
                          pinned: false,
                          snap: false,
                          elevation: 20,
                          actions: <Widget>[_searchBar()],
                        )
                      ],
                      body: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          itemCount: _filteredList.length,
                          itemBuilder: (BuildContext context, int index) {
                            //print('buildListView called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
                            return Padding(
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                              child: KennelsListItem(
                                kennelItem: _filteredList[index],
                                kennelFollowingUpdated: (int following, int notificationStatus, int emailAlertStatus, int isHomeKennel) {
                                  _filteredList[index].extensions.followingRequested = -1;
                                  _filteredList[index].extensions.notificationsRequested = -1;
                                  _filteredList[index].extensions.emailAlertRequested = -1;
                                  _filteredList[index].hkm.following = following;
                                  _filteredList[index].hkm.kennelNotificationPreference = notificationStatus;
                                  _filteredList[index].hkm.kennelEmailAlertPreference = emailAlertStatus;

                                  if (_filteredList[index].kennel.kennelId == getStringPref(StringPrefsEnum.homeKennelId)) {
                                    // if this kennel has been set as the home kennel, clear the home kennel
                                    // flag on the rest of the kennels

                                    for (int i = 0; i < _filteredList.length; i++) {
                                      _filteredList[i].isHomeKennel = false;
                                    }

                                    _filteredList[index].isHomeKennel = true;
                                  } else {
                                    _filteredList[index].isHomeKennel = false;
                                  }

                                  // filteredList[index].extensions.isHomeKennel = isHomeKennel;
                                  setState(() {});
                                },
                                kennelSelected: () {
                                  final KennelListAggregate kennel = _filteredList[index];
                                  // // this is a bit of a hack where we clear the list before navigating to the
                                  // // next page. When state changes occurred in child pages further down the
                                  // // route tree, the list would get refreshed, which I think was causing
                                  // // a bug where the selected Kennel itself would occasioinall change.
                                  // // By deleting the list, I'm hoping that this bug will be fixed.
                                  G0<TableModel>().globalKennelMainPageList.clear();
                                  Navigator.of(context)
                                      .push<dynamic>(
                                    MaterialPageRoute<dynamic>(
                                      builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
                                    ),
                                  )
                                      .then((void dummy) async {
                                    final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(
                                        SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagHasherKennelMapTable | SyncUserDataService.flagKennelsTable, true);
                                    final String resultStr = result ? 'successfully' : 'unsuccessfully';
                                    print('Pack member data synchronized $resultStr');
                                    await _refreshFromTable(true);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      G0<TableModel>().globalKennelMainPageList = null;
    });

    String query = 'DELETE FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)}';
    try {
      await G0<Database>().rawQuery(query);
    } catch (e) {
      print(e);
    }

    query = 'DELETE FROM ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)}';
    try {
      await G0<Database>().rawQuery(query);
    } catch (e) {
      print(e);
    }

    final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagKennelsTable | SyncUserDataService.flagHasherKennelMapTable, true);
    await _refreshFromTable(true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Kennel user data synchronized $resultStr');
  }
}
