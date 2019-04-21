import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';


class CitiesModel {
  CitiesModel(
      {this.cityId,
      this.cityName,
      this.regionId,
      this.latitude,
      this.longitude,
      this.cityAscii,
      this.flagFile,
      this.removed,
      this.updatedAt});


  final String cityId;
  final String cityName;
  final String regionId;
  final num latitude;
  final num longitude;
  final String cityAscii;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

  static List<CitiesModel> itemsFromJson(String jsonResult) {
    final List<CitiesModel> items = <CitiesModel>[];

    CitiesModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = CitiesModel(
          cityId: jsonItem['cityId'].toString(),
          cityName: jsonItem['cityName'],
          regionId: jsonItem['regionId'].toString(),
          latitude: jsonItem['latitude'],
          longitude: jsonItem['longitude'],
          cityAscii: jsonItem['cityAscii'],
          flagFile: jsonItem['flagFile'],
          updatedAt: DateTime.parse(jsonItem['updatedAt']),
          removed: jsonItem['removed']
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


class CitiesTableHelper {
  CitiesTableHelper._privateConstructor();

  static const String tableName = 'cities';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes
  static const String storedProcName = 'getCitiesMd';
  static const String restApiMethodName = 'hc3_get_cities_md';

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateCitiesData;
  static const IntPrefsEnum lastCacheClearKey =
      IntPrefsEnum.lastCacheClearCitiesData;

  static const String colId = 'id';
  static const String colCityId = 'cityId';
  static const String remoteDbId = 'cityId';
  static const String colCityName = 'cityName';
  static const String colRegionId = 'regionId';
  static const String colLatitude = 'latitude';
  static const String colLongitude = 'longitude';
  static const String colCityAscii = 'cityAscii';
  static const String colFlagFile = 'flagFile';
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final CitiesTableHelper instance =
      CitiesTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colCityId TEXT NOT NULL,
            $colCityName TEXT,
            $colRegionId TEXT,
            $colLatitude NUM,
            $colLongitude NUM,
            $colCityAscii TEXT,
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


  static Map<String, dynamic> toMap(CitiesModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      CitiesTableHelper.colCityId: item.cityId,
      CitiesTableHelper.colCityName: item.cityName,
      CitiesTableHelper.colRegionId: item.regionId,
      CitiesTableHelper.colLatitude: item.latitude,
      CitiesTableHelper.colLongitude: item.longitude,
      CitiesTableHelper.colCityAscii: item.cityAscii,
      CitiesTableHelper.colFlagFile: item.flagFile,
      CitiesTableHelper.colUpdatedAt: item.updatedAt.toString(),
      CitiesTableHelper.colUpdatedAtValue:
          item.updatedAt.millisecondsSinceEpoch,
      CitiesTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static CitiesModel fromMap(Map<String, dynamic> map) {
    final CitiesModel item = CitiesModel(
      cityId: map[CitiesTableHelper.colCityId],
      cityName: map[CitiesTableHelper.colCityName],
      regionId: map[CitiesTableHelper.colRegionId],
      latitude: map[CitiesTableHelper.colLatitude],
      longitude: map[CitiesTableHelper.colLongitude],
      cityAscii: map[CitiesTableHelper.colCityAscii],
      flagFile: map[CitiesTableHelper.colFlagFile],
      updatedAt: DateTime.parse(map[CitiesTableHelper.colUpdatedAt]),
      removed: map[CitiesTableHelper.colRemoved],
    );

    return item;
  }
}

class CitiesService {
  static final CitiesTableHelper instance =
      CitiesTableHelper._privateConstructor();

  Future<num> getLastUpdatedTime(Database db) async {

    final List<Map<String, dynamic>> table = await db.rawQuery(
        'SELECT MAX(${CitiesTableHelper.colUpdatedAtValue}) AS maxDate FROM ${CitiesTableHelper.tableName}');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<CitiesModel>> selectAllFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result =
        await db.query(CitiesTableHelper.tableName);

    final List<CitiesModel> records = <CitiesModel>[];

    if ((result != null) && (result.isNotEmpty)) {
      for (int i = 0; i < result.length; i++) {
        if (result[i]['removed'] == 0) {
          final CitiesModel record = CitiesTableHelper.fromMap(result[i]);
          records.add(record);
        }
      }
    }
    return records;
  }

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db
        .rawDelete('DELETE FROM ${CitiesTableHelper.tableName}')
        .then((void dummy) {
      setIntPref(CitiesTableHelper.lastCacheClearKey,
          DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<CitiesModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = CitiesTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery(
          'SELECT * FROM ${CitiesTableHelper.tableName} WHERE ${CitiesTableHelper.remoteDbId} = "${items[i].cityId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(CitiesTableHelper.tableName, row);
          print(result.toString() +
              ' inserted into to the ${CitiesTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await db.update(CitiesTableHelper.tableName, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${CitiesTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      }
    }
  }


  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    final List<dynamic> jsonResultSets = json.decode(rawResults);
    print('City result sets received from cloud = ${jsonResultSets.length}');

    int lastPercentage = 0;

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];
      print('City results received from cloud = ${jsonResults.length}');

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];
        final int percentage = (100 * (j/jsonResults.length)).round();

        if ((percentage !=lastPercentage) && (informUser != null))
        {
          lastPercentage =percentage;
          informUser('Loading city data\r\n$percentage% complete');   
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue':
              DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19))
                  .millisecondsSinceEpoch,
        });

        final String query =
            'SELECT * FROM ${CitiesTableHelper.tableName} WHERE ${CitiesTableHelper.remoteDbId} = "${jsonItem['cityId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(CitiesTableHelper.tableName, jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(CitiesTableHelper.tableName, jsonItem,
                where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print(
        '$insertCounter city records inserted, $updateCounter city records updated');
    return insertCounter;
  }


  
  Future<bool> updateFromBackend(Database db, bool forceRefresh) async {
    final int lastUpdate = getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((DateTime.now().millisecondsSinceEpoch - lastUpdate) >
            CitiesTableHelper.forceRequeryInterval)) {
      // check to see if we need to clear the cache
      int lastCacheClear = getIntPref(CitiesTableHelper.lastCacheClearKey);

      if (lastCacheClear == null) {
        // if lastCacheClear is null that means we've never cleared the
        // cache. This happens on startup. So, go ahead and set the lastCacheClear
        // date to now and set lastCacheClear to now to prevent the
        // cache from clearing immediatly upon startup
        lastCacheClear = DateTime.now().millisecondsSinceEpoch;
        setIntPref(CitiesTableHelper.lastCacheClearKey,
            DateTime.now().millisecondsSinceEpoch);
      }

      if (lastCacheClear + CitiesTableHelper.cacheDuration <
          DateTime.now().millisecondsSinceEpoch) {
        print(
            'clearing ${CitiesTableHelper.tableName} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
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
          Utilities.generateToken(userId, CitiesTableHelper.storedProcName);

      final String timeStr = updatedAfter.toString().substring(0, 19);

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'updatedAfter': timeStr
      });

      final http.Response response = await http
          .post(BASE_API_URL + CitiesTableHelper.restApiMethodName,
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

      setIntPref(CitiesTableHelper.lastUpdatedKey,
          DateTime.now().millisecondsSinceEpoch);
    }

    //final List<RegionsModel> allRecords = await selectAllFromLocalDb();

    return true;
  }

}
