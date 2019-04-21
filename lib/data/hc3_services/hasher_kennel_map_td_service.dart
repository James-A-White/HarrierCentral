import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

class HasherKennelMapTdModel {
  HasherKennelMapTdModel({this.hkmId, this.userId, this.kennelId, this.following, this.isMember, this.mismanagementRoleFlags, this.userRoleFlags, this.appAccessFlags, this.historicalPackRunCount, this.historicalHaringCount, this.removed, this.updatedAt});

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

  static List<HasherKennelMapTdModel> itemsFromJson(String jsonResult) {
    final List<HasherKennelMapTdModel> items = <HasherKennelMapTdModel>[];

    HasherKennelMapTdModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = HasherKennelMapTdModel(
          hkmId: jsonItem['hkmId'],
          userId: jsonItem['userId'],
          kennelId: jsonItem['kennelId'],
          following: jsonItem['following'],
          isMember: jsonItem['isMember'],
          mismanagementRoleFlags: jsonItem['mismanagementRoleFlags'],
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

class HasherKennelMapTdTableHelper {
  HasherKennelMapTdTableHelper._privateConstructor();

  static const String tableName = 'hasherKennelMap';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes
  static const String storedProcName = 'getUserKennelsTd';
  static const String restApiMethodName = 'hc3_get_user_kennels_td';

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateUserKennelData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearUserKennelData;

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

  static final HasherKennelMapTdTableHelper instance = HasherKennelMapTdTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
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

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(HasherKennelMapTdModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      HasherKennelMapTdTableHelper.colUserId: item.userId,
      HasherKennelMapTdTableHelper.colKennelId: item.kennelId,
      HasherKennelMapTdTableHelper.colFollowing: item.following,
      HasherKennelMapTdTableHelper.colIsMember: item.isMember,
      HasherKennelMapTdTableHelper.colMismanagementRoleFlags: item.mismanagementRoleFlags,
      HasherKennelMapTdTableHelper.colUserRoleFlags: item.userRoleFlags,
      HasherKennelMapTdTableHelper.colAppAccessFlags: item.appAccessFlags,
      HasherKennelMapTdTableHelper.colHistoricalPackRunCount: item.historicalPackRunCount,
      HasherKennelMapTdTableHelper.colHistoricalHaringCount: item.historicalHaringCount,
      HasherKennelMapTdTableHelper.colUpdatedAt: item.updatedAt,
      HasherKennelMapTdTableHelper.colRemoved: item.removed,
    };

    return map;
  }

  static HasherKennelMapTdModel fromMap(Map<String, dynamic> map) {
    final HasherKennelMapTdModel item = HasherKennelMapTdModel(
      hkmId: map[HasherKennelMapTdTableHelper.colHkmId],
      userId: map[HasherKennelMapTdTableHelper.colUserId],
      kennelId: map[HasherKennelMapTdTableHelper.colKennelId],
      following: map[HasherKennelMapTdTableHelper.colFollowing],
      isMember: map[HasherKennelMapTdTableHelper.colIsMember],
      mismanagementRoleFlags: map[HasherKennelMapTdTableHelper.colMismanagementRoleFlags],
      userRoleFlags: map[HasherKennelMapTdTableHelper.colUserRoleFlags],
      appAccessFlags: map[HasherKennelMapTdTableHelper.colAppAccessFlags],
      historicalPackRunCount: map[HasherKennelMapTdTableHelper.colHistoricalPackRunCount],
      historicalHaringCount: map[HasherKennelMapTdTableHelper.colHistoricalHaringCount],
      updatedAt: DateTime.parse(map[HasherKennelMapTdTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[HasherKennelMapTdTableHelper.colRemoved],
    );

    return item;
  }
}

class HasherKennelMapTdService {
  static final HasherKennelMapTdTableHelper instance = HasherKennelMapTdTableHelper._privateConstructor();

  Future<num> getLastUpdatedTime(Database db) async {
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX(${HasherKennelMapTdTableHelper.colUpdatedAtValue}) AS maxDate FROM ${HasherKennelMapTdTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<HasherKennelMapTdModel>> selectAllFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result = await db.query(HasherKennelMapTdTableHelper.tableName);

    final List<HasherKennelMapTdModel> records = <HasherKennelMapTdModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed'] == 0) {
          final HasherKennelMapTdModel record = HasherKennelMapTdTableHelper.fromMap(result[i]);
          records.add(record);
        }
      }
    }
    return records;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${HasherKennelMapTdTableHelper.tableName}').then((void dummy) {
      setIntPref(HasherKennelMapTdTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<HasherKennelMapTdModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = HasherKennelMapTdTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${HasherKennelMapTdTableHelper.tableName} WHERE ${HasherKennelMapTdTableHelper.remoteDbId} = "${items[i].hkmId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(HasherKennelMapTdTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${HasherKennelMapTdTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(HasherKennelMapTdTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${HasherKennelMapTdTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
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

        final String query = 'SELECT * FROM ${HasherKennelMapTdTableHelper.tableName} WHERE ${HasherKennelMapTdTableHelper.remoteDbId} = "${jsonItem['hkmId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(HasherKennelMapTdTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${UserKennelsTdTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(HasherKennelMapTdTableHelper.tableName, jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${UserKennelsTdTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter kennel records inserted, $updateCounter kennel records updated');
    return insertCounter;
  }

  Future<bool> updateFromBackend(Database db, bool forceRefresh) async {
    final int lastUpdate = getIntPref(HasherKennelMapTdTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh || ((DateTime.now().millisecondsSinceEpoch - lastUpdate) > HasherKennelMapTdTableHelper.forceRequeryInterval)) {
      // check to see if we need to clear the cache
      int lastCacheClear = getIntPref(HasherKennelMapTdTableHelper.lastCacheClearKey);

      if (lastCacheClear == null) {
        // if lastCacheClear is null that means we've never cleared the
        // cache. This happens on startup. So, go ahead and set the lastCacheClear
        // date to now and set lastCacheClear to now to prevent the
        // cache from clearing immediatly upon startup
        lastCacheClear = DateTime.now().millisecondsSinceEpoch;
        setIntPref(HasherKennelMapTdTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
      }

      if (lastCacheClear + HasherKennelMapTdTableHelper.cacheDuration < DateTime.now().millisecondsSinceEpoch) {
        print('clearing ${HasherKennelMapTdTableHelper.tableName} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        await clearTable();
      }

      // get the last updated time of any of the records in
      // the table and add one second to it
      final num timeValue = await getLastUpdatedTime(db);
      final DateTime updatedAfter = timeValue == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(timeValue + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = Utilities.generateToken(userId, HasherKennelMapTdTableHelper.storedProcName);

      final String timeStr = updatedAfter.toString().substring(0, 19);

      final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken': accessToken, 'updatedAfter': timeStr});

      final http.Response response = await http
          .post(BASE_API_URL + HasherKennelMapTdTableHelper.restApiMethodName, headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return false;
        },
      );

      // TODO(James): Fix issue where one city is returned every time, change the lastUpdated param to the database to the lastUpdatedValue (bigint) from lastUpdated (datetime)
      if (response.body.length > 20) {
        await bulkUpdateDatabase(response.body, db, null);
      }

      setIntPref(HasherKennelMapTdTableHelper.lastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
    }

    //final List<UserKennelsTdModel> allRecords = await selectAllFromLocalDb();

    return true;
  }
}
