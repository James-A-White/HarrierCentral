import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/database/database.dart';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/data/hc3_services/regions_service.dart';
import 'package:harrier_central/data/hc3_services/cities_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';

import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/pages/detail_pages/kennel_admin_main.dart';

class KennelListQueryExtenstions {
  KennelListQueryExtenstions({this.location, this.distToKennel, this.nextRunDate, this.lastRunDate, this.digitsAfterDecimal, this.currencySymbol, this.isHomeKennel, this.distancePreference, this.cityLat, this.cityLon});

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
        cityLon: map['cityLon']);
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

  int pageIndex = 1;

  @override
  void initState() {
    refreshFromTable(false);
    //print('initState called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');

    super.initState();
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
          coalesce(k.${KennelsTableHelper.colKennelLatitude},c.${CitiesTableHelper.colLatitude},$DEFAULT_LATITUDE) as cityLat,
          coalesce(k.${KennelsTableHelper.colKennelLongitude},c.${CitiesTableHelper.colLongitude},$DEFAULT_LONGITUDE) as cityLon,
          CASE WHEN ((h.homeKennelId IS NOT NULL) AND (h.homeKennelId = k.kennelId)) then 1 else 0 end as isHomeKennel,
          CASE WHEN h.preferences & 0x00000003 = 0 THEN COALESCE(k.distancePreference,n.distancePreference,0) ELSE (h.preferences & 0x00000003) - 2 END as distancePreference
          FROM ${KennelsTableHelper.tableName} k
          INNER JOIN ${CitiesTableHelper.tableName} c on c.cityId = k.cityId
          INNER JOIN ${RegionsTableHelper.tableName} r on r.regionId = k.regionId
          INNER JOIN ${CountriesTableHelper.tableName} n on n.countryId = k.countryId
          INNER JOIN ${HashersTableHelper.tableName} h on h.hasherId = "$hasherId"
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} hkm on hkm.kennelId = k.kennelId and hkm.${HasherKennelMapTableHelper.colUserId} = "$hasherId"
          ''';

          globalKennelMainPageList = <KennelListAggregate>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(Utilities.unInt(ll.latitude), Utilities.unInt(ll.longitude), Utilities.unInt(results[i]['cityLat']), Utilities.unInt(results[i]['cityLon'])).then((num dist) {
                  final KennelsModel kennelItem = KennelsTableHelper.fromMap(results[i]);
                  final HasherKennelMapModel hkmItem = HasherKennelMapTableHelper.fromMap(results[i]);
                  final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[i]);
                  extensionsItem.distToKennel = dist;
                  extensionsItem.followingRequested = -1;
                  extensionsItem.notificationsRequested = -1;
                  extensionsItem.emailAlertRequested = -1;

                  final KennelListAggregate item = KennelListAggregate(kennel: kennelItem, extensions: extensionsItem, hkm: hkmItem);

                  globalKennelMainPageList.add(item);
                  if (i == results.length - 1) {
                    globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => a.extensions.distToKennel.compareTo(b.extensions.distToKennel));
                    globalKennelMainPageList.sort((KennelListAggregate a, KennelListAggregate b) => (a.hkm.following == 1 ? 0 : a.hkm.following == 2 ? 1 : 2).compareTo(b.hkm.following == 1 ? 0 : b.hkm.following == 2 ? 1 : 2));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: globalKennelMainPageList == null
          ? const Center(
              child: HcCircularProgressIndicator(),
            )
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              padding: const EdgeInsets.only(top: 0.0),
              child: globalKennelMainPageList.isEmpty
                  ? const Center(child: Text('No Kennels available.'))
                  : RefreshIndicator(
                      onRefresh: () => _handleRefresh(),
                      displacement: 40.0,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: globalKennelMainPageList.length,
                        itemBuilder: (BuildContext context, int index) {
                          //print('buildListView called from kennel_list_page @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
                          return KennelsListItem(
                            kennelItem: globalKennelMainPageList[index],
                            kennelFollowingUpdated: (int following, int notificationStatus, int emailAlertStatus, int isHomeKennel) {
                              for (int i = 0; i < globalKennelMainPageList.length; i++) {
                                globalKennelMainPageList[i].extensions.isHomeKennel = 0;
                              }
                              globalKennelMainPageList[index].extensions.followingRequested = -1;
                              globalKennelMainPageList[index].extensions.notificationsRequested = -1;
                              globalKennelMainPageList[index].extensions.emailAlertRequested = -1;
                              globalKennelMainPageList[index].hkm.following = following;
                              globalKennelMainPageList[index].hkm.kennelNotificationPreference = notificationStatus;
                              globalKennelMainPageList[index].hkm.kennelEmailAlertPreference = emailAlertStatus;
                              globalKennelMainPageList[index].extensions.isHomeKennel = isHomeKennel;
                              setState(() {});
                            },
                            kennelSelected: () {
                              final KennelListAggregate kennel = globalKennelMainPageList[index];
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
                          );
                        },
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
    
    String query = 'DELETE FROM ${KennelsTableHelper.tableName}';
    try {
      await db.rawQuery(query);
    } catch (e) {
      print(e);
    }

    query = 'DELETE FROM ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)}';
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
