import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/sqflite_ffi_setup.dart';

/// "Drink chug-a-lug" under All: who is NOT checked in but would earn an award
/// if they came (James, 2026-09-25). Runs the real query on the real table
/// schemas, in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initSqfliteFfi();

  const String kennel = 'kennel-1';
  const String event = 'event-1';
  final DateTime now = DateTime.utc(2026, 9, 25, 12);
  final String recent = now
      .subtract(const Duration(days: 30))
      .toIso8601String();
  final String longAgo = now
      .subtract(const Duration(days: 800))
      .toIso8601String();

  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initPrefs();
    Get.reset();
    Get.put(TableModel());
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    Get.put<Database>(db);
    await EnumDataTables.hashers
        .helperFrom(tableModel)
        .createTable(db, DB_VERSION, AppDomainType.user);
    for (final EnumDataTables t in <EnumDataTables>[
      EnumDataTables.hasherKennelMap,
      EnumDataTables.hasherEventMap,
    ]) {
      await t
          .helperFrom(tableModel)
          .createTable(db, DB_VERSION, AppDomainType.event);
    }
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  /// Inserts [values], filling every other NOT NULL column with 0 / ''.
  Future<void> insert(String table, Map<String, Object?> values) async {
    final List<Map<String, Object?>> cols = await db.rawQuery(
      'PRAGMA table_info($table)',
    );
    final Map<String, Object?> row = <String, Object?>{};
    for (final Map<String, Object?> c in cols) {
      final String name = c['name']! as String;
      if (values.containsKey(name)) {
        row[name] = values[name];
      } else if (c['notnull'] == 1) {
        row[name] = (c['type'] as String).toUpperCase() == 'TEXT' ? '' : 0;
      }
    }
    await db.insert(table, row);
  }

  Future<void> hasher(String id, {int removed = 0, String? hashName}) =>
      insert(EnumDataTables.hashers.commonTableName, <String, Object?>{
        'hasherId': id,
        'dispName': id,
        'hashName': hashName ?? id,
        'removed': removed,
      });

  Future<void> member(
    String id, {
    int runs = 0,
    int historical = 0,
    int haring = 0,
    String? lastRun,
  }) => insert(EnumDataTables.hasherKennelMap.eventTableName, <String, Object?>{
    'hkmId': 'hkm-$id',
    'userId': id,
    'kennelId': kennel,
    'hcTotalRunCount': runs,
    'historicalTotalRunCount': historical,
    'hcHaringCount': haring,
    'dateOfLastRun': lastRun,
  });

  Future<void> onRun(
    String id, {
    int rsvp = 0,
    int attendance = 0,
    int isHare = 0,
  }) => insert(EnumDataTables.hasherEventMap.eventTableName, <String, Object?>{
    'hemId': 'hem-$id',
    'userId': id,
    'eventId': event,
    'rsvpState': rsvp,
    'attendenceState': attendance,
    'isHare': isHare,
  });

  Future<Map<String, DrinksResults>> expected() async {
    final List<DrinksResults> out = await DrinksListController.expectedAwards(
      db,
      eventId: event,
      kennelId: kennel,
      nowUtc: now,
    );
    return <String, DrinksResults>{
      for (final DrinksResults a in out) a.hasherId: a,
    };
  }

  test(
    'a recently active hasher one short of a milestone is listed, greyed',
    () async {
      await hasher('ninetyNine');
      await member('ninetyNine', runs: 90, historical: 9, lastRun: recent);
      await hasher('seven');
      await member('seven', runs: 6, lastRun: recent);

      final Map<String, DrinksResults> out = await expected();
      expect(out.keys, <String>['ninetyNine']);
      expect(out['ninetyNine']!.totalRunsThisKennel, 100);
      expect(out['ninetyNine']!.specialRunCount, specialRun100);
      expect(out['ninetyNine']!.atRun, isFalse);
    },
  );

  test('not active in the last year: left out unless they RSVP', () async {
    await hasher('lapsed');
    await member('lapsed', runs: 24, lastRun: longAgo);
    await hasher('lapsedButComing');
    await member('lapsedButComing', runs: 49, lastRun: longAgo);
    await onRun('lapsedButComing', rsvp: 2); // Maybe

    final Map<String, DrinksResults> out = await expected();
    expect(out.keys, <String>['lapsedButComing']);
  });

  test('a first run needs an RSVP; an RSVP of No is never listed', () async {
    await hasher('follower'); // follows, never ran
    await member('follower');
    await hasher('newbie'); // RSVP'd, no kennel row at all
    await onRun('newbie', rsvp: 3);
    await hasher('notComing');
    await member('notComing', runs: 9, lastRun: recent);
    await onRun('notComing', rsvp: 1);

    final Map<String, DrinksResults> out = await expected();
    expect(out.keys, <String>['newbie']);
    expect(out['newbie']!.specialRunCount, specialRunFirstRun);
  });

  test('a recent last-run date with 0 runs is not "active"', () async {
    // Seen on the Test Kennel 2026-09-25: "Placeholder user", 0 runs, a
    // last-run date in June — listed as a first run with no RSVP.
    await hasher('placeholder');
    await member('placeholder', lastRun: recent);

    expect(await expected(), isEmpty);
  });

  test('checked-in hashers are not "expected"', () async {
    await hasher('here');
    await member('here', runs: 4, lastRun: recent);
    await onRun('here', attendance: 20);

    expect(await expected(), isEmpty);
  });

  test('a named hare not yet checked in shows the haring milestone', () async {
    await hasher('hare');
    await member('hare', runs: 30, haring: 4, lastRun: longAgo);
    await onRun('hare', isHare: 1);

    final Map<String, DrinksResults> out = await expected();
    expect(out['hare']!.totalHaringThisKennel, 5);
    expect(out['hare']!.specialHaringCount, specialRunFifthRun);
  });

  test('removed and anonymous hashers are never listed', () async {
    await hasher('gone', removed: 1);
    await member('gone', runs: 99, lastRun: recent);
    await hasher('anon', hashName: '👣 Anonymous 12');
    await member('anon', runs: 99, lastRun: recent);

    expect(await expected(), isEmpty);
  });

  group('predictionApplies', () {
    test('upcoming and today (within the grace hours) yes; past no', () {
      expect(
        DrinksListController.predictionApplies(
          now.add(const Duration(days: 3)),
          now,
        ),
        isTrue,
      );
      expect(
        DrinksListController.predictionApplies(
          now.subtract(const Duration(hours: 3)),
          now,
        ),
        isTrue,
      );
      expect(
        DrinksListController.predictionApplies(
          now.subtract(const Duration(days: 2)),
          now,
        ),
        isFalse,
      );
    });
  });
}
