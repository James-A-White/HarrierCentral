// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

final GlobalKey<KennelsListPageState> kennelListPageKey = GlobalKey<KennelsListPageState>();

class KennelsListPage extends StatefulWidget {
  const KennelsListPage({Key key}) : super(key: key);

  @override
  KennelsListPageState createState() => KennelsListPageState();
}

enum EnumSortKennelListBy { distance, kennelName, cityName, countryRegionName, following }

class KennelsListPageState extends State<KennelsListPage> {
  KennelsListPageState();

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchKennelsText;
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0);

  List<KennelListAggregate> _filteredList = <KennelListAggregate>[];

  EnumSortKennelListBy _sortByType = EnumSortKennelListBy.following;

  @override
  void initState() {
    _searchController.text = '';
    _searchKennelsText = '';

    // NOTE: refreshFromTable will run asynchronously so don't expect the
    // tables to be populated immediately when this call returns.
    _refreshFromTable(false).then((void _) {
      setState(() {});
      // Future<dynamic>.delayed(const Duration(seconds: 1)).then((void _) {
      //   setState(() {});
      // });
    });

    ////print('initState called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

    super.initState();
  }

  Widget getKennelFab() {
    return SpeedDial(
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
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: const Icon(Entypo.heart, color: Colors.white),
            backgroundColor: Colors.red,
            label: 'Sort by following status',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _sortByType = EnumSortKennelListBy.following;
              await _refreshFromTable(true);
              setState(() {});
            },
          ),
          if (G0<AppModel>().hasLocationPermissions) ...<SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(FontAwesome.sort_amount_asc),
              backgroundColor: Colors.lightBlue.shade500,
              label: 'Sort by distance',
              labelStyle: const TextStyle(fontSize: 18.0),
              onTap: () async {
                _sortByType = EnumSortKennelListBy.distance;
                await _refreshFromTable(true);
                setState(() {});
              },
            ),
          ],
          SpeedDialChild(
            child: const Icon(FontAwesome.sort_alpha_asc),
            backgroundColor: Colors.pink.shade200,
            label: 'Sort by Kennel name',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _sortByType = EnumSortKennelListBy.kennelName;
              await _refreshFromTable(true);
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(MaterialCommunityIcons.city_variant_outline),
            backgroundColor: Colors.lightGreen.shade500,
            label: 'Sort by city name',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _sortByType = EnumSortKennelListBy.cityName;
              await _refreshFromTable(true);
              setState(() {});
            },
          ),
          // SpeedDialChild(
          //   child: const Icon(FontAwesome.sort_asc),
          //   backgroundColor: Colors.lightGreen.shade500,
          //   label: 'Sort by state/region name',
          //   labelStyle: const TextStyle(fontSize: 18.0),
          //   onTap: () {
          //     _sortByFollowingAndDistance = EnumSortKennelListBy.regionName;
          //     _refreshFromTable(true).then((void _) {
          //       setState(() {});
          //     });
          //   },
          // ),
          SpeedDialChild(
            child: const Icon(Entypo.globe),
            backgroundColor: Colors.lightGreen.shade500,
            label: 'Sort by country/region name',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () async {
              _sortByType = EnumSortKennelListBy.countryRegionName;
              await _refreshFromTable(true);
              setState(() {});
            },
          ),
        ]);
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
                  _searchKennelsText = text;
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
          SizedBox(
            width: 40,
            child: TextButton(
              style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
              child: const Text('X'),
              onPressed: () {
                _searchController.text = '';
                _searchKennelsText = '';
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
      //final Geolocator locator = Geolocator();
      if (G0<TableModel>().globalKennelMainPageList != null) {
        G0<TableModel>().globalKennelMainPageList.clear();
      }

      final String hasherId = getStringPref(StringPrefsEnum.userId);

      G0<TableModel>().globalKennelMainPageList = <KennelListAggregate>[];
      try {
        final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(EnumKennelQueryType.topKennelPage, EnumKennelQueryContext.user, hasherId: hasherId);

        for (int i = 0; i < results.length; i++) {
          final num dist = Geolocator.distanceBetween(G0<DeviceInfo>().deviceLat, G0<DeviceInfo>().deviceLon, results[i]['cityLat'] + .0, results[i]['cityLon'] + .0);

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

        setState(() {
          _filterResults();
        });
      } catch (e) {
        //print(e);
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
        _filteredList = QueryKennels.doFilter(_searchKennelsText, G0<TableModel>().globalKennelMainPageList);
      }

      if ((G0<AppModel>().hasLocationPermissions) && (_sortByType == EnumSortKennelListBy.distance)) {
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          return (a.isHomeKennel ? 0 : a.extensions.distToKennel).compareTo(b.isHomeKennel ? 0 : b.extensions.distToKennel);
        });
      } else if ((!G0<AppModel>().hasLocationPermissions) && (_sortByType == EnumSortKennelListBy.distance)) {
        // if no location permissions given, but search by distance selected
        // sort by kennelName
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          return (a.isHomeKennel ? ' ' : a.kennel.kennelName.trim()).compareTo(b.isHomeKennel ? ' ' : b.kennel.kennelName.trim());
        });
      } else if (_sortByType == EnumSortKennelListBy.kennelName) {
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          return (a.isHomeKennel ? ' ' : a.kennel.kennelName.trim()).compareTo(b.isHomeKennel ? ' ' : b.kennel.kennelName.trim());
        });
      } else if (_sortByType == EnumSortKennelListBy.cityName) {
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          return (a.isHomeKennel ? ' ' : a.extensions.cityName.trim()).compareTo(b.isHomeKennel ? ' ' : b.extensions.cityName.trim());
        });
      } else if (_sortByType == EnumSortKennelListBy.countryRegionName) {
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          int result = (a.isHomeKennel ? ' ' : a.extensions.countryName.trim()).compareTo(b.isHomeKennel ? ' ' : b.extensions.countryName.trim());

          if (result == 0) {
            result = a.extensions.regionName.trim().compareTo(b.extensions.regionName.trim());
          }

          if (result == 0) {
            result = a.extensions.cityName.trim().compareTo(b.extensions.cityName.trim());
          }

          return result;
        });
      } else if (_sortByType == EnumSortKennelListBy.following) {
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) {
          if (a.isHomeKennel) {
            return -1;
          }

          if (b.isHomeKennel) {
            return 1;
          }

          int result = (a.hkm.following == 1
                  ? 0
                  : a.hkm.following == 2
                      ? 2
                      : 1)
              .compareTo(b.hkm.following == 1
                  ? 0
                  : b.hkm.following == 2
                      ? 2
                      : 1);

          if (result == 0) {
            if (G0<AppModel>().hasLocationPermissions) {
              result = a.extensions.distToKennel.compareTo(b.extensions.distToKennel);
            } else {
              result = a.kennel.kennelName.trim().compareTo(b.kennel.kennelName.trim());
            }
          }

          return result;
        });
      } else {
        // this should never be reached, but if we do get here use the default sort
        _filteredList.sort((KennelListAggregate a, KennelListAggregate b) => a.extensions.distToKennel.compareTo(b.extensions.distToKennel));
      }

      //G0<TableModel>().globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (b.isHomeKennel ? 1 : 0).compareTo(a.isHomeKennel ? 1 : 0));

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: getKennelFab(),
      body: G0<TableModel>().globalKennelMainPageList == null
          ? const Center(
              child: HcCircularProgressIndicator(key: Key('3320159590')),
            )
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              padding: const EdgeInsets.only(top: 0.0),
              child: ((G0<TableModel>().globalKennelMainPageList == null) || (G0<TableModel>().globalKennelMainPageList.isEmpty))
                  ? Center(child: Text('Loading Kennels.', style: headingStyle))
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
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          itemCount: _filteredList.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            ////print('buildListView called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
                            return _filteredList.length == index
                                ? Container(height: 100.0)
                                : Padding(
                                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    child: KennelsListItem(
                                      kennelItem: _filteredList[index],
                                      kennelFollowingUpdated: (int following, int notificationStatus, int emailAlertStatus, int isHomeKennel) async {
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

                                        // delete all of the events for a kennel being followed (or unfollowed) before
                                        // requerying for those events.
                                        final String sql = '''
                                    DELETE FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)}
                                    WHERE ${G0<TableModel>().eventsTableHelper.colKennelId} = '${_filteredList[index].kennel.kennelId}'
                                    ''';

                                        await G0<Database>().rawQuery(sql);

                                        // when someone follows or unfollows a Kennel we need to re-sync the events to make sure that
                                        // we have either all of the events for the kennel (if it is being followed) or only the
                                        // events from the normal time period for unfollowed kennels (currently one year in the past)
                                        await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagNarrowEventsTable, true,
                                            forceReplicateAllRunsForKennel: _filteredList[index].kennel.kennelId);

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
                                            .then((void _) async {
                                          await G0<TableModel>().syncUserDataService.updateFromBackend(
                                              SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagHasherKennelMapTable | SyncUserDataService.flagKennelsTable,
                                              true);
                                          //final String resultStr = result ? 'successfully' : 'unsuccessfully';
                                          //print('Pack member data synchronized $resultStr');
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
      //print(e);
    }

    query = 'DELETE FROM ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)}';
    try {
      await G0<Database>().rawQuery(query);
    } catch (e) {
      //print(e);
    }

    await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagKennelsTable | SyncUserDataService.flagHasherKennelMapTable, true);
    await _refreshFromTable(true);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Kennel user data synchronized $resultStr');
  }
}
