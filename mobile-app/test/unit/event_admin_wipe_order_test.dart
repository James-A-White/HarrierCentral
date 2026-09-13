import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/sqflite_ffi_setup.dart';

/// The event domain is single-tenant, so moving to a different run clears the
/// previous one's rows. That wipe used to run BEFORE the fetch, so any
/// transient failure left the tables empty and adminEventId already advanced —
/// the screens showed nothing, and the NEXT visit skipped the wipe and quietly
/// worked. Barbados reported exactly that shape: an empty award list that
/// filled in on a second visit (2026-09-13).
///
/// app_boot_service had already learned this: "Wipe the local DB only once we
/// know we can repopulate it."
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initSqfliteFfi();

  late Database db;
  late SyncEventAdminService service;

  final Iterable<EnumDataTables> eventTables =
      EnumDataTables.values.where((EnumDataTables t) => t.hasEventTable);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initPrefs();

    Get.reset();
    Get.put(TableModel());

    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    Get.put<Database>(db);

    for (final EnumDataTables t in eventTables) {
      await t.helperFrom(tableModel).createTable(db, DB_VERSION, AppDomainType.event);
    }
    service = SyncEventAdminService();
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  Future<int> rowsIn(EnumDataTables t) async {
    final List<Map<String, Object?>> r =
        await db.rawQuery('SELECT COUNT(*) AS n FROM ${t.eventTableName}');
    return (r.first['n']! as int);
  }

  Future<void> seedOneRow() async {
    // hasherEventMap is the table the award list and the attendee list both
    // read, so it is the one whose loss the user actually notices.
    final HasherEventMapTableHelper h = tableModel.hasherEventMapTableHelper;
    await db.insert(EnumDataTables.hasherEventMap.eventTableName, <String, Object?>{
      h.colHemId: 'hem-1',
      h.colUserId: 'hasher-1',
      h.colEventId: 'event-A',
      h.colRsvpState: 3,
      h.colAttendenceState: 20,
      h.colIsHare: 0,
      h.colVirginVisitorType: 0,
      h.colEventStartDatetime: '2026-09-12 18:00:00',
      h.colEventStartDatetimeGmt: '2026-09-12 22:00:00',
      h.colRemoved: 0,
      h.colUpdatedAt: '2026-09-13 12:00:00',
    });
  }

  test('a same-event refresh never wipes, so a failed fetch costs nothing',
      () async {
    await seedOneRow();
    final bool wiped = await service.wipeIfSafe(
      db,
      eventChanged: false,
      eventId: 'event-A',
    );
    expect(wiped, isFalse);
    expect(await rowsIn(EnumDataTables.hasherEventMap), 1,
        reason: 'returning to the same run must not clear it');
  });

  test('changing event wipes — but only when it is actually called', () async {
    await seedOneRow();
    final bool wiped = await service.wipeIfSafe(
      db,
      eventChanged: true,
      eventId: 'event-B',
    );
    expect(wiped, isTrue);
    expect(await rowsIn(EnumDataTables.hasherEventMap), 0);
  });

  test('a wipe advances adminEventId; a skipped wipe does not', () async {
    await setStringPref(StringPrefsEnum.adminEventId, 'event-A');

    await service.wipeIfSafe(db, eventChanged: false, eventId: 'event-B');
    expect(getStringPref(StringPrefsEnum.adminEventId), 'event-A',
        reason: 'no wipe means the recorded event must not move either — '
            'otherwise the next visit thinks empty tables are current');

    await service.wipeIfSafe(db, eventChanged: true, eventId: 'event-B');
    expect(getStringPref(StringPrefsEnum.adminEventId), 'event-B');
  });

  test('every event-domain table is cleared, not just the obvious one',
      () async {
    await seedOneRow();
    await service.wipeIfSafe(db, eventChanged: true, eventId: 'event-B');
    for (final EnumDataTables t in eventTables) {
      expect(await rowsIn(t), 0, reason: '${t.eventTableName} left behind');
    }
  });
}
