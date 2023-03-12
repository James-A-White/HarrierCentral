import 'package:harrier_central/imports_null_safe.dart';

class CitiesTableHelper extends BaseTableHelper with BaseFields {
  CitiesTableHelper() {
    remoteDbId = 'cityId';
    humanReadableTableName = 'Cities';
    pageSize = SyncUserDataService.pageSize_citiesTable;
    tableFlag = SyncUserDataService.flagCitiesTable;
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   break;
      // case AppDomainType.kennel:
      //   break;
      // case AppDomainType.user:
      //   tableName = 'cities';
      //   break;
      default:
        tableName = 'cities';
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

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
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
            $colFlagFile TEXT,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
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
