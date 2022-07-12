// @dart=2.11
import 'package:harrier_central/imports.dart';

class SyncUserDataService {
  static const int flagHashersTable = 0x00000001;
  static const int flagCitiesTable = 0x00000002;
  static const int flagRegionsTable = 0x00000004;
  static const int flagCountriesTable = 0x00000008;
  static const int flagKennelsTable = 0x00000010;
  static const int flagNarrowEventsTable = 0x00000020;
  //static const int flagPaymentsTable = 0x00000040;

  static const int flagAllMasterDataWithoutHashers = 0x0000003E;
  static const int flagAllMasterData = 0x0000003F;

  static const int flagHasherKennelMapTable = 0x00010000;
  static const int flagHasherEventMapTable = 0x00020000;

  static const int flagsAllData = 0x0003003f;
  static const int flagAllDataWithoutHashersOrEvents = 0x0003001e;

  static const int pageSize_hashersTable = 1000;
  static const int pageSize_citiesTable = 250;
  static const int pageSize_regionsTable = 250;
  static const int pageSize_countriesTable = 250;
  static const int pageSize_kennelsTable = 250;
  static const int pageSize_eventsTable = 250;
  static const int pageSize_hkmTable = 250;
  static const int pageSize_hemTable = 250;

  num _hashersLastUpdated;
  num _citiesLastUpdated;
  num _regionsLastUpdated;
  num _countriesLastUpdated;
  num _kennelsLastUpdated;
  //num _paymentsLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _hasherEventMapLastUpdated;
  num _narrowEventsLastUpdated;

  Future<num> getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await G0<Database>().rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    //print(timeValue.toString());
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
    // _paymentsLastUpdated = (flags & flagPaymentsTable) == 0
    //     ? IGNORE_REPLICATION_TIMESTAMP
    //     : await getLastUpdatedTime(G0<TableModel>().paymentsTableHelper.colUpdatedAtValue, G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user));
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

