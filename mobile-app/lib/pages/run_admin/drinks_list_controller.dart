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
    this.atRun = true,
    this.rsvpState = 0,
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

  /// Checked in at this run. False for someone who is not here (yet) but
  /// would earn this award if they came — drawn greyed out under "All" and
  /// "Coming".
  final bool atRun;

  /// RSVP for this run: 3 Yes, 2 Maybe, 1 No, 0 none.
  final int rsvpState;

  /// Counts as "Coming": checked in, RSVP'd Yes or Maybe, or named as a hare.
  /// Maybe is in on purpose — on an award list a name too many costs nothing,
  /// a missed milestone does.
  bool get isComing => atRun || rsvpState == 3 || rsvpState == 2 || isHare == 1;

  static DrinksResults fromMap(Map<String, dynamic> map, {bool atRun = true}) =>
      DrinksResults(
        hasherId: map['hasherId'] as String,
        dispName: map['dispName'] as String,
        nameForSort: map['nameForSort'] as String,
        photo: (map['photo'] as String?) ?? '',
        totalRunsThisKennel: (map['totalRunsThisKennel'] as int?) ?? 0,
        totalHaringThisKennel: (map['totalHaringThisKennel'] as int?) ?? 0,
        isHare: (map['isHare'] as int?) ?? 0,
        atRun: atRun,
        rsvpState: (map['rsvpState'] as int?) ?? 0,
      );
}

/// The award list's filter (the pill at the top).
enum AwardFilter {
  /// Checked in, plus everyone due an award if they came (greyed out).
  all,

  /// Checked in, plus those not yet here who RSVP'd Yes/Maybe or are hares.
  coming,

  /// Checked in only.
  atHash,
}

