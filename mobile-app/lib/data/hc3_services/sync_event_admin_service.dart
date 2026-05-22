import 'package:harrier_central/imports.dart';

class SyncEventAdminService {
  // static const int EnumDataTables.hasherEventMap.flag = 0x00000001;
  // static const int EnumDataTables.hasherKennelMap.flag = 0x00000002;
  // static const int EnumDataTables.narrowEvents.flag = 0x00000004;
  // static const int EnumDataTables.payments.flag = 0x00000008;

  //static const int EnumDataTables.hashers.flag = 0x00000020;

  // static const int flagReceiptsTable = 0x00000010;
  // static const int flagKennelCreditTable = 0x00000040;

  // static const int flagsAllData = 0x0000007f;

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
    final int? timeValue = table.isNotEmpty ? table.first['maxDate'] : null;
    return timeValue ?? FORCE;
  }

  Future<void> _getLastUpdatedTimes(int flags) async {
    _hasherEventMapLastUpdated =
        (flags & EnumDataTables.hasherEventMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherEventMap.eventTableName,
          );
    _hasherKennelMapLastUpdated =
        (flags & EnumDataTables.hasherKennelMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherKennelMap.eventTableName,
          );
    _narrowEventsLastUpdated = (flags & EnumDataTables.events.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.eventsTableHelper.colUpdatedAtValue,
            EnumDataTables.events.commonTableName,
          );
    _paymentsLastUpdated = (flags & EnumDataTables.payments.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.paymentsTableHelper.colUpdatedAtValue,
            EnumDataTables.payments.eventTableName,
          );
    _receiptsLastUpdated = (flags & EnumDataTables.receipts.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.receiptsTableHelper.colUpdatedAtValue,
            EnumDataTables.receipts.eventTableName,
          );
    _hashersLastUpdated = (flags & EnumDataTables.hashers.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hashersTableHelper.colUpdatedAtValue,
            EnumDataTables.hashers.commonTableName,
          );
  }

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String eventId, {
    Function? informUser,
    bool usePaging = false,
  }) async {
    if (Utilities.isNotConnected()) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminEventId) != eventId) {
      //final HashersService hSrv = HashersService();
      // narrowEvents is not included here because all events are loaded all the time for all hashers.
      // TODO(James): create separate events table for event management

      for (final table in EnumDataTables.values.where((t) => t.hasEventTable)) {
        final helper = table.helperFrom(tableModel);
        await tableModel.baseService.clearTable(
          database,
          helper,
          table.eventTableName,
        );
      }
      await setStringPref(StringPrefsEnum.adminEventId, eventId);
    }

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
    String deviceSecret = (getStringPref(StringPrefsEnum.deviceSecret) ?? '')
        .toUpperCase();

    final Map<String, String> syncBody = <String, String>{
      'queryType': 'syncEventAdminData',
      'deviceId': deviceId,
      'eventId': eventId,
      'hashersUpdatedAfter': (flags & EnumDataTables.hashers.flag) == 0
          ? 'ignore'
          : ('${hashersUpdatedAfter}000000').substring(0, 26),
      'hasherEventMapUpdatedAfter':
          (flags & EnumDataTables.hasherEventMap.flag) == 0
          ? 'ignore'
          : ('${hasherEventMapUpdatedAfter}000000').substring(0, 26),
      'hasherKennelMapUpdatedAfter':
          (flags & EnumDataTables.hasherKennelMap.flag) == 0
          ? 'ignore'
          : ('${hasherKennelMapUpdatedAfter}000000').substring(0, 26),
      'narrowEventsUpdatedAfter': (flags & EnumDataTables.events.flag) == 0
          ? 'ignore'
          : ('${narrowEventsUpdatedAfter}000000').substring(0, 26),
      'paymentsUpdatedAfter': (flags & EnumDataTables.payments.flag) == 0
          ? 'ignore'
          : ('${paymentsUpdatedAfter}000000').substring(0, 26),
      'receiptsUpdatedAfter': (flags & EnumDataTables.receipts.flag) == 0
          ? 'ignore'
          : ('${receiptsUpdatedAfter}000000').substring(0, 26),
      'usePaging': usePaging ? '1' : '0',
    };

    final String responseBody = await ServiceCommon.sendHttpPost(() {
      syncBody['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_syncEventAdminData',
        paramString: deviceSecret,
      );
      return jsonEncode(syncBody);
    });

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await updateSqlTablesWithResultsFromBackendApiCall(
        // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
        // NOTE: x2028 also causes mobile apps to crash and we need to figure out a better way to filter for these.
        responseBody.replaceAll('\u2029', '').replaceAll('\u2028', ''),
        informUser: informUser,
      );
    }
    return true;
  }

  final List<BaseTableHelper> _eventTables = <BaseTableHelper>[
    tableModel.paymentsTableHelper,
    tableModel.receiptsTableHelper,
    tableModel.hasherEventMapTableHelper,
    tableModel.hasherKennelMapTableHelper,
  ];

  final List<BaseTableHelper> _commonTables = <BaseTableHelper>[
    tableModel.hashersTableHelper,
    tableModel.eventsTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(
    String jsonResults, {
    Function? informUser,
  }) async {
    List<dynamic> results = await tableModel.baseService
        .updateSqlTablesFromJsonWithAdHocData(
          jsonResults,
          _commonTables,
          database,
          AppDomainType.user,
        );

    results.addAll(
      await tableModel.baseService.updateSqlTablesFromJsonWithAdHocData(
        jsonResults,
        _eventTables,
        database,
        AppDomainType.event,
      ),
    );
    return results;
  }
}
