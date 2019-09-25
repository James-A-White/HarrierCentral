import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/util/preferences.dart';

class CountriesModel {
  CountriesModel({this.countryId, this.countryCode, this.latitude, this.longitude, this.countryName, this.continentCode, this.flagFile, this.currencyCode, this.primaryCultureCode, this.showRegion, this.currencySymbol, this.digitsAfterDecimal, this.removed, this.updatedAt});

  final String countryId;
  final String countryCode;
  final num latitude;
  final num longitude;
  final String countryName;
  final String continentCode;
  final String flagFile;
  final String currencyCode;
  final String primaryCultureCode;
  final int showRegion;
  final String currencySymbol;
  final int digitsAfterDecimal;
  final int removed;
  final DateTime updatedAt;

  static List<CountriesModel> itemsFromJson(String jsonResult) {
    final List<CountriesModel> items = <CountriesModel>[];

    CountriesModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = CountriesModel(
            countryId: jsonItem['countryId'].toString(),
            countryCode: jsonItem['countryCode'],
            latitude: jsonItem['latitude'],
            longitude: jsonItem['longitude'],
            countryName: jsonItem['countryName'],
            continentCode: jsonItem['continentCode'],
            flagFile: jsonItem['flagFile'],
            currencyCode: jsonItem['currencyCode'],
            primaryCultureCode: jsonItem['primaryCultureCode'],
            showRegion: jsonItem['showRegion'],
            currencySymbol: jsonItem['currencySymbol'],
            digitsAfterDecimal: jsonItem['digitsAfterDecimal'],
            updatedAt: DateTime.parse(jsonItem['updatedAt']),
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

class CountriesTableHelper {
  CountriesTableHelper._privateConstructor();

  static const String tableName = 'countries';
  //static const num forceRequeryInterval = 1 * 86400000;
  static const num forceRequeryInterval = 1 * 1000;
  static const num cacheDuration = 365 * 3 * 86400000; // cause a force refresh of the cache every 3 years. This effectively prevents cache refreshes

  static const IntPrefsEnum lastUpdatedKey = IntPrefsEnum.lastUpdateCountriesData;
  static const IntPrefsEnum lastCacheClearKey = IntPrefsEnum.lastCacheClearCountriesData;

  static const String colId = 'id';
  static const String colCountryId = 'countryId';
  static const String remoteDbId = 'countryId';
  static const String colCountryCode = 'countryCode';
  static const String colLatitude = 'latitude';
  static const String colLongitude = 'longitude';
  static const String colCountryName = 'countryName';
  static const String colContinentCode = 'continentCode';
  static const String colFlagFile = 'flagFile';
  static const String colCurrencyCode = 'currencyCode';
  static const String colPrimaryCultureCode = 'primaryCultureCode';
  static const String colShowRegion = 'showRegion';
  static const String colCurrencySymbol = 'currencySymbol';
  static const String colDigitsAfterDecimal = 'digitsAfterDecimal';
  static const String colRemoved = 'removed';
  static const String colUpdatedAt = 'updatedAt';
  static const String colUpdatedAtValue = 'updatedAtValue';

  // make this a singleton class

  static final CountriesTableHelper instance = CountriesTableHelper._privateConstructor();

  // SQL code to create the database table
  static Future<dynamic> createTable(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colCountryId TEXT NOT NULL,
            $colCountryCode TEXT NOT NULL,
            $colLatitude NUM,
            $colLongitude NUM,
            $colCountryName TEXT NOT NULL,
            $colContinentCode TEXT NOT NULL,
            $colFlagFile TEXT,
            $colCurrencyCode TEXT,
            $colPrimaryCultureCode TEXT,
            $colShowRegion NUM,
            $colCurrencySymbol TEXT,
            $colDigitsAfterDecimal NUM,
            
            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  static Map<String, dynamic> toMap(CountriesModel item) {
    final Map<String, dynamic> map = <String, dynamic>{
      CountriesTableHelper.colCountryId: item.countryId,
      CountriesTableHelper.colCountryCode: item.countryCode,
      CountriesTableHelper.colLatitude: item.latitude,
      CountriesTableHelper.colLongitude: item.longitude,
      CountriesTableHelper.colCountryName: item.countryName,
      CountriesTableHelper.colContinentCode: item.continentCode,
      CountriesTableHelper.colFlagFile: item.flagFile,
      CountriesTableHelper.colCurrencyCode: item.currencyCode,
      CountriesTableHelper.colPrimaryCultureCode: item.primaryCultureCode,
      CountriesTableHelper.colShowRegion: item.showRegion,
      CountriesTableHelper.colCurrencySymbol: item.currencySymbol,
      CountriesTableHelper.colDigitsAfterDecimal: item.digitsAfterDecimal,
      CountriesTableHelper.colUpdatedAt: item.updatedAt.toString(),
      CountriesTableHelper.colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      CountriesTableHelper.colRemoved: item.removed
    };

    return map;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      CountriesTableHelper.colCountryId: inputMap[CountriesTableHelper.colCountryId],
      CountriesTableHelper.colCountryCode: inputMap[CountriesTableHelper.colCountryCode],
      CountriesTableHelper.colLatitude: inputMap[CountriesTableHelper.colLatitude],
      CountriesTableHelper.colLongitude: inputMap[CountriesTableHelper.colLongitude],
      CountriesTableHelper.colCountryName: inputMap[CountriesTableHelper.colCountryName],
      CountriesTableHelper.colContinentCode: inputMap[CountriesTableHelper.colContinentCode],
      CountriesTableHelper.colFlagFile: inputMap[CountriesTableHelper.colFlagFile],
      CountriesTableHelper.colCurrencyCode: inputMap[CountriesTableHelper.colCurrencyCode],
      CountriesTableHelper.colPrimaryCultureCode: inputMap[CountriesTableHelper.colPrimaryCultureCode],
      CountriesTableHelper.colShowRegion: inputMap[CountriesTableHelper.colShowRegion],
      CountriesTableHelper.colCurrencySymbol: inputMap[CountriesTableHelper.colCurrencySymbol],
      CountriesTableHelper.colDigitsAfterDecimal: inputMap[CountriesTableHelper.colDigitsAfterDecimal],
      CountriesTableHelper.colUpdatedAt: inputMap[CountriesTableHelper.colUpdatedAt],
      CountriesTableHelper.colUpdatedAtValue: DateTime.parse(inputMap[CountriesTableHelper.colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      CountriesTableHelper.colRemoved: inputMap[CountriesTableHelper.colRemoved],
    };

    return outputMap;
  }

  static CountriesModel fromMap(Map<String, dynamic> map) {
    final CountriesModel item = CountriesModel(
      countryId: map[CountriesTableHelper.colCountryId],
      countryCode: map[CountriesTableHelper.colCountryCode],
      latitude: map[CountriesTableHelper.colLatitude],
      longitude: map[CountriesTableHelper.colLongitude],
      countryName: map[CountriesTableHelper.colCountryName],
      continentCode: map[CountriesTableHelper.colContinentCode],
      flagFile: map[CountriesTableHelper.colFlagFile],
      currencyCode: map[CountriesTableHelper.colCurrencyCode],
      primaryCultureCode: map[CountriesTableHelper.colPrimaryCultureCode],
      showRegion: map[CountriesTableHelper.colShowRegion],
      currencySymbol: map[CountriesTableHelper.colCurrencySymbol],
      digitsAfterDecimal: map[CountriesTableHelper.colDigitsAfterDecimal],
      updatedAt: DateTime.parse(map[CountriesTableHelper.colUpdatedAt]),
      removed: map[CountriesTableHelper.colRemoved],
    );

    return item;
  }
}

class CountriesService {
  static final CountriesTableHelper instance = CountriesTableHelper._privateConstructor();

  Future<void> clearTable() async {
    final Database db = await DBProvider.db.database;
    await db.rawDelete('DELETE FROM ${CountriesTableHelper.tableName}').then((void dummy) {
      setIntPref(CountriesTableHelper.lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> updateDatabase(List<CountriesModel> items) async {
    final Database db = await DBProvider.db.database;

    for (int i = 0; i < items?.length ?? 0; i++) {
      final Map<String, dynamic> row = CountriesTableHelper.toMap(items[i]);

      final List<Map<String, dynamic>> table = await db.rawQuery('SELECT * FROM ${CountriesTableHelper.tableName} WHERE ${CountriesTableHelper.remoteDbId} = "${items[i].countryId}"');
      if ((table == null) || (table.isEmpty)) {
        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.insert(CountriesTableHelper.tableName, row);
          print(result.toString() + ' inserted into to the ${CountriesTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      } else {
        final String rowId = table.first['id'].toString();

        await db.transaction<dynamic>((Transaction txn) async {
          final int result = await txn.update(CountriesTableHelper.tableName, row, where: 'id = $rowId');
          print(result.toString() + ' update to the ${CountriesTableHelper.tableName} table @ ${DateTime.now().millisecondsSinceEpoch}');
        });
      }
    }
  }

  Future<int> bulkUpdateDatabase(String rawResults, Database db, Function informUser) async {
    int updateCounter = 0;
    int insertCounter = 0;

    bool doNormalizeMap;

    final List<dynamic> jsonResultSets = json.decode(rawResults);
    print('country result sets received from cloud = ${jsonResultSets.length}');

    int lastPercentage = 0;

    for (int i = 0; i < jsonResultSets.length; i++) {
      final List<dynamic> jsonResults = jsonResultSets[i];
      print('country results received from cloud = ${jsonResults.length}');

      for (int j = 0; j < jsonResults.length; j++) {
        final Map<String, dynamic> jsonItem = jsonResults[j];

        if (doNormalizeMap == null) {
          final Map<String, dynamic> testMap = CountriesTableHelper.normalizeMap(jsonItem);
          doNormalizeMap = (testMap.length - 1) != jsonItem.length;
        }

        final int percentage = (100 * (j / jsonResults.length)).round();

        if ((percentage != lastPercentage) && (informUser != null)) {
          lastPercentage = percentage;
          informUser('Loading country data\r\n$percentage% complete');
        }

        jsonItem.addAll(<String, dynamic>{
          'updatedAtValue': DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)).millisecondsSinceEpoch,
        });

        final String query = 'SELECT * FROM ${CountriesTableHelper.tableName} WHERE ${CountriesTableHelper.remoteDbId} = "${jsonItem['countryId']}"';
        final List<Map<String, dynamic>> table = await db.rawQuery(query);

        if ((table == null) || (table.isEmpty)) {
          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.insert(CountriesTableHelper.tableName, doNormalizeMap ? CountriesTableHelper.normalizeMap(jsonItem) : jsonItem);
            insertCounter++;
            // print(result.toString() +
            //     ' inserted into to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        } else {
          final String rowId = table.first['id'].toString();

          await db.transaction<dynamic>((Transaction txn) async {
            //final int result =
            await txn.update(CountriesTableHelper.tableName, doNormalizeMap ? CountriesTableHelper.normalizeMap(jsonItem) : jsonItem, where: 'id = $rowId');
            updateCounter++;
            // print(result.toString() +
            //     ' update to the ${RegionsTableHelper.table} table @ ${DateTime.now().millisecondsSinceEpoch}');
          });
        }
      }
    }

    print('$insertCounter country records inserted, $updateCounter country records updated');
    return insertCounter;
  }
}
