// import 'package:hcportal/imports.dart';
// //import 'package:flutter/foundation.dart' as foundation;

// class FunctionSelectionPage extends StatefulWidget {
//   const FunctionSelectionPage(this.kennel, {super.key});

//   final HasherKennelsModel kennel;
//   @override
//   FunctionSelectionPageState createState() => FunctionSelectionPageState();
// }

// class FunctionSelectionPageState extends State<FunctionSelectionPage> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<KennelModel?> _getKennel(String publicKennelId) async {
//     KennelModel? rdm;

//     final String publicHasherId = await box.get(HIVE_HASHER_ID) as String;

//     final String accessToken = Utilities.generateToken(publicHasherId, 'hcportal_getKennel', paramString: publicKennelId);

//     final String body = jsonEncode(<String, String>{
//       'queryType': 'getKennel',
//       'publicHasherId': publicHasherId,
//       'accessToken': accessToken,
//       'publicKennelId': publicKennelId,
//     });

//     final String jsonResult = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
//     if (jsonResult.length > 10) {
//       final dynamic jsonItems = json.decode(jsonResult);
//       rdm = KennelModel.fromJson(jsonItems[0][0]);
//     }

//     return rdm;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Functions'),
//         leading: GestureDetector(
//           onTap: () {
//             Get.back();
//           },
//           child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
//         ),
//       ),
//       body: Center(
//         child: OverflowBar(
//           alignment: MainAxisAlignment.center,
//           overflowAlignment: OverflowBarAlignment.center,
//           spacing: 15.0,
//           children: <Widget>[
//             // ElevatedButton(
//             //   child: const Text('All fields'),
//             //   onPressed: () async {
//             //     await _setColumnsType(EKennelGridOptions.allFields);
//             //   },
//             // ),
//             ElevatedButton(
//               child: const SizedBox(
//                 height: 200,
//                 width: 200,
//                 child: Center(
//                   child: Text(
//                     'Manage Hashers',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontFamily: 'AvenirNextBold',
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20.0,
//                     ),
//                   ),
//                 ),
//               ),
//               onPressed: () {
//                 Get.to(() => KennelHashersPage(widget.kennel));
//               },
//             ),

//             ElevatedButton(
//               child: const SizedBox(
//                 height: 200,
//                 width: 200,
//                 child: Center(
//                   child: Text(
//                     'Manage Runs',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontFamily: 'AvenirNextBold',
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20.0,
//                     ),
//                   ),
//                 ),
//               ),
//               onPressed: () {
//                 Get.to(() => RunListPage(widget.kennel));
//               },
//             ),

//             ElevatedButton(
//               child: const SizedBox(
//                 height: 200,
//                 width: 200,
//                 child: Center(
//                   child: Text(
//                     'Edit Kennel',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontFamily: 'AvenirNextBold',
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20.0,
//                     ),
//                   ),
//                 ),
//               ),
//               onPressed: () async {
//                 KennelModel? kennel = await _getKennel(widget.kennel.publicKennelId);

//                 if (context.mounted) {
//                   await Get.to(() => KennelFormPage(initialData: kennel));
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
