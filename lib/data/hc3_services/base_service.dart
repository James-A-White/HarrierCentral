import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';


class BaseModel {
  BaseModel();
  List<BaseModel> itemsFromJson(String jsonResult) {}
}

class BaseTableHelper {
  BaseTableHelper();
  // CitiesTableHelper._privateConstructor();
  //   // make this a singleton class
  // final CitiesTableHelper instance = CitiesTableHelper._privateConstructor();

  String tableName;
  String remoteDbId;

  // final num forceRequeryInterval = 1 * 86400000;
  final num forceRequeryInterval = 1 * 1000;
  final num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  IntPrefsEnum lastUpdatedKey;
  IntPrefsEnum lastCacheClearKey;

  // SQL code to create the database table
  Future<dynamic> createTable(Database db, int version) async {}

  Map<String, dynamic> toMap(BaseModel item) {}

  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {}

  BaseModel fromMap(Map<String, dynamic> map) {}
}

class BaseService {

  Future<List<BaseModel>> selectAllFromLocalDb(BaseTableHelper tableHelper) async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result = await db.query(tableHelper.tableName);

    final List<BaseModel> records = <BaseModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed'] == 0) {
          final BaseModel record = tableHelper.fromMap(result[i]);
          records.add(record);
        }
      }
    }
    return records;
  }

  Future<num> getLastUpdatedTime(BaseTableHelper tableHelper, String colUpdatedAtValue) async {
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colUpdatedAtValue) AS maxDate FROM ${tableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable(BaseTableHelper tableHelper) async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${tableHelper.tableName}').then((void dummy) {
      setIntPref(tableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<int> bulkUpdateDatabase(BaseTableHelper tableHelper, String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;
    int deletedCounter = 0;

    bool doNormalizeMap;

    final List<dynamic> jsonResultSets = json.decode(rawResults);
    print('City result sets received from cloud = ${jsonResultSets.length}');

    int lastPercentage = 0;

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];
      print('City results received from cloud = ${jsonResults.length}');

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = tableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for ${tableHelper.tableName}, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}');
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();

        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading ${tableHelper.tableName} data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT id FROM ${tableHelper.tableName} WHERE ${tableHelper.remoteDbId} = "${jsonItem[tableHelper.remoteDbId]}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          await db.transaction<dynamic>((Transaction txn) async {
            await txn.insert(tableHelper.tableName, doNormalizeMap ? tableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            await txn.update(tableHelper.tableName, doNormalizeMap ? tableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
            updateCounter++;
          });
        }
      }
    }

    await db.transaction<dynamic>((Transaction txn) async {
      deletedCounter = await txn.delete(tableHelper.tableName, where: 'removed = 1');
    });

    print('$insertCounter ${tableHelper.tableName} records inserted, $updateCounter ${tableHelper.tableName} records updated, $deletedCounter ${tableHelper.tableName} records deleted');
    return insertCounter;
  }
}
