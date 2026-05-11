import 'package:harrier_central/imports.dart';

class SyncKennelAdminService {
  //static const int EnumDataTables.kennels.flag = 0x00000001;
  // static const int EnumDataTables.hasherKennelMap.flag = 0x00000002;
  // static const int EnumDataTables.hashers.flag = 0x00000004;
  // static const int EnumDataTables.hasherEventMap.flag = 0x00000008;
  // static const int EnumDataTables.payments.flag = 0x00000008;

  // exclude HasherEventMap and Payment from allData flags
  //static const int flagsAllData = 0x00000007;

  // ignore: constant_identifier_names
  static const int FORCE = FORCE_ALL_REPLICATION_TIMESTAMP - 1;

  int _kennelLastUpdated = FORCE;
  int _hasherKennelMapLastUpdated = FORCE;
  int _hashersLastUpdated = FORCE;
  int _hasherEventMapLastUpdated = FORCE;
  int _paymentsLastUpdated = FORCE;

  Future<int> _getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await database.rawQuery(
      'SELECT MAX($colName) AS maxDate FROM $tableName',
    );
    final int? timeValue = table.first['maxDate'];
    //print(timeValue.toString());
    return timeValue ?? FORCE;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _kennelLastUpdated = (flags & EnumDataTables.kennels.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.kennelsTableHelper.colUpdatedAtValue,
            EnumDataTables.kennels.commonTableName,
          );
    _hashersLastUpdated = (flags & EnumDataTables.hashers.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hashersTableHelper.colUpdatedAtValue,
            EnumDataTables.hashers.commonTableName,
          );
    _hasherKennelMapLastUpdated =
        (flags & EnumDataTables.hasherKennelMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherKennelMap.kennelTableName,
          );
    _hasherEventMapLastUpdated =
        (flags & EnumDataTables.hasherEventMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherEventMap.kennelTableName,
          );
    _paymentsLastUpdated = (flags & EnumDataTables.payments.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.paymentsTableHelper.colUpdatedAtValue,
            EnumDataTables.payments.kennelTableName,
          );
  }

  Future<void> clearEventData() async {
    await tableModel.baseService.clearTable(
      database,
      tableModel.hasherEventMapTableHelper,
      EnumDataTables.hasherEventMap.kennelTableName,
    );
    await tableModel.baseService.clearTable(
      database,
      tableModel.paymentsTableHelper,
      EnumDataTables.payments.kennelTableName,
    );
  }

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String kennelId, {
    Function? informUser,
    bool usePaging = false,
    String? targetHasherId,
  }) async {
    if (Utilities.isNotConnected()) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminKennelId) != kennelId) {
      // NOTE: kennels and hashers are not cleared here because all kennels and all hashers are loaded all the time for all users
      for (final table in EnumDataTables.values.where(
        (t) => t.hasKennelTable,
      )) {
        final helper = table.helperFrom(tableModel);
        await tableModel.baseService.clearTable(
          database,
          helper,
          helper.getTableName(AppDomainType.kennel),
        );
      }

      await setStringPref(StringPrefsEnum.adminKennelId, kennelId);
    }

    // final int kennelsLastUpdate = (flags & EnumDataTables.kennels.flag) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    // final int hashersLastUpdate = (flags & EnumDataTables.hashers.flag) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int hasherKennelMapLastUpdate = (flags & EnumDataTables.hasherKennelMap.flag) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.kennelAdmin)) ?? 0;

    if (forceRefresh || true)
    // ((kennelsLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - kennelsLastUpdate) > KennelsTableHelper.forceRequeryInterval) ||
    // ((hashersLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hashersLastUpdate) > HashersTableHelper.forceRequeryInterval) ||
    // ((hasherKennelMapLastUpdate != null) && (DateTime.now().millisecondsSinceEpoch - hasherKennelMapLastUpdate) > HasherKennelMapTableHelper.forceRequeryInterval)
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

      final DateTime kennelsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _kennelLastUpdated + 1,
      );
      final DateTime hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _hashersLastUpdated + 1,
      );
      final DateTime hasherKennelMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);
      final DateTime hasherEventMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1);
      final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _paymentsLastUpdated + 1,
      );

      String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      if (userId.isEmpty) {
        userId = GUID_EMPTY;
      }

      String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      String deviceSecret = (getStringPref(StringPrefsEnum.deviceSecret) ?? '')
          .toUpperCase();

      final String accessToken = Utilities.generateToken(
        userId,
        'hcapp_syncKennelAdminData',
        paramString: deviceSecret,
      );

      final Map<String, dynamic> params = <String, String>{
        'queryType': 'syncKennelAdminData',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'kennelId': kennelId,
        'hashersUpdatedAfter': (flags & EnumDataTables.hashers.flag) == 0
            ? 'ignore'
            : ('${hashersUpdatedAfter}000000').substring(0, 26),
        'kennelsUpdatedAfter': (flags & EnumDataTables.kennels.flag) == 0
            ? 'ignore'
            : ('${kennelsUpdatedAfter}000000').substring(0, 26),
        'hasherKennelMapUpdatedAfter':
            (flags & EnumDataTables.hasherKennelMap.flag) == 0
            ? 'ignore'
            : ('${hasherKennelMapUpdatedAfter}000000').substring(0, 26),
        'hasherEventMapUpdatedAfter':
            (flags & EnumDataTables.hasherEventMap.flag) == 0
            ? 'ignore'
            : ('${hasherEventMapUpdatedAfter}000000').substring(0, 26),
        'paymentsUpdatedAfter': (flags & EnumDataTables.payments.flag) == 0
            ? 'ignore'
            : ('${paymentsUpdatedAfter}000000').substring(0, 26),
        'usePaging': usePaging ? '1' : '0',
      };

      if (targetHasherId != null) {
        params['targetHasherId'] = targetHasherId;
      }

      final String body = jsonEncode(params);

      final String responseBody = await ServiceCommon.sendHttpPost(body);

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        await updateSqlTablesWithResultsFromBackendApiCall(
          // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
          responseBody.replaceAll('\u2029', ''),
          informUser: informUser,
        );
      }
    }
    return true;
  }

  List<BaseTableHelper> kennelTables = <BaseTableHelper>[
    tableModel.kennelsTableHelper,
    //tableModel.hashersTableHelper,
    tableModel.hasherKennelMapTableHelper,
    tableModel.hasherEventMapTableHelper,
    tableModel.paymentsTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(
    String jsonResults, {
    Function? informUser,
  }) async {
    return tableModel.baseService.updateSqlTablesFromJsonWithAdHocData(
      jsonResults,
      kennelTables,
      database,
      AppDomainType.kennel,
    );
  }
}
