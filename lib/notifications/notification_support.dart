import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/util/preferences.dart';

import 'package:harrier_central/database/database.dart';

Future<void> subscribeToTopics(FirebaseMessaging _firebaseMessaging) async {
  DBProvider.db.database.then((Database db) async {
    try {
      final String userId = getStringPref(StringPrefsEnum.userId);
      print('UserId = $userId');

      String sql = '''

          SELECT e.eventId,e.eventName,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference
          FROM ${NarrowEventsTableHelper.tableName} e
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} hkm on e.kennelId = hkm.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.user)} hem on hem.eventId = e.eventId and hem.userId = "$userId"
          WHERE e.eventStartDatetime BETWEEN datetime('now','localtime','-8 hours') AND datetime('now','localtime','+14 days') 
          AND e.isVisible <> 0 
          AND coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) != 2
          AND hkm.following != 2 
          
          ''';

      List<Map<String, dynamic>> results = await db.rawQuery(sql);

      for (int i = 0; i < results.length; i++) {
        _firebaseMessaging.subscribeToTopic('evtUpdate_${results[i]['eventId']}');
        print('subscribed to: evtUpdate_${results[i]['eventId']} - ${results[i]['eventName']}');
      }

      sql = '''

          SELECT e.eventId,e.eventName,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference
          FROM ${NarrowEventsTableHelper.tableName} e
          LEFT OUTER JOIN ${HasherKennelMapTableHelper.getTableName(HasherKennelMapTableType.user)} hkm on e.kennelId = hkm.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN ${HasherEventMapTableHelper.getTableName(HasherEventMapTableType.user)} hem on hem.eventId = e.eventId and hem.userId = "$userId"
          WHERE e.eventStartDatetime BETWEEN datetime('now','localtime','-8 hours') AND datetime('now','localtime','+14 days') 
          AND coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) == 2
          
          ''';

      results = await db.rawQuery(sql);

      for (int i = 0; i < results.length; i++) {
        _firebaseMessaging.unsubscribeFromTopic('evtUpdate_${results[i]['eventId']}');
        print('unsubscribed from: evtUpdate_${results[i]['eventId']} - ${results[i]['eventName']}');
      }
    } catch (e) {
      print(e);
    }
  });
}

class NotificationSupport {
  void configureNotifications() {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.requestNotificationPermissions();

    _firebaseMessaging.configure(onMessage: (dynamic content) {
      print('onMessage content = ${content.toString()}');
    }, onLaunch: (dynamic content) {
      print('onLaunch content = ${content.toString()}');
    }, onResume: (dynamic content) {
      print('onResume content = ${content.toString()}');
    });

    _firebaseMessaging.getToken().then((String token) {
      print('Messaging token = $token');
    });

    subscribeToTopics(_firebaseMessaging);
    _firebaseMessaging.subscribeToTopic('test');
  }
}
