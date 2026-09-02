// ignore_for_file: constant_identifier_names
import 'package:harrier_central/imports.dart';

class SyncUserDataService {
  // static const int EnumDataTables.hashers.flag = 0x00000001;
  // static const int EnumDataTables.cities.flag = 0x00000002;
  // static const int EnumDataTables.regions.flag = 0x00000004;
  // static const int EnumDataTables.countries.flag = 0x00000008;
  // static const int EnumDataTables.kennels.flag = 0x00000010;
  // static const int EnumDataTables.narrowEvents.flag = 0x00000020;
  // static const int EnumDataTables.payments.flag = 0x00000040;
  // static const int EnumDataTables.hasherKennelMap.flag = 0x00010000;
  // static const int EnumDataTables.hasherEventMap.flag = 0x00020000;

  // static const int flagAllMasterDataWithoutHashers = 0x0000003E;
  // static const int flagAllMasterData = 0x0000003F;
  // static const int flagsAllData = 0x0003007f;
  // static const int flagAllDataWithoutHashersOrEvents = 0x0003001e;

  static const int pageSize_hashersTable = 2500;
  static const int pageSize_citiesTable = 250;
  static const int pageSize_regionsTable = 250;
  static const int pageSize_countriesTable = 250;
  static const int pageSize_songsTable = 250;
  static const int pageSize_kennelsTable = 250;
  static const int pageSize_eventsTable = 250;
  static const int pageSize_hkmTable = 250;
  static const int pageSize_hemTable = 250;

  static const int FORCE = FORCE_ALL_REPLICATION_TIMESTAMP - 1;

  /// True while the boot-time full user-data sync ([syncAllUserDataFromBackend])
  /// is running. The lighter runs-tab background sync yields to it so the two
  /// don't write the shared events/HEM/payments tables concurrently.
  bool isFullSyncInProgress = false;

  int _hashersLastUpdated = FORCE;
  int _citiesLastUpdated = FORCE;
  int _regionsLastUpdated = FORCE;
  int _countriesLastUpdated = FORCE;
  int _songsLastUpdated = FORCE;
  int _kennelsLastUpdated = FORCE;
  int _paymentsLastUpdated = FORCE;
  int _hasherKennelMapLastUpdated = FORCE;
  int _hasherEventMapLastUpdated = FORCE;
  int _narrowEventsLastUpdated = FORCE;

  Future<int> _getLastUpdatedTime(String colName, String tableName) async {
    final List<Map<String, dynamic>> table = await database.rawQuery(
      'SELECT MAX($colName) AS maxDate FROM $tableName',
    );
    final int? timeValue = table.isNotEmpty ? table.first['maxDate'] : null;
    return timeValue ?? FORCE;
  }

  Future<void> getLastUpdatedTimes(int flags) async {
    _hashersLastUpdated = (flags & EnumDataTables.hashers.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hashersTableHelper.colUpdatedAtValue,
            EnumDataTables.hashers.commonTableName,
          );
    _citiesLastUpdated = (flags & EnumDataTables.cities.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.citiesTableHelper.colUpdatedAtValue,
            EnumDataTables.cities.commonTableName,
          );
    _regionsLastUpdated = (flags & EnumDataTables.regions.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.regionsTableHelper.colUpdatedAtValue,
            EnumDataTables.regions.commonTableName,
          );
    _countriesLastUpdated = (flags & EnumDataTables.countries.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.countriesTableHelper.colUpdatedAtValue,
            EnumDataTables.countries.commonTableName,
          );
    _songsLastUpdated = (flags & EnumDataTables.songs.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.songsTableHelper.colUpdatedAtValue,
            EnumDataTables.songs.commonTableName,
          );
    _kennelsLastUpdated = (flags & EnumDataTables.kennels.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.kennelsTableHelper.colUpdatedAtValue,
            EnumDataTables.kennels.commonTableName,
          );
    _paymentsLastUpdated = (flags & EnumDataTables.payments.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.paymentsTableHelper.colUpdatedAtValue,
            EnumDataTables.payments.commonTableName,
          );
    _hasherKennelMapLastUpdated =
        (flags & EnumDataTables.hasherKennelMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherKennelMap.commonTableName,
          );
    _hasherEventMapLastUpdated =
        (flags & EnumDataTables.hasherEventMap.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
            EnumDataTables.hasherEventMap.commonTableName,
          );
    _narrowEventsLastUpdated = (flags & EnumDataTables.events.flag) == 0
        ? IGNORE_REPLICATION_TIMESTAMP
        : await _getLastUpdatedTime(
            tableModel.eventsTableHelper.colUpdatedAtValue,
            EnumDataTables.events.commonTableName,
          );
  }