/// The "Drink chug-a-lug" list: who at this run has earned a down-down for a
/// milestone, and why — and, for today's and upcoming runs, who would earn one
/// if they came ([expected], shown greyed out under "All").
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
/// GetX will not dispose this on pop. The page's GetBuilder(init:) deletes it
/// when the page is disposed; every visit therefore starts with a fresh load,
/// as the old initState did. Every `await` is followed by an `isClosed` check for the
/// same reason `setStateIfMounted` existed.
class DrinksListController extends GetxController {
  DrinksListController({required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  static String tagFor(String eventId) => 'drinks-$eventId';

  /// Awards earned by the hashers checked in at this run.
  final RxList<DrinksResults> awards = <DrinksResults>[].obs;

  /// Awards that would be earned by hashers who are NOT checked in, if they
  /// came: active in the kennel in the last [activeWithinDays] days, RSVP'd
  /// Yes or Maybe, or named as a hare. Only for runs where [canPredict].
  final RxList<DrinksResults> expected = <DrinksResults>[].obs;

  /// The All | Coming | At Hash switch. All and Coming add rows from
  /// [expected], greyed out.
  final Rx<AwardFilter> filter = AwardFilter.all.obs;

  static const int activeWithinDays = 365;

  /// Hours after its start that a run still counts as "today" for
  /// predictions — the down-downs happen after the trail.
  static const int predictGraceHours = 12;
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

  /// Whether "if they came" means anything for this run. The prediction adds
  /// one run to each hasher's CURRENT kennel total, which is right for today's
  /// run and upcoming ones, and wrong for a past run (it would count every run
  /// they have done since). Past runs therefore show only who was there.
  bool get canPredict => predictionApplies(
    eventAggregate.event.eventStartDatetimeGmt,
    DateTime.now().toUtc(),
  );

  static bool predictionApplies(DateTime startGmt, DateTime nowUtc) => startGmt
      .toUtc()
      .isAfter(nowUtc.subtract(const Duration(hours: predictGraceHours)));

  /// What the list shows now: the attendees, then (under All or Coming) the
  /// hashers who would earn an award if they came. Reads [filter], [awards]
  /// and [expected], so an Obx calling it tracks all three.
  List<DrinksResults> get visible =>
      visibleFor(filter.value, awards.toList(), expected.toList(), canPredict);

  static List<DrinksResults> visibleFor(
    AwardFilter f,
    List<DrinksResults> here,
    List<DrinksResults> due,
    bool predict,
  ) {
    final List<DrinksResults> out;
    if (!predict || f == AwardFilter.atHash) {
      out = <DrinksResults>[...here];
    } else if (f == AwardFilter.coming) {
      out = <DrinksResults>[
        ...here,
        ...due.where((DrinksResults d) => d.isComing),
      ];
    } else {
      out = <DrinksResults>[...here, ...due];
    }
    return byMostRuns(out);
  }

  /// Most runs on top (James, 2026-09-25) — the big milestones lead the
  /// circle — checked in and greyed-out together; haring count breaks a tie.
  /// Stable, so equal counts keep the queries' order.
  static List<DrinksResults> byMostRuns(List<DrinksResults> list) {
    final List<(int, DrinksResults)> indexed = <(int, DrinksResults)>[
      for (int i = 0; i < list.length; i++) (i, list[i]),
    ];
    indexed.sort(((int, DrinksResults) a, (int, DrinksResults) b) {
      int c = b.$2.totalRunsThisKennel.compareTo(a.$2.totalRunsThisKennel);
      if (c != 0) return c;
      c = b.$2.totalHaringThisKennel.compareTo(a.$2.totalHaringThisKennel);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return <DrinksResults>[for (final (_, DrinksResults d) in indexed) d];
  }

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

    final bool synced = await tableModel.syncEventAdminService
        .updateFromBackend(
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
    final List<DrinksResults> due = canPredict
        ? await _queryExpected()
        : const <DrinksResults>[];
    if (isClosed) return;

    awards.assignAll(found);
    expected.assignAll(due);
    isLoading.value = false;
    // updateFromBackend returns false when it could not reach the server. An
    // empty list after a FAILED sync is not evidence of no awards.
    loadFailed.value = !synced && found.isEmpty && due.isEmpty;
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
  ///
  /// [atRun] false marks the rows as hashers not checked in ([expected]).
  static List<DrinksResults> awardsFromRows(
    List<Map<String, dynamic>> rows, {
    bool atRun = true,
  }) {
    final List<DrinksResults> found = <DrinksResults>[];
    for (final Map<String, dynamic> row in rows) {
      final DrinksResults item = DrinksResults.fromMap(row, atRun: atRun);
      item.specialRunCount = Utilities.checkSpecialRun(
        item.totalRunsThisKennel,
      );
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
      BootLogger.logError('[DrinksList.awards] eventId=$_eventId', e, s);
      return const <DrinksResults>[];
    }
  }

  /// Hashers NOT checked in at this run whose next run here would earn an
  /// award (James, 2026-09-25). Who counts, from the kennel's members list and
  /// this run's RSVPs (both in the event domain, synced by [load]):
  /// - ran with this kennel in the last [activeWithinDays] days, or
  /// - RSVP'd Yes (3) or Maybe (2), or
  /// - is named as a hare on this run;
  /// - never someone who RSVP'd No (1).
  /// A first run (no runs yet) therefore needs an RSVP: every follower who has
  /// never come would otherwise be listed.
  ///
  /// Counts are the standing totals + 1 for this run (+1 haring only for a
  /// hare) — the same fallback [_queryAwards] uses when the nightly stamp is
  /// absent, which it always is for someone not checked in.
  Future<List<DrinksResults>> _queryExpected() => expectedAwards(
    database,
    eventId: _eventId,
    kennelId: eventAggregate.event.kennelId,
    nowUtc: DateTime.now().toUtc(),
  );

  /// [_queryExpected]'s query, static so a test can run it on an in-memory
  /// database (test/unit/drinks_expected_awards_test.dart).
  static Future<List<DrinksResults>> expectedAwards(
    Database db, {
    required String eventId,
    required String kennelId,
    required DateTime nowUtc,
  }) async {
    final hs = tableModel.hashersTableHelper;
    final hk = tableModel.hasherKennelMapTableHelper;
    final he = tableModel.hasherEventMapTableHelper;
    final String cutoff = nowUtc
        .subtract(const Duration(days: activeWithinDays))
        .toIso8601String();
    final String query =
        '''
        WITH ids AS (
          SELECT ${hk.colUserId} AS id FROM ${EnumDataTables.hasherKennelMap.eventTableName}
            WHERE ${hk.colKennelId} = ?
          UNION
          SELECT ${he.colUserId} AS id FROM ${EnumDataTables.hasherEventMap.eventTableName}
            WHERE ${he.colEventId} = ?
        )
        SELECT
          h.${hs.colHasherId},
          coalesce(
            hem.${he.colDisplayName},
            h.${hs.colDispName},
            h.${hs.colHashName},
            h.${hs.colFirstName} || ' ' || h.${hs.colLastName},'<no name>') as dispName,
          lower(' ' || coalesce(h.${hs.colHashName},'') || ' ' || coalesce(h.${hs.colDispName},'') || ' ' || coalesce(h.${hs.colFirstName},'') || ' ' || coalesce(h.${hs.colLastName},'') || ' ') as nameForSort,
          h.${hs.colPhoto},
          coalesce(hkm.${hk.colHcHaringCount},0)
            + coalesce(hkm.${hk.colHistoricalHaringCount},0)
            + case when hem.${he.colIsHare} = 1 then 1 else 0 end
            as totalHaringThisKennel,
          coalesce(hkm.${hk.colHcTotalRunCount},0)
            + coalesce(hkm.${hk.colHistoricalTotalRunCount},0) + 1
            as totalRunsThisKennel,
          hem.${he.colIsHare},
          hem.${he.colRsvpState}
        FROM ids
        INNER JOIN ${EnumDataTables.hashers.commonTableName} h ON h.${hs.colHasherId} = ids.id
        LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.eventTableName} hkm
          ON hkm.${hk.colUserId} = ids.id AND hkm.${hk.colKennelId} = ?
        LEFT OUTER JOIN ${EnumDataTables.hasherEventMap.eventTableName} hem
          ON hem.${he.colUserId} = ids.id AND hem.${he.colEventId} = ?
        WHERE coalesce(hem.${he.colAttendenceState}, 0) < 20
          AND coalesce(hem.${he.colRsvpState}, 0) <> 1
          AND (
            -- Active: a recent last run AND at least one run on record. A
            -- last-run date with 0 runs exists (a check-in that was undone);
            -- without the count it passed as "active" and read as a first run.
            (julianday(hkm.${hk.colDateOfLastRun}) >= julianday(?)
              AND coalesce(hkm.${hk.colHcTotalRunCount},0)
                + coalesce(hkm.${hk.colHistoricalTotalRunCount},0) > 0)
            OR hem.${he.colRsvpState} IN (2, 3)
            OR hem.${he.colIsHare} = 1
          )
          AND h.${hs.colRemoved} = 0
          AND h.${hs.colHashName} not like '👣 Anonymous%'
        ORDER BY totalHaringThisKennel, totalRunsThisKennel
        ''';
    try {
      final List<Map<String, dynamic>> rows = await db.rawQuery(query, <Object>[
        kennelId,
        eventId,
        kennelId,
        eventId,
        cutoff,
      ]);
      return awardsFromRows(rows, atRun: false);
    } catch (e, s) {
      BootLogger.logError('[DrinksList.expected] eventId=$eventId', e, s);
      return const <DrinksResults>[];
    }
  }
}
