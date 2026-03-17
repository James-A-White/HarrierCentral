// import 'package:hcportal/imports.dart';

// // class PromotionsModel with _$PromotionsModel {
// //   factory PromotionsModel(
// //       {required final String promotionId,
// //       final String? promoGroupId,
// //       final String? kennelId,
// //       final String? cityId,
// //       final String? eventId,
// //       final String? userId,
// //       required final String promoName,
// //       required final DateTime promoStartDate,
// //       final DateTime? promoEndDate,
// //       required final int promoDisplayButtons,
// //       required final String promoImage,
// //       required final String promoImageExtension,
// //       required final String promoOverlayTiming,
// //       final String? promoImageWide,
// //       final String? promoImageTall,
// //       final String? promoExternalUrl,
// //       final String? promoExternalUrlButtonText,
// //       required final int promoPriority,
// //       final double? promoLat,
// //       final double? promoLon,
// //       final int? promoRadius,
// //       required final int promoGeographicScope,
// //       required final int promoImageIsDark,
// //       required final int promoDisplayTimingDotsToDisplay,
// //       required final String promoDisplayTimingDotsShape,
// //       required final int promoDisplayTimingDotsSize,
// //       required final String promoType,
// //       required final int promoIsDraft}) = _PromotionsModel;




// class PromotionController extends GetxController {
//   final promoDisplayTimeInMs = TextEditingController();

//   final startDateController = TextEditingController();
//   final endDateController = TextEditingController();
//   final promoNameController = TextEditingController();

//   final promoDotsToDisplay = TextEditingController();
//   final promoDotsSize = TextEditingController();



//   // final role1FocusNode = FocusNode();
//   // final role2FocusNode = FocusNode();
//   // final sessionCodeFocusNode = FocusNode();
//   // final btnNewSessionFocusNode = FocusNode();
//   // final btnConnectToSessionFocusNode = FocusNode();

//   //final passwordController = TextEditingController();
//   final _status = Rx<RxStatus>(RxStatus.empty());
//   RxStatus get status => _status.value;

//   DateTime promoStartDate = DateTime.now();
//   DateTime promoEndDate = DateTime.now().add(const Duration(days: 30));

//   static PromotionController get to => Get.find(); // add this line

//   final Box<dynamic> _box = Hive.box('HCPortal');

//   // @override
//   // void onInit() {
//   //   super.onInit();
//   // }

//   // @override
//   // void onReady() {
//   //   super.onReady();
//   // }

//   @override
//   void onClose() {
//     promoDisplayTimeInMs.dispose();
//     startDateController.dispose();
//     promoNameController.dispose();
//     endDateController.dispose();
//     //passwordController.dispose();
//   }

//   bool _isRole1Valid() {
//     if (promoDisplayTimeInMs.text.trim().isEmpty) {
//       //M.showToast('Enter email id', status: SnackBarStatus.error);

//       Get.showSnackbar(
//         const GetSnackBar(
//           //title: title,
//           message: 'Enter role or your name (max 6 characters)',
//           //icon: const Icon(Icons.refresh),
//           duration: Duration(seconds: 3),
//         ),
//       );

//       return false;
//     }

//     return true;
//   }

//   bool _isRole2Valid() {
//     if (startDateController.text.trim().isEmpty) {
//       //M.showToast('Enter email id', status: SnackBarStatus.error);

//       Get.showSnackbar(
//         const GetSnackBar(
//           //title: title,
//           message: 'Enter role or your name (max 6 characters)',
//           //icon: const Icon(Icons.refresh),
//           duration: Duration(seconds: 3),
//         ),
//       );

//       return false;
//     }

//     return true;
//   }

//   bool _isSessionCodeValid() {
//     RegExp regex = RegExp(r'^[a-zA-Z]+$');
//     bool isNotCharOnly = !regex.hasMatch(promoNameController.text.trim());

//     if (isNotCharOnly || promoNameController.text.trim().length != 6) {
//       // M.showToast('Enter valid email id', status: SnackBarStatus.error);
//       Get.showSnackbar(
//         const GetSnackBar(
//           //title: title,
//           message: 'Please enter valid session code',
//           //icon: const Icon(Icons.refresh),
//           duration: Duration(seconds: 3),
//         ),
//       );

//       return false;
//     }

//     return true;
//   }

