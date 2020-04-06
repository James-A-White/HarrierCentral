import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';

import 'package:json_annotation/json_annotation.dart';

part 'regions_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class RegionsModel implements BaseModel {
  RegionsModel({
    this.regionId,
    this.regionName,
    this.countryId,
    this.flagFile,
    this.removed,
    this.updatedAt,
  });

  factory RegionsModel.fromJson(Map<String,dynamic> json) => _$RegionsModelFromJson(json);
 
  @override
  Map<String,dynamic> toJson() => _$RegionsModelToJson(this);

  final String regionId;
  final String regionName;
  final String countryId;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

}

// TODO(James): Eventually add the flag file to the Regions and Cities JSON or remove it completely from the app

class RegionsTableHelper with BaseFields implements BaseTableHelper {
  RegionsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'regions';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'regionId';

  final String colRegionId = 'regionId';
  final String colRegionName = 'regionName';
  final String colCountryId = 'countryId';
  final String colFlagFile = 'flagFile';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
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
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  //  @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$RegionsModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final RegionsModel item = _$RegionsModelFromJson(inputMap);
    final Map<String, dynamic> outputMap = _$RegionsModelToJson(item);
    return outputMap;
  }

  @override
  RegionsModel fromMap(Map<String, dynamic> map) {
    final RegionsModel item = RegionsModel.fromJson(map);
    return item;
  }
}
