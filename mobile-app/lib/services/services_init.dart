import 'package:harrier_central/imports.dart';
// import your concrete classes
// import 'app_model.dart';
// import 'device_info.dart';
// import 'prefs.dart';

/// Register all long-lived services. Call from main(), and on “restart”.
Future<void> initServices() async {
  if (Get.isRegistered<AppLifecycleController>()) {
    //print('AppLifecycleController delete 1');
    await Get.delete<AppLifecycleController>(
      force: true,
    ); // or await if you prefer
  }

  // 1. App Lifecycle Controller (Must be permanent to survive restarts)
  // This registers the AppLifecycleController globally.
  Get.put<AppLifecycleController>(AppLifecycleController(), permanent: true);

  // 1) Synchronous singletons first

  if (Get.isRegistered<AppModel>()) {
    //print('AppModel delete 1');
    await Get.delete<AppModel>(force: true); // or await if you prefer
  }

  //print('Init services called: ${DateTime.now().millisecondsSinceEpoch}');

  Get.put<AppModel>(AppModel(), permanent: true);

  // AppModel must be first, as other services may read from it during init()
  if (Get.isRegistered<NetworkService>()) {
    await Get.delete<NetworkService>(force: true); // or await if you prefer
  }

  // NetworkService: lazy + fenix, then explicitly init once now
  Get.lazyPut<NetworkService>(() => NetworkService(), fenix: true);
  await networkService.init(); // first init

  if (Get.isRegistered<TableModel>()) {
    await Get.delete<TableModel>(force: true); // or await if you prefer
  }

  // 3) Models/services that (may) depend on the DB
  // If your TableModel takes a Database, prefer: Get.put(TableModel(db), permanent: true);
  Get.lazyPut<TableModel>(() => TableModel(), fenix: true);

  tableModel.tablesForRemoteSync.clear();

  tableModel.tablesForRemoteSync.addAll(<BaseTableHelper>[
    tableModel.citiesTableHelper,
    tableModel.countriesTableHelper,
    tableModel.regionsTableHelper,
    tableModel.receiptsTableHelper,
    tableModel.paymentsTableHelper,
    tableModel.hashersTableHelper,
    //tableModel.kennelCreditsTableHelper,
    tableModel.kennelsTableHelper,
    tableModel.eventsTableHelper,
    tableModel.hasherEventMapTableHelper,
    tableModel.hasherKennelMapTableHelper,
  ]);

  if (!Get.isRegistered<DeviceInfo>()) {
    // immediately initialize the first time you register
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final mq = MediaQueryData.fromView(view);

    await Get.putAsync<DeviceInfo>(
      () async => DeviceInfo().init(
        mq.size.width,
        mq.size.height,
        mq.textScaler.scale(1.0),
      ),
      permanent: true,
    );
  }

  // 5) NotificationService — initialised once here; callers use Get.find<NotificationService>().
  if (!Get.isRegistered<NotificationService>()) {
    if (Firebase.apps.isNotEmpty) {
      await Get.putAsync<NotificationService>(
        () => NotificationService().init(),
        permanent: false,
      );
    }
    // If Firebase is not yet initialised, NotificationService will be registered
    // lazily the first time it is needed (see future_run_list_controller.onInitAsync).
  }

  // 6) If you have other async services, await them here similarly with putAsync.
  // No Get.allReady() needed on newer GetX—just await each putAsync you call.

  // S1 (DataRepository): DataRepository.instance is a lazy singleton — no
  // registration needed here. When the migration progresses and DataRepository
  // gains async resources of its own (e.g. a direct DB connection), initialise
  // it here alongside the other services.

  // DataChangeService: broadcast stream for cross-controller change notification.
  if (Get.isRegistered<DataChangeService>()) {
    await Get.delete<DataChangeService>(force: true);
  }
  Get.lazyPut<DataChangeService>(() => DataChangeService(), fenix: true);

  // MainNavigationController is registered as permanent inside MainNavigationPage.
  // It must be explicitly deleted here so that after logout the next user gets a
  // fresh controller instance — onInit/onInitAsync fires correctly, stale Rx state
  // is cleared, and the WidgetsBindingObserver + screenWatcherSub from the old
  // session are properly torn down via onClose().
  if (Get.isRegistered<MainNavigationController>()) {
    await Get.delete<MainNavigationController>(force: true);
  }

  // Permissions V2: load the last-known permission matrix from storage so the
  // gate uses it from boot. approveLogin only re-sends the matrix when it
  // changes, so without this a restart would drop back to the enum floor.
  PermissionMatrix.setGlobalJson(
    getStringPref(StringPrefsEnum.permissionMatrixJson),
  );

  // Apple Watch companion bridge (iOS-only internally; no-op elsewhere).
  // Permanent: the method-call handler must stay alive across restarts so
  // watch commands always have a receiver.
  if (!Get.isRegistered<WatchBridgeService>()) {
    Get.put<WatchBridgeService>(WatchBridgeService(), permanent: true);
  }

  // Payment outbox: persists charges until the server acknowledges them and
  // retries them across sessions. Permanent — queued payments from a
  // previous session must get their boot-time retry even if no payment UI
  // is ever opened.
  if (!Get.isRegistered<PaymentOutboxService>()) {
    Get.put<PaymentOutboxService>(PaymentOutboxService(), permanent: true);
  }
}
