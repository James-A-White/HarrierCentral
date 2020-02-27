import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/constants.dart';

class BaseModel {
  BaseModel();
  List<BaseModel> itemsFromJson(String jsonResult) {
    return null;
  }
}

enum AppDomainType {user,event,kennel}
enum TableType { baseTable, hemUser, hemEventAdmin, hkmUser, hkmEventAdmin, hkmKennelAdmin, paymentsUser, paymentsEvent }

class BaseTableHelper {
  BaseTableHelper();

  String tableName;
  String remoteDbId;

  String getTableName(TableType tableType) {
    return null;
  }

  final num forceRequeryInterval = 1 * 1000;
  final num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  Future<dynamic> createTable(Database db, int version, TableType tableType) async {}

  Map<String, dynamic> toMap(BaseModel item) {
    return null;
  }

  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return null;
  }

  BaseModel fromMap(Map<String, dynamic> map) {
    return null;
  }
}

mixin BaseFields {
  final String colId = 'id';
  final String colRemoved = 'removed';
  final String colUpdatedAt = 'updatedAt';
  final String colUpdatedAtValue = 'updatedAtValue';
}

class BaseService {
  String getTableName(BaseTableHelper tableHelper, TableType tableType) {
    String tableName = tableHelper.tableName;
    if (tableType != null) {
      switch (tableType) {
        case TableType.baseTable:
          // don't change the string, keep it as it was initialized above
          break;
        case TableType.hemEventAdmin:
          tableName = hemAdminTable;
          break;
        case TableType.hemUser:
          tableName = hemUserTable;
          break;
        case TableType.hkmUser:
          tableName = hkmUserTable;
          break;
        case TableType.hkmEventAdmin:
          tableName = hkmEventAdminTable;
          break;
        case TableType.hkmKennelAdmin:
          tableName = hkmKennelAdminTable;
          break;
        case TableType.paymentsEvent:
          tableName = eventPaymentsTable;
          break;
        case TableType.paymentsUser:
          tableName = userPaymentsTable;
          break;
        default:
          // this will cause a SQL error and help us debug, should put a debug assert here
          tableName = '';
          break;
      }
    }

    return tableName;
  }

  Future<List<BaseModel>> selectAllFromLocalDb(BaseTableHelper tableHelper, {TableType tableType}) async {
    final Database db = await DBProvider.db.database;
    final String tableName = getTableName(tableHelper, tableType);

    final List<Map<String, dynamic>> result = await db.query(tableName);

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

  Future<num> getLastUpdatedTime(BaseTableHelper tableHelper, String colUpdatedAtValue, {TableType tableType}) async {
    final String tableName = getTableName(tableHelper, tableType);
    if((tableName == null) || (tableName.isEmpty))
    {
      int xxx = 0;
    }
    final Database db = await DBProvider.db.database;
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colUpdatedAtValue) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable(BaseTableHelper tableHelper, {TableType tableType}) async {
    final String tableName = getTableName(tableHelper, tableType);
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM $tableName').then((void dummy) {
      setIntPrefStrKey(LAST_CACHE_CLEAR_KEY + tableHelper.getTableName(tableType), DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<int> bulkUpdateDatabase(BaseTableHelper tableHelper, String rawResults, Database db, Function informUser, {TableType tableType}) async {
    int updateCounter = 0;
    int insertCounter = 0;
    int deletedCounter = 0;

    bool doNormalizeMap;

    final String tableName = getTableName(tableHelper, tableType);

    final List<dynamic> jsonResultSets = json.decode(rawResults);
    print('$tableName result sets received from cloud = ${jsonResultSets.length}');

    int lastPercentage = 0;

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];
      print('$tableName results received from cloud = ${jsonResults.length}');

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = tableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for $tableName, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length - 1}');
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();

        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading $tableName data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT id FROM $tableName WHERE ${tableHelper.remoteDbId} = "${jsonItem[tableHelper.remoteDbId]}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((jsonResults[j]['removed'] ?? 0) == 0) {
          if (jsonResults[j]['removed'] == null) {
            print('$tableName should implement a removed field');
          }

          if ((table == null) || (table.isEmpty)) {
            await db.transaction<dynamic>((Transaction txn) async {
              await txn.insert(tableName, doNormalizeMap ? tableHelper.normalizeMap(jsonItem) : jsonItem);
              insertCounter++;
            });
          } else {
            final String rowId = table.first['id'].toString();
            await db.transaction<dynamic>((Transaction txn) async {
              await txn.update(tableName, doNormalizeMap ? tableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
              updateCounter++;
            });
          }
        } else {
          
          if ((table != null) && (table.isNotEmpty)) {
            final String rowId = table.first['id'].toString();
            if ((rowId != null) && (rowId.isNotEmpty)) {
              await db.transaction<dynamic>((Transaction txn) async {
                await txn.delete(tableName, where: 'id = $rowId');
                deletedCounter++;
              });
            }
          }
        }
      }
    }

    print('$insertCounter $tableName records inserted, $updateCounter $tableName records updated, $deletedCounter $tableName records deleted');
    return insertCounter;
  }
}
