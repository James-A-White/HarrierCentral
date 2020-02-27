import 'dart:async';
import 'dart:io';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/notifications_table.dart';
import 'package:harrier_central/database/migrations.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/globals.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    // if _database is null we instantiate it
    _database = await initDB(null);
    return _database;
  }

  Future<bool> deleteDb() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DB_NAME);
    await deleteDatabase(path);

    return true;
  }

  // Future<bool> resetDb() async
  // {

  //   if (_database != null) {
  //     final Directory documentsDirectory = await getApplicationDocumentsDirectory();
  //     final String path = join(documentsDirectory.path, DB_NAME);
  //   }

  //   return true;
  // }

  Future<Database> initDB(Function informUser) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DB_NAME);
    return openDatabase(path, version: MigrationsTableHelper.dbVersion, 
      onOpen: (Database db) {
        // nothing happens in here
      }, 
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
          MigrationsTableHelper.doDatabaseMigrations(db,oldVersion, MigrationsTableHelper.dbVersion);
          await setIntPref(IntPrefsEnum.databaseVersion, MigrationsTableHelper.dbVersion);
      },
      onCreate: (Database db, int version) async {
        // create user tables
        await hashersTableHelper.createTable(db, version,null);
        await citiesTableHelper.createTable(db, version,null);
        await regionsTableHelper.createTable(db, version,null);
        await countriesTableHelper.createTable(db, version,null);
        await kennelsTableHelper.createTable(db, version,null);
        await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmUser);
        await hasherEventMapTableHelper.createTable(db, version, TableType.hemUser);
        await eventsTableHelper.createTable(db, version,null);
        await paymentsTableHelper.createTable(db, version,TableType.paymentsUser);
        await NotificationsTableHelper.createTable(db, version);
        await MigrationsTableHelper.createTable(db,version);

        // create event admin tables
        await hasherEventMapTableHelper.createTable(db, version, TableType.hemEventAdmin);
        await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmEventAdmin);
        await paymentsTableHelper.createTable(db, version,TableType.paymentsEvent);
        await receiptsTableHelper.createTable(db, version,null);
        await kennelCreditsTableHelper.createTable(db, version,null);

        // create kennel admin tables
        await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmKennelAdmin);

        if (informUser != null) {
          informUser('Loading city data\r\n0% complete');
        }
        // first load the cities from the static text file into SQFLITE
        final String cityJson = await rootBundle.loadString('database/cities.json');
        final BaseService citySrv = BaseService();
        await citySrv.bulkUpdateDatabase(citiesTableHelper,cityJson, db, informUser);

        if (informUser != null) {
          informUser('Loading region data\r\n0% complete');
        }
        // first load the regions from the static text file into SQFLITE
        final String regionJson = await rootBundle.loadString('database/regions.json');
        await baseService.bulkUpdateDatabase(regionsTableHelper,regionJson, db, informUser);

        if (informUser != null) {
          informUser('Loading country data\r\n0% complete');
        }

        final String countriesJson = await rootBundle.loadString('database/countries.json');
        await baseService.bulkUpdateDatabase(countriesTableHelper,countriesJson, db, informUser);

        final SyncUserDataService cSrv = SyncUserDataService();
        final bool result = await cSrv.updateFromBackend(db, SyncUserDataService.flagsAllData, false, informUser: informUser);
        final String resultStr = result ? 'successfully' : 'unsuccessfully';
        print('Master data synchronized $resultStr');
    });
  }
}
