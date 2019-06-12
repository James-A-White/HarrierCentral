import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/widgets/run_list_item.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';

class FutureRunsListPage extends StatefulWidget {
  const FutureRunsListPage({Key key}) : super(key: key);

  @override
  FutureRunListPageState createState() => FutureRunListPageState();
}

class FutureRunQueryExtenstions {
  FutureRunQueryExtenstions({this.daysUntilEvent, this.distToEvent, this.hareList, this.mismanagementRoleFlags, this.currencySymbol, this.digitsAfterDecimal, this.rsvpState, this.isHare, this.following});

  final num daysUntilEvent;
  num distToEvent;
  final String hareList;
  final int mismanagementRoleFlags;
  int digitsAfterDecimal;
  String currencySymbol;
  final int rsvpState;
  final int isHare;
  final int following;

  static FutureRunQueryExtenstions fromMap(Map<String, dynamic> map) {
    final FutureRunQueryExtenstions item = FutureRunQueryExtenstions(daysUntilEvent: map['daysUntilEvent'], hareList: map['hareList'], mismanagementRoleFlags: map['mismanagementRoleFlags'], following: map['following']);
    return item;
  }
}

class FutureRunAggregate {
  FutureRunAggregate({
    this.event,
    this.kennel,
    this.extensions,
  });

  final NarrowEventsModel event;
  final KennelsModel kennel;
  final FutureRunQueryExtenstions extensions;
}

class FutureRunListPageState extends State<FutureRunsListPage> with AutomaticKeepAliveClientMixin {
  // BuildContext context;

  @override
  bool get wantKeepAlive => true;

  int pageIndex = 1;
  List<FutureRunAggregate> futureRunsList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: futureRunsList == null ? const HcCircularProgressIndicator() : _buildListView());
  }

  Future<void> _handleRefresh() async {
    final Database db = await DBProvider.db.database;

    final SyncUserDataService cSrv = SyncUserDataService();
    cSrv.updateFromBackend(db, SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable, false).then((bool result) {
      refreshFromTable(true);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Events user data synchronized $resultStr');
    });
  }

  @override
  void initState() {
    refreshFromTable(false);
    super.initState();
  }

  void refreshFromTable(bool forceRefresh) {
    if (forceRefresh || (futureRunsList == null)|| (futureRunsList.isEmpty)) {
      final Geolocator locator = Geolocator();

      final String userId = getStringPref(StringPrefsEnum.userId);

      Utilities.getLatLong().then((LatLon ll) {
        DBProvider.db.database.then((Database db) {
          final String query = ''' 
      
        SELECT  
          evt.*,
          k.*,
          coalesce(hkm.mismanagementRoleFlags,0) as mismanagementRoleFlags,
          coalesce(hkm.following,0) as following,
          coalesce(hem.rsvpState,0) as rsvpState,
          coalesce(hem.isHare,0) as isHare,
          julianday(evt.eventStartDatetime) - julianday('now') as daysUntilEvent,
             (SELECT GROUP_CONCAT(h.dispName,",") FROM hasherEventMapForRunAdmin hem2
              INNER JOIN hashers h on hem2.userId = h.hasherId
              WHERE hem2.eventId = evt.eventId AND hem2.isHare = 1) as hareList
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN hasherEventMapForRunAdmin hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          WHERE evt.eventStartDatetime > date('now','-4 hour') and evt.isVisible = 1
          AND (
                (coalesce(hkm.following,0) <= 1) 
                OR 
                (coalesce(hem.rsvpState,0) >= 2)
              )
          ORDER BY evt.eventStartDatetime
          ''';

          futureRunsList = <FutureRunAggregate>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(ll.latitude, ll.longitude, results[i]['narrowEventLatitude'], results[i]['narrowEventLongitude']).then((num dist) {
                  final NarrowEventsModel eventItem = NarrowEventsTableHelper.fromMap(results[i]);
                  final KennelsModel kennelItem = KennelsTableHelper.fromMap(results[i]);
                  final FutureRunQueryExtenstions extensionsItem = FutureRunQueryExtenstions.fromMap(results[i]);
                  extensionsItem.distToEvent = dist;
                  extensionsItem.currencySymbol = '€^';
                  extensionsItem.digitsAfterDecimal = 2;

                  if ((extensionsItem.following >= 1) || ((extensionsItem.following == 0) && (dist < 50000))) {
                    final FutureRunAggregate item = FutureRunAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem);
                    futureRunsList.add(item);
                  }
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

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: futureRunsList.isEmpty
          ? const Center(child: Text('No Runs available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                //padding: const EdgeInsets.only( bottom: 40.0),
                itemCount: futureRunsList.length,
                itemBuilder: (BuildContext context, int index) {
                  //return Container();
                  // if ((model.futureRunsList[index].daysUntilNextRun < 9999) &&
                  //     (model.futureRunsList[index].isVisible != 0)) {
                  return RunListItem(futureRun: futureRunsList[index]);
                  // } else {
                  //   return Container();
                  // }
                },
              ),
            ),
    );
  }
}
