import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/database/database.dart';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/singletons.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

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
    // DBProvider.db.database.then((Database db) {
    //   db.rawQuery('SELECT id,kennelId FROM kennels ORDER BY id').then((List<Map<String,dynamic>> result) {
    //     print(result);
    //   });
    // });

    // DBProvider.db.database.then((Database db) {
    //   db.rawQuery('SELECT id,kennelId,userId FROM hasherKennelMap ORDER BY id').then((List<Map<String,dynamic>> result) {
    //     print(result.toString().replaceAll('},', '},\r\n'));
    //   });
    // });
    super.initState();
  }

  void refreshFromTable(bool forceRefresh) {
    if (forceRefresh || (singletonKennelMainPageList == null)) {
      final Geolocator locator = Geolocator();
      if (singletonKennelMainPageList != null) {
        singletonKennelMainPageList.clear();
      }

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          const String query = ''' 
      
        SELECT  
          k.*, 
          hkm.hkmId, 
          COALESCE(hkm.following,0) as following,
          COALESCE(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location,
          (SELECT min(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime >= datetime('now') ) as nextRunDate,
          (SELECT max(eventStartDatetime) from narrowEvents e where e.kennelId = k.kennelId and e.eventStartDatetime <= datetime('now') ) as lastRunDate,
          n.digitsAfterDecimal,
          n.currencySymbol
          FROM kennels k
          INNER JOIN cities c on c.cityId = k.cityId
          INNER JOIN regions r on r.regionId = k.regionId
          INNER JOIN countries n on n.countryId = k.countryId
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.kennelId = k.kennelId 
          
          ''';

          singletonKennelMainPageList = <Map<String, dynamic>>[]; 
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(ll.latitude, ll.longitude, results[i]['latitude'], results[i]['longitude']).then((double dist) {
                  final Map<String, dynamic> item = <String, dynamic>{};
                  item.addAll(<String, dynamic>{'distance': dist.round()});
                  item.addAll(<String, dynamic>{'followingRequested': -1});
                  item.addAll(results[i]);
                  singletonKennelMainPageList.add(item);
                  if (i == results.length - 1) {
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
      body: singletonKennelMainPageList == null ? _buildCircularProgressIndicator() : _buildListView());
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(),
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

  Widget _buildListView() {
    singletonKennelMainPageList.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['distance']).compareTo(b['distance']));
    singletonKennelMainPageList.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['following']==1?0:a['following']==2?1:2).compareTo(b['following']==1?0:b['following']==2?1:2));
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      padding: const EdgeInsets.only(top: 0.0),
      child: singletonKennelMainPageList.isEmpty
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: singletonKennelMainPageList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 150.0,
                    padding: const EdgeInsets.all(0.0),
                    child: ListView(scrollDirection: Axis.horizontal, children: <Widget>[
                      KennelsListItem(kennel: singletonKennelMainPageList[index]),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
