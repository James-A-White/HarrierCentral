import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geolocator/geolocator.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/services/kennel_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/singletons.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:scoped_model/scoped_model.dart';

class KennelsListPage extends StatefulWidget {
  const KennelsListPage({Key key, @required this.kennelModel}) : super(key: key);

  final KennelScopedModel kennelModel;

  @override
  KennelsListPageState createState() => KennelsListPageState(model: kennelModel);
}

class KennelsListPageState extends State<KennelsListPage> {
  KennelsListPageState({@required this.model});

  KennelScopedModel model;

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
    if (forceRefresh || (Singletons.kennelMainPageList == null)) {
      final Geolocator locator = Geolocator();

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          const String query = ''' 
      
        SELECT  
          k.*, hkm.following,
          c.cityName || ', ' || CASE WHEN n.showRegion = 1 THEN r.regionName || ', ' ELSE '' END || n.countryName as location
          FROM kennels k
          INNER JOIN cities c on c.cityId = k.cityId
          INNER JOIN regions r on r.regionId = k.regionId
          INNER JOIN countries n on n.countryId = k.countryId
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.kennelId = k.kennelId 
          
          ''';

          Singletons.kennelMainPageList = <Map<String, dynamic>>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              
                for (int i = 0; i < results.length; i++) {
                  locator.distanceBetween(ll.latitude, ll.longitude, results[i]['latitude'], results[i]['longitude']).then((double dist) {
                    final Map<String, dynamic> item = <String, dynamic>{};
                    item.addAll(<String, dynamic>{'distance': dist.round()});
                    item.addAll(results[i]);
                    Singletons.kennelMainPageList.add(item);
                    if (i == results.length - 1)
                    {
                      setState(() {
                        
                      });
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
    return ScopedModel<KennelScopedModel>(
      model: model,
      child: Scaffold(
        body: ScopedModelDescendant<KennelScopedModel>(
          builder: (BuildContext context, Widget child, KennelScopedModel model) {
            return Singletons.kennelMainPageList == null ? _buildCircularProgressIndicator() : _buildListView();
          },
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    model.getKennelsFromBackend(false).then((void dummy) {
      refreshFromTable(true);
    });
  }

  Widget _buildListView() {
    Singletons.kennelMainPageList.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['distance']).compareTo(b['distance']));
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      padding: const EdgeInsets.only(top: 0.0),
      child: Singletons.kennelMainPageList.isEmpty
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: Singletons.kennelMainPageList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 150.0,
                    padding: const EdgeInsets.all(0.0),
                    child: ListView(scrollDirection: Axis.horizontal, children: <Widget>[
                      KennelsListItem(kennel: Singletons.kennelMainPageList[index]),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
