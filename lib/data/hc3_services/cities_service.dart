import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';

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

  final String cityId;
  final String cityName;
  final String regionId;
  final num latitude;
  final num longitude;
  final String cityAscii;
  final String flagFile;
  final int removed;
  final DateTime updatedAt;

  @override
  List<CitiesModel> itemsFromJson(String jsonResult) {
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

class CitiesTableHelper with BaseFields implements BaseTableHelper 
{
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
  Future<dynamic> createTable(Database db, int version,TableType tableType) async {
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
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colCityId: item.cityId,
      colCityName: item.cityName,
      colRegionId: item.regionId,
      colLatitude: item.latitude,
      colLongitude: item.longitude,
      colCityAscii: item.cityAscii,
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
      colCityId: inputMap[colCityId],
      colCityName: inputMap[colCityName],
      colRegionId: inputMap[colRegionId],
      colLatitude: inputMap[colLatitude],
      colLongitude: inputMap[colLongitude],
      colCityAscii: inputMap[colCityAscii],
      colFlagFile: inputMap[colFlagFile],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  CitiesModel fromMap(Map<String, dynamic> map) {
    final CitiesModel item = CitiesModel(
      cityId: map[colCityId],
      cityName: map[colCityName],
      regionId: map[colRegionId],
      latitude: map[colLatitude],
      longitude: map[colLongitude],
      cityAscii: map[colCityAscii],
      flagFile: map[colFlagFile],
      updatedAt: DateTime.parse(map[colUpdatedAt]),
      removed: map[colRemoved],
    );

    return item;
  }
}
