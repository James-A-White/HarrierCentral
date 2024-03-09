import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

// Ambient variable to access the service locator
// NOTE: I've given this variable a very unique name even if it is against normal
// DART style conventions.

// ignore: non_constant_identifier_names
final GetIt G0 = GetIt.instance;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  EnumConnectionStatus2 connectionStatus = EnumConnectionStatus2.notConnected;
  StreamSubscription<Position>? geoLocationStream;
  late DateTime appStartTime;
  EdbStatus dbStatus = EdbStatus.uninitialized;

  bool hasLocationPermissions = false;

  // TODO(DevTeam): Make sure this is eventually called
  void dispose() {
    if (geoLocationStream != null) {
      geoLocationStream!.cancel();
    }
  }
}

class TableModel {
  TableModel();

  late CitiesTableHelper citiesTableHelper;
  late CountriesTableHelper countriesTableHelper;
  late RegionsTableHelper regionsTableHelper;
  late ReceiptsTableHelper receiptsTableHelper;
  late PaymentsTableHelper paymentsTableHelper;
  late HashersTableHelper hashersTableHelper;
  //KennelCreditsTableHelper kennelCreditsTableHelper;
  late KennelsTableHelper kennelsTableHelper;
  late EventsTableHelper eventsTableHelper;
  late HasherEventMapTableHelper hasherEventMapTableHelper;
  late HasherKennelMapTableHelper hasherKennelMapTableHelper;

  late SyncUserDataService syncUserDataService;
  late SyncKennelAdminService syncKennelAdminService;
  late SyncEventAdminService syncEventAdminService;

  late BaseService baseService;

  late HashersService hashersService;
  late PaymentsService paymentsService;
  late EventsService eventsService;
  late HasherEventMapService hasherEventMapService;
  late HasherKennelMapService hasherKennelMapService;

  List<KennelListAggregate>? globalKennelMainPageList;

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

  List<BaseTableHelper> tablesForRemoteSync = <BaseTableHelper>[];
}

class DeviceInfo {
  DeviceInfo();

  late IosDeviceInfo iosInfo;
  late AndroidDeviceInfo androidInfo;

  String deviceId = 'unknown';
  String deviceType = 'unknown';
  String deviceName = 'unknown';
  String systemName = 'unknown';
  String systemVersion = 'unknown';
  String manufacturer = 'unknown';

  late double deviceWidthScaleFactor;
  late double deviceHeightScaleFactor;
  late double deviceMaxScaleFactor;
  late double deviceMinScaleFactor;
  late double deviceWidth;
  late double deviceHeight;
  double? deviceLat;
  double? deviceLon;
  late double deviceTextScaleFactor;
  late double textClamp00;
  late double textClamp15;
  late double textClamp25;
  late double textClamp50;
  late double textClamp75;
  late double textClamp99;

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
      deviceId = androidInfo.id.toUpperCase();
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion = '${androidInfo.version.sdkInt.toString()} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch'}';
      manufacturer = androidInfo.brand;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      iosInfo = await deviceInfo.iosInfo;
      deviceId = (iosInfo.identifierForVendor ?? '<no device ID>').toUpperCase();
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }
  }
}
