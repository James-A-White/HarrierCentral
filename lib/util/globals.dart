import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';

// Ambient variable to access the service locator
// NOTE: I've given this variable a very unique name even if it is against normal
// DART style conventions.

// ignore: non_constant_identifier_names
final GetIt G0 = GetIt.instance;

Future<void> setupLocalServices(num deviceWidth, num deviceHeight) async {
  G0.registerSingleton<AppModel>(AppModel());
  G0.registerSingletonAsync<DeviceInfo>(() async {
    final DeviceInfo deviceInfo = DeviceInfo();
    await deviceInfo.init(deviceWidth, deviceHeight);
    return deviceInfo;
  });

  _initTables();
}

void _initTables() {
  if (G0.isRegistered<TableModel>()) {
    G0.unregister<TableModel>();
  }
  G0.registerSingleton<TableModel>(TableModel());
  G0<TableModel>().initializeGlobals();

  G0<TableModel>().tablesForRemoteSync = <BaseTableHelper>[
    G0<TableModel>().citiesTableHelper,
    G0<TableModel>().countriesTableHelper,
    G0<TableModel>().regionsTableHelper,
    G0<TableModel>().receiptsTableHelper,
    G0<TableModel>().paymentsTableHelper,
    G0<TableModel>().hashersTableHelper,
    G0<TableModel>().kennelCreditsTableHelper,
    G0<TableModel>().kennelsTableHelper,
    G0<TableModel>().eventsTableHelper,
    G0<TableModel>().hasherEventMapTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper
  ];
}

bool _createIndexes = false;

Future<void> setupDatabase(
    Function informUser, String clientAppIdentifier) async {
  G0.registerSingletonAsync<Database>(() async {
    _initTables();
    return DBProvider.openOrInitDb(
      DB_NAME,
      DB_VERSION,
      informUser,
      Tables.migrationList,
      createTables: _createTables,
      openDb: _openDb,
      clientAppIdentifier: clientAppIdentifier,
    );
  });

  G0.isReady<Database>().then((void dummy) async {
    await G0<TableModel>().syncUserDataService.updateFromBackend(
        SyncUserDataService.flagsAllData, false,
        informUser: informUser);
    if (_createIndexes) {
      await Tables.createIndexes(
          G0<Database>(), DB_VERSION, informUser, clientAppIdentifier);
      await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);
      await setBoolPref(BoolPrefsEnum.dbCreated, true);
    }
  });
}

Future<void> _openDb(
    dynamic db, Function informUser, String clientAppIdentifier) async {}

Future<void> _createTables(dynamic db, int version, Function informUser,
    String clientAppIdentifier) async {
  await Tables.createTables(db, version, informUser);
  _createIndexes = true;
}

class AppModel {
  AppModel();
  EnumConnectionStatus connectionStatus = EnumConnectionStatus.not_connected;
  StreamSubscription<Position> geoLocationStream;
  DateTime appStartTime;

  bool hasLocationPermissions = false;

  // TODO(DevTeam): Make sure this is eventually called
  void dispose() {
    geoLocationStream.cancel();
  }
}

class TableModel {
  TableModel();

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

  SyncUserDataService syncUserDataService;
  SyncKennelAdminService syncKennelAdminService;
  SyncEventAdminService syncEventAdminService;

  BaseService baseService;

  HashersService hashersService;
  PaymentsService paymentsService;
  EventsService eventsService;
  HasherEventMapService hasherEventMapService;
  HasherKennelMapService hasherKennelMapService;

  List<KennelListAggregate> globalKennelMainPageList = <KennelListAggregate>[];

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

    //
    syncUserDataService = SyncUserDataService();
    syncKennelAdminService = SyncKennelAdminService();
    syncEventAdminService = SyncEventAdminService();

    baseService = BaseService();
    hashersService = HashersService();
    paymentsService = PaymentsService();
    eventsService = EventsService();
    hasherEventMapService = HasherEventMapService();
    hasherKennelMapService = HasherKennelMapService();
  }

  List<BaseTableHelper> tablesForRemoteSync;
}

class DeviceInfo {
  DeviceInfo();

  IosDeviceInfo iosInfo;
  AndroidDeviceInfo androidInfo;

