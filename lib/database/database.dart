import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:harrier_central/services/all_hashers_service.dart';
import 'package:harrier_central/services/cities_service.dart';
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
    _database = await initDB();
    return _database;
  }

  Future<Database> initDB() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, DB_NAME);
    return openDatabase(path, version: 1, onOpen: (Database db) {},
        onCreate: (Database db, int version) async {
      await AllHashersTableHelper.createTable(db, version);
      await CitiesTableHelper.createTable(db, version);

      final String json = await rootBundle.loadString('database/cities.json');
      final CitiesService srv = CitiesService();
      await srv.bulkUpdateDatabase(json,db);
    });
  }
}
