// import 'dart:async';

// import 'package:flutter/material.dart';

// import 'package:harrier_central/data_models/payment_report_model.dart';

// import 'package:scoped_model/scoped_model.dart';

// import 'dart:async';

// import 'package:flutter/material.dart';

// import 'package:harrier_central/remote_api_data/kennel_member_scoped_model.dart';
// import 'package:harrier_central/remote_api_data/payment_report_service.dart';
// import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
// import 'package:harrier_central/widgets/payment_report_list_item.dart';
// import 'package:harrier_central/data_models/kennel_model.dart';


// class PaymentReportPage extends StatelessWidget {
//   final String eventId;


//   PaymentReportPage({Key key, @required this.eventId}) : super(key: key);

//   final PaymentReportService paymentReportService = PaymentReportService();
  

//   @override
//   Widget build(BuildContext context) {
//     if ((paymentReportService?.paymentList?.length ?? 0) == 0) {
//       paymentReportService.getPaymentReport(eventId: eventId).then((void dummy){ return Container(color: Colors.red, width: 100, height: 100);});
//     }

//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: Theme.of(context).primaryColor,
//         title: Text(
//           //'${kennel.kennelShortName} Members',
//           'Test',
//           style: TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: PaymentReportListBody(paymentReportService: paymentReportService, eventId: eventId),
//     );
//   }
// }

// class PaymentReportListBody extends StatelessWidget {
//   final String eventId;
//   final PaymentReportService paymentReportService;

//   PaymentReportListBody({Key key, @required this.paymentReportService, @required this.eventId})
//       : super(key: key);

//   BuildContext context;
//   //KennelMemberScopedModel model;

//   //int pageIndex = 1;

  

//   @override
//   Widget build(BuildContext context) {
//     this.context = context;

//     // return ScopedModelDescendant<KennelMemberScopedModel>(
//     //   builder:
//     //       (BuildContext context, Widget child, KennelMemberScopedModel model) {
//         //this.model = model;
        
        
//         // return model.isLoading
//         //     ? _buildCircularProgressIndicator()
//         //     : _buildListView();

//         return _buildListView(paymentReportService);
//     //   },
//     // );
//   }

//   // Widget _buildCircularProgressIndicator() {
//   //   return const Center(
//   //     child: CircularProgressIndicator(),
//   //   );
//   // }

//   Future<Null> _handleRefresh() async {
//     paymentReportService.getPaymentReport(eventId: eventId);
//     return null;
//   }

//   Widget _buildListView(PaymentReportService paymentReportService) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: <Widget>[
//         Expanded(
//         child:Padding(
//           padding: const EdgeInsets.only(top: 10.0),
//           child: paymentReportService.paymentList.length == 0
//               ? const Center(child: Text('No Kennels available.'))
//               : RefreshIndicator(
//                   onRefresh: () => _handleRefresh(),
//                   displacement: 40.0,
//                   child: ListView.builder(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     itemCount: paymentReportService.paymentList.length,
//                     itemBuilder: (BuildContext context, int index) {
//                       return Container(
//                         height: 85.0,
//                         padding: const EdgeInsets.all(0.0),
//                         child: ListView(
//                             scrollDirection: Axis.horizontal,
//                             children: <Widget>[
//                               PaymentReportListItem(
//                                   paymentReportItem: paymentReportService.paymentList[index]),
//                             ]),
//                       );
//                     },
//                   ),
//                 ),
//         ),),
//             //      Container(
//             //   width: 150.0,
//             //   child: RaisedButton(
//             //     child: const Text(
//             //       'Add Member',
//             //       style: TextStyle(color: Colors.white),
//             //     ),
//             //     onPressed: () {
//             //       Navigator.push<dynamic>(
//             //         context,
//             //         MaterialPageRoute<dynamic>(
//             //           builder: (context) => AddMemberPage(
//             //                 kennelId: kennelId,
//             //               ),
//             //         ),
//             //       );
//             //     },
//             //   ),
//             // ),
         
//       ],
//     );
//   }
// }
