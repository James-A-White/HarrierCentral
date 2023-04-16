import 'package:harrier_central/imports.dart';

class SyncKennelAdminService {
  static const int flagKennelTable = 0x00000001;
  static const int flagHasherKennelMapTable = 0x00000002;
  static const int flagHashersTable = 0x00000004;

  static const int flagsAllData = 0x00000007;

  // ignore: constant_identifier_names
  static const int FORCE = FORCE_ALL_REPLICATION_TIMESTAMP - 1;

  int _kennelLastUpdated = FORCE;
  int _hasherKennelMapLastUpdated = FORCE;
  int _hashersLastUpdated = FORCE;

  Future<int> _getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await G0<Database>().rawQuery('SELECT MAX($colName) AS maxDate FROM $tableName');
    final int? timeValue = table.first['maxDate'];
    //print(timeValue.toString());
    return timeValue ?? FORCE;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _kennelLastUpdated = (flags & flagKennelTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(G0<TableModel>().kennelsTableHelper.colUpdatedAtValue, G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.kennel));
    _hashersLastUpdated = (flags & flagHashersTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(G0<TableModel>().hashersTableHelper.colUpdatedAtValue, G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user));
    _hasherKennelMapLastUpdated = (flags & flagHasherKennelMapTable) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue, G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel));
  }

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String kennelId, {
    Function? informUser,
    bool usePaging = false,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return false;
    }

    if (getStringPref(StringPrefsEnum.adminKennelId) != kennelId) {
      // NOTE: kennels and hashers are not cleared here because all kennels and all hashers are loaded all the time for all users
      await G0<TableModel>().baseService.clearTable(
            G0<Database>(),
            G0<TableModel>().hasherKennelMapTableHelper,
            G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel),
          );

      await setStringPref(StringPrefsEnum.adminKennelId, kennelId);
    }

    // final int kennelsLastUpdate = (flags & flagKennelTable) == 0 ? null : getIntPref(KennelsTableHelper.lastUpdatedKey) ?? 0;
    // final int hashersLastUpdate = (flags & flagHashersTable) == 0 ? null : getIntPref(HashersTableHelper.lastUpdatedKey) ?? 0;
    // final int hasherKennelMapLastUpdate = (flags & flagHasherKennelMapTable) == 0 ? null : getIntPref(HasherKennelMapTableHelper.getLastUpdatedKey(TableType.kennelAdmin)) ?? 0;

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

      final DateTime kennelsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(_kennelLastUpdated + 1);
      final DateTime hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(_hashersLastUpdated + 1);
      final DateTime hasherKennelMapUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);

      String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      if (userId.isEmpty) {
        userId = GUID_EMPTY;
      }

      final String accessToken = IveCoreUtilities.generateToken(userId, 'syncKennelAdminData392');

      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken': accessToken,
        'kennelId': kennelId,
        'hashersUpdatedAfter': (flags & flagHashersTable) == 0 ? 'ignore' : ('${hashersUpdatedAfter}000000').substring(0, 26),
        'kennelsUpdatedAfter': (flags & flagKennelTable) == 0 ? 'ignore' : ('${kennelsUpdatedAfter}000000').substring(0, 26),
        'hasherKennelMapUpdatedAfter': (flags & flagHasherKennelMapTable) == 0 ? 'ignore' : ('${hasherKennelMapUpdatedAfter}000000').substring(0, 26),
        'usePaging': usePaging ? '1' : '0',
      });

      final String responseBody = await ServiceCommon.sendHttpPost('hc3_sync_kennel_admin_data_392', body);

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
    G0<TableModel>().kennelsTableHelper,
    G0<TableModel>().hashersTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromBackendApiCall(String jsonResults, {Function? informUser}) async {
    return G0<TableModel>().baseService.updateSqlTablesFromJsonWithAdHocData(jsonResults, kennelTables, G0<Database>(), AppDomainType.kennel);
  }
}
