import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:harrier_central/util/constants.dart';
import 'package:ive_flutter_core/base_service.dart';

import 'package:ive_flutter_core/migrations.dart';
import 'package:harrier_central/util/globals.dart';

import 'package:harrier_central/database/notifications_table.dart';

class Tables {
  static String getTableName(BaseTableHelper tableHelper, {TableType tableType}) {
    String tableName = tableHelper.tableName;
    if (tableType != null) {
      switch (tableType) {
        case TableType.baseTable:
          // don't change the string, keep it as it was initialized above
          break;
        case TableType.hemEventAdmin:
          tableName = hemAdminTable;
          break;
        case TableType.hemUser:
          tableName = hemUserTable;
          break;
        case TableType.hkmUser:
          tableName = hkmUserTable;
          break;
        case TableType.hkmEventAdmin:
          tableName = hkmEventAdminTable;
          break;
        case TableType.hkmKennelAdmin:
          tableName = hkmKennelAdminTable;
          break;
        case TableType.paymentsEvent:
          tableName = eventPaymentsTable;
          break;
        case TableType.paymentsUser:
          tableName = userPaymentsTable;
          break;
        default:
          // this will cause a SQL error and help us debug, should put a debug assert here
          assert(false);
          tableName = '';
          break;
      }
    }

    return tableName;
  }

  // *****************
  // DB migrations & version

  static List<MigrationsModel> migrationList = <MigrationsModel>[
    // MIGRATION 221
    MigrationsModel(dbVersion: 221, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colHomeKennelId} TEXT;
         '''),

    // MIGRATION 222
    MigrationsModel(dbVersion: 222, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 223
    MigrationsModel(dbVersion: 223, migrationText: '''
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} ADD COLUMN ${hasherEventMapTableHelper.colEventEmailAlertPreference} INT;
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 224
    MigrationsModel(dbVersion: 224, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPriceForExtras} NUM;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colExtrasDescription} TEXT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colDoTrackHashCash} INT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelMismanagementTeam} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colDistancePreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colIncludeInGlobalHashDirectory} INT;
            ALTER TABLE ${countriesTableHelper.tableName} ADD COLUMN ${countriesTableHelper.colDistancePreference} INT NOT NULL DEFAULT 0;
         '''),

    // MIGRATION 225
    MigrationsModel(dbVersion: 225, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colPreferences} INT;
         '''),

    // MIGRATION 226
    MigrationsModel(dbVersion: 226, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
         '''),

    // MIGRATION 227
    MigrationsModel(dbVersion: 227, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colDoPayForExtras} INT;
         '''),

    // MIGRATION 228
    MigrationsModel(dbVersion: 228, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags1} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags2} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags3} INT;
         '''),

    MigrationsModel(dbVersion: 229, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires3} TEXT;
         '''),

    MigrationsModel(dbVersion: 230, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge3} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge3} NUM;
         '''),

    MigrationsModel(dbVersion: 231, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colAllowSelfPayment} INT;
         '''),

    MigrationsModel(dbVersion: 232, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colSurcharge} INT;
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colPaymentProvider} INT;
         '''),

    MigrationsModel(dbVersion: 251, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationCountry} TEXT;
         '''),

    MigrationsModel(dbVersion: 252, migrationText: '''
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationRegion} TEXT;
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationSubRegion} TEXT;         
         '''),

    MigrationsModel(dbVersion: 253, migrationText: '''
                  ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPinColor} INT;    
         '''),

    MigrationsModel(dbVersion: DB_VERSION, migrationText: '''
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventGeographicScope} INT;          
         '''),
  ];

  static Future<void> createTables(Database db, int version, Function informUser) async {
    await hashersTableHelper.createTable(db, version, null);
    await citiesTableHelper.createTable(db, version, null);
    await regionsTableHelper.createTable(db, version, null);
    await countriesTableHelper.createTable(db, version, null);
    await kennelsTableHelper.createTable(db, version, null);
    await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmUser);
    await hasherEventMapTableHelper.createTable(db, version, TableType.hemUser);
    await eventsTableHelper.createTable(db, version, null);
    await paymentsTableHelper.createTable(db, version, TableType.paymentsUser);
    await NotificationsTableHelper.createTable(db, version);
    await MigrationsTableHelper.createTable(db, version);

    // create event admin tables
    await hasherEventMapTableHelper.createTable(db, version, TableType.hemEventAdmin);
    await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmEventAdmin);
    await paymentsTableHelper.createTable(db, version, TableType.paymentsEvent);
    await receiptsTableHelper.createTable(db, version, null);
    await kennelCreditsTableHelper.createTable(db, version, null);

    // create kennel admin tables
    await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmKennelAdmin);

    if (informUser != null) {
      informUser('Loading city data\r\n0% complete');
    }
    // first load the cities from the static text file into SQFLITE
    final String cityJson = await rootBundle.loadString('database/cities.json');
    final BaseService citySrv = BaseService();
    await citySrv.bulkUpdateDatabase(
      citiesTableHelper,
      Tables.getTableName(citiesTableHelper),
      cityJson,
      db,
      informUser: informUser,
    );

    if (informUser != null) {
      informUser('Loading region data\r\n0% complete');
    }
    // first load the regions from the static text file into SQFLITE
    final String regionJson = await rootBundle.loadString('database/regions.json');
    await baseService.bulkUpdateDatabase(
      regionsTableHelper,
      Tables.getTableName(regionsTableHelper),
      regionJson,
      db,
      informUser: informUser,
    );

    if (informUser != null) {
      informUser('Loading country data\r\n0% complete');
    }

    final String countriesJson = await rootBundle.loadString('database/countries.json');
    await baseService.bulkUpdateDatabase(
      countriesTableHelper,
      Tables.getTableName(countriesTableHelper),
      countriesJson,
      db,
      informUser: informUser,
    );
  }
}