  /// Serialises common-domain syncs. The boot full sync and the runs
  /// controller's triggerBackgroundSync (tab switch) could overlap and race
  /// bulkUpdateDatabase's check-then-insert, double-inserting new rows into
  /// the common tables — which are never wiped short of a full re-sync, so
  /// duplicates there are the stickiest of all (see AsyncSerializer). A
  /// queued sync runs after the in-flight one commits, re-reads the advanced
  /// watermarks, and becomes a cheap delta.
  final AsyncSerializer _syncSerializer = AsyncSerializer();

  Future<bool> updateFromBackend(
    int tablesToSync,
    bool forceRefresh, {
    String? clientAppIdentifer,
    String? singleRecordId,
    void Function(String)? informUser,
    String? forceReplicateAllRunsForKennel,
    String batchText = '',
    required String debugText,
    Client? client,
    bool usePaging = false,
  }) => _syncSerializer.run(
    () => _updateFromBackend(
      tablesToSync,
      forceRefresh,
      clientAppIdentifer: clientAppIdentifer,
      singleRecordId: singleRecordId,
      informUser: informUser,
      forceReplicateAllRunsForKennel: forceReplicateAllRunsForKennel,
      batchText: batchText,
      debugText: debugText,
      client: client,
      usePaging: usePaging,
    ),
  );

