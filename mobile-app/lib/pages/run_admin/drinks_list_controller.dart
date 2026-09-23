// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

/// One attendee's standing at this run, and which award (if any) it earns.
class DrinksResults {
  DrinksResults({
    required this.hasherId,
    required this.dispName,
    required this.nameForSort,
    required this.photo,
    required this.totalRunsThisKennel,
    required this.totalHaringThisKennel,
    this.specialRunCount = 0,
    this.specialHaringCount = 0,
    this.isHare = 0,
  });

  final String hasherId;
  final String dispName;
  final String nameForSort;
  final String photo;
  final int totalRunsThisKennel;
  final int totalHaringThisKennel;
  int specialRunCount;
  int specialHaringCount;
  int isHare;

  static DrinksResults fromMap(Map<String, dynamic> map) => DrinksResults(
    hasherId: map['hasherId'] as String,
    dispName: map['dispName'] as String,
    nameForSort: map['nameForSort'] as String,
    photo: (map['photo'] as String?) ?? '',
    totalRunsThisKennel: (map['totalRunsThisKennel'] as int?) ?? 0,
    totalHaringThisKennel: (map['totalHaringThisKennel'] as int?) ?? 0,
    isHare: (map['isHare'] as int?) ?? 0,
  );
}

/// The "Drink chug-a-lug" list: who at this run has earned a down-down for a
/// milestone, and why.
///
/// Migrated from a StatefulWidget on 2026-09-23, after the page painted "No
/// awards yet for this Trail" for a run whose awards were on the phone the
/// whole time: the State cleared its list before an `await`, refilled it
/// after, and never called setState. Here the list is an [RxList] assigned in
/// ONE step ([load] → [awardsFromRows] → `assignAll`), so a repaint cannot be
/// forgotten, and there is one owner of the load sequence rather than two
/// callers each running the query.
///
/// The award rule itself is [awardsFromRows] — a pure function of rows, so it
/// is unit-tested (test/unit/drinks_awards_rule_test.dart) for the first time.
///
/// Lifetime: the page is pushed with a plain MaterialPageRoute, not Get.to, so
/// GetX will not dispose this on pop. The page deletes it (tagged by eventId)
/// in its PopScope; every visit therefore starts with a fresh load, as the old
/// initState did. Every `await` is followed by an `isClosed` check for the
/// same reason `setStateIfMounted` existed.
class DrinksListController extends GetxController {
  DrinksListController({required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static String tagFor(String eventId) => 'drinks-$eventId';

  final RxList<DrinksResults> awards = <DrinksResults>[].obs;
  final RxBool isLoading = false.obs;

  /// Whether the last attempt to load actually reached the server.
  ///
  /// Without this the screen cannot tell "this run genuinely has no awards"
  /// apart from "we never managed to ask", and it showed the first message for
  /// both. Barbados reported an empty award list that filled in on a second
  /// visit; their logs carried 35 failed connection checks and 77 failed syncs
  /// in a week (James, 2026-09-13).
  final RxBool loadFailed = false.obs;

  String get _eventId => eventAggregate.event.eventId;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// Sync this run's admin data, then rebuild the list from the local tables.
  /// The single owner of that sequence — see the class comment for why.
  Future<void> load() async {
    if (!Utilities.isConnected()) {
      // Was a silent no-op: no sync, no spinner, no message — so the screen
      // fell through to "No awards yet for this Trail" and stated as fact
      // something it had never checked.
      isLoading.value = false;
      loadFailed.value = true;
      return;
    }

    isLoading.value = true;

    final bool synced = await tableModel.syncEventAdminService.updateFromBackend(
      EnumDataTables.hashers.flag |
          EnumDataTables.payments.flag |
          EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      _eventId,
    );
    if (isClosed) return;

    final List<DrinksResults> found = await _queryAwards();
    if (isClosed) return;

    awards.assignAll(found);
    isLoading.value = false;
    // updateFromBackend returns false when it could not reach the server. An
    // empty list after a FAILED sync is not evidence of no awards.
    loadFailed.value = !synced && found.isEmpty;
  }

  /// The refresh button. Checks the connection first and says so plainly when
  /// there is none, rather than spinning and landing back on an empty list.
  Future<void> manualRefresh() async {
    if (!Utilities.isConnected()) {
      await Utilities.showAlert(
        'No connection',
        'A connection is required to get the current run counts. Check your '
            'signal or Wi-Fi and try again.',
        'OK',
      );
      if (isClosed) return;
      loadFailed.value = true;
      return;
    }
    await load();
  }

  /// Which of these attendees earn an award, and for what. Pure: rows in,
  /// awards out, input order kept (the query orders by haring then runs).
  static List<DrinksResults> awardsFromRows(List<Map<String, dynamic>> rows) {
    final List<DrinksResults> found = <DrinksResults>[];
    for (final Map<String, dynamic> row in rows) {
      final DrinksResults item = DrinksResults.fromMap(row);
      item.specialRunCount = Utilities.checkSpecialRun(item.totalRunsThisKennel);
      if (item.isHare == 1) {
        item.specialHaringCount = Utilities.checkSpecialHaring(
          item.totalHaringThisKennel,
        );
      }
      if (item.specialRunCount != specialRunNo ||
          item.specialHaringCount != specialRunNo) {
        found.add(item);
      }
    }
    return found;
  }

  Future<List<DrinksResults>> _queryAwards() async {
    // Run/haring milestone counts must be INCLUSIVE of this run. hem.totalRuns/
    // HaringThisKennel is a cumulative-per-event stamp written by a nightly
    // backend SP, so it is NULL for a live (same-day) event — falling straight
    // back to historical-only badly under-counts. When it is NULL, fall back to
    // the standing HC total + 1 (this run): + always for runs, + only when the
    // hasher is a hare on this event for haring. Historical baseline is added on
    // top in every case.
    final String query =
        '''
        SELECT 
          h.${tableModel.hashersTableHelper.colHasherId},
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colDisplayName},
            h.${tableModel.hashersTableHelper.colDispName},
            h.${tableModel.hashersTableHelper.colHashName},
            h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},"<no name>") as dispName,
          lower(" " || coalesce(h.${tableModel.hashersTableHelper.colHashName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colDispName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colFirstName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colLastName},"") || " ") as nameForSort,
          h.${tableModel.hashersTableHelper.colPhoto},         
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel},
            coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},0)
              + case when hem.${tableModel.hasherEventMapTableHelper.colIsHare} = 1 then 1 else 0 end)
          + coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},0)
          as totalHaringThisKennel,
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel},
            coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},0) + 1)
          + coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},0)
          as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colIsHare}
          FROM ${EnumDataTables.hasherEventMap.eventTableName} hem 
          INNER JOIN ${EnumDataTables.hashers.commonTableName} h on hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}  
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.eventTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId} AND hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = hem.${tableModel.hasherEventMapTableHelper.colEventKennelId}
          WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = '$_eventId' 
          AND hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= 20
          AND h.${tableModel.hashersTableHelper.colRemoved} = 0 
          AND h.${tableModel.hashersTableHelper.colHashName} not like '👣 Anonymous%' 
          ORDER BY totalHaringThisKennel, totalRunsThisKennel
          ''';
    try {
      final List<Map<String, dynamic>> rows = await database.rawQuery(query);
      return awardsFromRows(rows);
    } catch (e, s) {
      BootLogger.logError(
        '[DrinksList.awards] eventId=$_eventId',
        e,
        s,
      );
      return const <DrinksResults>[];
    }
  }
}
