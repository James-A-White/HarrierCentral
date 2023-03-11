// @dart=2.11
import 'package:harrier_central/imports.dart';

// TODO(James): Eventually add the flag file to the Regions and Cities JSON or remove it completely from the app

class RegionsTableHelper extends BaseTableHelper with BaseFields {
  RegionsTableHelper() {
    remoteDbId = 'regionId';
    humanReadableTableName = 'Regions';
    pageSize = SyncUserDataService.pageSize_regionsTable;
    tableFlag = SyncUserDataService.flagRegionsTable;
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
      //   tableName = 'regions';
      //   break;
      default:
        tableName = 'regions';
    }
    return tableName;
  }

  final String colRegionId = 'regionId';
  final String colRegionName = 'regionName';
  final String colRegionSearchTags = 'regionSearchTags';
  final String colRegionAbbreviation = 'regionAbbreviation';
  final String colCountryId = 'countryId';
  final String colFlagFile = 'flagFile';

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colRegionId TEXT NOT NULL,
            $colRegionName TEXT NOT NULL,
            $colRegionSearchTags TEXT,
            $colRegionAbbreviation TEXT,
            $colCountryId TEXT NOT NULL,
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
    return RegionsModel.fromJson(inputMap).toJson();
  }

  @override
  RegionsModel fromMap(Map<String, dynamic> map) {
    return RegionsModel.fromJson(map);
  }
}
