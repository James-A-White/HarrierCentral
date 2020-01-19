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
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';

class FutureRunsListPage extends StatefulWidget {
  const FutureRunsListPage({Key key}) : super(key: key);

  @override
  FutureRunListPageState createState() => FutureRunListPageState();
}

class RunDetailsQueryExtensions {
  RunDetailsQueryExtensions({this.daysUntilEvent, this.distToEvent, this.mismanagementRoleFlags, this.currencySymbol, this.digitsAfterDecimal, this.rsvpState, this.isHare, this.following, this.notificationPreference, this.emailAlertPreference, this.distancePreference});

  final num daysUntilEvent;
  num distToEvent;
  final int mismanagementRoleFlags;
  int digitsAfterDecimal;
  String currencySymbol;
  final int rsvpState;
  final int isHare;
  final int following;
  int notificationPreference;
  int emailAlertPreference;
  int distancePreference;

  static RunDetailsQueryExtensions fromMap(Map<String, dynamic> map) {
    final RunDetailsQueryExtensions item = RunDetailsQueryExtensions(
        daysUntilEvent: map['daysUntilEvent'],
        digitsAfterDecimal: map['digitsAfterDecimal'],
        currencySymbol: map['currencySymbol'],
        mismanagementRoleFlags: map['mismanagementRoleFlags'],
        following: map['following'],
        notificationPreference: map['notificationPreference'],
        emailAlertPreference: map['emailAlertPreference'],
        distancePreference: map['distancePreference']);
    return item;
  }
}

class RunDetailsAggregate {
  RunDetailsAggregate({
    this.event,
    this.kennel,
    this.extensions,
  });

  final NarrowEventsModel event;
  final KennelsModel kennel;
  final RunDetailsQueryExtensions extensions;
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  // BuildContext context;

  // @override
  // bool get wantKeepAlive => true;

  int pageIndex = 1;
  List<RunDetailsAggregate> futureRunsList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: futureRunsList == null ? const HcCircularProgressIndicator() : _buildListView());
  }

  Future<void> _handleRefresh({bool queryBackend = true, bool clearLocalTables = false}) async {
    final Database db = await DBProvider.db.database;

    setState(() {
      futureRunsList = null;
    });

    if (clearLocalTables) {
      String query = 'DELETE FROM ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.user)}';
      try {
        await db.rawQuery(query);
      } catch (e) {
        print(e);
      }

      query = 'DELETE FROM ${NarrowEventsTableHelper.tableName}';
      try {
        await db.rawQuery(query);
      } catch (e) {
        print(e);
      }
    }

    if (queryBackend) {
      final SyncUserDataService cSrv = SyncUserDataService();
      cSrv.updateFromBackend(db, SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable, false).then((bool result) {
        refreshFromTable(true);
        final String resultStr = result ? 'successfully' : 'unsuccessfully';
        print('Events user data synchronized $resultStr');
      });
    }
  }

  @override
  void initState() {
    refreshFromTable(false);
    super.initState();
  }

  void refreshFromTable(bool forceRefresh) {
    if (forceRefresh || (futureRunsList == null) || (futureRunsList.isEmpty)) {
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
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference,
          coalesce(hem.eventEmailAlertPreference,hkm.kennelEmailAlertPreference,0) as emailAlertPreference,
          n.digitsAfterDecimal,
          n.currencySymbol,
          CAST(julianday(evt.eventStartDatetime) + 0.5 AS INT) - CAST(julianday('now','localtime') + 0.5 AS INT) as daysUntilEvent,
          julianday(evt.eventStartDatetime) + 0.5 as eventJulian,
          julianday('now','localtime') + 0.5 as nowJulian,
          CASE WHEN h.preferences & 0x00000003 = 0 THEN COALESCE(k.distancePreference,n.distancePreference,0) ELSE (h.preferences & 0x00000003) - 2 END as distancePreference
          FROM narrowEvents evt
          INNER JOIN kennels k on k.kennelId = evt.kennelId
          INNER JOIN countries n on n.countryId = k.countryId
          INNER JOIN hashers h on h.hasherId = "$userId"
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.kennelId = evt.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN hasherEventMap hem on hem.eventId = evt.eventId and hem.userId = "$userId"
          WHERE evt.eventStartDatetime > datetime('now','localtime','-4 hours') and evt.isVisible = 1
          AND (
                (coalesce(hkm.following,0) <= 1) 
                OR 
                (coalesce(hem.rsvpState,0) >= 2)
              )
          ORDER BY evt.eventStartDatetime
          ''';

          futureRunsList = <RunDetailsAggregate>[];
          try {
            db.rawQuery(query).then((List<Map<String, dynamic>> results) {
              for (int i = 0; i < results.length; i++) {
                locator.distanceBetween(Utilities.unInt(ll.latitude), Utilities.unInt(ll.longitude), Utilities.unInt(results[i]['narrowEventLatitude']), Utilities.unInt(results[i]['narrowEventLongitude'])).then((num dist) {
                  final NarrowEventsModel eventItem = NarrowEventsTableHelper.fromMap(results[i]);
                  final KennelsModel kennelItem = KennelsTableHelper.fromMap(results[i]);
                  final RunDetailsQueryExtensions extensionsItem = RunDetailsQueryExtensions.fromMap(results[i]);
                  extensionsItem.distToEvent = dist;
                  // extensionsItem.currencySymbol = '€^';
                  // extensionsItem.digitsAfterDecimal = 2;

                  final num julianNow = results[i]['nowJulian'];
                  final num eventJulian = results[i]['eventJulian'];

                  print('Julian now = $julianNow, Event julian = $eventJulian, EventName = ${eventItem.eventName}');

                  if ((extensionsItem.following >= 1) || ((extensionsItem.following == 0) && (dist < 50000))) {
                    final RunDetailsAggregate item = RunDetailsAggregate(event: eventItem, kennel: kennelItem, extensions: extensionsItem);
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
                  child: FlatButton(
                    color: Theme.of(context).accentColor,
                    child: Text('Reload runs', style: buttonLabelStyleMedium),
                    onPressed: () async {
                      _handleRefresh(queryBackend: true, clearLocalTables: false);
                    },
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(queryBackend: true, clearLocalTables: true),
              displacement: 40.0,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 50),
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
