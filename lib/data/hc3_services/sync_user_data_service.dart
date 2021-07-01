import 'package:harrier_central/imports.dart';

class SyncUserDataService {
  static const int flagHashersTable = 0x00000001;
  static const int flagCitiesTable = 0x00000002;
  static const int flagRegionsTable = 0x00000004;
  static const int flagCountriesTable = 0x00000008;
  static const int flagKennelsTable = 0x00000010;
  static const int flagNarrowEventsTable = 0x00000020;
  static const int flagPaymentsTable = 0x00000040;

  static const int flagAllMasterDataWithoutHashers = 0x0000007E;
  static const int flagAllMasterData = 0x0000007F;

  static const int flagHasherKennelMapTable = 0x00010000;
  static const int flagHasherEventMapTable = 0x00020000;

  static const int flagsAllData = 0x0003007f;

  num _hashersLastUpdated;
  num _citiesLastUpdated;
  num _regionsLastUpdated;
  num _countriesLastUpdated;
  num _kennelsLastUpdated;
  num _paymentsLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _hasherEventMapLastUpdated;
  num _narrowEventsLastUpdated;

  Future<num> getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await G0<Database>().rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _hashersLastUpdated = (flags & flagHashersTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().hashersTableHelper.colUpdatedAtValue, G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user));
    _citiesLastUpdated = (flags & flagCitiesTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().citiesTableHelper.colUpdatedAtValue, G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user));
    _regionsLastUpdated = (flags & flagRegionsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().regionsTableHelper.colUpdatedAtValue, G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user));
    _countriesLastUpdated = (flags & flagCountriesTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().countriesTableHelper.colUpdatedAtValue, G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user));
    _kennelsLastUpdated = (flags & flagKennelsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().kennelsTableHelper.colUpdatedAtValue, G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user));
    _paymentsLastUpdated = (flags & flagPaymentsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().paymentsTableHelper.colUpdatedAtValue, G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(
            G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
            G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user),
          );
    _hasherEventMapLastUpdated = (flags & flagHasherEventMapTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(
            G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
            G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user),
          );
    _narrowEventsLastUpdated = (flags & flagNarrowEventsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().eventsTableHelper.colUpdatedAtValue, G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user));
  }

  Future<bool> updateFromBackend(int tablesToSync, bool forceRefresh, {String clientAppIdentifer, String singleRecordId, Function informUser}) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return false;
    }

    // final int hashersLastUpdate = (tablesToSync & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int citiesLastUpdate = (tablesToSync & flagCitiesTable) == 0 ? null : getIntPref(CitiesTableHelper.lastUpdatedKey) ?? 0;
    // final int regionsLastUpdate = (tablesToSync & flagRegionsTable) == 0 ? null : getIntPref(RegionsTableHelper.lastUpdatedKey) ?? 0;
    // final int countriesLastUpdate = (tablesToSync & flagCountriesTable) == null ? 0 : getIntPref(CountriesTableHelper.lastUpdatedKey) ?? 0;
    // final int kennelsLastUpdate = (tablesToSync & flagKennelsTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    // final int hasherKennelMapLastUpdate = (tablesToSync & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.user)) ?? 0;
    // final int hasherEventMapLastUpdate = (tablesToSync & flagHasherEventMapTable) == 0 ? null : getIntPref(HasherEventMapTableHelper.getLastUpdatedKey(HasherEventMapTableType.user)) ?? 0;
    // final int narrowEventsLastUpdate = (tablesToSync & flagNarrowEventsTable) == 0 ? null : getIntPref(NarrowEventsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh || true)

    // ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) ||
    // ((citiesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - citiesLastUpdate) > CitiesTableHelper.forceRequeryInterval) ||
    // ((regionsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - regionsLastUpdate) > RegionsTableHelper.forceRequeryInterval) ||
    // ((countriesLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - countriesLastUpdate) > CountriesTableHelper.forceRequeryInterval) ||
    // ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) ||
    // ((hasherEventMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherEventMapLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((narrowEventsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - narrowEventsLastUpdate) > NarrowEventsTableHelper.forceRequeryInterval))

    {
      // check to see if we need to clear the cache
      //int lastCacheClear = getIntPref(CitiesTableHelper.lastCacheClearKey);

      // if (lastCacheClear == null) {
      //   // if lastCacheClear is null that means we've never cleared the
      //   // cache. This happens on startup. So, go ahead and set the lastCacheClear
      //   // date to now and set lastCacheClear to now to prevent the
      //   // cache from clearing immediatly upon startup
      //   lastCacheClear = DateTime.now().millisecondsSinceEpoch;
      //   setIntPref(CitiesTableHelper.lastCacheClearKey,
      //       DateTime.now().millisecondsSinceEpoch);
      // }

      // if (lastCacheClear + CitiesTableHelper.cacheDuration <
      //     DateTime.now().millisecondsSinceEpoch) {
      //   print(
      //       'clearing ${CitiesTableHelper.tableName} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      //   await clearTable();
      // }

      // get the last updated time of any of the records in
      // the table and add one second to it
      await getLastUpdatedTimes(tablesToSync);

      final DateTime hashersUpdatedAfter =
          _hashersLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime citiesUpdatedAfter =
          _citiesLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_citiesLastUpdated + 1000);
      final DateTime regionsUpdatedAfter =
          _regionsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_regionsLastUpdated + 1000);
      final DateTime countriesUpdatedAfter =
          _countriesLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_countriesLastUpdated + 1000);
      final DateTime kennelsUpdatedAfter =
          _kennelsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);
      final DateTime paymentsUpdatedAfter =
          _paymentsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null
          ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP)
          : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
      final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null
          ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP)
          : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
      final DateTime narrowEventsUpdatedAfter = _narrowEventsLastUpdated == null
          ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP)
          : DateTime.fromMillisecondsSinceEpoch(_narrowEventsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = IveCoreUtilities.generateToken(userId, 'syncUserData');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'hashersUpdatedAfter': (tablesToSync & flagHashersTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
        'citiesUpdatedAfter': (tablesToSync & flagCitiesTable) == 0 ? 'ignore' : citiesUpdatedAfter.toString().substring(0, 19),
        'regionsUpdatedAfter': (tablesToSync & flagRegionsTable) == 0 ? 'ignore' : regionsUpdatedAfter.toString().substring(0, 19),
        'countriesUpdatedAfter': (tablesToSync & flagCountriesTable) == 0 ? 'ignore' : countriesUpdatedAfter.toString().substring(0, 19),
        'kennelsUpdatedAfter': (tablesToSync & flagKennelsTable) == 0 ? 'ignore' : kennelsUpdatedAfter.toString().substring(0, 19),
        'hasherKennelMapUpdatedAfter': (tablesToSync & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
        'hasherEventMapUpdatedAfter': (tablesToSync & flagHasherEventMapTable) == 0 ? 'ignore' : hasherEventMapUpdatedAfter.toString().substring(0, 19),
        'narrowEventsUpdatedAfter': (tablesToSync & flagNarrowEventsTable) == 0 ? 'ignore' : narrowEventsUpdatedAfter.toString().substring(0, 19),
        'paymentsUpdatedAfter': (tablesToSync & flagPaymentsTable) == 0 ? 'ignore' : paymentsUpdatedAfter.toString().substring(0, 19),
      });

      final String responseBody = await ServiceCommon.sendHttpPost('hc3_sync_user_data', body);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        await updateSqlTablesWithResultsFromBackendApiCall(responseBody, informUser: informUser);
        //await setIntPref(IntPrefsEnum.lastSuccessfulUserDataSyncInMs, DateTime.now().millisecondsSinceEpoch);
        await setDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate, DateTime.now());
      }
    }
    return true;
  }

  final List<BaseTableHelper> _userTables = <BaseTableHelper>[
    G0<TableModel>().hashersTableHelper,
    G0<TableModel>().paymentsTableHelper,
    G0<TableModel>().citiesTableHelper,
    G0<TableModel>().regionsTableHelper,
    G0<TableModel>().countriesTableHelper,
    G0<TableModel>().kennelsTableHelper,
    G0<TableModel>().eventsTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper,
    G0<TableModel>().hasherEventMapTableHelper
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Function informUser}) async {
    return G0<TableModel>().baseService.updateSqlTablesFromJson(jsonResults, _userTables, G0<Database>(), AppDomainType.user, informUser: informUser);
  }
}
