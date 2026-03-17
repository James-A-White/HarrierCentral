// // ignore_for_file: sort_child_properties_last

// import 'package:intl/intl.dart';

// import 'package:hcportal/imports.dart';
// import 'package:hcportal/models/promotions/promotions_model.dart';

// class PromotionListPage extends StatefulWidget {
//   const PromotionListPage({super.key});

//   @override
//   PromotionListPageState createState() => PromotionListPageState();
// }

// class PromotionListPageState extends State<PromotionListPage> {
//   final List<PromotionsModel> _allPromotions = <PromotionsModel>[];

//   @override
//   void initState() {
//     super.initState();
//     _getPromotions().then((_) {
//       setState(() {});
//     });
//   }

//   // bool _isLoaded = false;

//   Future<void> _getPromotions() async {
//     setState(() {
//       // _isLoaded = false;
//     });

//     final String accessToken = Utilities.generateToken(HC_ADMIN_PORTAL_INTERNAL_USER_ID, 'hcportal_getPromotions');

//     final String body = jsonEncode(<String, dynamic>{
//       'publicHasherId': HC_ADMIN_PORTAL_INTERNAL_USER_ID,
//       'accessToken': accessToken,
//       'publicKennelId': null,
//       'promoType': null,
//       'promoStartDate': null,
//       'ipAddress': null,
//       'ipGeoDetails': null
//     });

//     //print(body);

//     final String jsonResult = await ServiceCommon.sendHttpPost('hcportal_get_promotions', body);

//     final dynamic jsonItems = json.decode(jsonResult);
//     for (int i = 0; i < jsonItems[0].length; i++) {
//       PromotionsModel rlm = PromotionsModel.fromJson(jsonItems[0][i]);
//       _allPromotions.add(rlm);
//     }

//     setState(() {});
//     return;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Promotions'),
//         leading: GestureDetector(
//           onTap: () {
//             Get.back();
//           },
//           child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
//         ),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: SingleChildScrollView(
//                 primary: false,
//                 child: StaggeredGrid.count(
//                   crossAxisCount: 5,
//                   mainAxisSpacing: 14.0,
//                   crossAxisSpacing: 14.0,
//                   children: _allPromotions.map(
//                     (PromotionsModel e) {
//                       return StaggeredGridTile.count(
//                         crossAxisCellCount: 1,
//                         mainAxisCellCount: 2.35,
//                         child: ElevatedButton(
//                             style: ButtonStyle(
//                               backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
//                               shape: WidgetStateProperty.all<OutlinedBorder>(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                 ),
//                               ),
//                             ),
//                             onPressed: () async {
//                               await router.navigateTo(
//                                 context,
//                                 'promotionPage',
//                                 routeSettings: RouteSettings(arguments: <String, dynamic>{'promotionModel': e}),
//                               );
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Container(
//                                   padding: const EdgeInsets.only(top: 12.0, left: 10.0, right: 10.0),
//                                   height: 100.0,
//                                   child: Center(
//                                     child: Text(e.promoName,
//                                         textAlign: TextAlign.center,
//                                         style: const TextStyle(
//                                           color: Colors.black,
//                                           fontSize: 20.0,
//                                         )),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.all(10), child: Image.network(e.promoImage + e.promoImageExtension),
//                                   //child: Image.network(_hasherKennels[index].kennelLogo),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 12.0, left: 10.0, right: 10.0),
//                                   child: Text(DateFormat('E, MMM d, yyyy').format(e.promoStartDate),
//                                       style: const TextStyle(
//                                         color: Colors.black,
//                                         fontSize: 18.0,
//                                       )),
//                                 ),
//                               ],
//                             )),
//                       );
//                     },
//                   ).toList(),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