  String deviceId = 'unknown';
  String deviceType = 'unknown';
  String deviceName = 'unknown';
  String systemName = 'unknown';
  String systemVersion = 'unknown';
  String manufacturer = 'unknown';

  num deviceWidthScaleFactor;
  num deviceHeightScaleFactor;
  num deviceMaxScaleFactor;
  num deviceMinScaleFactor;
  num deviceWidth;
  num deviceHeight;
  num deviceLat;
  num deviceLon;

  // a flag to indicate if we are running in the simulator
  bool isPhysicalDevice = true;
  bool get supportsCamera => Platform.isAndroid || isPhysicalDevice;

  Future<void> init(num deviceWidth, num deviceHeight) async {
    deviceWidth = deviceWidth;
    deviceHeight = deviceHeight;
    deviceWidthScaleFactor = deviceWidth / BASE_DEVICE_WIDTH;
    deviceHeightScaleFactor = deviceHeight / BASE_DEVICE_HEIGHT;
    deviceMaxScaleFactor = max(deviceWidthScaleFactor, deviceHeightScaleFactor);
    deviceMinScaleFactor = min(deviceWidthScaleFactor, deviceHeightScaleFactor);

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.androidId.toUpperCase();
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion =
          '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch}';
      manufacturer = androidInfo.brand;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toUpperCase();
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }
  }

//   void initializeGlobals() {
//   G0<TableModel>().citiesTableHelper = CitiesTableHelper();
//   G0<TableModel>().countriesTableHelper = CountriesTableHelper();
//   G0<TableModel>().regionsTableHelper = RegionsTableHelper();
//   G0<TableModel>().receiptsTableHelper = ReceiptsTableHelper();
//   G0<TableModel>().paymentsTableHelper = PaymentsTableHelper();
//   G0<TableModel>().hashersTableHelper = HashersTableHelper();
//   G0<TableModel>().kennelCreditsTableHelper = KennelCreditsTableHelper();
//   G0<TableModel>().kennelsTableHelper = KennelsTableHelper();
//   G0<TableModel>().eventsTableHelper = EventsTableHelper();
//   G0<TableModel>().hasherEventMapTableHelper = HasherEventMapTableHelper();
//   G0<TableModel>().hasherKennelMapTableHelper = HasherKennelMapTableHelper();

//   G0<TableModel>().baseService = BaseService();
//   hashersService = HashersService();

//   G0<TableModel>().syncUserDataService = SyncUserDataService();
//   G0<TableModel>().syncKennelAdminService = SyncKennelAdminService();
//   G0<TableModel>().syncEventAdminService = SyncEventAdminService();
// }

}

// // Ambient variable to access the service locator
// // NOTE: I've given this variable a very unique name even if it is against normal
// // DART style conventions.

// // ignore: non_constant_identifier_names
// final GetIt G0 = GetIt.instance;

// class AppModel {
//   AppModel();
//   EnumConnectionStatus connectionStatus = EnumConnectionStatus.not_connected;
//   StreamSubscription<Position> geoLocationStream;
//   DateTime appStartTime;

//   // TODO(DevTeam): Make sure this is eventually called
//   void dispose() {
//     geoLocationStream.cancel();
//   }
// }

// Future<void> setupLocalServices(num G0<DeviceInfo>().deviceWidth, num G0<DeviceInfo>().deviceHeight) async {
//   G0.registerSingleton<AppModel>(AppModel());
//   // G0.registerSingletonAsync<DeviceInfo>(() async {
//   //   final DeviceInfo deviceInfo = DeviceInfo();
//   //   await deviceInfo.init(G0<DeviceInfo>().deviceWidth, G0<DeviceInfo>().deviceHeight);
//   //   return deviceInfo;
//   // });

//   // G0.registerSingleton<HelperMapsModel>(HelperMapsModel());
//   // G0<HelperMapsModel>().init();

//   _initTables();
// }

// // NEEDS MIGRATION

// List<KennelListAggregate> G0<TableModel>().globalKennelMainPageList;

// num G0<DeviceInfo>().deviceWidthScaleFactor;
// num G0<DeviceInfo>().deviceHeightScaleFactor;
// num G0<DeviceInfo>().deviceMaxScaleFactor;
// num G0<DeviceInfo>().deviceMinScaleFactor;

