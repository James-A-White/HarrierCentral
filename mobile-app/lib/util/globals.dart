import 'package:harrier_central/imports.dart';

// Ambient variable to access the service locator
// NOTE: I've given this variable a very unique name even if it is against normal
// DART style conventions.

// ignore: non_constant_identifier_names
//final GetIt G0 = GetIt.instance;

AppModel get appModel => Get.find<AppModel>();
DeviceInfo get deviceInfo => Get.find<DeviceInfo>();
TableModel get tableModel => Get.find<TableModel>();
Database get database => Get.find<Database>();
NetworkService get networkService => Get.find<NetworkService>();
NotificationService get notificationService => Get.find<NotificationService>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Shorthand for the current user's ID from preferences.
String? getUserId() => getStringPref(StringPrefsEnum.userId);

/// Show a standardised Harrier Central snackbar via GetX.
void showHcSnackbar(
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  Get.snackbar(
    isError ? 'Error' : 'Harrier Central',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? hc_red : hc_blue,
    colorText: Colors.white,
    duration: duration,
  );
}

bool _createIndexes = false;

Future<bool> setupDatabase(
  void Function(String)? informUser,
  String clientAppIdentifier,
) async {
  // bool initialLoad = false;
  // if (getIntPref(IntPrefsEnum.databaseVersion) != DB_VERSION) {
  //   initialLoad = true;
  // }

  // print('******* > DB Setup step 1');
  appModel.dbStatus = EdbStatus.opening;

  if (Get.isRegistered<Database>()) {
    await Get.delete<Database>(); // or await if you prefer
  }

  await Get.putAsync<Database>(() async {
    // _initTables();
    return DBProvider.openOrInitDb(
      DB_NAME,
      DB_VERSION,
      informUser,
      Tables.migrationList,
      createTables: _createTables,
      openDb: _openDb,
      clientAppIdentifier: clientAppIdentifier,
    );
  }, permanent: true);

  final Client client = Client();

  // print('******* > DB Setup step 7');

  try {
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.cities.flag |
          EnumDataTables.regions.flag |
          EnumDataTables.countries.flag |
          EnumDataTables.songs.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: Cities, Regions, Countries, Songs on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: false,
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag | EnumDataTables.payments.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: HEM on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: false,
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherKennelMap.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: HKM on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: false,
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.kennels.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: Kennels on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: true,
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: Events on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: true,
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hashers.flag,
      false,
      informUser: informUser,
      debugText: 'Globals: Hashers on launch',
      batchText: 'Batch #',
      client: client,
      usePaging: true,
    );

    await setDatePref(
      DatePrefsEnum.lastSuccessfulUserDataFullSync,
      DateTime.now(),
    );

    await CommonQueries.deleteRemovedRecords(
      EnumDataTables.hashers.commonTableName,
    );
    await CommonQueries.deleteRemovedRecords(
      EnumDataTables.events.commonTableName,
    );
    await CommonQueries.deleteRemovedRecords(
      EnumDataTables.events.commonTableName,
    );

    // print('******* > DB Setup step 10');

    if (_createIndexes) {
      await Tables.createIndexes(
        database,
        DB_VERSION,
        informUser,
        clientAppIdentifier,
      );
      // print('******* > DB Setup step 10.1');
      await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);
      // print('******* > DB Setup step 10.2');
    }
  } finally {
    client.close();
  }

  String message = (await CommonQueries.countRecords(
    EnumDataTables.hashers.commonTableName,
  )).toString();
  if (kDebugMode) {
    debugPrint('Hashers count = $message');
  }

  message = (await CommonQueries.countRecords(
    EnumDataTables.events.commonTableName,
  )).toString();
  if (kDebugMode) {
    debugPrint('Events count = $message');
  }

  message = (await CommonQueries.countRecords(
    EnumDataTables.kennels.commonTableName,
  )).toString();
  if (kDebugMode) {
    debugPrint('Kennels count = $message');
  }

  message = (await CommonQueries.countRecords(
    EnumDataTables.hasherEventMap.commonTableName,
  )).toString();
  if (kDebugMode) {
    debugPrint('Hasher event map count = $message');
  }

  message = (await CommonQueries.countRecords(
    EnumDataTables.hasherKennelMap.commonTableName,
  )).toString();
  if (kDebugMode) {
    debugPrint('Hasher kennel map count = $message');
  }

  if (kDebugMode) {
    debugPrint('******* > DB Setup step 11');
  }

  appModel.dbStatus = EdbStatus.opened;
  if (kDebugMode) {
    debugPrint('******* > DB Setup step 12');
  }

  return true;
}

