import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';

class CountriesModel implements BaseModel {
  CountriesModel({this.countryId, this.countryCode, this.latitude, this.longitude, this.countryName, this.continentCode, this.flagFile, this.currencyCode, this.primaryCultureCode, this.showRegion, this.currencySymbol, this.digitsAfterDecimal, this.distancePreference, this.removed, this.updatedAt});

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
  final int distancePreference;

  final int removed;
  final DateTime updatedAt;

  @override
  List<CountriesModel> itemsFromJson(String jsonResult) {
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
            distancePreference: jsonItem['distancePreference'],
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

class CountriesTableHelper implements BaseTableHelper {
  CountriesTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  IntPrefsEnum lastUpdatedKey;

  @override
  IntPrefsEnum lastCacheClearKey;

  @override
  String tableName = 'countries';

  @override
  String remoteDbId = 'countryId';

  final String colId = 'id';
  final String colCountryId = 'countryId';

  final String colCountryCode = 'countryCode';
  final String colLatitude = 'latitude';
  final String colLongitude = 'longitude';
  final String colCountryName = 'countryName';
  final String colContinentCode = 'continentCode';
  final String colFlagFile = 'flagFile';
  final String colCurrencyCode = 'currencyCode';
  final String colPrimaryCultureCode = 'primaryCultureCode';
  final String colShowRegion = 'showRegion';
  final String colCurrencySymbol = 'currencySymbol';
  final String colDigitsAfterDecimal = 'digitsAfterDecimal';
  final String colDistancePreference = 'distancePreference';

  final String colRemoved = 'removed';
  final String colUpdatedAt = 'updatedAt';
  final String colUpdatedAtValue = 'updatedAtValue';

  @override
  Future<dynamic> createTable(Database db, int version) async {
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
            $colDistancePreference INT,
            
            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colCountryId: item.countryId,
      colCountryCode: item.countryCode,
      colLatitude: item.latitude,
      colLongitude: item.longitude,
      colCountryName: item.countryName,
      colContinentCode: item.continentCode,
      colFlagFile: item.flagFile,
      colCurrencyCode: item.currencyCode,
      colPrimaryCultureCode: item.primaryCultureCode,
      colShowRegion: item.showRegion,
      colCurrencySymbol: item.currencySymbol,
      colDigitsAfterDecimal: item.digitsAfterDecimal,
      colDistancePreference: item.distancePreference,
      colUpdatedAt: item.updatedAt.toString(),
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      colRemoved: item.removed
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colCountryId: inputMap[colCountryId],
      colCountryCode: inputMap[colCountryCode],
      colLatitude: inputMap[colLatitude],
      colLongitude: inputMap[colLongitude],
      colCountryName: inputMap[colCountryName],
      colContinentCode: inputMap[colContinentCode],
      colFlagFile: inputMap[colFlagFile],
      colCurrencyCode: inputMap[colCurrencyCode],
      colPrimaryCultureCode: inputMap[colPrimaryCultureCode],
      colShowRegion: inputMap[colShowRegion],
      colCurrencySymbol: inputMap[colCurrencySymbol],
      colDigitsAfterDecimal: inputMap[colDigitsAfterDecimal],
      colDistancePreference: inputMap[colDistancePreference],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  CountriesModel fromMap(Map<String, dynamic> map) {
    final CountriesModel item = CountriesModel(
      countryId: map[colCountryId],
      countryCode: map[colCountryCode],
      latitude: map[colLatitude],
      longitude: map[colLongitude],
      countryName: map[colCountryName],
      continentCode: map[colContinentCode],
      flagFile: map[colFlagFile],
      currencyCode: map[colCurrencyCode],
      primaryCultureCode: map[colPrimaryCultureCode],
      showRegion: map[colShowRegion],
      currencySymbol: map[colCurrencySymbol],
      digitsAfterDecimal: map[colDigitsAfterDecimal],
      distancePreference: map[colDistancePreference],
      updatedAt: DateTime.parse(map[colUpdatedAt]),
      removed: map[colRemoved],
    );

    return item;
  }
}
