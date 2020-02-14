import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/preferences.dart';

class RegionsModel implements BaseModel {
  RegionsModel({
    this.regionId,
    this.regionName,
    this.countryId,
    this.flagFile,
    this.removed,
    this.updatedAt,
  });

  final String regionId;
  final String regionName;
  final String countryId;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

  @override
  List<RegionsModel> itemsFromJson(String jsonResult) {
    final List<RegionsModel> items = <RegionsModel>[];

    RegionsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = RegionsModel(regionId: jsonItem['regionId'].toString(), regionName: jsonItem['regionName'], countryId: jsonItem['countryId'].toString(), flagFile: jsonItem['flagFile'], updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)), removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class RegionsTableHelper implements BaseTableHelper {
  RegionsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  IntPrefsEnum lastUpdatedKey;

  @override
  IntPrefsEnum lastCacheClearKey;

  @override
  String tableName = 'regions';

  @override
  String remoteDbId = 'regionId';

  final String colId = 'id';
  final String colRegionId = 'regionId';
  final String colRegionName = 'regionName';
  final String colCountryId = 'countryId';
  final String colFlagFile = 'flagFile';
  final String colRemoved = 'removed';
  final String colUpdatedAt = 'updatedAt';
  final String colUpdatedAtValue = 'updatedAtValue';

  @override
  Future<dynamic> createTable(Database db, int version) async {
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
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colRegionId: item.regionId,
      colRegionName: item.regionName,
      colCountryId: item.countryId,
      colFlagFile: item.flagFile,
      colUpdatedAt: item.updatedAt.toString(),
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      colRemoved: item.removed
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colRegionId: inputMap[colRegionId],
      colRegionName: inputMap[colRegionName],
      colCountryId: inputMap[colCountryId],
      colFlagFile: inputMap[colFlagFile],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  RegionsModel fromMap(Map<String, dynamic> map) {
    final RegionsModel item = RegionsModel(
      regionId: map[colRegionId],
      regionName: map[colRegionName],
      countryId: map[colCountryId],
      flagFile: map[colFlagFile],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }
}
