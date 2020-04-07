import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

//import 'package:harrier_central/util/constants.dart';

class BaseModel {
  BaseModel();
  factory BaseModel.fromJson() => null;
  Map<String,dynamic> toJson() => null;
}

enum AppDomainType {user,event,kennel}
enum TableType { baseTable, hemUser, hemEventAdmin, hkmUser, hkmEventAdmin, hkmKennelAdmin, paymentsUser, paymentsEvent }

class BaseTableHelper {
  BaseTableHelper();

  String tableName;
  String remoteDbId;

  final num forceRequeryInterval = 1 * 1000;
  final num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  String getTableName(TableType tableType) => null;
  Future<dynamic> createTable(Database db, int version, TableType tableType) async => null;
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) => null;
  BaseModel fromMap(Map<String, dynamic> map) => null;
}

mixin BaseFields {
  final String colId = 'id';
  final String colRemoved = 'removed';
  final String colUpdatedAt = 'updatedAt';
  final String colUpdatedAtValue = 'updatedAtValue';
}

class BaseService {
  
  Future<List<BaseModel>> selectAllFromLocalDb(Database db, BaseTableHelper tableHelper, String tableName) async {

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

  Future<num> getLastUpdatedTime(Database db, BaseTableHelper tableHelper,String tableName,String colUpdatedAtValue) async {
    
    final List<Map<String, dynamic>> table = await db.rawQuery('SELECT MAX($colUpdatedAtValue) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    return timeValue;
  }

  Future<void> clearTable(Database db, BaseTableHelper tableHelper,String tableName) async {
    final String query = 'DELETE FROM $tableName';
    await db.rawDelete(query).then((void dummy) {
      //setIntPrefStrKey(LAST_CACHE_CLEAR_KEY + tableHelper.getTableName(tableType), DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<int> bulkUpdateDatabase(BaseTableHelper tableHelper, String tableName, String rawResults, Database db, {Function informUser}) async {
    int updateCounter = 0;
    int insertCounter = 0;
    int deletedCounter = 0;

    bool doNormalizeMap;
    
    final List<dynamic> jsonResultSets = json.decode(rawResults);
    print('$tableName result sets received from cloud = ${jsonResultSets.length}');

    int lastPercentage = 0;

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];
      print('$tableName results received from cloud = ${jsonResults.length}');

      for (int j = 0; j < jsonResults.length; j++) {
        Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = tableHelper.normalizeMap(jsonItem);
          doNormalizeMap = testMap.length != jsonItem.length;
          if (doNormalizeMap) {
            print('Normalize map called for $tableName, # of fields on the wire = ${jsonItem.length}, # of fields in internal DB = ${testMap.length}');
            for (int i = 0; i < jsonItem.length; i++)
            {
              final String key = jsonItem.keys.elementAt(i);
              if (!testMap.containsKey(key))
              {
                print('$key field is on the wire but not in the internal database');
              }
            }

            for (int i = 0; i < testMap.length; i++)
            {
              final String key = testMap.keys.elementAt(i);
              if (!jsonItem.containsKey(key))
              {
                print('$key field is in the internal database but not on the wire');
              }
            }
          }
        }

        final int percentage = (100 * (j / jsonResults.length)).round();

        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading $tableName data\r\n$percentage% complete');
        }

        // important: make sure to normalize the map before adding the updatedAtValue!
        if (doNormalizeMap)
        {
          jsonItem = tableHelper.normalizeMap(jsonItem);
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
              await txn.insert(tableName, jsonItem);
              insertCounter++;
            });
          } else {
            final String rowId = table.first['id'].toString();
            await db.transaction<dynamic>((Transaction txn) async {
              await txn.update(tableName, jsonItem, where: 'id = $rowId');
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