  Future<bool> updateFromBackend(
    int tablesToSync,
    bool forceRefresh, {
    String clientAppIdentifer,
    String singleRecordId,
    Function informUser,
    String forceReplicateAllRunsForKennel,
    String batchText = '',
    @required String debugText,
    Client client,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return false;
    }

    int batchNumber = 1;

    while (tablesToSync != 0) {
      print('***** ===== >' + debugText);

      final DateTime startTime = DateTime.now();
      print('updateFromBackEnd started = 0');

      if (forceRefresh || true) {
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
        // final DateTime paymentsUpdatedAfter =
        //     _paymentsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
        final DateTime hasherKennelMapUpdatedAfter =
            _hasherKennelMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
        final DateTime hasherEventMapUpdatedAfter =
            _hasherEventMapLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
        final DateTime narrowEventsUpdatedAfter =
            _narrowEventsLastUpdated == null ? DateTime.fromMillisecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMillisecondsSinceEpoch(_narrowEventsLastUpdated + 1000);

        String userId = getStringPref(StringPrefsEnum.userId);
        if ((userId ?? '').isEmpty) {
          userId = GUID_EMPTY;
        }

        final String accessToken = IveCoreUtilities.generateToken(userId, 'syncUserData392');

        final Map<String, String> params = <String, String>{
          'userId': userId,
          'accessToken': accessToken,
          'citiesUpdatedAfter': (tablesToSync & flagCitiesTable) == 0 ? 'ignore' : citiesUpdatedAfter.toString().substring(0, 19),
          'regionsUpdatedAfter': (tablesToSync & flagRegionsTable) == 0 ? 'ignore' : regionsUpdatedAfter.toString().substring(0, 19),
          'countriesUpdatedAfter': (tablesToSync & flagCountriesTable) == 0 ? 'ignore' : countriesUpdatedAfter.toString().substring(0, 19),
          'hasherKennelMapUpdatedAfter': (tablesToSync & flagHasherKennelMapTable) == 0 ? 'ignore' : hasherKennelMapUpdatedAfter.toString().substring(0, 19),
          'hasherEventMapUpdatedAfter': (tablesToSync & flagHasherEventMapTable) == 0 ? 'ignore' : hasherEventMapUpdatedAfter.toString().substring(0, 19),
          'hashersUpdatedAfter': (tablesToSync & flagHashersTable) == 0 ? 'ignore' : hashersUpdatedAfter.toString().substring(0, 19),
          'kennelsUpdatedAfter': (tablesToSync & flagKennelsTable) == 0 ? 'ignore' : kennelsUpdatedAfter.toString().substring(0, 19),
          'narrowEventsUpdatedAfter': (tablesToSync & flagNarrowEventsTable) == 0 ? 'ignore' : narrowEventsUpdatedAfter.toString().substring(0, 19),
          'forceReplicateAllRunsForKennel': forceReplicateAllRunsForKennel ?? 'ignore',
        };

        final List<BaseTableHelper> tables = <BaseTableHelper>[];
        if ((tablesToSync & flagCitiesTable) != 0) {
          tables.add(G0<TableModel>().citiesTableHelper);
        }
        if ((tablesToSync & flagRegionsTable) != 0) {
          tables.add(G0<TableModel>().regionsTableHelper);
        }
        if ((tablesToSync & flagCountriesTable) != 0) {
          tables.add(G0<TableModel>().countriesTableHelper);
        }

        final String body = jsonEncode(params);

        print('http request issued: ${DateTime.now().difference(startTime).inMilliseconds.toString()}');

        final String responseBody = await ServiceCommon.sendHttpPost('hc3_sync_user_data_392', body, client: client);

        print('http response received: ${DateTime.now().difference(startTime).inMilliseconds.toString()}');

        if (!responseBody.startsWith(ERROR_PREFIX)) {
          // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
          tablesToSync = await updateSqlTablesWithResultsFromApiWithPaging(responseBody.replaceAll('\u2029', ''),
              informUser: informUser, suppressDeletes: true, batchText: batchText + ' ' + batchNumber.toString(), tables: tables.isEmpty ? null : tables);
          //await setIntPref(IntPrefsEnum.lastSuccessfulUserDataSyncInMs, DateTime.now().millisecondsSinceEpoch);
          await setDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate, DateTime.now());

          if (tablesToSync != 0) {
            batchNumber++;
          }
        } else {
          print('XXXXXXX Server error processing response in SyncUserDataService updateFromBackend XXXXXXXX');
        }

        print('http response processed: ${DateTime.now().difference(startTime).inMilliseconds.toString()}');

        if (DateTime.now().difference(startTime).inMilliseconds > 5000) {
          int xxx = 0;
        }
      }
    }
    return true;
  }

  final List<BaseTableHelper> _userTables = <BaseTableHelper>[
    G0<TableModel>().hashersTableHelper,
    //G0<TableModel>().paymentsTableHelper,
    G0<TableModel>().citiesTableHelper,
    G0<TableModel>().regionsTableHelper,
    G0<TableModel>().countriesTableHelper,
    G0<TableModel>().kennelsTableHelper,
    G0<TableModel>().eventsTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper,
    G0<TableModel>().hasherEventMapTableHelper
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromApiWithAdHocData(String jsonResults, {Function informUser, bool suppressDeletes = false, String batchText, List<BaseTableHelper> tables}) async {
    return G0<TableModel>().baseService.updateSqlTablesFromJsonWithAdHocData(
          jsonResults,
          tables ?? _userTables,
          G0<Database>(),
          AppDomainType.user,
          informUser: informUser,
          suppressDeletes: suppressDeletes,
          batchText: batchText,
        );
  }

  Future<int> updateSqlTablesWithResultsFromApiWithPaging(String jsonResults, {Function informUser, bool suppressDeletes = false, String batchText, List<BaseTableHelper> tables}) async {
    return G0<TableModel>().baseService.updateSqlTablesFromJsonWithPaging(
          jsonResults,
          tables ?? _userTables,
          G0<Database>(),
          AppDomainType.user,
          informUser: informUser,
          suppressDeletes: suppressDeletes,
          batchText: batchText,
        );
  }
}
