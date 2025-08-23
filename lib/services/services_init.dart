import 'package:harrier_central/imports.dart';
// import your concrete classes
// import 'app_model.dart';
// import 'device_info.dart';
// import 'prefs.dart';

/// Register all long-lived services. Call from main(), and on “restart”.
Future<void> initServices() async {
  // 1) Synchronous singletons first

  if (Get.isRegistered<AppModel>()) {
    await Get.delete<AppModel>(); // or await if you prefer
  }

  Get.put<AppModel>(AppModel(), permanent: true);

  if (Get.isRegistered<TableModel>()) {
    await Get.delete<TableModel>(); // or await if you prefer
  }

  // 3) Models/services that (may) depend on the DB
  // If your TableModel takes a Database, prefer: Get.put(TableModel(db), permanent: true);
  Get.put<TableModel>(TableModel(), permanent: true);

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

  if (Get.isRegistered<DeviceInfo>()) {
    await Get.delete<DeviceInfo>(); // or await if you prefer
  }

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

  // 5) If you have other async services, await them here similarly with putAsync.
  // No Get.allReady() needed on newer GetX—just await each putAsync you call.
}
