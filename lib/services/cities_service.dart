import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/data_models/cities_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

class CitiesTableHelper {
  CitiesTableHelper._privateConstructor();

  static const String table = 'cities';
  static const num forceRequeryInterval = 1 * 86400000;
  //static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes
  static const String storedProcName = 'getAllCities';
  static const String restApiMethodName = 'hc3_get_all_cities';

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
          CREATE TABLE $table (
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

    await db.execute('CREATE INDEX idx_${table}_id ON $table($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${table}_update_at_value ON $table($colUpdatedAtValue);');
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

  Future<num> getLastUpdatedTime() async {
    final Database db = await DBProvider.db.database;
    //print(await db.rawQuery('SELECT TOP 10 * FROM ${CitiesTableHelper.table}'));

    final List<Map<String, dynamic>> table = await db.rawQuery(
        'SELECT MAX(${CitiesTableHelper.colUpdatedAtValue}) AS maxDate FROM ${CitiesTableHelper.table}');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<List<CitiesModel>> selectAllFromLocalDb() async {
    final Database db = await DBProvider.db.database;

    final List<Map<String, dynamic>> result =
        await db.query(CitiesTableHelper.table);

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
        .rawDelete('DELETE FROM ${CitiesTableHelper.table}')
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
          'SELECT * FROM ${CitiesTableHelper.table} WHERE ${CitiesTableHelper.remoteDbId} = "${items[i].cityId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(CitiesTableHelper.table, row);
          print(result.toString() +
              ' inserted into to the ${CitiesTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          int result = await db.update(CitiesTableHelper.table, row,
              where: 'id = $rowId');
          print(result.toString() +
              ' update to the ${CitiesTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db) async {
    int updateCounter = 0;
    int insertCounter = 0;

    final dynamic jsonResult = json.decode(rawResults);

    final int i = jsonResult.length;

    print('city records received from cloud = $i');

    await jsonResult.forEach((dynamic jsonItem) async {

      jsonItem.addAll(<String, dynamic>{
        'updatedAtValue':
            DateTime.parse(jsonItem['updatedAt']).millisecondsSinceEpoch,
      });

      final String query =
          'SELECT * FROM ${CitiesTableHelper.table} WHERE ${CitiesTableHelper.remoteDbId} = "${jsonItem['cityId'].toString()}"';
      final List<Map<String, dynamic>> table = await db.rawQuery(query);

      if ((table == null) || (table.isEmpty)) {
        //print(table.length.toString());
        await db.transaction<dynamic>((Transaction txn) async {
          //final int result =
              await txn.insert(CitiesTableHelper.table, jsonItem); 
          insertCounter++;
          // print(result.toString() +
          //     ' inserted into to the ${CitiesTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          //final int result = 
          await txn.update(CitiesTableHelper.table, jsonItem,
              where: 'id = $rowId');
          updateCounter++;
          // print(result.toString() +
          //     ' update to the ${CitiesTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      }
    });
    print('$insertCounter records inserted, $updateCounter records updated');
    return insertCounter;
  }

  Future<List<CitiesModel>> getAllRecords(bool forceRefresh) async {
    final int lastUpdate = getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh ||
        ((DateTime.now().millisecondsSinceEpoch - lastUpdate) >
            CitiesTableHelper.forceRequeryInterval)) {
      // check to see if we need to clear the cache
      int lastCacheClear =
          getIntPref(CitiesTableHelper.lastCacheClearKey);
      
      if (lastCacheClear == null)
      {
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
            'clearing ${CitiesTableHelper.table} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        await clearTable();
      }

      final num timeValue = await getLastUpdatedTime();
      final DateTime updatedAfter = timeValue == null
          ? DateTime(2019, 1, 1)
          : DateTime.fromMillisecondsSinceEpoch(timeValue);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken =
          Utilities.generateToken(userId, CitiesTableHelper.storedProcName);

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'updatedAfter': updatedAfter.toUtc().toString().substring(0, 19)
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
        final Database db = await DBProvider.db.database;
        await bulkUpdateDatabase(response.body, db);
      }

      setIntPref(CitiesTableHelper.lastUpdatedKey,
          DateTime.now().millisecondsSinceEpoch);
    }

    final List<CitiesModel> allRecords = await selectAllFromLocalDb();

    return allRecords;
  }
}
