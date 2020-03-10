import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/database/database.dart';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/pages/detail_pages/kennel_admin_main.dart';

class KennelListQueryExtenstions {
  KennelListQueryExtenstions({this.location, this.distToKennel, this.nextRunDate, this.lastRunDate, this.digitsAfterDecimal, this.currencySymbol, this.isHomeKennel, this.distancePreference, this.cityLat, this.cityLon, this.nameForSearch});

  final String location;
  num distToKennel;
  final String nextRunDate;
  final String lastRunDate;
  final int digitsAfterDecimal;
  final String currencySymbol;
  int isHomeKennel;
  int distancePreference;
  num cityLat;
  num cityLon;
  final String nameForSearch;

  int followingRequested;
  int notificationsRequested;
  int emailAlertRequested;

  static KennelListQueryExtenstions fromMap(Map<String, dynamic> map) {
    final KennelListQueryExtenstions item = KennelListQueryExtenstions(
        location: map['location'],
        distToKennel: map['distToKennel'],
        nextRunDate: map['nextRunDate'],
        lastRunDate: map['lastRunDate'],
        digitsAfterDecimal: map['digitsAfterDecimal'],
        currencySymbol: map['currencySymbol'],
        isHomeKennel: map['isHomeKennel'],
        distancePreference: map['distancePreference'],
        cityLat: map['cityLat'],
        cityLon: map['cityLon'],
        nameForSearch: map['nameForSearch']);
    return item;
  }
}

class KennelListAggregate {
  KennelListAggregate({
    this.kennel,
    this.hkm,
    this.extensions,
  });

  final KennelsModel kennel;
  final HasherKennelMapModel hkm;
  final KennelListQueryExtenstions extensions;
}

class KennelsListPage extends StatefulWidget {
  const KennelsListPage({Key key}) : super(key: key);

  @override
  KennelsListPageState createState() => KennelsListPageState();
}

class KennelsListPageState extends State<KennelsListPage> {
  KennelsListPageState();

  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();
  String searchText;

  List<KennelListAggregate> filteredList = <KennelListAggregate>[];

  int pageIndex = 1;

  @override
  void initState() {
    searchController.text = '';
    searchText = '';

    // NOTE: refreshFromTable will run asynchronously so don't expect the
    // tables to be populated immediately when this call returns.
    refreshFromTable(false);

    //print('initState called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

    super.initState();
  }