//   Future<void> onConnectToSession() async {
//     if (_isSessionCodeValid() && _isRole1Valid()) {
//       _status.value = RxStatus.loading();
//       try {
//         String accessToken = 'not required';
//         // final String accessToken = Utilities.generateToken(HC_ADMIN_PORTAL_INTERNAL_USER_ID, 'hcportal_getEvents');

//         final String body = jsonEncode(<String, dynamic>{
//           'tenantId': null,
//           'stakeholderId': _box.get('stakeholderId'),
//           'accessToken': accessToken,
//           'sessionCode': 'DAC:${promoNameController.text.trim().toUpperCase()}',
//           'stakeholderAbbreviation': promoDisplayTimeInMs.text
//         });

//         final String jsonResult = await ServiceCommon.sendHttpPost('dm1_connect_to_session', body);

//         if (jsonResult.length > 10) {
//           final dynamic jsonItems = json.decode(jsonResult);
//           if (jsonItems.length > 0) {
//             if (jsonItems[0][0]['decisionActivityId'] != null) {
//               String decisionActivityId = jsonItems[0][0]['decisionActivityId'];

//               Box<dynamic> box = Hive.box('CMeter');
//               box.put('decisionActivityId', decisionActivityId);
//               box.put('sessionCode', promoNameController.text.trim().toUpperCase());
//             }
//           }

//           Get.showSnackbar(
//             const GetSnackBar(
//               //title: title,
//               message: 'Connected to session',
//               //icon: const Icon(Icons.refresh),
//               duration: Duration(seconds: 3),
//             ),
//           );

//           _status.value = RxStatus.success();

//           //Get.to(const DecisionView());
//         } else {
//           Get.showSnackbar(
//             const GetSnackBar(
//               //title: title,
//               message: 'Session not found',
//               //icon: const Icon(Icons.refresh),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }
//       } catch (e) {
//         e.printError();
//         //M.showToast(e.toString(), status: SnackBarStatus.error);
//         Get.showSnackbar(
//           GetSnackBar(
//             //title: title,
//             message: e.toString(),
//             //icon: const Icon(Icons.refresh),
//             duration: const Duration(seconds: 3),
//           ),
//         );

//         _status.value = RxStatus.error(e.toString());
//       }
//     }
//   }

//   Future<void> onCreateNewSession() async {
//     if (_isRole2Valid()) {
//       _status.value = RxStatus.loading();
//       try {
//         String accessToken = 'not required';
//         // final String accessToken = Utilities.generateToken(HC_ADMIN_PORTAL_INTERNAL_USER_ID, 'hcportal_getEvents');

//         final String body = jsonEncode(<String, dynamic>{
//           'tenantId': null,
//           'stakeholderId': _box.get('stakeholderId'),
//           'stakeholderAbbreviation': startDateController.text.trim(),
//           'accessToken': accessToken,
//           'decisionActivityId': null,
//           'decisionActivityName': null,
//         });

//         final String jsonResult = await ServiceCommon.sendHttpPost('dm1_create_basic_decision_activity', body);

//         if (jsonResult.length > 10) {
//           final dynamic jsonItems = json.decode(jsonResult);
//           if (jsonItems.length > 0) {
//             if (jsonItems[0][0]['decisionActivityId'] != null) {
//               String decisionActivityId = jsonItems[0][0]['decisionActivityId'];
//               String sessionCode = jsonItems[0][0]['sessionCode'];

//               Box<dynamic> box = Hive.box('CMeter');
//               box.put('decisionActivityId', decisionActivityId);
//               box.put('sessionCode', sessionCode.trim().toUpperCase());
//             }
//           }

//           Get.showSnackbar(
//             const GetSnackBar(
//               //title: title,
//               message: 'Connected to session',
//               //icon: const Icon(Icons.refresh),
//               duration: Duration(seconds: 3),
//             ),
//           );

//           _status.value = RxStatus.success();

//           //Get.to(const DecisionView());
//         } else {
//           Get.showSnackbar(
//             const GetSnackBar(
//               //title: title,
//               message: 'Session not found',
//               //icon: const Icon(Icons.refresh),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }
//       } catch (e) {
//         e.printError();
//         //M.showToast(e.toString(), status: SnackBarStatus.error);
//         Get.showSnackbar(
//           GetSnackBar(
//             //title: title,
//             message: e.toString(),
//             //icon: const Icon(Icons.refresh),
//             duration: const Duration(seconds: 3),
//           ),
//         );

//         _status.value = RxStatus.error(e.toString());
//       }
//     }
//   }
// }
