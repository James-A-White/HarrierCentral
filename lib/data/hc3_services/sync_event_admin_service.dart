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

  // ignore: constant_identifier_names
  static const int FORCE = FORCE_ALL_REPLICATION_TIMESTAMP - 1;

  int _hasherEventMapLastUpdated = FORCE;
  int _hasherKennelMapLastUpdated = FORCE;
  int _narrowEventsLastUpdated = FORCE;
  int _paymentsLastUpdated = FORCE;
  int _receiptsLastUpdated = FORCE;
  int _hashersLastUpdated = FORCE;

  Future<int> _getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await database.rawQuery(
      'SELECT MAX($colName) AS maxDate FROM $tableName',
    );
    int? timeValue = table.first['maxDate'];
    //print(timeValue.toString());
    return timeValue ?? FORCE;
  }

  Future<void> _getLastUpdatedTimes(int flags) async {
    _hasherEventMapLastUpdated =
        (flags & flagHasherEventMapTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
              tableModel.hasherEventMapTableHelper.getTableName(
                AppDomainType.event,
              ),
            );
    _hasherKennelMapLastUpdated =
        (flags & flagHasherKennelMapTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
              tableModel.hasherKennelMapTableHelper.getTableName(
                AppDomainType.event,
              ),
            );
    _narrowEventsLastUpdated =
        (flags & flagNarrowEventsTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.eventsTableHelper.colUpdatedAtValue,
              tableModel.eventsTableHelper.getTableName(AppDomainType.user),
            );
    _paymentsLastUpdated =
        (flags & flagPaymentsTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.paymentsTableHelper.colUpdatedAtValue,
              tableModel.paymentsTableHelper.getTableName(AppDomainType.event),
            );
    _receiptsLastUpdated =
        (flags & flagReceiptsTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.receiptsTableHelper.colUpdatedAtValue,
              tableModel.receiptsTableHelper.getTableName(AppDomainType.event),
            );
    _hashersLastUpdated =
        (flags & flagHashersTable) == 0
            ? IGNORE_REPLICATION_TIMESTAMP
            : await _getLastUpdatedTime(
              tableModel.hashersTableHelper.colUpdatedAtValue,
              tableModel.hashersTableHelper.getTableName(AppDomainType.user),
            );
  }

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String eventId, {
    Function? informUser,
    bool usePaging = false,
  }) async {
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminEventId) != eventId) {
      //final HashersService hSrv = HashersService();
      // narrowEvents is not included here because all events are loaded all the time for all hashers.
      // TODO(James): create separate events table for event management

      await tableModel.baseService.clearTable(
        database,
        tableModel.paymentsTableHelper,
        tableModel.paymentsTableHelper.getTableName(AppDomainType.event),
      );
      await tableModel.baseService.clearTable(
        database,
        tableModel.hasherEventMapTableHelper,
        tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event),
      );
      await tableModel.baseService.clearTable(
        database,
        tableModel.hasherKennelMapTableHelper,
        tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event),
      );
      await tableModel.baseService.clearTable(
        database,
        tableModel.receiptsTableHelper,
        tableModel.receiptsTableHelper.getTableName(AppDomainType.event),
      );
      // await tableModel.baseService.clearTable(database, tableModel.kennelCreditsTableHelper, tableModel.kennelCreditsTableHelper.getTableName(AppDomainType.event));
      // we don't want to clear the Hashers table since it is meant to be persistent and not tied to a single event

      await setStringPref(StringPrefsEnum.adminEventId, eventId);
    }

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
      await _getLastUpdatedTimes(flags);

      final DateTime hasherEventMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1);
      final DateTime hasherKennelMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);
      final DateTime narrowEventsUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_narrowEventsLastUpdated + 1);
      final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _paymentsLastUpdated + 1,
      );
      final DateTime receiptsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _receiptsLastUpdated + 1,
      );
      final DateTime hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _hashersLastUpdated + 1,
      );

      String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      if (userId.isEmpty) {
        userId = GUID_EMPTY;
      }

      String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      String deviceSecret =
          (getStringPref(StringPrefsEnum.deviceSecret) ?? '').toUpperCase();

      final String accessToken = Utilities.generateToken(
        userId,
        'hcapp_syncEventAdminData',
        paramString: deviceSecret,
      );

      final String body = jsonEncode(<String, String>{
        'queryType': 'syncEventAdminData',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'eventId': eventId,
        'hashersUpdatedAfter':
            (flags & flagHashersTable) == 0
                ? 'ignore'
                : ('${hashersUpdatedAfter}000000').substring(0, 26),
        'hasherEventMapUpdatedAfter':
            (flags & flagHasherEventMapTable) == 0
                ? 'ignore'
                : ('${hasherEventMapUpdatedAfter}000000').substring(0, 26),
        'hasherKennelMapUpdatedAfter':
            (flags & flagHasherKennelMapTable) == 0
                ? 'ignore'
                : ('${hasherKennelMapUpdatedAfter}000000').substring(0, 26),
        'narrowEventsUpdatedAfter':
            (flags & flagNarrowEventsTable) == 0
                ? 'ignore'
                : ('${narrowEventsUpdatedAfter}000000').substring(0, 26),
        'paymentsUpdatedAfter':
            (flags & flagPaymentsTable) == 0
                ? 'ignore'
                : ('${paymentsUpdatedAfter}000000').substring(0, 26),
        'receiptsUpdatedAfter':
            (flags & flagReceiptsTable) == 0
                ? 'ignore'
                : ('${receiptsUpdatedAfter}000000').substring(0, 26),
        'usePaging': usePaging ? '1' : '0',
      });

      final String responseBody = await ServiceCommon.sendHttpPostV2(body);

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
    tableModel.paymentsTableHelper,
    tableModel.hashersTableHelper,
    tableModel.receiptsTableHelper,
    tableModel.eventsTableHelper,
    tableModel.hasherEventMapTableHelper,
    tableModel.hasherKennelMapTableHelper,
    //tableModel.kennelCreditsTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(
    String jsonResults, {
    Function? informUser,
  }) async {
    return tableModel.baseService.updateSqlTablesFromJsonWithAdHocData(
      jsonResults,
      _eventTables,
      database,
      AppDomainType.event,
    );
  }
}