// num G0<DeviceInfo>().deviceWidth;
// num G0<DeviceInfo>().deviceHeight;

// bool G0<AppModel>().hasLocationPermissions = false;

// DateTime appStartTime;

// StreamSubscription<Position> geoLocationStream;
// num G0<DeviceInfo>().deviceLat;
// num G0<DeviceInfo>().deviceLon;

// CitiesTableHelper G0<TableModel>().citiesTableHelper;
// CountriesTableHelper G0<TableModel>().countriesTableHelper;
// RegionsTableHelper G0<TableModel>().regionsTableHelper;
// ReceiptsTableHelper G0<TableModel>().receiptsTableHelper;
// PaymentsTableHelper G0<TableModel>().paymentsTableHelper;
// HashersTableHelper G0<TableModel>().hashersTableHelper;
// KennelCreditsTableHelper G0<TableModel>().kennelCreditsTableHelper;
// KennelsTableHelper G0<TableModel>().kennelsTableHelper;
// EventsTableHelper G0<TableModel>().eventsTableHelper;
// HasherEventMapTableHelper G0<TableModel>().hasherEventMapTableHelper;
// HasherKennelMapTableHelper G0<TableModel>().hasherKennelMapTableHelper;

// List<BaseTableHelper> userTables = <BaseTableHelper>[
//   G0<TableModel>().citiesTableHelper,
//   G0<TableModel>().countriesTableHelper,
//   G0<TableModel>().regionsTableHelper,
//   G0<TableModel>().paymentsTableHelper,
//   G0<TableModel>().hashersTableHelper,
//   G0<TableModel>().kennelsTableHelper,
//   G0<TableModel>().eventsTableHelper,
//   G0<TableModel>().hasherEventMapTableHelper,
//   G0<TableModel>().hasherKennelMapTableHelper,
// ];

// BaseService G0<TableModel>().baseService;
// HashersService hashersService;
// PaymentsService G0<TableModel>().paymentsService;
// EventsService G0<TableModel>().eventsService;
// HasherEventMapService G0<TableModel>().hasherEventMapService;
// HasherKennelMapService G0<TableModel>.hasherKennelMapService;
// SyncUserDataService G0<TableModel>().syncUserDataService;
// SyncKennelAdminService G0<TableModel>().syncKennelAdminService;
// SyncEventAdminService G0<TableModel>().syncEventAdminService;

// Database G0<Database>();

// Future<void> openOrInitializeDb(
//     String dbName, int dbVersion, Function informUser,
//     {@required List<MigrationsModel> migrations,
//     @required Function createTables}) async {
//   G0<Database>() = await DBProvider.openOrInitDb(
//       DB_NAME, dbVersion, informUser, migrations,
//       createTables: createTables);
// }

// void initializeGlobals() {
//   G0<TableModel>().citiesTableHelper = CitiesTableHelper();
//   G0<TableModel>().countriesTableHelper = CountriesTableHelper();
//   G0<TableModel>().regionsTableHelper = RegionsTableHelper();
//   G0<TableModel>().receiptsTableHelper = ReceiptsTableHelper();
//   G0<TableModel>().paymentsTableHelper = PaymentsTableHelper();
//   G0<TableModel>().hashersTableHelper = HashersTableHelper();
//   G0<TableModel>().kennelCreditsTableHelper = KennelCreditsTableHelper();
//   G0<TableModel>().kennelsTableHelper = KennelsTableHelper();
//   G0<TableModel>().eventsTableHelper = EventsTableHelper();
//   G0<TableModel>().hasherEventMapTableHelper = HasherEventMapTableHelper();
//   G0<TableModel>().hasherKennelMapTableHelper = HasherKennelMapTableHelper();

//   G0<TableModel>().baseService = BaseService();
//   hashersService = HashersService();
//   G0<TableModel>().paymentsService = PaymentsService();
//   G0<TableModel>().eventsService = EventsService();
//   G0<TableModel>().hasherEventMapService = HasherEventMapService();
//   G0<TableModel>.hasherKennelMapService = HasherKennelMapService();

//   G0<TableModel>().syncUserDataService = SyncUserDataService();
//   G0<TableModel>().syncKennelAdminService = SyncKennelAdminService();
//   G0<TableModel>().syncEventAdminService = SyncEventAdminService();
// }
