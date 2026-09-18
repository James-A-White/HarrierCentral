import 'package:harrier_central/imports.dart';

class SyncEventAdminService {

  //static const int EnumDataTables.hashers.flag = 0x00000020;

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

  /// Serialises event-domain syncs. [updateFromBackend] and
  /// [updateRsvpsFromBackend] both write the same event tables, so they
  /// share ONE queue — overlapping them used to race bulkUpdateDatabase's
  /// check-then-insert and duplicate rows (see AsyncSerializer). A queued
  /// call runs after the in-flight one commits and re-reads the advanced
  /// watermarks, so it degrades to a cheap delta.
  final AsyncSerializer _syncSerializer = AsyncSerializer();

  Future<bool> updateFromBackend(
    int flags,
    bool forceRefresh,
    String eventId, {
    Function? informUser,
    bool usePaging = false,
  }) => _syncSerializer.run(
    () => _updateFromBackend(
      flags,
      forceRefresh,
      eventId,
      informUser: informUser,
      usePaging: usePaging,
    ),
  );

  Future<bool> _updateFromBackend(
    int flags,
    bool forceRefresh,
    String eventId, {
    Function? informUser,
    bool usePaging = false,
  }) async {
    if (Utilities.isNotConnected()) {
      return false;
    }

    // ⚠ THE WIPE USED TO HAPPEN HERE, BEFORE THE FETCH.
    //
    // The event domain is single-tenant, so moving to a different run has to
    // clear the previous one's rows. Doing that BEFORE knowing the new rows
    // could be fetched meant any transient failure — a hash on a bad signal —
    // left the tables empty and adminEventId already updated, so the screens
    // showed nothing and the next visit skipped the wipe and quietly worked.
    // Barbados reported exactly that: an empty award list that filled in on a
    // second visit (James, 2026-09-13).
    //
    // app_boot_service learned this same lesson already: "Wipe the local DB
    // only once we know we can repopulate it."
    //
    // So the wipe now happens AFTER a successful response, via wipeIfSafe().
    final bool eventChanged =
        getStringPref(StringPrefsEnum.adminEventId) != eventId;

    // check to see if we need to clear the cache
    //int lastCacheClear = getIntPref(CitiesTableHelper.lastCacheClearKey);

    // if (lastCacheClear == null) {
    //   // if lastCacheClear is null that means we've never cleared the
    //   // cache. This happens on startup. So, go ahead and set the lastCacheClear
    //   // date to now and set lastCacheClear to now to prevent the
    //   // cache from clearing immediatly upon startup

    // Watermarks. For a CHANGED event the tables still hold the PREVIOUS
    // event's rows, so their max(updatedAt) is not a watermark for this one —
    // using it would suppress every row older than the last event's newest.
    // Ask for everything instead; the wipe-and-replace below makes it a full
    // load rather than a merge.
    if (eventChanged) {
      _forceAllUpdatedTimes(flags);
    } else {
      await _getLastUpdatedTimes(flags);
    }

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

    // A failed fetch returns FALSE and changes nothing. It used to return true
    // regardless, so callers could not tell an empty result from an unanswered
    // request — which is how the award list came to state "No awards yet for
    // this Trail" about a run it had never managed to ask about.
    if (responseBody.startsWith(ERROR_PREFIX)) {
      return false;
    }

    // Only now, with rows in hand, is it safe to drop the previous event's.
    await wipeIfSafe(database, eventChanged: eventChanged, eventId: eventId);

    await updateSqlTablesWithResultsFromBackendApiCall(
      // this replaces a nasty paragraph separator (x2029) that caused the mobile apps to crash
      // NOTE: x2028 also causes mobile apps to crash and we need to figure out a better way to filter for these.
      responseBody.replaceAll('\u2029', '').replaceAll('\u2028', ''),
      informUser: informUser,
    );
    return true;
  }

