import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/core/base_service.dart';

import 'package:json_annotation/json_annotation.dart';

part 'cities_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class CitiesModel implements BaseModel {
  CitiesModel({
    this.cityId,
    this.cityName,
    this.regionId,
    this.latitude,
    this.longitude,
    this.cityAscii,
    this.flagFile,
    this.removed,
    this.updatedAt,
  });

  factory CitiesModel.fromJson(Map<String,dynamic> json) => _$CitiesModelFromJson(json);

  @override
  Map<String,dynamic> toJson() => _$CitiesModelToJson(this);

  final String cityId;
  final String cityName;
  final String regionId;
  final num latitude;
  final num longitude;
  final String cityAscii;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

}

class CitiesTableHelper with BaseFields implements BaseTableHelper {
  CitiesTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'cities';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'cityId';

  final String colCityId = 'cityId';
  final String colCityName = 'cityName';
  final String colRegionId = 'regionId';
  final String colLatitude = 'latitude';
  final String colLongitude = 'longitude';
  final String colCityAscii = 'cityAscii';
  final String colFlagFile = 'flagFile';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
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
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return CitiesModel.fromJson(map).toJson();
  }

  @override
  CitiesModel fromMap(Map<String, dynamic> map) {
    return CitiesModel.fromJson(map);
  }
}
