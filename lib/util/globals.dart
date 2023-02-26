// @dart=2.11
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

// Ambient variable to access the service locator
// NOTE: I've given this variable a very unique name even if it is against normal
// DART style conventions.

// ignore: non_constant_identifier_names
final GetIt G0 = GetIt.instance;

Future<void> setupLocalServices(num deviceWidth, num deviceHeight, double textScaleFactor) async {
  G0.registerSingleton<AppModel>(AppModel());
  G0.registerSingletonAsync<DeviceInfo>(() async {
    final DeviceInfo deviceInfo = DeviceInfo();
    await deviceInfo.init(deviceWidth, deviceHeight, textScaleFactor);
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
    //G0<TableModel>().kennelCreditsTableHelper,
    G0<TableModel>().kennelsTableHelper,
    G0<TableModel>().eventsTableHelper,
    G0<TableModel>().hasherEventMapTableHelper,
    G0<TableModel>().hasherKennelMapTableHelper
  ];
}

bool _createIndexes = false;

Future<bool> setupDatabase(Function informUser, String clientAppIdentifier) async {
  // bool initialLoad = false;
  // if (getIntPref(IntPrefsEnum.databaseVersion) != DB_VERSION) {
  //   initialLoad = true;
  // }

  // print('******* > DB Setup step 1');
  G0<AppModel>().dbStatus = EdbStatus.opening;
  G0.registerSingletonAsync<Database>(() async {
    // print('******* > DB Setup step 2');
    _initTables();
    // print('******* > DB Setup step 3');
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

  // print('******* > DB Setup step 6');

  await G0.isReady<Database>();

  final Client client = Client();

  // print('******* > DB Setup step 7');

  try {
    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagCitiesTable | SyncUserDataService.flagRegionsTable | SyncUserDataService.flagCountriesTable,
          false,
          informUser: informUser,
          debugText: 'Globals: Cities, Regions, Countries on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: false,
        );

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagPaymentsTable,
          false,
          informUser: informUser,
          debugText: 'Globals: HEM on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: false,
        );

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagHasherKennelMapTable,
          false,
          informUser: informUser,
          debugText: 'Globals: HKM on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: false,
        );

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagKennelsTable,
          false,
          informUser: informUser,
          debugText: 'Globals: Kennels on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: true,
        );

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagHashersTable,
          false,
          informUser: informUser,
          debugText: 'Globals: Hashers on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: true,
        );

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagNarrowEventsTable,
          false,
          informUser: informUser,
          debugText: 'Globals: Events on launch',
          batchText: 'Batch #',
          client: client,
          usePaging: true,
        );

    await CommonQueries.deleteRemovedRecords(G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user));
    await CommonQueries.deleteRemovedRecords(G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user));
    await CommonQueries.deleteRemovedRecords(G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.kennel));

    // print('******* > DB Setup step 10');

    if (_createIndexes) {
      await Tables.createIndexes(G0<Database>(), DB_VERSION, informUser, clientAppIdentifier);
      // print('******* > DB Setup step 10.1');
      await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);
      // print('******* > DB Setup step 10.2');
    }
  } finally {
    client.close();
  }

  String message = (await CommonQueries.countRecords(G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user))).toString();
  if (kDebugMode) {
    print('Hashers count = $message');
  }

  message = (await CommonQueries.countRecords(G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user))).toString();
  if (kDebugMode) {
    print('Events count = $message');
  }

  message = (await CommonQueries.countRecords(G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user))).toString();
  if (kDebugMode) {
    print('Kennels count = $message');
  }

  message = (await CommonQueries.countRecords(G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user))).toString();
  if (kDebugMode) {
    print('Hasher event map count = $message');
  }

  message = (await CommonQueries.countRecords(G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user))).toString();
  if (kDebugMode) {
    print('Hasher kennel map count = $message');
  }

  if (kDebugMode) {
    print('******* > DB Setup step 11');
  }

  G0<AppModel>().dbStatus = EdbStatus.opened;
  if (kDebugMode) {
    print('******* > DB Setup step 12');
  }

  return true;
}

Future<void> _openDb(dynamic db, Function informUser, String clientAppIdentifier) async {}

Future<void> _createTables(dynamic db, int version, Function informUser, String clientAppIdentifier) async {
  // print('******* > DB Setup step 4');
  await Tables.createTables(db, version, informUser);
  // print('******* > DB Setup step 5');
  _createIndexes = true;
}

enum EdbStatus {
  uninitialized,
  opening,
  opened,
}

class AppModel {
  AppModel();
  EnumConnectionStatus connectionStatus = EnumConnectionStatus.not_connected;
  StreamSubscription<Position> geoLocationStream;
  DateTime appStartTime;
  EdbStatus dbStatus = EdbStatus.uninitialized;

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
  //KennelCreditsTableHelper kennelCreditsTableHelper;
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
    //kennelCreditsTableHelper = KennelCreditsTableHelper();
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
  num deviceTextScaleFactor;
  num textClamp00;
  num textClamp15;
  num textClamp25;
  num textClamp50;
  num textClamp75;
  num textClamp99;

  // a flag to indicate if we are running in the simulator
  bool isPhysicalDevice = true;
  bool get supportsCamera => Platform.isAndroid || isPhysicalDevice;

  Future<void> init(num deviceWidth, num deviceHeight, double textScaleFactor) async {
    deviceWidth = deviceWidth;
    deviceHeight = deviceHeight;
    deviceWidthScaleFactor = deviceWidth / BASE_DEVICE_WIDTH;
    deviceHeightScaleFactor = deviceHeight / BASE_DEVICE_HEIGHT;
    deviceMaxScaleFactor = max(deviceWidthScaleFactor, deviceHeightScaleFactor);
    deviceMinScaleFactor = min(deviceWidthScaleFactor, deviceHeightScaleFactor);
    deviceTextScaleFactor = textScaleFactor;
    textClamp00 = textScaleFactor.clamp(0.9, 1.00);
    textClamp15 = textScaleFactor.clamp(0.9, 1.15);
    textClamp25 = textScaleFactor.clamp(0.9, 1.25);
    textClamp50 = textScaleFactor.clamp(0.9, 1.50);
    textClamp75 = textScaleFactor.clamp(0.9, 1.75);

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      androidInfo = await deviceInfo.androidInfo;
      deviceId = (androidInfo.id ?? '<no Android ID>').toUpperCase();
      deviceType = '${androidInfo.model ?? '<no Android model>'} / device: ${androidInfo.device ?? '<no Android device'}';
      deviceName = '<unknown>';
      systemName = androidInfo.host ?? '<no Android system name>';
      systemVersion =
          '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release ?? '<no Android release>'} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch'}';
      manufacturer = androidInfo.brand ?? '<no Android brand>';
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
}