Future<void> _openDb(
  dynamic db,
  Function informUser,
  String clientAppIdentifier,
) async {}

Future<void> _createTables(
  dynamic db,
  int version,
  Function informUser,
  String clientAppIdentifier,
) async {
  // print('******* > DB Setup step 4');
  await Tables.createTables(db, version, informUser);
  // print('******* > DB Setup step 5');
  _createIndexes = true;
}

enum EdbStatus { uninitialized, opening, opened }

class AppModel extends GetxService {
  AppModel();
  //StreamSubscription<Position>? geoLocationStream;
  DateTime appStartTime = DateTime.now();
  EdbStatus dbStatus = EdbStatus.uninitialized;

  bool hasLocationPermissions = false;

  // TODO(DevTeam): Make sure this is eventually called
  void dispose() {
    // if (geoLocationStream != null) {
    //   geoLocationStream!.cancel();
    // }
  }
}

class TableModel extends GetxService {
  // Helpers
  late final CitiesTableHelper citiesTableHelper = CitiesTableHelper();
  late final CountriesTableHelper countriesTableHelper = CountriesTableHelper();
  late final SongsTableHelper songsTableHelper = SongsTableHelper();
  late final RegionsTableHelper regionsTableHelper = RegionsTableHelper();
  late final ReceiptsTableHelper receiptsTableHelper = ReceiptsTableHelper();
  late final PaymentsTableHelper paymentsTableHelper = PaymentsTableHelper();
  late final HashersTableHelper hashersTableHelper = HashersTableHelper();
  late final KennelsTableHelper kennelsTableHelper = KennelsTableHelper();
  late final EventsTableHelper eventsTableHelper = EventsTableHelper();
  late final HasherEventMapTableHelper hasherEventMapTableHelper =
      HasherEventMapTableHelper();
  late final HasherKennelMapTableHelper hasherKennelMapTableHelper =
      HasherKennelMapTableHelper();

  // Services
  late final SyncUserDataService syncUserDataService = SyncUserDataService();
  late final SyncKennelAdminService syncKennelAdminService =
      SyncKennelAdminService();
  late final SyncEventAdminService syncEventAdminService =
      SyncEventAdminService();

  late final BaseService baseService = BaseService();
  late final HashersService hashersService = HashersService();
  late final PaymentsService paymentsService = PaymentsService();
  late final EventsService eventsService = EventsService();
  late final HasherEventMapService hasherEventMapService =
      HasherEventMapService();
  late final HasherKennelMapService hasherKennelMapService =
      HasherKennelMapService();

  List<KennelListAggregate>? globalKennelMainPageList;
  final List<BaseTableHelper> tablesForRemoteSync = <BaseTableHelper>[];

  // Cleanup hooks if any helper/service exposes dispose/close
  @override
  void onClose() {
    // Release the sync table registry so GC can collect the helper references.
    tablesForRemoteSync.clear();
    // The nested table helpers and services are plain Dart objects; they do not
    // hold closeable resources themselves (HTTP clients are per-request).
    // If helpers gain dispose() methods in future, call them here.
    super.onClose();
  }
}

class DeviceInfo extends GetxService {
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
  double? deviceAccuracy;
  double? deviceAltitude;
  late double deviceTextScaleFactor;
  late double textClamp00;
  late double textClamp15;
  late double textClamp25;
  late double textClamp50;
  late double textClamp75;
  late double textClamp99;

  bool isPhysicalDevice = true;
  bool get supportsCamera => Platform.isAndroid || isPhysicalDevice;

  /// Async init method that returns itself so it works with Get.putAsync
  Future<DeviceInfo> init(num width, num height, double textScaleFactor) async {
    deviceWidth = width.toDouble();
    deviceHeight = height.toDouble();

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
    textClamp99 = textScaleFactor.clamp(0.9, 1.99);

    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      androidInfo = await plugin.androidInfo;
      deviceId = androidInfo.id.toUpperCase();
      deviceType = '${androidInfo.model} / device: ${androidInfo.device}';
      deviceName = '<unknown>';
      systemName = androidInfo.host;
      systemVersion =
          '${androidInfo.version.sdkInt} / release: ${androidInfo.version.release} / security patch: ${androidInfo.version.securityPatch ?? '<no Android security patch>'}';
      manufacturer = androidInfo.brand;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      iosInfo = await plugin.iosInfo;
      deviceId = (iosInfo.identifierForVendor ?? '<no device ID>')
          .toUpperCase();
      deviceType = iosInfo.model;
      deviceName = iosInfo.name;
      systemName = iosInfo.systemName;
      systemVersion = iosInfo.systemVersion;
      manufacturer = 'Apple';
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }

    return this;
  }
}
