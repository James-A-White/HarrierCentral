// @dart=2.11
import 'package:harrier_central/imports.dart';

enum AppDomainType { user, event, kennel }
//enum TableType { baseTable, hemUser, hemEventAdmin, hkmUser, hkmEventAdmin, hkmKennelAdmin, paymentsUser, paymentsEvent }

class Tables {
  // the variable below is there to suppress a warning about defining classes with only static members
  int unusedVariableToSuppressWarning;

  // static String getTableName(BaseTableHelper tableHelper, {AppDomainType appDomainType}) {
  //   String tableName = tableHelper.tableName;
  //   if (tableType != null) {
  //     switch (tableType) {
  //       case TableType.baseTable:
  //         // don't change the string, keep it as it was initialized above
  //         break;
  //       case TableType.hemEventAdmin:
  //         tableName = hemAdminTable;
  //         break;
  //       case TableType.hemUser:
  //         tableName = hemUserTable;
  //         break;
  //       case TableType.hkmUser:
  //         tableName = hkmUserTable;
  //         break;
  //       case TableType.hkmEventAdmin:
  //         tableName = hkmEventAdminTable;
  //         break;
  //       case TableType.hkmKennelAdmin:
  //         tableName = hkmKennelAdminTable;
  //         break;
  //       case TableType.paymentsEvent:
  //         tableName = eventPaymentsTable;
  //         break;
  //       case TableType.paymentsUser:
  //         tableName = userPaymentsTable;
  //         break;
  //       default:
  //         // this will cause a SQL error and help us debug, should put a debug assert here
  //         assert(false);
  //         tableName = '';
  //         break;
  //     }
  //   }

  //   return tableName;
  // }

  // *****************
  // DB migrations & version

  static List<MigrationsModel> migrationList = <MigrationsModel>[
    // MIGRATION 270
    MigrationsModel(
        dbVersion: 351,
        migrationText: ''' 
      ALTER TABLE ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().regionsTableHelper.colRegionAbbreviation} TEXT;
    ''',
        appliedAtInt: 0),

    MigrationsModel(
        dbVersion: 352,
        migrationText: ''' 
      ALTER TABLE ${G0<TableModel>().citiesTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().citiesTableHelper.colCitySearchTags} TEXT;
      ALTER TABLE ${G0<TableModel>().regionsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().regionsTableHelper.colRegionSearchTags} TEXT;
      ALTER TABLE ${G0<TableModel>().countriesTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().countriesTableHelper.colCountrySearchTags} TEXT;
      ALTER TABLE ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().kennelsTableHelper.colKennelSearchTags} TEXT;
    ''',
        appliedAtInt: 0),

    MigrationsModel(
        dbVersion: 365,
        migrationText: ''' 
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount} INT;

      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;

      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${G0<TableModel>().hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

    ''',
        appliedAtInt: 0),

    MigrationsModel(
        dbVersion: 366,
        migrationText: ''' 
      ALTER TABLE ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().eventsTableHelper.colEventUrl} TEXT;
      
      ALTER TABLE ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().kennelsTableHelper.colIntegrationType} TEXT;
      ALTER TABLE ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().kennelsTableHelper.colInboundIntegrationId} INT;
      ALTER TABLE ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${G0<TableModel>().kennelsTableHelper.colKennelEventsUrl} TEXT;

      ''',
        appliedAtInt: 0),

    // // MIGRATION 222
    // MigrationsModel(dbVersion: 222, migrationText: '''
    //         ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
    //         ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
    //         ALTER TABLE ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${G0<TableModel>().hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
    //      '''),
  ];

  static Future<void> createTables(Database db, int version, Function informUser) async {
    await G0<TableModel>().hashersTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().citiesTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().regionsTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().countriesTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().kennelsTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().hasherKennelMapTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().hasherEventMapTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().eventsTableHelper.createTable(db, version, AppDomainType.user);
    await G0<TableModel>().paymentsTableHelper.createTable(db, version, AppDomainType.user);
    await NotificationsTableHelper.createTable(db, version);
    await MigrationsTableHelper.createTable(db, version);

    // create event admin tables
    await G0<TableModel>().hasherEventMapTableHelper.createTable(db, version, AppDomainType.event);
    await G0<TableModel>().hasherKennelMapTableHelper.createTable(db, version, AppDomainType.event);
    await G0<TableModel>().paymentsTableHelper.createTable(db, version, AppDomainType.event);
    await G0<TableModel>().receiptsTableHelper.createTable(db, version, AppDomainType.event);
    await G0<TableModel>().kennelCreditsTableHelper.createTable(db, version, AppDomainType.event);

    // create kennel admin tables
    await G0<TableModel>().hasherKennelMapTableHelper.createTable(db, version, AppDomainType.kennel);
  }

  static Future<void> createIndexes(Database db, int version, Function informUser, String clientAppIdentifier) async {
    await G0<TableModel>().hashersTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().citiesTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().regionsTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().countriesTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().kennelsTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().hasherKennelMapTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().hasherEventMapTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().eventsTableHelper.createIndexes(db, version, AppDomainType.user);
    await G0<TableModel>().paymentsTableHelper.createIndexes(db, version, AppDomainType.user);

    // create event admin tables
    await G0<TableModel>().hasherEventMapTableHelper.createIndexes(db, version, AppDomainType.event);
    await G0<TableModel>().hasherKennelMapTableHelper.createIndexes(db, version, AppDomainType.event);
    await G0<TableModel>().paymentsTableHelper.createIndexes(db, version, AppDomainType.event);
    await G0<TableModel>().receiptsTableHelper.createIndexes(db, version, AppDomainType.event);
    await G0<TableModel>().kennelCreditsTableHelper.createIndexes(db, version, AppDomainType.event);

    // create kennel admin tables
    await G0<TableModel>().hasherKennelMapTableHelper.createIndexes(db, version, AppDomainType.kennel);
  }
}
