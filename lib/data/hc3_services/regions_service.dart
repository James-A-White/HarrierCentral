import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class RegionsModel {
  RegionsModel(
      {this.regionId,
      this.regionName,
      this.countryId,
      this.flagFile,
      this.removed,
      this.updatedAt});

  final String regionId;
  final String regionName;
  final String countryId;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

  static List<RegionsModel> itemsFromJson(String jsonResult) {
    final List<RegionsModel> items = <RegionsModel>[];

    RegionsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = RegionsModel(
            regionId: jsonItem['regionId'].toString(),
            regionName: jsonItem['regionName'],
            countryId: jsonItem['countryId'].toString(),
            flagFile: jsonItem['flagFile'],
            updatedAt: DateTime.parse(
                jsonItem['updatedAt'].toString().substring(0, 19)),
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

class RegionsTableHelper {
  RegionsTableHelper._privateConstructor();

  static const String tableName = 'regions';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 *
      3 *
      86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateRegionsData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearRegionsData;

  static const String colId = 'id';
  static const String remoteDbId = 'regionId';

  static const String colRegionId = 'regionId';
  static const String colRegionName = 'regionName';
  static const String colCountryId = 'countryId';
  static const String colFlagFile = 'flagFile';
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final RegionsTableHelper instance =
      RegionsTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colRegionId TEXT NOT NULL,
            $colRegionName TEXT,
            $colCountryId TEXT,
            $colFlagFile TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }


  static Map<String, dynamic> toMap(RegionsModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      RegionsTableHelper.colRegionId: item.regionId,
      RegionsTableHelper.colRegionName: item.regionName,
      RegionsTableHelper.colCountryId: item.countryId,
      RegionsTableHelper.colFlagFile: item.flagFile,
      RegionsTableHelper.colUpdatedAt: item.updatedAt.toString(),
      RegionsTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      RegionsTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static RegionsModel fromMap(Map<String, dynamic> map) {
    final RegionsModel item = RegionsModel(
      regionId: map[RegionsTableHelper.colRegionId],
      regionName: map[RegionsTableHelper.colRegionName],
      countryId: map[RegionsTableHelper.colCountryId],
      flagFile: map[RegionsTableHelper.colFlagFile],
      updatedAt: DateTime.parse(
          map[RegionsTableHelper.colUpdatedAt].toString().substring(0, 19)),
      removed: map[RegionsTableHelper.colRemoved],
    );

    return item;
  }
}

class RegionsService {
  static final RegionsTableHelper instance =
      RegionsTableHelper._privateConstructor();

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${RegionsTableHelper.tableName}')
        .then((void dummy) {
      setIntPref(RegionsTableHelper.lastCacheClearKey,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<RegionsModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = RegionsTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM ${RegionsTableHelper.tableName} WHERE ${RegionsTableHelper.remoteDbId} = "${items[i].regionId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(RegionsTableHelper.tableName, row);
          print(result.toString() +
              ' inserted into to the ${RegionsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(RegionsTableHelper.tableName, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${RegionsTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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

    print('Region records received from cloud = $len');

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        final int percentage = (100 * (j/jsonResults.length)).round();
        if ((percentage != lastPercentage) && (informUser != null))
        {
          lastPercentage =percentage;
          informUser('Loading region data\r\n$percentage% complete');   
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue':
              DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19))
                  .millisecondsSinceEpoch,
        });

        final String query =
            'SELECT * FROM ${RegionsTableHelper.tableName} WHERE ${RegionsTableHelper.remoteDbId} = "${jsonItem['regionId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(RegionsTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(RegionsTableHelper.tableName, jsonItem,
                where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print(
        '$insertCounter region records inserted, $updateCounter region records updated');
    return insertCounter;
  }
}
