// @dart=2.11
import 'package:harrier_central/imports.dart';

class SyncEventAdminService {
  static const int flagHasherEventMapTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagNarrowEventsTable = 0x00000004;
  static const int flagPaymentsTable = 0x00000008;
  static const int flagReceiptsTable = 0x00000010;
  static const int flagHashersTable = 0x00000020;
  static const int flagKennelCreditTable = 0x00000040;

  static const int flagsAllData = 0x0000007f;

  num _hasherEventMapLastUpdated;
  num _hasherKennelMapLastUpdated;
  num _narrowEventsLastUpdated;
  num _paymentsLastUpdated;
  num _receiptsLastUpdated;
  num _hashersLastUpdated;
  num _kennelCreditsLastUpdated;

  Future<num> getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await G0<Database>().rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final num timeValue = table.first['maxDate'];
    //print(timeValue.toString());
    return timeValue;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _hasherEventMapLastUpdated = (flags & flagHasherEventMapTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue, G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue, G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event));
    _narrowEventsLastUpdated = (flags & flagNarrowEventsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().eventsTableHelper.colUpdatedAtValue, G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user));
    _paymentsLastUpdated = (flags & flagPaymentsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().paymentsTableHelper.colUpdatedAtValue, G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event));
    _receiptsLastUpdated = (flags & flagReceiptsTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().receiptsTableHelper.colUpdatedAtValue, G0<TableModel>().receiptsTableHelper.getTableName(AppDomainType.event));
    _hashersLastUpdated = (flags & flagHashersTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().hashersTableHelper.colUpdatedAtValue, G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user));
    //_hashersLastUpdated = true ? IGNORE_REPLICATION_TIMESTAMP  : await getLastUpdatedTime(db, HashersTableHelper.colUpdatedAtValue, HashersTableHelper.tableName);
    _kennelCreditsLastUpdated = (flags & flagKennelCreditTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await getLastUpdatedTime(G0<TableModel>().kennelCreditsTableHelper.colUpdatedAtValue, G0<TableModel>().kennelCreditsTableHelper.getTableName(AppDomainType.event));
  }

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String eventId, {
    Function informUser,
    bool usePaging = false,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminEventId) != eventId) {
      //final HashersService hSrv = HashersService();
      // narrowEvents is not included here because all events are loaded all the time for all hashers.
      // TODO(James): create separate events table for event management

      await G0<TableModel>().baseService.clearTable(
            G0<Database>(),
            G0<TableModel>().paymentsTableHelper,
            G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.event),
          );
      await G0<TableModel>().baseService.clearTable(G0<Database>(), G0<TableModel>().hasherEventMapTableHelper, G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event));
      await G0<TableModel>().baseService.clearTable(G0<Database>(), G0<TableModel>().hasherKennelMapTableHelper, G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event));
      await G0<TableModel>().baseService.clearTable(G0<Database>(), G0<TableModel>().receiptsTableHelper, G0<TableModel>().receiptsTableHelper.getTableName(AppDomainType.event));
      await G0<TableModel>().baseService.clearTable(G0<Database>(), G0<TableModel>().kennelCreditsTableHelper, G0<TableModel>().kennelCreditsTableHelper.getTableName(AppDomainType.event));
      // we don't want to clear the Hashers table since it is meant to be persistent and not tied to a single event

      await setStringPref(StringPrefsEnum.adminEventId, eventId);
    }

    // final int hasherEventMapLastUpdate = (flags & flagHasherEventMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HasherEventMapTableHelper.getLastUpdatedKey(HasherEventMapTableType.eventAdmin)) ?? 0;
    // final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.eventAdmin)) ?? 0;
    // final int narrowEventsLastUpdate = (flags & flagNarrowEventsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(NarrowEventsTableHelper.lastUpdatedKey) ?? 0;
    // final int paymentsLastUpdate = (flags & flagReceiptsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(PaymentsTableHelper.lastUpdatedKey) ?? 0;
    // final int receiptsLastUpdate = (flags & flagReceiptsTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(ReceiptsTableHelper.lastUpdatedKey) ?? 0;
    // final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int kennelCreditsLastUpdate = (flags & flagKennelCreditTable) == 0 ? IGNORE_REPLICATION_TIMESTAMP : getIntPref(KennelCreditsTableHelper.lastUpdatedKey) ?? 0;

    if (forceRefresh || true)
    // ((paymentsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - paymentsLastUpdate) > PaymentsTableHelper.forceRequeryInterval) ||
    // ((receiptsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - receiptsLastUpdate) > ReceiptsTableHelper.forceRequeryInterval) ||
    // ((hasherEventMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherEventMapLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval) ||
    // ((narrowEventsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - narrowEventsLastUpdate) > NarrowEventsTableHelper.forceRequeryInterval) ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HasherEventMapTableHelper.forceRequeryInterval) ||
    // ((kennelCreditsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelCreditsLastUpdate) > KennelCreditsTableHelper.forceRequeryInterval)

    // )

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
      //   //print(
      //       'clearing ${CitiesTableHelper.tableName} cache @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      //   await clearTable();
      // }

      // get the last updated time of any of the records in
      // the table and add one second to it
      await getLastUpdatedTimes(flags);

      final DateTime hasherEventMapUpdatedAfter =
          _hasherEventMapLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
      final DateTime hasherKennelMapUpdatedAfter =
          _hasherKennelMapLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
      final DateTime narrowEventsUpdatedAfter =
          _narrowEventsLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_narrowEventsLastUpdated + 1000);
      final DateTime paymentsUpdatedAfter =
          _paymentsLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_paymentsLastUpdated + 1000);
      final DateTime receiptsUpdatedAfter =
          _receiptsLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_receiptsLastUpdated + 1000);
      final DateTime hashersUpdatedAfter =
          _hashersLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_hashersLastUpdated + 1000);
      final DateTime kennelCreditsUpdatedAfter =
          _kennelCreditsLastUpdated == null ? DateTime.fromMicrosecondsSinceEpoch(FORCE_ALL_REPLICATION_TIMESTAMP) : DateTime.fromMicrosecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

      String userId = getStringPref(StringPrefsEnum.userId);
      if ((userId ?? '').isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = IveCoreUtilities.generateToken(userId, 'syncEventAdminData392');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'eventId': eventId,
        'hashersUpdatedAfter': (flags & flagHashersTable) == 0 ? 'ignore' : (hashersUpdatedAfter.toString() + '000000').substring(0, 26),
        'hasherEventMapUpdatedAfter': (flags & flagHasherEventMapTable) == 0 ? 'ignore' : (hasherEventMapUpdatedAfter.toString() + '000000').substring(0, 26),
        'hasherKennelMapUpdatedAfter': (flags & flagHasherKennelMapTable) == 0 ? 'ignore' : (hasherKennelMapUpdatedAfter.toString() + '000000').substring(0, 26),
        'narrowEventsUpdatedAfter': (flags & flagNarrowEventsTable) == 0 ? 'ignore' : (narrowEventsUpdatedAfter.toString() + '000000').substring(0, 26),
        'paymentsUpdatedAfter': (flags & flagPaymentsTable) == 0 ? 'ignore' : (paymentsUpdatedAfter.toString() + '000000').substring(0, 26),
        'receiptsUpdatedAfter': (flags & flagReceiptsTable) == 0 ? 'ignore' : (receiptsUpdatedAfter.toString() + '000000').substring(0, 26),
        'kennelCreditsUpdatedAfter': (flags & flagKennelCreditTable) == 0 ? 'ignore' : (kennelCreditsUpdatedAfter.toString() + '000000').substring(0, 26),
        'usePaging': usePaging ? '1' : '0',
      });

      final String responseBody = await ServiceCommon.sendHttpPost('hc3_sync_event_admin_data_392', body);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        await updateSqlTablesWithResultsFromBackendApiCall(
          // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
          // NOTE: x2028 also causes mobile apps to crash and we need to figure out a better way to filter for these.
          responseBody.replaceAll('\u2029', '').replaceAll('\u2028', ''),
          informUser: informUser,
        );
      }
    }
    return true;
  }

  final List<BaseTableHelper> _eventTables = <BaseTableHelper>[
    G0<TableModel>().paymentsTableHelper,
    G0<TableModel>().hashersTableHelper,
    G0<TableModel>().receiptsTableHelper,
    G0<TableModel>().eventsTableHelper,
    G0<TableModel>().hasherEventMapTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper,
    G0<TableModel>().kennelCreditsTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Function informUser}) async {
    return G0<TableModel>().baseService.updateSqlTablesFromJsonWithAdHocData(jsonResults, _eventTables, G0<Database>(), AppDomainType.event);
  }
}
