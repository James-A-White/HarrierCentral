import 'package:harrier_central/imports.dart';

/// The kennel catalogue on the phone (3.1): run packages, memberships,
/// haberdashery — what is on sale, what it costs, and what promotional
/// credit it grants.
///
/// GLOBAL, like songs and kennels: every kennel's products reach every
/// phone. The data is small, and scoping to followed kennels would orphan
/// the product behind a hasher's own past payment the moment they
/// unfollowed (James, 2026-09-13).
class ProductsTableHelper extends BaseTableHelper<AppDomainType>
    with BaseFields {
  ProductsTableHelper() {
    remoteDbId = 'productId';
    humanReadableTableName = 'Products';
    pageSize = SyncUserDataService.pageSize_productsTable;
    tableFlag = EnumDataTables.products.flag;
  }

  @override
  String getTableName(AppDomainType appDomainType) {
    String tableName;
    switch (appDomainType) {
      case AppDomainType.user:
        tableName = EnumDataTables.products.commonTableName;
        break;
      default:
        throw Exception(
          'EnumDataTables.${EnumDataTables.products.name} does not have a table associated with it.',
        );
    }
    return tableName;
  }

  final String colProductId = 'productId';
  final String colKennelId = 'kennelId';
  final String colProductType = 'productType';
  final String colName = 'name';
  final String colDescription = 'description';
  final String colPriceCharged = 'priceCharged';
  final String colPromotionalCredit = 'promotionalCredit';
  final String colUnitCost = 'unitCost';
  final String colRunCount = 'runCount';
  final String colIsActive = 'isActive';
  final String colSortOrder = 'sortOrder';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colProductId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colProductType INT NOT NULL,
            $colName TEXT NOT NULL,
            $colDescription TEXT,
            $colPriceCharged REAL NOT NULL,
            $colPromotionalCredit REAL NOT NULL,
            $colUnitCost REAL NOT NULL,
            $colRunCount INT,
            $colIsActive INT NOT NULL,
            $colSortOrder INT NOT NULL,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      // UNIQUE from the start (3.1): every synced table now carries a unique
      // constraint on the server id, so two overlapping applies cannot both
      // insert the same row. See BaseService.bulkUpdateDatabase, which does
      // INSERT OR REPLACE so the conflict heals instead of throwing.
      'CREATE UNIQUE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
    // The shop reads one kennel's catalogue at a time.
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_kennel ON ${getTableName(appDomainType)}($colKennelId, $colIsActive);',
    );
  }
}
