import 'package:harrier_central/imports.dart';

class CitiesTableHelper extends BaseTableHelper<AppDomainType> with BaseFields {
  CitiesTableHelper() {
    remoteDbId = 'cityId';
    humanReadableTableName = 'Cities';
    pageSize = SyncUserDataService.pageSize_citiesTable;
    tableFlag = EnumDataTables.cities.flag;
  }

  @override
  String getTableName(AppDomainType appDomainType) {
    String tableName;

    switch (appDomainType) {
      case AppDomainType.user:
        tableName = EnumDataTables.cities.commonTableName;
        break;
      default:
        throw Exception(
          'EnumDataTables.${EnumDataTables.cities.name} does not have a table associated with it.',
        );
    }
    return tableName;
  }

  final String colCityId = 'cityId';
  final String colCityName = 'cityName';
  final String colCitySearchTags = 'citySearchTags';
  final String colRegionId = 'regionId';
  final String colLatitude = 'latitude';
  final String colLongitude = 'longitude';
  final String colCityAscii = 'cityAscii';
  final String colFlagFile = 'flagFile';
  final String colIanaTimeZone = 'ianaTimeZone';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colCityId TEXT NOT NULL,
            $colCityName TEXT NOT NULL,
            $colCitySearchTags TEXT,
            $colRegionId TEXT NOT NULL,
            $colLatitude NUM NOT NULL,
            $colLongitude NUM NOT NULL,
            $colCityAscii TEXT NOT NULL,
            $colIanaTimeZone TEXT NOT NULL,
            $colFlagFile TEXT,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return CitiesModel.fromJson(inputMap).toJson();
  }

  @override
  CitiesModel fromMap(Map<String, dynamic> map) {
    return CitiesModel.fromJson(map);
  }
}