  Container searchBar() {
    return Container(
      // decoration: const BoxDecoration(
      //   // border: new Border.all(width: 1.0, color: Colors.black),
      //   //shape: BoxShape.circle,
      //   color: Colors.white,
      //   boxShadow: <BoxShadow>[
      //     BoxShadow(
      //       color: Color.fromARGB(70, 0, 0, 0),
      //       offset: Offset(0.0, 6.0),
      //       blurRadius: 10.0,
      //     ),
      //   ],
      // ),
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
                  searchText = text;
                  filterResults();
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
            child: FlatButton(
              //color: Colors.red,
              child: const Text('X'),
              textColor: Colors.grey[700],
              onPressed: () {
                searchController.text = '';
                searchText = '';
                //_refreshPackListFromTables(true);
              },
            ),
          ),
        ],
      ),
    );
  }

  void refreshFromTable(bool forceRefresh) {
    if (forceRefresh || (globalKennelMainPageList == null) || (globalKennelMainPageList.isEmpty)) {
      final Geolocator locator = Geolocator();
      if (globalKennelMainPageList != null) {
        globalKennelMainPageList.clear();
      }

      final String hasherId = getStringPref(StringPrefsEnum.userId);

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          final String query = ''' 
      
        SELECT  
          k.*, 
          hkm.hkmId, 
          hkm.kennelNotificationPreference,
          hkm.kennelEmailAlertPreference,
          COALESCE(hkm.following,0) as following,
          COALESCE(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location,
          (SELECT min(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime >= datetime('now','localtime') ) as nextRunDate,
          (SELECT max(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime <= datetime('now','localtime') ) as lastRunDate,
          n.digitsAfterDecimal,
          n.currencySymbol,
          coalesce(k.${kennelsTableHelper.colKennelLatitude},c.${citiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          coalesce(k.${kennelsTableHelper.colKennelLongitude},c.${citiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          CASE WHEN ((h.homeKennelId IS NOT NULL) AND (h.homeKennelId = k.kennelId)) then 1 else 0 end as isHomeKennel,
          CASE WHEN h.preferences & 0x00000003 = 0 THEN COALESCE(k.distancePreference,n.distancePreference,0) ELSE (h.preferences & 0x00000003) - 2 END as distancePreference,
          lower(k.${kennelsTableHelper.colKennelName} || " " || k.${kennelsTableHelper.colKennelShortName} || " " || c.${citiesTableHelper.colCityName} || " " || r.${regionsTableHelper.colRegionName} || " " || n.${countriesTableHelper.colCountryName} || " " 
            || case 
              when n.${countriesTableHelper.colContinentCode} = "EU" then "europe" 
              when n.${countriesTableHelper.colContinentCode} = "AF" then "africa" 
              when n.${countriesTableHelper.colContinentCode} = "AS" then "asia" 
              when n.${countriesTableHelper.colContinentCode} = "NA" then "north america" 
              when n.${countriesTableHelper.colContinentCode} = "SA" then "south america" 
              when n.${countriesTableHelper.colContinentCode} = "OC" then "oceania" 
              when n.${countriesTableHelper.colContinentCode} = "AN" then "antarctica" 
              else "" 
              end
            ) as nameForSearch
          FROM ${kennelsTableHelper.tableName} k
          INNER JOIN ${citiesTableHelper.tableName} c on c.cityId = k.cityId
          INNER JOIN ${regionsTableHelper.tableName} r on r.regionId = k.regionId
          INNER JOIN ${countriesTableHelper.tableName} n on n.countryId = k.countryId
          INNER JOIN ${hashersTableHelper.tableName} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} hkm on hkm.kennelId = k.kennelId and hkm.${hasherKennelMapTableHelper.colUserId} = "$hasherId"
          ''';

          globalKennelMainPageList = <KennelListAggregate>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(Utilities.unInt(ll.latitude), Utilities.unInt(ll.longitude), Utilities.unInt(results[i]['cityLat']), Utilities.unInt(results[i]['cityLon'])).then((num dist) {
                  final KennelsModel kennelItem = kennelsTableHelper.fromMap(results[i]);
                  final HasherKennelMapModel hkmItem = hasherKennelMapTableHelper.fromMap(results[i]);
                  final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[i]);
                  extensionsItem.distToKennel = dist;
                  extensionsItem.followingRequested = -1;
                  extensionsItem.notificationsRequested = -1;
                  extensionsItem.emailAlertRequested = -1;

                  final KennelListAggregate item = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem);

                  globalKennelMainPageList.add(item);
                  if (i == results.length - 1) {
                    if (hasLocationPermissions) {
                      globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => a.extensions.distToKennel.compareTo(b.extensions.distToKennel));
                    } else {
                      globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => a.kennel.kennelName.compareTo(b.kennel.kennelName));
                    }

                    globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (a.hkm.following == 1 ? 0 : a.hkm.following == 2 ? 1 : 2).compareTo(b.hkm.following == 1 ? 0 : b.hkm.following == 2 ? 1 : 2));

                    globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (b.hkm.isHomeKennel).compareTo(a.hkm.isHomeKennel));
                    filterResults();
                    setState(() {});
                  }
                });
              }
            });
          } catch (e) {
            print(e);
          }
        });
      });
    } else {
      // if the global list is already loaded,
      // go ahead and call filterResults to make sure that the
      // filtered list is also populated, otherwise we might
      // end up with an empty list.
      filterResults();
    }
  }

  void filterResults() {
    if (globalKennelMainPageList != null) {
      if (searchController.text.isEmpty) {
        filteredList = <KennelListAggregate>[];
        filteredList.addAll(globalKennelMainPageList);
      } else {
        filteredList = globalKennelMainPageList.where((KennelListAggregate a) => a.extensions.nameForSearch.toLowerCase().contains(searchText.toLowerCase())).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: globalKennelMainPageList == null
          ? const Center(
              child: HcCircularProgressIndicator(),
            )
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              padding: const EdgeInsets.only(top: 0.0),
              child: ((globalKennelMainPageList == null) || (globalKennelMainPageList.isEmpty))
                  ? Center(child: Text('No Kennels available.', style: headingStyle))
                  : NestedScrollView(
                      headerSliverBuilder: (BuildContext context, bool innerBoxScrolled) => [
                        //!innerBoxScrolled ? Container() :
                        SliverAppBar(
                          floating: false,
                          pinned: false,
                          snap: false,
                          elevation: 20,
                          actions: <Widget>[searchBar()],
                        )
                      ],
                      body: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (BuildContext context, int index) {
                            //print('buildListView called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
                            return Padding(
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                              child: KennelsListItem(
                                kennelItem: filteredList[index],
                                kennelFollowingUpdated: (int following, int notificationStatus, int emailAlertStatus, int isHomeKennel) {
                                  filteredList[index].extensions.followingRequested = -1;
                                  filteredList[index].extensions.notificationsRequested = -1;
                                  filteredList[index].extensions.emailAlertRequested = -1;
                                  filteredList[index].hkm.following = following;
                                  filteredList[index].hkm.kennelNotificationPreference = notificationStatus;
                                  filteredList[index].hkm.kennelEmailAlertPreference = emailAlertStatus;
                                  // if this kennel has been set as the home kennel, clear the home kennel
                                  // flag on the rest of the kennels
                                  if (isHomeKennel != 0) {
                                    for (int i = 0; i < filteredList.length; i++) {
                                      filteredList[i].extensions.isHomeKennel = 0;
                                    }
                                  }
                                  filteredList[index].extensions.isHomeKennel = isHomeKennel;
                                  setState(() {});
                                },
                                kennelSelected: () {
                                  final KennelListAggregate kennel = filteredList[index];
                                  // // this is a bit of a hack where we clear the list before navigating to the
                                  // // next page. When state changes occurred in child pages further down the
                                  // // route tree, the list would get refreshed, which I think was causing
                                  // // a bug where the selected Kennel itself would occasioinall change.
                                  // // By deleting the list, I'm hoping that this bug will be fixed.
                                  globalKennelMainPageList.clear();
                                  Navigator.of(context)
                                      .push<dynamic>(
                                    MaterialPageRoute<dynamic>(
                                      builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
                                    ),
                                  )
                                      .then((void dummy) {
                                    refreshFromTable(true);
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
    final Database db = await DBProvider.db.database;

    setState(() {
      globalKennelMainPageList = null;
    });

    String query = 'DELETE FROM ${kennelsTableHelper.tableName}';
    try {
      await db.rawQuery(query);
    } catch (e) {
      print(e);
    }

    query = 'DELETE FROM ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)}';
    try {
      await db.rawQuery(query);
    } catch (e) {
      print(e);
    }

    final SyncUserDataService cSrv = SyncUserDataService();
    cSrv.updateFromBackend(db, SyncUserDataService.flagKennelsTable | SyncUserDataService.flagHasherKennelMapTable, false).then((bool result) {
      refreshFromTable(true);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Kennel user data synchronized $resultStr');
    });
  }
}
