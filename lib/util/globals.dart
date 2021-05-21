import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import 'package:ive_flutter_core/database/migrations.dart';
import 'package:ive_flutter_core/database/database.dart';
import 'package:ive_flutter_core/database/base_service.dart';

import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/database/query_kennels.dart';

import 'package:harrier_central/data/hc3_services/cities_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/data/hc3_services/regions_service.dart';
import 'package:harrier_central/data/hc3_services/receipts_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_kennel_map_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';

List<KennelListAggregate> globalKennelMainPageList;

num deviceWidthScaleFactor;
num deviceHeightScaleFactor;
num deviceMaxScaleFactor;
num deviceMinScaleFactor;

num deviceWidth;
num deviceHeight;

bool hasLocationPermissions = false;

DateTime appStartTime;

StreamSubscription<Position> geoLocationStream;
num deviceLat;
num deviceLon;

CitiesTableHelper citiesTableHelper;
CountriesTableHelper countriesTableHelper;
RegionsTableHelper regionsTableHelper;
ReceiptsTableHelper receiptsTableHelper;
PaymentsTableHelper paymentsTableHelper;
HashersTableHelper hashersTableHelper;
KennelCreditsTableHelper kennelCreditsTableHelper;
KennelsTableHelper kennelsTableHelper;
EventsTableHelper eventsTableHelper;
HasherEventMapTableHelper hasherEventMapTableHelper;
HasherKennelMapTableHelper hasherKennelMapTableHelper;

List<BaseTableHelper> userTables = <BaseTableHelper>[
  citiesTableHelper,
  countriesTableHelper,
  regionsTableHelper,
  paymentsTableHelper,
  hashersTableHelper,
  kennelsTableHelper,
  eventsTableHelper,
  hasherEventMapTableHelper,
  hasherKennelMapTableHelper,
];

BaseService baseService;
HashersService hashersService;
PaymentsService paymentsService;
EventsService eventsService;
HasherEventMapService hasherEventMapService;
HasherKennelMapService hasherKennelMapService;
SyncUserDataService syncUserDataService;
SyncKennelAdminService syncKennelAdminService;
SyncEventAdminService syncEventAdminService;

Database internalSqlDb;

Future<void> openOrInitializeDb(
    String dbName, int dbVersion, Function informUser,
    {@required List<MigrationsModel> migrations,
    @required Function createTables}) async {
  internalSqlDb = await DBProvider.openOrInitDb(
      DB_NAME, dbVersion, informUser, migrations,
      createTables: createTables);
}

void initializeGlobals() {
  citiesTableHelper = CitiesTableHelper();
  countriesTableHelper = CountriesTableHelper();
  regionsTableHelper = RegionsTableHelper();
  receiptsTableHelper = ReceiptsTableHelper();
  paymentsTableHelper = PaymentsTableHelper();
  hashersTableHelper = HashersTableHelper();
  kennelCreditsTableHelper = KennelCreditsTableHelper();
  kennelsTableHelper = KennelsTableHelper();
  eventsTableHelper = EventsTableHelper();
  hasherEventMapTableHelper = HasherEventMapTableHelper();
  hasherKennelMapTableHelper = HasherKennelMapTableHelper();

  baseService = BaseService();
  hashersService = HashersService();
  paymentsService = PaymentsService();
  eventsService = EventsService();
  hasherEventMapService = HasherEventMapService();
  hasherKennelMapService = HasherKennelMapService();

  syncUserDataService = SyncUserDataService();
  syncKennelAdminService = SyncKennelAdminService();
  syncEventAdminService = SyncEventAdminService();
}
