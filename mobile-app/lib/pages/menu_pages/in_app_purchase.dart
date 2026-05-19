// // @dart=2.11
// import 'package:harrier_central/imports.dart';

// class InAppPurchasePage extends StatefulWidget {
//   //final FutureRunScopedModel futureRunsModel;

//   const InAppPurchasePage({Key key}) : super(key: key);

//   @override
//   InAppPurchasePageState createState() => InAppPurchasePageState();
// }

// class InAppPurchasePageState extends State<InAppPurchasePage> {
//   List<QProduct> _products;

//   Future<void> _getProducts() async {
//     _products = <QProduct>[];
//     try {
//       final QOfferings offerings = await Qonversion.offerings();
//       setStateIfMounted(() {
//         _products = offerings.main.products;
//       });
//     } catch (e) {
//       //print(e);
//     }
//   }

//   final String _userId = getStringPref(StringPrefsEnum.userId);

//   @override
//   void initState() {
//     _launchQonversion();
//     super.initState();
//   }

//   //QLaunchResult _qLaunchResult;

//   Future<void> _launchQonversion() async {
//     await Qonversion.setDebugMode();

//     // _qLaunchResult = await Qonversion.launch(
//     //   'MWZuq2mnsUxL-fvpm9Y5oIaUeXs-asAk',
//     //   isObserveMode: false,
//     // );

//     await Qonversion.launch(
//       'MWZuq2mnsUxL-fvpm9Y5oIaUeXs-asAk',
//       isObserveMode: false,
//     );

//     await Qonversion.setUserId(_userId);

//     //await Qonversion.setAdvertisingID();
//     await _getProducts();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: themeAppBarBackground,
//         title: const Text(
//           'In App Purchases',
//           style: TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: Backgrounds.defaultHcBackground(),
//         child: Stack(
//           alignment: AlignmentDirectional.center,
//           children: <Widget>[
//             if (_products == null) ...<Widget>[],
//             if (_products != null) ...<Widget>[
//               ListView.separated(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 itemCount: _products.length,
//                 padding: const EdgeInsets.only(top: 5),
//                 separatorBuilder: (BuildContext context, int index) => const Divider(
//                   height: 1.0,
//                   color: Colors.black45,
//                 ),
//                 //itemExtent: 58.0,
//                 //shrinkWrap: true,
//                 itemBuilder: (BuildContext context, int index) {
//                   return _productWidget(_products[index]);
//                 },
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _productWidget(QProduct product) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         ListTile(
//           title: Text('Store ID: ${product.storeId}'),
//           subtitle: Text('Q ID: ${product.qonversionId}'),
//           trailing: product.skProduct != null ? Text(product.skProduct.localizedTitle) : null,
//           //onTap: () => //print(product.toJson()),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8),
//           child:             TextButton(
//             child: const Text('Buy'),
//             style: ButtonStyle(
//               backgroundColor: WidgetStateProperty.resolveWith<Color>(
//                 (Set<WidgetState> states) {
//                   if (states.contains(WidgetState.disabled)) {
//                     return Colors.grey.shade700;
//                   }
//                   return Colors.blue; // Use the component's default.
//                 },
//               ),
//               textStyle: WidgetStateProperty.resolveWith<TextStyle>(
//                 (Set<WidgetState> states) {
//                   if (states.contains(WidgetState.disabled)) {
//                     return TextStyle(color: Colors.grey.shade200);
//                   }
//                   return const TextStyle(color: Colors.white); // Use the component's default.
//                 },
//               ),
//             ),
//             // color: hc_blue,
//             // textColor: Colors.white,
//             onPressed: () async {
//               //final Map<String, QPermission> permissions = await Qonversion.purchase(product.qonversionId);
//               //final QPermission permission = permissions.values.firstWhere((QPermission element) => element.productId == product.qonversionId, orElse: () => null);

//               //print(permission?.isActive);
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class InAppPurchasePageContent extends StatefulWidget {
//   const InAppPurchasePageContent({Key key}) : super(key: key);

//   @override
//   _InAppPurchasePageContentState createState() => _InAppPurchasePageContentState();
// }

// class _InAppPurchasePageContentState extends State<InAppPurchasePageContent> {
//   TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);

//   TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: MediaQuery.sizeOf(context).height,
//       width: MediaQuery.sizeOf(context).width,
//       child: Center(child: Text(' In App Purchase\r\nPage Placeholder', textAlign: TextAlign.center, style: headingStyle)),
//     );
//   }
// }
