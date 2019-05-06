import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';

class HasherKennelMapModel {
  HasherKennelMapModel({this.hkmId, this.userId, this.kennelId, this.following, this.isMember, this.mismanagementRoleFlags, this.userRoleFlags, this.appAccessFlags, this.historicalPackRunCount, this.historicalHaringCount, this.removed, this.updatedAt});

  final String hkmId;
  final String userId;
  final String kennelId;
  final int following;
  final int isMember;
  final int mismanagementRoleFlags;
  final int userRoleFlags;
  final int appAccessFlags;
  final num historicalPackRunCount;
  final num historicalHaringCount;
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
          mismanagementRoleFlags: jsonItem['mismanagementRoleFlags'] ?? 0,
          userRoleFlags: jsonItem['userRoleFlags'],
          appAccessFlags: jsonItem['appAccessFlags'],
          historicalPackRunCount: jsonItem['historicalPackRunCount'],
          historicalHaringCount: jsonItem['historicalHaringCount'],
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
  admin,
}

const String hkmTableName = 'hasherKennelMap';
const String hkmAdminTableName = 'hasherKennelMapForRunAdmin';

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
  static const String colMismanagementRoleFlags = 'mismanagementRoleFlags';
  static const String colUserRoleFlags = 'userRoleFlags';
  static const String colAppAccessFlags = 'appAccessFlags';
  static const String colHistoricalPackRunCount = 'historicalPackRunCount';
  static const String colHistoricalHaringCount = 'historicalHaringCount';
  static const String colUpdatedAt = 'updatedAt';
  static const String colRemoved = 'removed';

  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final HasherKennelMapTableHelper instance = HasherKennelMapTableHelper._privateConstructor();

  static String getTableName(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.admin) {
      return hkmAdminTableName;
    }
    return hkmTableName;
  }

  static IntPrefsEnum getLastUpdatedKey(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.admin) {
      return IntPrefsEnum.lastUpdateAdminHasherKennelMaplData;
    }
    return IntPrefsEnum.lastUpdateHasherKennelMaplData;
  }

  static IntPrefsEnum getLastCacheClearKey(HasherKennelMapTableType tblType) {
    if (tblType == HasherKennelMapTableType.admin) {
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
            $colMismanagementRoleFlags INT,
            $colUserRoleFlags INT,
            $colAppAccessFlags INT,
            $colHistoricalPackRunCount NUM,
            $colHistoricalHaringCount NUM,
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
      HasherKennelMapTableHelper.colMismanagementRoleFlags: item.mismanagementRoleFlags,
      HasherKennelMapTableHelper.colUserRoleFlags: item.userRoleFlags,
      HasherKennelMapTableHelper.colAppAccessFlags: item.appAccessFlags,
      HasherKennelMapTableHelper.colHistoricalPackRunCount: item.historicalPackRunCount,
      HasherKennelMapTableHelper.colHistoricalHaringCount: item.historicalHaringCount,
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
      mismanagementRoleFlags: map[HasherKennelMapTableHelper.colMismanagementRoleFlags],
      userRoleFlags: map[HasherKennelMapTableHelper.colUserRoleFlags],
      appAccessFlags: map[HasherKennelMapTableHelper.colAppAccessFlags],
      historicalPackRunCount: map[HasherKennelMapTableHelper.colHistoricalPackRunCount],
      historicalHaringCount: map[HasherKennelMapTableHelper.colHistoricalHaringCount],
      updatedAt: DateTime.parse(map[HasherKennelMapTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[HasherKennelMapTableHelper.colRemoved],
    );

    return item;
  }
}

class HasherKennelMapService {
  static final HasherKennelMapTableHelper instance = HasherKennelMapTableHelper._privateConstructor();

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
            await txn.update(HasherKennelMapTableHelper.getTableName(tblType), jsonItem, where: 'id = $rowId');
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

    Future<void> toggleFollowing(Map<String, dynamic> kennel,HasherKennelMapTableType tblType) async {

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final String body = jsonEncode(<String, Object>{'userId': userId, 'accessToken': accessToken, 'kennelId': kennel['kennelId'], 'targetUserId': userId, 'isFollowing': kennel['followingRequested']});

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_kennel', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    final Database db = await DBProvider.db.database;
    bulkUpdateDatabase(response.body, db, null, tblType);

    final dynamic result = json.decode(response.body);
    kennel['following'] = result[0][0]['following'];
    kennel['followingRequested'] = -1;

    //print(response.body);
  }
  
}
