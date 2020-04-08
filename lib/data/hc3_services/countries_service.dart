import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:ive_flutter_core/database/base_service.dart';

import 'package:json_annotation/json_annotation.dart';

part 'countries_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class CountriesModel implements BaseModel {
  CountriesModel({this.countryId, this.countryCode, this.latitude, this.longitude, this.countryName, this.continentCode, this.flagFile, this.currencyCode, this.primaryCultureCode, this.showRegion, this.currencySymbol, this.digitsAfterDecimal, this.distancePreference, this.removed, this.updatedAt});

  factory CountriesModel.fromJson(Map<String,dynamic> json) => _$CountriesModelFromJson(json);
 
  @override
  Map<String,dynamic> toJson() => _$CountriesModelToJson(this);

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
}

class CountriesTableHelper with BaseFields implements BaseTableHelper {
  CountriesTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'countries';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'countryId';

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

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
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
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return CountriesModel.fromJson(map).toJson();
  }

  @override
  CountriesModel fromMap(Map<String, dynamic> map) {
    return CountriesModel.fromJson(map);
  }
}
