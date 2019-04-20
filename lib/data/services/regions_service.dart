import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

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

  static const String table = 'regions';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 *
      3 *
      86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes
  static const String storedProcName = 'getAllRegions';
  static const String restApiMethodName = 'hc3_get_all_regions';

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateRegionsData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearRegionsData;

  static const String colId = 'id';
  static const String colRegionId = 'regionId';
  static const String remoteDbId = 'regionId';
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
          CREATE TABLE $table (
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

    await db.execute('CREATE INDEX idx_${table}_id ON $table($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${table}_update_at_value ON $table($colUpdatedAtValue);');
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

  Future<num> getLastUpdatedTime(Database db) async {

    final List<Map<String, dynamic>> table = await db.rawQuery(
        'SELECT MAX(${RegionsTableHelper.colUpdatedAtValue}) AS maxDate FROM ${RegionsTableHelper.table}');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<RegionsModel>> selectAllFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result =
        await db.query(RegionsTableHelper.table);

    final List<RegionsModel> records = <RegionsModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed'] == 0) {
          final RegionsModel record = RegionsTableHelper.fromMap(result[i]);
          records.add(record);
        }
      }
    }
    return records;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${RegionsTableHelper.table}')
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
          'SELECT * FROM ${RegionsTableHelper.table} WHERE ${RegionsTableHelper.remoteDbId} = "${items[i].regionId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(RegionsTableHelper.table, row);
          print(result.toString() +
              ' inserted into to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(RegionsTableHelper.table, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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
            'SELECT * FROM ${RegionsTableHelper.table} WHERE ${RegionsTableHelper.remoteDbId} = "${jsonItem['regionId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          //print(table.length.toString());
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(RegionsTableHelper.table, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(RegionsTableHelper.table, jsonItem,
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

  Future<bool> updateFromBackend(Database db, bool forceRefresh) async {
    final int lastUpdate = getIntPref(RegionsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((DateTime.now().millisecondsSinceEpoch - lastUpdate) >
            RegionsTableHelper.forceRequeryInterval)) {
      // check to see if we need to clear the cache
      int lastCacheClear = getIntPref(RegionsTableHelper.lastCacheClearKey);

      if (lastCacheClear == null) {
        // if lastCacheClear is null that means we've never cleared the
        // cache. This happens on startup. So, go ahead and set the lastCacheClear
        // date to now and set lastCacheClear to now to prevent the
        // cache from clearing immediatly upon startup
        lastCacheClear = DateTime.now().millisecondsSinceEpoch;
        setIntPref(RegionsTableHelper.lastCacheClearKey,
            DateTime.now().millisecondsSinceEpoch);
      }

      if (lastCacheClear + RegionsTableHelper.cacheDuration <
          DateTime.now().millisecondsSinceEpoch) {
        print(
            'clearing ${RegionsTableHelper.table} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        await clearTable();
      }

      // get the last updated time of any of the records in
      // the table and add one second to it
      final num timeValue = await getLastUpdatedTime(db);
      final DateTime updatedAfter = timeValue == null
          ? DateTime(2019, 1, 1)
          : DateTime.fromMillisecondsSinceEpoch(timeValue + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken =
          Utilities.generateToken(userId, RegionsTableHelper.storedProcName);

      final String timeStr = updatedAfter.toString().substring(0, 19);

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'updatedAfter': timeStr
      });

      final http.Response response = await http
          .post(BASE_API_URL + RegionsTableHelper.restApiMethodName,
              headers: <String, String>{'content-type': 'application/json'},
              body: body
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

      setIntPref(RegionsTableHelper.lastUpdatedKey,
          DateTime.now().millisecondsSinceEpoch);
    }

    //final List<RegionsModel> allRecords = await selectAllFromLocalDb();

    return true;
  }
}
