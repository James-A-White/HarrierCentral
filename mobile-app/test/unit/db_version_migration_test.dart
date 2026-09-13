import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';

/// DB_VERSION and Tables.migrationList must agree.
///
/// This invariant was enforced ONLY at runtime, by a guard in
/// MainNavigationPageController that runs after boot and after login. So
/// bumping DB_VERSION without adding a migration record passed analyze, passed
/// every test, built, signed, uploaded and installed — and then showed testers
/// "Database Version Mismatch" and stopped the app dead. That is a developer
/// mistake being caught on a user's device, two builds and an hour of Apple
/// processing too late (James, 2026-09-13).
///
/// These tests move the invariant to where it belongs: they fail the moment
/// DB_VERSION changes without its record, before anything is built.
void main() {
  // migrationList's initialiser builds SQL from tableModel, which is a
  // Get.find. Registering the service is all the setup these tests need — no
  // database, no platform channels.
  setUpAll(() => Get.put(TableModel()));
  tearDownAll(Get.reset);

  test('DB_VERSION has a migration record', () {
    final Iterable<int> versions = Tables.migrationList.map(
      (dynamic m) => m.dbVersion as int,
    );
    expect(
      versions,
      contains(DB_VERSION),
      reason:
          'DB_VERSION is $DB_VERSION with no MigrationsModel for it. Add one '
          'to Tables.migrationList — empty migrationText is fine when the jump '
          'is ten or more, since those devices wipe and reload instead.',
    );
  });

  test('DB_VERSION is the HIGHEST migration record', () {
    final List<int> versions =
        Tables.migrationList.map((dynamic m) => m.dbVersion as int).toList()
          ..sort();
    expect(
      versions.last,
      DB_VERSION,
      reason:
          'The guard compares DB_VERSION against the LAST record after '
          'sorting, so a record numbered above DB_VERSION blocks the app just '
          'as surely as a missing one.',
    );
  });

  test('no two migrations share a version number', () {
    final List<int> versions = Tables.migrationList
        .map((dynamic m) => m.dbVersion as int)
        .toList();
    expect(
      versions.length,
      versions.toSet().length,
      reason: 'A duplicate dbVersion makes which migration ran ambiguous.',
    );
  });
}