  /// Clears the event-domain tables, but ONLY when the event actually changed.
  ///
  /// Call this AFTER a successful fetch, never before. Returns whether it
  /// wiped, so the decision is observable to a test rather than buried.
  @visibleForTesting
  Future<bool> wipeIfSafe(
    Database db, {
    required bool eventChanged,
    required String eventId,
  }) async {
    if (!eventChanged) return false;
    for (final table in EnumDataTables.values.where((t) => t.hasEventTable)) {
      await tableModel.baseService.clearTable(
        db,
        table.helperFrom(tableModel),
        table.eventTableName,
      );
    }
    await setStringPref(StringPrefsEnum.adminEventId, eventId);
    return true;
  }

  /// Ask the server for EVERYTHING the flags cover, ignoring whatever the
  /// local tables happen to hold. Used when the event changed.
  void _forceAllUpdatedTimes(int flags) {
    int f(int flag) => (flags & flag) == 0 ? IGNORE_REPLICATION_TIMESTAMP : FORCE;
    _hasherEventMapLastUpdated = f(EnumDataTables.hasherEventMap.flag);
    _hasherKennelMapLastUpdated = f(EnumDataTables.hasherKennelMap.flag);
    _narrowEventsLastUpdated = f(EnumDataTables.events.flag);
    _paymentsLastUpdated = f(EnumDataTables.payments.flag);
    _receiptsLastUpdated = f(EnumDataTables.receipts.flag);
    _hashersLastUpdated = f(EnumDataTables.hashers.flag);
  }

  Future<bool> updateRsvpsFromBackend(
    String eventId, {
    bool usePaging = false,
  }) => _syncSerializer.run(
    () => _updateRsvpsFromBackend(eventId, usePaging: usePaging),
  );

  Future<bool> _updateRsvpsFromBackend(
    String eventId, {
    bool usePaging = false,
  }) async {
    if (Utilities.isNotConnected()) {
      return false;
    }

    // Same ordering fix as _updateFromBackend: decide here, wipe only after the
    // response lands. This path is the RSVP refresh, so an early wipe on a bad
    // connection empties the attendee list just as thoroughly.
    final bool eventChanged =
        getStringPref(StringPrefsEnum.adminEventId) != eventId;

    final int flags =
        EnumDataTables.hasherEventMap.flag | EnumDataTables.hashers.flag;
    if (eventChanged) {
      _forceAllUpdatedTimes(flags);
    } else {
      await _getLastUpdatedTimes(flags);
    }

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1);
    final DateTime hashersUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(_hashersLastUpdated + 1);

    String userId = getStringPref(StringPrefsEnum.userId) ?? '';
    if (userId.isEmpty) {
      userId = GUID_EMPTY;
    }

    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = (getStringPref(StringPrefsEnum.deviceSecret) ?? '')
        .toUpperCase();

    final Map<String, String> syncBody = <String, String>{
      'queryType': 'getEventRsvps',
      'deviceId': deviceId,
      'eventId': eventId,
      'hashersUpdatedAfter':
          ('${hashersUpdatedAfter}000000').substring(0, 26),
      'hasherEventMapUpdatedAfter':
          ('${hasherEventMapUpdatedAfter}000000').substring(0, 26),
      'usePaging': usePaging ? '1' : '0',
    };

    final String responseBody = await ServiceCommon.sendHttpPost(() {
      syncBody['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_getEventRsvps',
        paramString: deviceSecret,
      );
      return jsonEncode(syncBody);
    });

    if (responseBody.startsWith(ERROR_PREFIX)) {
      return false;
    }

    await wipeIfSafe(database, eventChanged: eventChanged, eventId: eventId);

    await updateSqlTablesWithResultsFromBackendApiCall(
      responseBody.replaceAll(' ', '').replaceAll(' ', ''),
    );
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
    // Both writes inside ONE queued action: this method writes the COMMON
    // tables as well as the event ones, so splitting them would let another
    // service interleave between the two halves.
    return localDbSyncWrites.run(() async {
      final String stripped = ServiceCommon.stripSuccessEnvelope(jsonResults);

      List<dynamic> results = await tableModel.baseService
          .updateSqlTablesFromJsonWithAdHocData(
            stripped,
            _commonTables,
            database,
            AppDomainType.user,
          );

      results.addAll(
        await tableModel.baseService.updateSqlTablesFromJsonWithAdHocData(
          stripped,
          _eventTables,
          database,
          AppDomainType.event,
        ),
      );
      return results;
    });
  }
}
