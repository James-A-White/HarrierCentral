import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/util/enums.dart';

class HasherKennelMapModel {
  HasherKennelMapModel(
      {this.hkmId, this.userId, this.kennelId, this.following, this.isMember, this.isHomeKennel, this.mismanagementRoleFlags, this.userRoleFlags, this.appAccessFlags, this.historicalPackRunCount, this.historicalHaringCount, this.dateOfLastRun, this.membershipExpirationDate, this.memberSince, this.removed, this.updatedAt});

  final String hkmId;
  final String userId;
  final String kennelId;
  final int following;
  final int isMember;
  final int isHomeKennel;
  final int mismanagementRoleFlags;
  final int userRoleFlags;
  final int appAccessFlags;
  final num historicalPackRunCount;
  final num historicalHaringCount;
  final DateTime dateOfLastRun;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final DateTime updatedAt;
  final int removed;

  static List<HasherKennelMapModel> itemsFromJson(String jsonResult) {
    final List<HasherKennelMapModel> items = <HasherKennelMapModel>[];

    HasherKennelMapModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = HasherKennelMapModel(
          hkmId: jsonItem['hkmId'],
          userId: jsonItem['userId'],
          kennelId: jsonItem['kennelId'],
          following: jsonItem['following'],
          isMember: jsonItem['isMember'],
          isHomeKennel: jsonItem['isHomeKennel'],
          mismanagementRoleFlags: jsonItem['mismanagementRoleFlags'] ?? 0,
          userRoleFlags: jsonItem['userRoleFlags'],
          appAccessFlags: jsonItem['appAccessFlags'],
          historicalPackRunCount: jsonItem['historicalPackRunCount'],
          historicalHaringCount: jsonItem['historicalHaringCount'],
          dateOfLastRun: jsonItem['dateOfLastRun'] == null ? null : DateTime.parse(jsonItem['dateOfLastRun'].toString().substring(0, 19)),
          membershipExpirationDate: jsonItem['membershipExpirationDate'] == null ? null : DateTime.parse(jsonItem['membershipExpirationDate'].toString().substring(0, 19)),
          memberSince: jsonItem['memberSince'] == null ? null : DateTime.parse(jsonItem['memberSince'].toString().substring(0, 19)),
          updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
          removed: jsonItem['removed'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

enum HasherKennelMapTableType {
  user,
  eventAdmin,
  kennelAdmin
}

const String hkmTableName = 'hasherKennelMap';
const String hkmEventAdminTableName = 'hasherKennelMapForRunAdmin';
const String hkmKennelAdminTableName = 'hasherKennelMapForKennelAdmin';

class HasherKennelMapTableHelper {
  HasherKennelMapTableHelper._privateConstructor();

  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const String colId = 'id';
  static const String remoteDbId = 'hkmId';
  static const String colHkmId = 'hkmId';
  static const String colUserId = 'userId';
  static const String colKennelId = 'kennelId';
  static const String colFollowing = 'following';
  static const String colIsMember = 'isMember';
  static const String colIsHomeKennel = 'isHomeKennel';
  static const String colMismanagementRoleFlags = 'mismanagementRoleFlags';
  static const String colUserRoleFlags = 'userRoleFlags';
  static const String colAppAccessFlags = 'appAccessFlags';
  static const String colHistoricalPackRunCount = 'historicalPackRunCount';
  static const String colHistoricalHaringCount = 'historicalHaringCount';
  static const String colDateOfLastRun = 'dateOfLastRun';
  static const String colMembershipExpirationDate = 'membershipExpirationDate';
  static const String colMemberSince = 'memberSince';
  static const String colUpdatedAt = 'updatedAt';
  static const String colRemoved = 'removed';

  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final HasherKennelMapTableHelper instance = HasherKennelMapTableHelper._privateConstructor();

  static String getTableName(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.eventAdmin) {
      return hkmEventAdminTableName;
    } else if (tblType ==HasherKennelMapTableType.kennelAdmin) {
      return hkmKennelAdminTableName;
    }
    return hkmTableName;
  }

  static IntPrefsEnum getLastUpdatedKey(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.eventAdmin) {
      return IntPrefsEnum.lastUpdateAdminHasherKennelMaplData;
    }
    return IntPrefsEnum.lastUpdateHasherKennelMaplData;
  }

  static IntPrefsEnum getLastCacheClearKey(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.eventAdmin) {
      return IntPrefsEnum.lastCacheClearAdminHasherKennelMapData;
    }
    return IntPrefsEnum.lastCacheClearHasherKennelMapData;
  }

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version, HasherKennelMapTableType tblType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(tblType)} (
            $colId INTEGER PRIMARY KEY,

            $colHkmId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colFollowing INT,
            $colIsMember INT,
            $colIsHomeKennel INT,
            $colMismanagementRoleFlags INT,
            $colUserRoleFlags INT,
            $colAppAccessFlags INT,
            $colHistoricalPackRunCount NUM,
            $colHistoricalHaringCount NUM,
            $colDateOfLastRun TEXT,
            $colMembershipExpirationDate TEXT,
            $colMemberSince TEXT,
            $colRemoved INT,
            $colUpdatedAt TEXT,

            $colUpdatedAtValue NUM NULL
          )
          ''');

    String sql = 'CREATE INDEX idx_${getTableName(tblType)}_id ON ${getTableName(tblType)}($remoteDbId);';
    await db.execute(sql);
    sql = 'CREATE INDEX idx_${getTableName(tblType)}_update_at_value ON ${getTableName(tblType)}($colUpdatedAtValue);';
    await db.execute(sql);
  }

  static Map<String, dynamic> toMap(HasherKennelMapModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      HasherKennelMapTableHelper.colUserId: item.userId,
      HasherKennelMapTableHelper.colKennelId: item.kennelId,
      HasherKennelMapTableHelper.colFollowing: item.following,
      HasherKennelMapTableHelper.colIsMember: item.isMember,
      HasherKennelMapTableHelper.colIsHomeKennel: item.isHomeKennel,
      HasherKennelMapTableHelper.colMismanagementRoleFlags: item.mismanagementRoleFlags,
      HasherKennelMapTableHelper.colUserRoleFlags: item.userRoleFlags,
      HasherKennelMapTableHelper.colAppAccessFlags: item.appAccessFlags,
      HasherKennelMapTableHelper.colHistoricalPackRunCount: item.historicalPackRunCount,
      HasherKennelMapTableHelper.colHistoricalHaringCount: item.historicalHaringCount,
      HasherKennelMapTableHelper.colDateOfLastRun: item.dateOfLastRun,
      HasherKennelMapTableHelper.colMembershipExpirationDate: item.membershipExpirationDate,
      HasherKennelMapTableHelper.colMemberSince: item.memberSince,
      HasherKennelMapTableHelper.colUpdatedAt: item.updatedAt,
      HasherKennelMapTableHelper.colRemoved: item.removed,
    };

    return map;
  }

  static HasherKennelMapModel fromMap(Map<String, dynamic> map) {
    final HasherKennelMapModel item = HasherKennelMapModel(
      hkmId: map[HasherKennelMapTableHelper.colHkmId],
      userId: map[HasherKennelMapTableHelper.colUserId],
      kennelId: map[HasherKennelMapTableHelper.colKennelId],
      following: map[HasherKennelMapTableHelper.colFollowing],
      isMember: map[HasherKennelMapTableHelper.colIsMember],
      isHomeKennel: map[HasherKennelMapTableHelper.colIsHomeKennel],
      mismanagementRoleFlags: map[HasherKennelMapTableHelper.colMismanagementRoleFlags],
      userRoleFlags: map[HasherKennelMapTableHelper.colUserRoleFlags],
      appAccessFlags: map[HasherKennelMapTableHelper.colAppAccessFlags],
      historicalPackRunCount: map[HasherKennelMapTableHelper.colHistoricalPackRunCount],
      historicalHaringCount: map[HasherKennelMapTableHelper.colHistoricalHaringCount],
      dateOfLastRun: (map[HasherKennelMapTableHelper.colDateOfLastRun] == null) ? null : DateTime.parse(map[HasherKennelMapTableHelper.colDateOfLastRun].toString().substring(0, 19)),
      membershipExpirationDate: (map[HasherKennelMapTableHelper.colMembershipExpirationDate] == null) ? null : DateTime.parse(map[HasherKennelMapTableHelper.colMembershipExpirationDate].toString().substring(0, 19)),
      memberSince: (map[HasherKennelMapTableHelper.colMemberSince] == null) ? null : DateTime.parse(map[HasherKennelMapTableHelper.colMemberSince].toString().substring(0, 19)),
      updatedAt: DateTime.parse(map[HasherKennelMapTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[HasherKennelMapTableHelper.colRemoved],
    );

    return item;
  }
}

class HasherKennelMapService {
  static final HasherKennelMapTableHelper instance = HasherKennelMapTableHelper._privateConstructor();

  static Future<num> getLastUpdatedTime(HasherKennelMapTableType tblType) async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${HasherKennelMapTableHelper.colUpdatedAtValue}) AS maxDate FROM ${HasherKennelMapTableHelper.getTableName(tblType)}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable(HasherKennelMapTableType tblType) async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${HasherKennelMapTableHelper.getTableName(tblType)}').then((void dummy) {
      setIntPref(HasherKennelMapTableHelper.getLastCacheClearKey(tblType), DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<HasherKennelMapModel> items, HasherKennelMapTableType tblType) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = HasherKennelMapTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${HasherKennelMapTableHelper.getTableName(tblType)} WHERE ${HasherKennelMapTableHelper.remoteDbId} = "${items[i].hkmId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(HasherKennelMapTableHelper.getTableName(tblType), row);
          print(result.toString() + ' inserted into to the ${HasherKennelMapTableHelper.getTableName(tblType)} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(HasherKennelMapTableHelper.getTableName(tblType), row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${HasherKennelMapTableHelper.getTableName(tblType)} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser, HasherKennelMapTableType tblType) async {
    int updateCounter = 0;
    int insertCounter = 0;

    final List<dynamic> jsonResultSets = json.decode(rawResults);

    final int len = jsonResultSets.length;
    int lastPercentage = 0;

    print('Kennel records received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        final int percentage = (100 * (j / jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading kennel data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${HasherKennelMapTableHelper.getTableName(tblType)} WHERE ${HasherKennelMapTableHelper.remoteDbId} = "${jsonItem['hkmId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(HasherKennelMapTableHelper.getTableName(tblType), jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${UserKennelsTdTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(HasherKennelMapTableHelper.getTableName(tblType), jsonItem, where: 'id = $rowId').then((int result){
              print(result.toString());
            });
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${UserKennelsTdTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter hasher kennel map records inserted, $updateCounter hasher kennel map records updated');
    return insertCounter;
  }

  //=================  Domain specific functions ================

  Future<void> updateHasherKennelStatus(Map<String, dynamic> kennel, HasherKennelMapTableType tblType, {int monthsToAddToMembership, String targetUserId}) async {

    if (globalConnectionStatus == connectionStatus_notConnected)
    {
      return;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final num _hasherKennelMapLastUpdated = await HasherKennelMapService.getLastUpdatedTime(tblType);
    final num _kennelsLastUpdated = await KennelsService.getLastUpdatedTime();

    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);

    monthsToAddToMembership ??= 0;

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennel['kennelId'],
      'targetUserId': targetUserId ?? userId,
      'isFollowing': kennel['followingRequested'],
      'isHomeKennel' : -1,
      'monthsToAddToMembership' : monthsToAddToMembership,
      //'paymentAmount' : ,
      'hasherKennelMapUpdatedAfter' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
      'kennelsUpdatedAfter' : kennelsUpdatedAfter.toString().substring(0, 19)
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_kennel', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    if (tblType == HasherKennelMapTableType.eventAdmin)
    { 
        await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);  
    } else if (tblType == HasherKennelMapTableType.kennelAdmin) {
        await SyncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body); 
    } else {
        await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body); 
    }

    final dynamic result = json.decode(response.body);

    kennel['following'] = result[1][0]['following'];  // HACK!!! Fix this so that results can be returned in any order and not specifically [1][0]
    kennel['followingRequested'] = -1;
  }
}
