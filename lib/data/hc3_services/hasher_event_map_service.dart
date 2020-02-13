import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';

class HasherEventMapModel {
  HasherEventMapModel(
      {this.hemId,
      this.userId,
      this.eventId,
      this.hasherOwnEventId,
      this.userStartEvent,
      this.userEndEvent,
      this.rsvpState,
      this.attendenceState,
      this.isHare,
      this.eventNotificationPreference,
      this.eventEmailAlertPreference,
      this.eventCountOverride,
      this.virginVisitorType,
      this.displayName,
      this.email,
      this.phoneNumber,
      this.removed,
      this.updatedAt});

  final String hemId;
  final String userId;
  final String eventId;
  final String hasherOwnEventId;
  final String userStartEvent;
  final String userEndEvent;
  int rsvpState;
  final int attendenceState;
  int isHare;
  int eventNotificationPreference;
  int eventEmailAlertPreference;
  final num eventCountOverride;
  final num virginVisitorType;
  final String displayName;
  final String email;
  final String phoneNumber;

  final int removed;
  final DateTime updatedAt;

  static List<HasherEventMapModel> itemsFromJson(String jsonResult) {
    final List<HasherEventMapModel> items = <HasherEventMapModel>[];

    HasherEventMapModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = HasherEventMapModel(
            hemId: jsonItem['hemId'],
            userId: jsonItem['userId'],
            eventId: jsonItem['eventId'],
            hasherOwnEventId: jsonItem['hasherOwnEventId'],
            userStartEvent: jsonItem['userStartEvent'],
            userEndEvent: jsonItem['userEndEvent'],
            rsvpState: jsonItem['rsvpState'],
            attendenceState: jsonItem['attendenceState'],
            isHare: jsonItem['isHare'],
            eventNotificationPreference: jsonItem['eventNotificationPreference'],
            eventEmailAlertPreference: jsonItem['eventEmailAlertPreference'],
            eventCountOverride: jsonItem['eventCountOverride'],
            virginVisitorType: jsonItem['virginVisitorType'],
            displayName: jsonItem['displayName'],
            email: jsonItem['email'],
            phoneNumber: jsonItem['phoneNumber'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

enum HasherEventMapTableType { user, eventAdmin }

const String thisTable = 'hasherEventMap';
const String hemTableName = 'hasherEventMap';
const String hemAdminTableName = 'hasherEventMapForRunAdmin';

class HasherEventMapTableHelper {
  HasherEventMapTableHelper._privateConstructor();

  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  // static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateHasherEventMapData;
  // static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearHasherEventMapData;

  static const String colId = 'id';
  static const String remoteDbId = 'hemId';

  static const String colHemId = 'hemId';
  static const String colUserId = 'userId';
  static const String colEventId = 'eventId';
  static const String colHasherOwnEventId = 'hasherOwnEventId';
  static const String colUserStartEvent = 'userStartEvent';
  static const String colUserEndEvent = 'userEndEvent';
  static const String colRsvpState = 'rsvpState';
  static const String colAttendenceState = 'attendenceState';
  static const String colIsHare = 'isHare';
  static const String colEventNotificationPreference = 'eventNotificationPreference';
  static const String colEventEmailAlertPreference = 'eventEmailAlertPreference';
  static const String colEventCountOverride = 'eventCountOverride';
  static const String colVirginVisitorType = 'virginVisitorType';
  static const String colDisplayName = 'displayName';
  static const String colEmail = 'email';
  static const String colPhoneNumber = 'phoneNumber';

  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final HasherEventMapTableHelper instance = HasherEventMapTableHelper._privateConstructor();

  static String getTableName(HasherEventMapTableType tblType) {
    if (tblType == HasherEventMapTableType.eventAdmin) {
      return hemAdminTableName;
    }
    return hemTableName;
  }

  static IntPrefsEnum getLastUpdatedKey(HasherEventMapTableType tblType) {
    if (tblType == HasherEventMapTableType.eventAdmin) {
      return IntPrefsEnum.lastUpdateAdminHasherEventMapData;
    }
    return IntPrefsEnum.lastUpdateHasherEventMapData;
  }

  static IntPrefsEnum getLastCacheClearKey(HasherEventMapTableType tblType) {
    if (tblType == HasherEventMapTableType.eventAdmin) {
      return IntPrefsEnum.lastCacheClearAdminHasherEventMapData;
    }
    return IntPrefsEnum.lastCacheClearHasherEventMapData;
  }

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version, HasherEventMapTableType tblType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(tblType)} (
            $colId INTEGER PRIMARY KEY,

            $colHemId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colEventId TEXT,
            $colHasherOwnEventId TEXT,
            $colUserStartEvent TEXT,
            $colUserEndEvent TEXT,
            $colRsvpState INT,
            $colAttendenceState INT,
            $colIsHare INT,
            $colEventNotificationPreference INT,
            $colEventEmailAlertPreference INT,
            $colEventCountOverride NUM,
            $colVirginVisitorType NUM,
            $colDisplayName TEXT,
            $colEmail TEXT,
            $colPhoneNumber TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL

          )
          ''');

    await db.execute('CREATE INDEX idx_${getTableName(tblType)}_id ON ${getTableName(tblType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(tblType)}_update_at_value ON ${getTableName(tblType)}($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(HasherEventMapModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      HasherEventMapTableHelper.colHemId: item.hemId,
      HasherEventMapTableHelper.colUserId: item.userId,
      HasherEventMapTableHelper.colEventId: item.eventId,
      HasherEventMapTableHelper.colHasherOwnEventId: item.hasherOwnEventId,
      HasherEventMapTableHelper.colUserStartEvent: item.userStartEvent,
      HasherEventMapTableHelper.colUserEndEvent: item.userEndEvent,
      HasherEventMapTableHelper.colRsvpState: item.rsvpState,
      HasherEventMapTableHelper.colAttendenceState: item.attendenceState,
      HasherEventMapTableHelper.colIsHare: item.isHare,
      HasherEventMapTableHelper.colEventNotificationPreference: item.eventNotificationPreference,
      HasherEventMapTableHelper.colEventEmailAlertPreference: item.eventEmailAlertPreference,
      HasherEventMapTableHelper.colEventCountOverride: item.eventCountOverride,
      HasherEventMapTableHelper.colVirginVisitorType: item.virginVisitorType,
      HasherEventMapTableHelper.colDisplayName: item.displayName,
      HasherEventMapTableHelper.colEmail: item.email,
      HasherEventMapTableHelper.colPhoneNumber: item.phoneNumber,
      HasherEventMapTableHelper.colUpdatedAt: item.updatedAt.toString(),
      HasherEventMapTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      HasherEventMapTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      HasherEventMapTableHelper.colHemId: inputMap[HasherEventMapTableHelper.colHemId],
      HasherEventMapTableHelper.colUserId: inputMap[HasherEventMapTableHelper.colUserId],
      HasherEventMapTableHelper.colEventId: inputMap[HasherEventMapTableHelper.colEventId],
      HasherEventMapTableHelper.colHasherOwnEventId: inputMap[HasherEventMapTableHelper.colHasherOwnEventId],
      HasherEventMapTableHelper.colUserStartEvent: inputMap[HasherEventMapTableHelper.colUserStartEvent],
      HasherEventMapTableHelper.colUserEndEvent: inputMap[HasherEventMapTableHelper.colUserEndEvent],
      HasherEventMapTableHelper.colRsvpState: inputMap[HasherEventMapTableHelper.colRsvpState],
      HasherEventMapTableHelper.colAttendenceState: inputMap[HasherEventMapTableHelper.colAttendenceState],
      HasherEventMapTableHelper.colIsHare: inputMap[HasherEventMapTableHelper.colIsHare],
      HasherEventMapTableHelper.colEventNotificationPreference: inputMap[HasherEventMapTableHelper.colEventNotificationPreference],
      HasherEventMapTableHelper.colEventEmailAlertPreference: inputMap[HasherEventMapTableHelper.colEventEmailAlertPreference],
      HasherEventMapTableHelper.colEventCountOverride: inputMap[HasherEventMapTableHelper.colEventCountOverride],
      HasherEventMapTableHelper.colVirginVisitorType: inputMap[HasherEventMapTableHelper.colVirginVisitorType],
      HasherEventMapTableHelper.colDisplayName: inputMap[HasherEventMapTableHelper.colDisplayName],
      HasherEventMapTableHelper.colEmail: inputMap[HasherEventMapTableHelper.colEmail],
      HasherEventMapTableHelper.colPhoneNumber: inputMap[HasherEventMapTableHelper.colPhoneNumber],
      HasherEventMapTableHelper.colUpdatedAt: inputMap[HasherEventMapTableHelper.colUpdatedAt],
      HasherEventMapTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[HasherEventMapTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      HasherEventMapTableHelper.colRemoved: inputMap[HasherEventMapTableHelper.colRemoved],
    };

    return outputMap;
  }

  static HasherEventMapModel fromMap(Map<String, dynamic> map) {
    final HasherEventMapModel item = HasherEventMapModel(
      hemId: map[HasherEventMapTableHelper.colHemId],
      userId: map[HasherEventMapTableHelper.colUserId],
      eventId: map[HasherEventMapTableHelper.colEventId],
      hasherOwnEventId: map[HasherEventMapTableHelper.colHasherOwnEventId],
      userStartEvent: map[HasherEventMapTableHelper.colUserStartEvent],
      userEndEvent: map[HasherEventMapTableHelper.colUserEndEvent],
      rsvpState: map[HasherEventMapTableHelper.colRsvpState],
      attendenceState: map[HasherEventMapTableHelper.colAttendenceState],
      isHare: map[HasherEventMapTableHelper.colIsHare],
      eventNotificationPreference: map[HasherEventMapTableHelper.colEventNotificationPreference],
      eventEmailAlertPreference: map[HasherEventMapTableHelper.colEventEmailAlertPreference],
      eventCountOverride: map[HasherEventMapTableHelper.colEventCountOverride],
      virginVisitorType: map[HasherEventMapTableHelper.colVirginVisitorType],
      displayName: map[HasherEventMapTableHelper.colDisplayName],
      email: map[HasherEventMapTableHelper.colEmail],
      phoneNumber: map[HasherEventMapTableHelper.colPhoneNumber],
      updatedAt: DateTime.parse(map[HasherEventMapTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[HasherEventMapTableHelper.colRemoved],
    );

    return item;
  }
}

class HasherEventMapService {
  //static final HasherEventMapTableHelper instance = HasherEventMapTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime(HasherEventMapTableType tblType) async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${HasherEventMapTableHelper.colUpdatedAtValue}) AS maxDate FROM ${HasherEventMapTableHelper.getTableName(tblType)}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable(HasherEventMapTableType tblType) async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${HasherEventMapTableHelper.getTableName(tblType)}').then((void dummy) {
      setIntPref(HasherEventMapTableHelper.getLastCacheClearKey(tblType), DateTime.now().millisecondsSinceEpoch);
    });
  }

  // TODO(James): If we ever need to use this, check out the logic to prevent user table records from accidentally being inserted with other users (see error below)
  // Future<void> updateDatabase(List<HasherEventMapModel> items, HasherEventMapTableType tblType) async {
  //   final Database db = await DBProvider.db.database;

  //   final String userId = getStringPref(StringPrefsEnum.userId);

  //   for (int i = 0; i < items?.length ?? 0; i++) {
  //     final Map<String, dynamic> row = HasherEventMapTableHelper.toMap(items[i]);

  //     final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${HasherEventMapTableHelper.getTableName(tblType)} WHERE ${HasherEventMapTableHelper.remoteDbId} = "${items[i].hemId}"');
  //     if ((table == null) || (table.isEmpty)) {
  //       xxxxxx => if ((tblType != HasherEventMapTableType.user) || ((tblType == HasherEventMapTableType.user) && (userId == row['userId']))) {
  //         await db.transaction<dynamic>((Transaction txn) async {
  //           final int result = await txn.insert(HasherEventMapTableHelper.getTableName(tblType), row);
  //           print(result.toString() + ' inserted into to the ${HasherEventMapTableHelper.getTableName(tblType)} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
  //         });
  //       }
  //     } else {
  //       final String rowId = table.first['id'].toString();

  //       await db.transaction<dynamic>((Transaction txn) async {
  //         final int result = await txn.update(HasherEventMapTableHelper.getTableName(tblType), row, where: 'id = $rowId');
  //         print(result.toString() + ' update to the ${HasherEventMapTableHelper.getTableName(tblType)} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
  //       });
  //     }
  //   }
  // }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser, HasherEventMapTableType tblType) async {
    int updateCounter = 0;
    int insertCounter = 0;
    int deletedCounter = 0;

    final String userId = getStringPref(StringPrefsEnum.userId);

    bool doNormalizeMap;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Hasher event map recordsets received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = HasherEventMapTableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for ${HasherEventMapTableHelper.getTableName(tblType)}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}');
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading hasher data \r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch});

        final String query = 'SELECT id FROM ${HasherEventMapTableHelper.getTableName(tblType)} WHERE ${HasherEventMapTableHelper.remoteDbId} = "${jsonItem['hemId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          if ((tblType != HasherEventMapTableType.user) || ((tblType == HasherEventMapTableType.user) && (userId == jsonItem['userId']))) {
            await db.transaction<dynamic>((Transaction txn) async {
              

              await txn.insert(HasherEventMapTableHelper.getTableName(tblType), doNormalizeMap ? HasherEventMapTableHelper.normalizeMap(jsonItem) : jsonItem);
              insertCounter++;
              // print(result.toString() +
              //     ' inserted into to the ${HasherEventMapTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
            });
          }
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            
            await txn.update(HasherEventMapTableHelper.getTableName(tblType), doNormalizeMap ? HasherEventMapTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');

            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${HasherEventMapTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }


    await db.transaction<dynamic>((Transaction txn) async {
      
      deletedCounter = await txn.delete(HasherEventMapTableHelper.getTableName(tblType), where: 'removed = 1');
    });

    print('$insertCounter hasher event map records inserted, $updateCounter hasher event map records updated, $deletedCounter hasher event map records deleted @ ${DateTime.now().millisecondsSinceEpoch}');
    return insertCounter;
  }

  //==============  Domain specific functions ===========

  static Future<Map<String, String>> sendRunCountReportByEmail({String kennelId, String kennelName}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken1 = Utilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String accessToken2 = Utilities.generateToken(userId, 'getMyKennelRunTotals');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken1': accessToken1, 'accessToken2': accessToken2, 'kennelId': kennelId, 'kennelName': kennelName, 'userName': userName, 'emailAddress': emailAddress});

      final http.Response response = await http.post(EMAIL_RUN_REPORT_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
        (dynamic error) {
          return <String, String>{'result': 'error', 'email': ''};
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{'result': 'No valid email address found', 'email': ''};
  }

  Future<List<dynamic>> joinEvent(String eventId, HasherEventMapTableType tblType, String hasherId, String hasherEventMapId, {int rsvpState = -1, int attendenceState = -1, int isHare = -1, int virginVisitorType = 0, int notificationState = -1, int emailAlertState = -1}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final num _hasherEventMapLastUpdated = await HasherEventMapService.getLastUpdatedTime(HasherEventMapTableType.eventAdmin);
    final num _hasherKennelMapLastUpdated = await HasherKennelMapService.getLastUpdatedTime(HasherKennelMapTableType.eventAdmin);
    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(paymentsTableHelper,paymentsTableHelper.colUpdatedAtValue);

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'hasherEventMapId': hasherEventMapId,
      'isHare': isHare,
      'rsvpState': rsvpState,
      'attendenceState': attendenceState,
      'virginVisitorType': virginVisitorType,
      'notificationState': notificationState,
      'emailAlertState': emailAlertState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString()
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_event', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    List<dynamic> adHocData;

    if (tblType == HasherEventMapTableType.eventAdmin) {
      adHocData = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else {
      adHocData = await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    }

    return adHocData;
  }

  Future<List<dynamic>> joinEventAsVisitor(String eventId, HasherEventMapTableType tblType, String displayName, int virginVisitorType, int attendenceState, String email, String phoneNumber) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinEventAsVisitor');

    final num _hasherEventMapLastUpdated = await HasherEventMapService.getLastUpdatedTime(HasherEventMapTableType.eventAdmin);
    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(paymentsTableHelper,paymentsTableHelper.colUpdatedAtValue);

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'displayName': displayName ?? '<no name>',
      'virginVisitorType': virginVisitorType == null ? null : virginVisitorType.toString(),
      'attendenceState': attendenceState == null ? null : attendenceState.toString(),
      'email': email,
      'phoneNumber': phoneNumber,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_event_as_visitor', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<dynamic> adHocData = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);

    return adHocData;
  }
}
