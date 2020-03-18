import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';





class CommonQueries {
  static Future<String> getClosestEventInTime(String kennelId) async {
    String result = 'none';
    try {
      final Database db = await DBProvider.db.database;

      final String sql = ''' 

          SELECT e.eventId,
          e.eventName,
          (julianday(eventStartDatetime) - julianday('now','localtime')) * 24 as deltaHours
          FROM ${eventsTableHelper.tableName} e
          WHERE e.kennelId = "$kennelId"
          ORDER BY abs(julianday('now') - julianday(eventStartDatetime)) ASC
          
          ''';

      final List<Map<String, dynamic>> results = await db.rawQuery(sql);

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          if ((results[i]['deltaHours'] <= ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) && (results[i]['deltaHours'] >= -ALLOW_CHECKIN_SCAN_HOURS_AFTER_EVENT)) {
            result = results[i]['eventId'];
            break;
          } else if (results[i]['deltaHours'] > ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT) {
            result = (results[i]['deltaHours'] - ALLOW_CHECKIN_SCAN_HOURS_BEFORE_EVENT).toString();
            break;
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  static Future<String> getUserIdFromUqr(String uqr) async {
    uqr = uqr.toUpperCase();
    String result = 'none';
    try {
      final Database db = await DBProvider.db.database;

      final String sql = ''' 

          SELECT h.hasherId
          FROM ${hashersTableHelper.tableName} h
          WHERE upper(h.qrCode) = "$uqr"
          
          ''';

      final List<Map<String, dynamic>> results = await db.rawQuery(sql);

      if (results.isNotEmpty) {
        result = results[0]['hasherId'];
      }
    } catch (e) {
      print(e);
    }
    return result;
  }
}
