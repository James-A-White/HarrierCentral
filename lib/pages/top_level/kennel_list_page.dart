import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/database/database.dart';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/pages/detail_pages/kennel_admin_main.dart';


import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';


class KennelListQueryExtenstions {
  KennelListQueryExtenstions({this.location,this.distToKennel,this.nextRunDate,this.lastRunDate,this.digitsAfterDecimal,this.currencySymbol});

  final String location;
  num distToKennel;
  final String nextRunDate;
  final String lastRunDate;
  final int digitsAfterDecimal;
  final String currencySymbol;

  int followingRequested;
  int notificationsRequested;

  static KennelListQueryExtenstions fromMap(Map<String, dynamic> map) {
    final KennelListQueryExtenstions item = KennelListQueryExtenstions(location: map['location'], distToKennel: map['distToKennel'], nextRunDate: map['nextRunDate'], lastRunDate: map['lastRunDate'],digitsAfterDecimal: map['digitsAfterDecimal'],currencySymbol: map['currencySymbol'] );
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
    if (forceRefresh || (globalKennelMainPageList == null)|| (globalKennelMainPageList.isEmpty)) {
      final Geolocator locator = Geolocator();
      if (globalKennelMainPageList != null) {
        globalKennelMainPageList.clear();
      }

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          const String query = ''' 
      
        SELECT  
          k.*, 
          hkm.hkmId, 
          hkm.kennelNotificationPreference,
          COALESCE(hkm.following,0) as following,
          COALESCE(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location,
          (SELECT min(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime >= datetime('now','localtime') ) as nextRunDate,
          (SELECT max(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime <= datetime('now','localtime') ) as lastRunDate,
          n.digitsAfterDecimal,
          n.currencySymbol
          FROM kennels k
          INNER JOIN cities c on c.cityId = k.cityId
          INNER JOIN regions r on r.regionId = k.regionId
          INNER JOIN countries n on n.countryId = k.countryId
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.kennelId = k.kennelId 
          
          ''';

          globalKennelMainPageList = <KennelListAggregate>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(ll.latitude, ll.longitude, results[i]['kennelLatitude'], results[i]['kennelLongitude']).then((num dist) {

                  // final Map<String, dynamic> item = <String, dynamic>{};
                  // item.addAll(<String, dynamic>{'distance': dist.round()});
                  // item.addAll(<String, dynamic>{'followingRequested': -1});
                  // item.addAll(results[i]);
                  final KennelsModel kennelItem = KennelsTableHelper.fromMap(results[i]);
                  final HasherKennelMapModel hkmItem = HasherKennelMapTableHelper.fromMap(results[i]);
                  final KennelListQueryExtenstions extensionsItem = KennelListQueryExtenstions.fromMap(results[i]);
                  extensionsItem.distToKennel = dist;
                  extensionsItem.followingRequested = -1;
                  extensionsItem.notificationsRequested = -1;

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
                          return 
                              KennelsListItem(
                                kennelItem: globalKennelMainPageList[index],
                                kennelFollowingUpdated: (int following,int notificationStatus){
                                  globalKennelMainPageList[index].extensions.followingRequested = -1;
                                  globalKennelMainPageList[index].extensions.notificationsRequested = -1;
                                  globalKennelMainPageList[index].hkm.following = following;
                                  globalKennelMainPageList[index].hkm.kennelNotificationPreference = notificationStatus;
                                },
                                kennelSelected: () {
                                  final KennelListAggregate kennel = globalKennelMainPageList[index];
                                  // // this is a bit of a hack where we clear the list before navigating to the
                                  // // next page. When state changes occurred in child pages further down the
                                  // // route tree, the list would get refreshed, which I think was causing 
                                  // // a bug where the selected Kennel itself would occasioinall change.
                                  // // By deleting the list, I'm hoping that this bug will be fixed.
                                  globalKennelMainPageList.clear();
                                  Navigator.of(context).push<dynamic>(
                                    MaterialPageRoute<dynamic>(
                                      builder: (BuildContext context) => KennelAdminMainPage(kennelAggregateItem: kennel),
                                    ),
                                  ).then((void dummy){
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

    final SyncUserDataService cSrv = SyncUserDataService();
    cSrv.updateFromBackend(db, SyncUserDataService.flagKennelsTable | SyncUserDataService.flagHasherKennelMapTable, false).then((bool result) {
      refreshFromTable(true);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Kennel user data synchronized $resultStr');
    });
  }
}
