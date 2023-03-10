// @dart=2.11
import 'package:harrier_central/imports.dart';

class CountriesTableHelper extends BaseTableHelper with BaseFields {
  CountriesTableHelper() {
    remoteDbId = 'countryId';
    humanReadableTableName = 'Countries';
    pageSize = SyncUserDataService.pageSize_countriesTable;
    tableFlag = SyncUserDataService.flagCountriesTable;
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
      //   tableName = 'countries';
      //   break;
      default:
        tableName = 'countries';
    }
    return tableName;
  }

  final String colCountryId = 'countryId';

  final String colCountryCode = 'countryCode';
  final String colLatitude = 'latitude';
  final String colLongitude = 'longitude';
  final String colCountryName = 'countryName';
  final String colCountrySearchTags = 'countrySearchTags';
  final String colContinentCode = 'continentCode';
  final String colFlagFile = 'flagFile';
  final String colCurrencyCode = 'currencyCode';
  final String colPrimaryCultureCode = 'primaryCultureCode';
  final String colShowRegion = 'showRegion';
  final String colCurrencySymbol = 'currencySymbol';
  final String colDigitsAfterDecimal = 'digitsAfterDecimal';
  final String colDistancePreference = 'distancePreference';

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colCountryId TEXT NOT NULL,
            $colCountryCode TEXT NOT NULL,
            $colLatitude NUM,
            $colLongitude NUM,
            $colCountryName TEXT NOT NULL,
            $colCountrySearchTags TEXT,
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
    return CountriesModel.fromJson(inputMap).toJson();
  }

  @override
  CountriesModel fromMap(Map<String, dynamic> map) {
    return CountriesModel.fromJson(map);
  }
}
