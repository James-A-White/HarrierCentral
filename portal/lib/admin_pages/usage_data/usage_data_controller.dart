// // usage_data_controller.dart

// import 'package:hcportal/imports.dart';
// import 'package:hcportal/models/usage_category_detail/usage_category_detail.dart';
// import 'package:hcportal/models/usage_data_new_events/usage_data_new_events.dart';

// class UsageDataController extends GetxController {
//   final hcVersions = <UdHcVersion>[].obs;
//   final appActivity = <UdAppActivityModel>[].obs;
//   final integrationMonitor = <UdIntegrationMonitorModel>[].obs;
//   final recentUsers = <UdRecentUserModel>[].obs;
//   final newEvents = <UdNewEventsModel>[].obs;

//   final isUpdatingId = (-1).obs;
//   final isUpdatingDays = (-1).obs;

//   final maxHcVersion = 0.obs;
//   late final Timer refreshTimer;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchUsageData();
//     refreshTimer =
//         Timer.periodic(const Duration(seconds: 15), (_) => fetchUsageData());
//   }

//   @override
//   void onClose() {
//     refreshTimer.cancel();
//     super.onClose();
//   }

//   Future<void> fetchUsageData() async {
//     final accessToken = Utilities.generateToken(
//       box.get(HIVE_HASHER_ID) as String,
//       'hcportal_getUsageData',
//     );

//     final body = <String, String>{
//       'queryType': 'getUsageData',
//       'publicHasherId': box.get(HIVE_HASHER_ID) as String,
//       'accessToken': accessToken,
//     };

//     var jsonString = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
//     jsonString = jsonString.replaceAll('[[{', '{').replaceAll('}]]', '}');
//     final elements = jsonString.split('],[');

//     hcVersions.value = _parseList(elements[0], UdHcVersion.fromJson);
//     integrationMonitor.value =
//         _parseList(elements[1], UdIntegrationMonitorModel.fromJson);
//     appActivity.value = _parseList(elements[2], UdAppActivityModel.fromJson);
//     recentUsers.value = _parseList(elements[3], UdRecentUserModel.fromJson);
//     newEvents.value = _parseList(elements[4], UdNewEventsModel.fromJson);

//     _calculateMaxHcVersion();
//   }

//   List<T> _parseList<T>(String raw, T Function(Map<String, dynamic>) fromJson) {
//     final list = json.decode('[$raw]') as List<dynamic>;
//     return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
//   }

//   void _calculateMaxHcVersion() {
//     int maxValue = 0;
//     for (final version in hcVersions) {
//       final value = version.isNotiPhone + version.isiPhone;
//       if (value > maxValue) maxValue = value;
//     }
//     maxHcVersion.value = maxValue;
//   }

//   Future<void> getCategoryDetail(
//       int categoryId, int days, BuildContext context) async {
//     isUpdatingId.value = categoryId;
//     isUpdatingDays.value = days;

//     final accessToken = Utilities.generateToken(
//       box.get(HIVE_HASHER_ID) as String,
//       'hcportal_getCategoryDetail',
//     );

//     final body = <String, String>{
//       'queryType': 'getCategoryDetail',
//       'publicHasherId': box.get(HIVE_HASHER_ID) as String,
//       'accessToken': accessToken,
//       'categoryId': categoryId.toString(),
//       'days': days.toString(),
//     };

//     final result = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
//     final items = (json.decode(result) as List<dynamic>).first as List<dynamic>;

//     final displayStr = items
//         .map((e) =>
//             UdCategoryDetailModel.fromJson(e as Map<String, dynamic>).message ??
//             '')
//         .join('\n');

//     await IveCoreUtilities.showAlert(context, 'Details', displayStr, 'OK');

//     isUpdatingId.value = -1;
//     isUpdatingDays.value = -1;
//   }

//   Future<void> getHcVersionDetail(
//       String version, String build, BuildContext context) async {
//     final accessToken = Utilities.generateToken(
//       box.get(HIVE_HASHER_ID) as String,
//       'hcportal_getCategoryDetail',
//     );

//     final body = <String, String>{
//       'queryType': 'getCategoryDetail',
//       'publicHasherId': box.get(HIVE_HASHER_ID) as String,
//       'accessToken': accessToken,
//       'categoryId': '100',
//       'days': '14',
//       'hcVersion': version,
//       'hcBuild': build,
//     };

//     final result = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
//     final items = (json.decode(result) as List<dynamic>).first as List<dynamic>;

//     final displayStr = items
//         .map((e) =>
//             UdCategoryDetailModel.fromJson(e as Map<String, dynamic>).message ??
//             '')
//         .join('\n');

//     await IveCoreUtilities.showAlert(context, 'Details', displayStr, 'OK');
//   }

//   Future<void> integrationBlockPressed(
//       UdIntegrationMonitorModel integration, BuildContext context) async {
//     if (integration.integrationId == 1) {
//       final naughty = integration.kennelsFailedInfo.replaceAll(',', '\r\n');
//       final nice = integration.kennelsSucceededInfo.replaceAll(',', '\r\n');
//       await IveCoreUtilities.showAlert(
//         context,
//         'Naughty / Nice list',
//         'Naughty List:\n$naughty\nNice List:\n$nice',
//         'Done',
//       );
//     }
//   }
// }
