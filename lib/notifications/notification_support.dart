import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';

import 'package:harrier_central/database/notifications_table.dart';

class NotificationSupport {
  void configureNotifications(bool doSubscriptions) {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, alert: true, badge: false));

    _firebaseMessaging.configure(onMessage: (dynamic content) {
      print('onMessage content = ${content.toString()}');
      return;
    }, onLaunch: (dynamic content) {
      print('onLaunch content = ${content.toString()}');
      return;
    }, onResume: (dynamic content) {
      print('onResume content = ${content.toString()}');
      return;
    });

    _firebaseMessaging.getToken().then((String token) {
      print('Messaging token = $token');
    });

    if (doSubscriptions) {
      initNotificationTopics(_firebaseMessaging);
    }
  }

  Future<void> initNotificationTopics(
      FirebaseMessaging _firebaseMessaging) async {
    try {
      final String userId = getStringPref(StringPrefsEnum.userId);
      print('UserId = $userId');

      //
      //
      // Process user notifications for cases where someone is following a kennel (or has auto follow on)
      //
      //

      String sql = '''
          SELECT e.eventId,e.eventName,e.eventStartDatetime,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          LEFT OUTER JOIN ${hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.eventId = e.eventId and hem.userId = "$userId"
          WHERE e.eventStartDatetime BETWEEN datetime('now','localtime','-8 hours') AND datetime('now','localtime','+$NOTIFICATION_DAYS_IN_FUTURE days') 
          AND e.isVisible <> 0 
          AND 
            (
              (coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) != 2 AND hkm.following = 1) -- notify any run for a kennel that's being followed
              OR 
              (coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) = 1) -- or, notify for any run that has explicitly had notifications turned on
            )
          ''';

      List<Map<String, dynamic>> results = await internalSqlDb.rawQuery(sql);

      for (int i = 0; i < results.length; i++) {
        final String tag =
            '$NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']}';
        _firebaseMessaging.subscribeToTopic(tag);
        print(
            'subscribed to: $NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']} - ${results[i]['eventName']} - ${results[i]['eventStartDatetime']}');
        NotificationsTableHelper.recordNotificationStatus(
            NOTIFICATION_PREFIX_EVENT_UPDATE, tag, 1);
      }

      // only deactivate subscriptions that have existed and no longer do
      // this is a classic "clean up" function. Normally this would not produce
      // any records because they should already be cleaned up
      sql = '''
          SELECT e.eventId,e.eventName,e.eventStartDatetime,
          coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) as notificationPreference
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          INNER JOIN ${NotificationsTableHelper.tableName} notif on notif.${NotificationsTableHelper.colNotificationTag} = "$NOTIFICATION_PREFIX_EVENT_UPDATE" || e.eventId
          LEFT OUTER JOIN ${hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.eventId = e.eventId and hem.userId = "$userId"
          WHERE (
              e.eventStartDatetime BETWEEN datetime('now','localtime','-1 days') AND datetime('now','localtime','+$NOTIFICATION_DAYS_IN_FUTURE days') 
              AND coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) = 2 -- cancel any notification that's been marked for cancellation
            ) OR (
              e.eventStartDatetime BETWEEN datetime('now','localtime','-10 years') AND datetime('now','localtime','-1 days') 
              AND coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) != 0 -- cancel any notification that's existed
            )
          ''';

      results = await internalSqlDb.rawQuery(sql);

      for (int i = 0; i < results.length; i++) {
        final String tag =
            '$NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']}';
        _firebaseMessaging.unsubscribeFromTopic(tag);
        print(
            'unsubscribed from: $NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']} - ${results[i]['eventName']} - ${results[i]['eventStartDatetime']}');
        NotificationsTableHelper.recordNotificationStatus(
            NOTIFICATION_PREFIX_EVENT_UPDATE, tag, 0);
      }

      // clean up the notification table
      // in doing so, try to unsubscribe one more time
      // we don't want to let any subscriptions sneak through because they will not otherwise be deleted
      // each user can have a maximum of 80 active subscriptions at one time.
      sql = '''
          SELECT notif.${NotificationsTableHelper.colNotificationTag} as topicTag FROM ${NotificationsTableHelper.tableName} notif WHERE notif.${NotificationsTableHelper.colNotificationTag} IN 
          (SELECT "$NOTIFICATION_PREFIX_EVENT_UPDATE" || e.eventId 
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          WHERE e.eventStartDatetime BETWEEN datetime('now','localtime','-10 years') AND datetime('now','localtime','-7 days'))
          ''';

      results = await internalSqlDb.rawQuery(sql);
      for (int i = 0; i < results.length; i++) {
        final String tag = results[i]['topicTag'];
        _firebaseMessaging.subscribeToTopic(results[i]['eventId']);
        print('timeout unsubscribed from: ${results[i]['topicTag']}');
        NotificationsTableHelper.recordNotificationStatus(
            NOTIFICATION_PREFIX_EVENT_UPDATE, tag, 1);
      }

      // clean up the notification table and hope we have unsubscribed from
      // all the notifications!
      // TODO(James): Eventually add a cleanup function to the server
      sql = '''
          DELETE FROM ${NotificationsTableHelper.tableName} WHERE ${NotificationsTableHelper.colNotificationTag} IN 
          (SELECT "$NOTIFICATION_PREFIX_EVENT_UPDATE" || e.eventId 
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          WHERE e.eventStartDatetime BETWEEN datetime('now','localtime','-10 years') AND datetime('now','localtime','-7 days'))
          ''';

      results = await internalSqlDb.rawQuery(sql);
    } catch (e) {
      print(e);
    }
  }

  Future<void> setNotificationState({String eventId, String kennelId}) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

    try {
      final String userId = getStringPref(StringPrefsEnum.userId);
      print('UserId = $userId');

      //
      //
      // Process user notifications for cases where someone is following a kennel (or has auto follow on)
      //
      //

      final String sql = '''
          SELECT e.eventId,e.eventName,e.eventStartDatetime,
          CASE WHEN e.eventStartDatetime < datetime('now','localtime','-1 days') THEN 2 ELSE coalesce(hem.eventNotificationPreference,hkm.kennelNotificationPreference,0) END as notificationPreference
          FROM ${eventsTableHelper.getTableName(AppDomainType.user)} e
          LEFT OUTER JOIN ${hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on e.kennelId = hkm.kennelId and hkm.userId = "$userId"
          LEFT OUTER JOIN ${hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem on hem.eventId = e.eventId and hem.userId = "$userId"
          WHERE e.eventId = "$eventId" OR e.kennelId = "$kennelId"
          AND e.eventStartDatetime BETWEEN datetime('now','localtime','-7 days') AND datetime('now','localtime','+$NOTIFICATION_DAYS_IN_FUTURE days') 
          ''';

      final List<Map<String, dynamic>> results =
          await internalSqlDb.rawQuery(sql);

      for (int i = 0; i < results.length; i++) {
        final String tag =
            '$NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']}';
        if (results[i]['notificationPreference'] == 1) {
          _firebaseMessaging.subscribeToTopic(tag);
          print(
              'subscribed to: $NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']} - ${results[i]['eventName']} - ${results[i]['eventStartDatetime']}');
        } else if (results[i]['notificationPreference'] == 2) {
          _firebaseMessaging.unsubscribeFromTopic(tag);
          print(
              'unsubscribed from: $NOTIFICATION_PREFIX_EVENT_UPDATE${results[i]['eventId']} - ${results[i]['eventName']} - ${results[i]['eventStartDatetime']}');
        }

        NotificationsTableHelper.recordNotificationStatus(
            NOTIFICATION_PREFIX_EVENT_UPDATE, tag, 1);
      }
    } catch (e) {
      print(e);
    }
  }
}
