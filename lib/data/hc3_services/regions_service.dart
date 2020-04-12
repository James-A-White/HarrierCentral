import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:ive_flutter_core/database/base_service.dart';

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

  // @override
  // String tableName = 'regions';

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   break;
      // case AppDomainType.kennel:
      //   break;
      // case AppDomainType.user:
      //   tableName = 'regions';
      //   break;
      default:
        tableName = 'regions';
    }
    return tableName;
  }

  @override
  String remoteDbId = 'regionId';

  final String colRegionId = 'regionId';
  final String colRegionName = 'regionName';
  final String colCountryId = 'countryId';
  final String colFlagFile = 'flagFile';

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
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


  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return RegionsModel.fromJson(map).toJson();
  }

  @override
  RegionsModel fromMap(Map<String, dynamic> map) {
    return RegionsModel.fromJson(map);
  }
}
