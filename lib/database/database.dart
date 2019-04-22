import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/cities_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/data/hc3_services/regions_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/sync_master_data_service.dart';
import 'package:harrier_central/util/constants.dart';

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

  Future<Database> initDB(Function informUser) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DB_NAME);
    return openDatabase(path, version: 1, onOpen: (Database db) {}, onCreate: (Database db, int version) async {
      await HashersTableHelper.createTable(db, version);
      await CitiesTableHelper.createTable(db, version);
      await RegionsTableHelper.createTable(db, version);
      await CountriesTableHelper.createTable(db, version);
      await KennelsTableHelper.createTable(db, version);
      await HasherKennelMapTableHelper.createTable(db, version);
      await HasherEventMapTableHelper.createTable(db, version);

      if (informUser != null) {
        informUser('Loading city data\r\n0% complete');
      }
      // first load the cities from the static text file into SQFLITE
      final String cityJson = await rootBundle.loadString('database/cities.json');
      final CitiesService citySrv = CitiesService();
      await citySrv.bulkUpdateDatabase(cityJson, db, informUser);

      if (informUser != null) {
        informUser('Loading region data\r\n0% complete');
      }
      // first load the regions from the static text file into SQFLITE
      final String regionJson = await rootBundle.loadString('database/regions.json');
      final RegionsService regionSrv = RegionsService();
      await regionSrv.bulkUpdateDatabase(regionJson, db, informUser);

      if (informUser != null) {
        informUser('Loading country data\r\n0% complete');
      }

      final String countriesJson = await rootBundle.loadString('database/countries.json');
      final CountriesService countriesSrv = CountriesService();
      await countriesSrv.bulkUpdateDatabase(countriesJson, db, informUser);

      if (informUser != null) {
        informUser('Updating from\r\ncloud back-end');
      }

      final SyncDataService cSrv = SyncDataService();
      final bool result = await cSrv.updateFromBackend(db, SyncDataService.flagsAllData, false);
      final String resultStr = result ? 'successfully' : 'unsuccessfully';
      print('Master data synchronized $resultStr');
    });
  }
}
