import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/sqflite_ffi_setup.dart';

/// The products table is new in 3.1 and carries the unique constraint that
/// the whole DB_VERSION 540 reload exists to install.
void main() {
  initSqfliteFfi();

  late Database db;
  final ProductsTableHelper helper = ProductsTableHelper();
  final String table = EnumDataTables.products.commonTableName;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await helper.createTable(db, 540, AppDomainType.user);
    await helper.createIndexes(db, 540, AppDomainType.user);
  });

  tearDown(() async => db.close());

  Map<String, Object?> row(String productId, {String name = 'Run package'}) =>
      <String, Object?>{
        helper.colProductId: productId,
        helper.colKennelId: 'kennel-1',
        helper.colProductType: 4,
        helper.colName: name,
        helper.colPriceCharged: 70.0,
        helper.colPromotionalCredit: 7.0,
        helper.colUnitCost: 0.0,
        helper.colIsActive: 1,
        helper.colSortOrder: 0,
        helper.colRemoved: 0,
        helper.colUpdatedAt: '2026-09-13 12:00:00',
      };

  test('the server id is unique — a second insert cannot duplicate it',
      () async {
    await db.insert(table, row('p1'));
    expect(
      () async => db.insert(table, row('p1', name: 'Duplicate')),
      throwsA(isA<DatabaseException>()),
      reason: 'without this the double-insert race duplicates rows silently',
    );
    expect((await db.query(table)).length, 1);
  });

  test('INSERT OR REPLACE heals the race instead of throwing', () async {
    await db.insert(table, row('p1'));
    // What BaseService.bulkUpdateDatabase now does when its pre-scan missed a
    // row another apply inserted meanwhile.
    await db.insert(
      table,
      row('p1', name: 'Fresher server copy'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final List<Map<String, Object?>> rows = await db.query(table);
    expect(rows.length, 1, reason: 'one product, not two');
    expect(rows.first[helper.colName], 'Fresher server copy');
  });

  test('two different products coexist', () async {
    await db.insert(table, row('p1'));
    await db.insert(table, row('p2', name: 'Away weekend'));
    expect((await db.query(table)).length, 2);
  });
}