  Future<bool> _updateFromBackend(
    int tablesToSync,
    bool forceRefresh, {
    String? clientAppIdentifer,
    String? singleRecordId,
    void Function(String)? informUser,
    String? forceReplicateAllRunsForKennel,
    String batchText = '',
    required String debugText,
    Client? client,
    bool usePaging = false,
  }) async {
    if (Utilities.isNotConnected()) {
      return false;
    }

    // final lastFullSync =
    //     getDatePref(DatePrefsEnum.lastSuccessfulUserDataFullSync) ??
    //     DateTime(2000);

    // if (!forceRefresh &&
    //     lastFullSync.isAfter(
    //       DateTime.now().subtract(
    //         const Duration(seconds: DEBOUNCE_SYNC_USER_DATA),
    //       ),
    //     )) {
    //   return true;
    // }

    debugPrint('[BOOT] SyncUserData.updateFromBackend: start, flags=0x${tablesToSync.toRadixString(16)}, debugText=$debugText: ${DateTime.now().millisecondsSinceEpoch}ms');
    int batchNumber = 1;
    // Guard against an infinite paging loop. If the base-service bitmask
    // logic fails to clear a table's bit when the SP returns 0 rows, the
    // while condition never reaches 0. 100 pages is far more than any real
    // sync would need; anything beyond that is a stuck loop.
    const int maxBatches = 100;

    while (tablesToSync != 0) {
      if (batchNumber > maxBatches) {
        debugPrint(
          'SyncUserDataService: paging loop exceeded $maxBatches batches '
          '(tablesToSync=0x${tablesToSync.toRadixString(16)}). '
          'Breaking to prevent hang.',
        );
        break;
      }
      debugPrint('[BOOT] SyncUserData.updateFromBackend: batch $batchNumber start, tablesToSync=0x${tablesToSync.toRadixString(16)}: ${DateTime.now().millisecondsSinceEpoch}ms');

      debugPrint('[BOOT] SyncUserData.updateFromBackend: getLastUpdatedTimes start: ${DateTime.now().millisecondsSinceEpoch}ms');
      await getLastUpdatedTimes(tablesToSync);
      debugPrint('[BOOT] SyncUserData.updateFromBackend: getLastUpdatedTimes done: ${DateTime.now().millisecondsSinceEpoch}ms');

      final DateTime hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _hashersLastUpdated + 1,
      );
      final DateTime citiesUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _citiesLastUpdated + 1,
      );
      final DateTime regionsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _regionsLastUpdated + 1,
      );
      final DateTime countriesUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_countriesLastUpdated + 1);
      final DateTime songsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _songsLastUpdated + 1,
      );
      final DateTime kennelsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _kennelsLastUpdated + 1,
      );
      final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        _paymentsLastUpdated + 1,
      );
      final DateTime hasherKennelMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);
      final DateTime hasherEventMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1);
      final DateTime narrowEventsUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(_narrowEventsLastUpdated + 1);

      String userId = getStringPref(StringPrefsEnum.userId) ?? '';
      if (userId.isEmpty) {
        userId = GUID_EMPTY;
      }

      String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

      final Map<String, dynamic> params = <String, dynamic>{
        'queryType': 'syncUserData',
        'deviceId': deviceId,
        'citiesUpdatedAfter': (tablesToSync & EnumDataTables.cities.flag) == 0
            ? 'ignore'
            : ('${citiesUpdatedAfter}000000').substring(0, 26),
        'regionsUpdatedAfter': (tablesToSync & EnumDataTables.regions.flag) == 0
            ? 'ignore'
            : ('${regionsUpdatedAfter}000000').substring(0, 26),
        'countriesUpdatedAfter':
            (tablesToSync & EnumDataTables.countries.flag) == 0
            ? 'ignore'
            : ('${countriesUpdatedAfter}000000').substring(0, 26),
        'songsUpdatedAfter': (tablesToSync & EnumDataTables.songs.flag) == 0
            ? 'ignore'
            : ('${songsUpdatedAfter}000000').substring(0, 26),
        'hasherKennelMapUpdatedAfter':
            (tablesToSync & EnumDataTables.hasherKennelMap.flag) == 0
            ? 'ignore'
            : ('${hasherKennelMapUpdatedAfter}000000').substring(0, 26),
        'hasherEventMapUpdatedAfter':
            (tablesToSync & EnumDataTables.hasherEventMap.flag) == 0
            ? 'ignore'
            : ('${hasherEventMapUpdatedAfter}000000').substring(0, 26),
        'hashersUpdatedAfter': (tablesToSync & EnumDataTables.hashers.flag) == 0
            ? 'ignore'
            : ('${hashersUpdatedAfter}000000').substring(0, 26),
        'kennelsUpdatedAfter': (tablesToSync & EnumDataTables.kennels.flag) == 0
            ? 'ignore'
            : ('${kennelsUpdatedAfter}000000').substring(0, 26),
        'narrowEventsUpdatedAfter':
            (tablesToSync & EnumDataTables.events.flag) == 0
            ? 'ignore'
            : ('${narrowEventsUpdatedAfter}000000').substring(0, 26),
        'paymentsUpdatedAfter':
            (tablesToSync & EnumDataTables.payments.flag) == 0
            ? 'ignore'
            : ('${paymentsUpdatedAfter}000000').substring(0, 26),
        'forceReplicateAllRunsForKennel':
            forceReplicateAllRunsForKennel ?? 'ignore',
        'usePaging': usePaging ? '1' : '0',
      };

      if (kDebugMode) {
        params['includeNulls'] = true;
      }

      final List<BaseTableHelper> tables = [
        for (final t in EnumDataTables.values)
          if (t.isSet(tablesToSync)) t.helperFrom(tableModel),
      ];

      //print('http request issued: ${DateTime.now().difference(startTime).inMilliseconds.toString()}');

      debugPrint('[BOOT] SyncUserData.updateFromBackend: HTTP POST start (batch $batchNumber): ${DateTime.now().millisecondsSinceEpoch}ms');
      final String responseBody = await ServiceCommon.sendHttpPost(() {
        params['accessToken'] = Utilities.generateToken(
          userId,
          'hcapp_syncUserData',
          paramString: deviceSecret,
        );
        return jsonEncode(params);
      }, client: client);
      debugPrint('[BOOT] SyncUserData.updateFromBackend: HTTP POST done (batch $batchNumber): ${DateTime.now().millisecondsSinceEpoch}ms — responseLen=${responseBody.length}, isError=${responseBody.startsWith(ERROR_PREFIX)}');

      if (!responseBody.startsWith(ERROR_PREFIX)) {
        // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
        debugPrint('[BOOT] SyncUserData.updateFromBackend: updateSqlTables start (batch $batchNumber): ${DateTime.now().millisecondsSinceEpoch}ms');
        tablesToSync = await updateSqlTablesWithResultsFromApiWithPaging(
          //responseBody.replaceAll('\u2029', '').replaceAll('\u2028', ''),
          responseBody.replaceAll('\u2029', '').replaceAll('\u2028', ''),
          informUser: informUser,
          suppressDeletes: true,
          batchText: '$batchText $batchNumber',
          tables: tables.isEmpty ? null : tables,
        );
        //await setIntPref(IntPrefsEnum.lastSuccessfulUserDataSyncInMs, DateTime.now().millisecondsSinceEpoch);
        debugPrint('[BOOT] SyncUserData.updateFromBackend: updateSqlTables done (batch $batchNumber): ${DateTime.now().millisecondsSinceEpoch}ms — remaining=0x${tablesToSync.toRadixString(16)}');
        await setDatePref(
          DatePrefsEnum.lastSuccessfulUserDataSync,
          DateTime.now(),
        );

        if (tablesToSync != 0) {
          batchNumber++;
        }
      } else {
        if (kDebugMode) {
          // ignore: avoid_print
          debugPrint(
            'XXXXXXX Server error processing response in SyncUserDataService updateFromBackend XXXXXXXX',
          );
        }
        // A server error means there are no results to page through.
        // Without this break, tablesToSync stays non-zero and the while loop
        // retries the same failing request forever — causing the app to hang.
        break;
      }

      //print('http response processed: ${DateTime.now().difference(startTime).inMilliseconds.toString()}');

      // if (DateTime.now().difference(startTime).inMilliseconds > 5000) {
      //   int xxx = 0;
      // }
    }
    debugPrint('[BOOT] SyncUserData.updateFromBackend: COMPLETE after $batchNumber batches: ${DateTime.now().millisecondsSinceEpoch}ms');
    return true;
  }

  final List<BaseTableHelper> _userTables = <BaseTableHelper>[
    tableModel.hashersTableHelper,
    tableModel.paymentsTableHelper,
    tableModel.citiesTableHelper,
    tableModel.regionsTableHelper,
    tableModel.countriesTableHelper,
    tableModel.songsTableHelper,
    tableModel.kennelsTableHelper,
    tableModel.eventsTableHelper,
    tableModel.hasherKennelMapTableHelper,
    tableModel.hasherEventMapTableHelper,
  ];

  Future<List<dynamic>> updateSqlTablesWithResultsFromApiWithAdHocData(
    String jsonResults, {
    void Function(String)? informUser,
    bool suppressDeletes = false,
    String? batchText,
    List<BaseTableHelper>? tables,
  }) async {
    // Serialised: write SPs apply their sync rowsets straight through here,
    // outside the updateFromBackend guard, which is how an RSVP landing during
    // a background sync doubled rows.
    return localDbSyncWrites.run(
      () => tableModel.baseService.updateSqlTablesFromJsonWithAdHocData(
        ServiceCommon.stripSuccessEnvelope(jsonResults),
        tables ?? _userTables,
        database,
        AppDomainType.user,
        informUser: informUser,
        suppressDeletes: suppressDeletes,
        batchText: batchText ?? '',
      ),
    );
  }

  Future<int> updateSqlTablesWithResultsFromApiWithPaging(
    String jsonResults, {
    void Function(String)? informUser,
    bool suppressDeletes = false,
    String? batchText,
    List<BaseTableHelper>? tables,
  }) async {
    return localDbSyncWrites.run(
      () => tableModel.baseService.updateSqlTablesFromJsonWithPaging(
        jsonResults,
        tables ?? _userTables,
        database,
        AppDomainType.user,
        informUser: informUser,
        suppressDeletes: suppressDeletes,
        batchText: batchText ?? '',
      ),
    );
  }
}
