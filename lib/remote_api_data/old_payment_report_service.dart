// import 'dart:async';
// import 'dart:convert';

// import 'package:harrier_central/util/enums.dart';
// import 'package:harrier_central/data_models/payment_report_model.dart';
// import 'package:harrier_central/util/constants.dart';
// import 'package:harrier_central/util/preferences.dart';
// import 'package:harrier_central/util/utilities.dart';


// import 'package:http/http.dart' as http;

// class PaymentReportService {
//         final List<PaymentReportModel> _paymentList = <PaymentReportModel>[];
//       List<PaymentReportModel> get paymentList => _paymentList;

//   Future<List<PaymentReportModel>> getPaymentReport(
//       {String eventId,
//       String kennelId,
//       String paidTo,
//       String paidBy,
//       int showAllTransactions}) async {


//     eventId ??= '00000000-0000-0000-0000-000000000000';
//     kennelId ??= '00000000-0000-0000-0000-000000000000';
//     paidTo ??= '00000000-0000-0000-0000-000000000000';
//     paidBy ??= '00000000-0000-0000-0000-000000000000';


//     final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

//     final String accessToken =
//         Utilities.generateToken(userId, 'getPaymentReport');

//     final String body = jsonEncode(<String, String>{
//       'userId': userId,
//       'accessToken': accessToken,
//       'kennelId': kennelId,
//       'eventId': eventId,
//       'showAllTransactions': (showAllTransactions ?? 0).toString(),
//       'paidTo': paidTo,
//       'paidBy': paidBy
//     });

//     final http.Response response = await http
//         .post(BASE_API_URL + 'get_payment_report',
//             headers: <String, String>{'content-type': 'application/json'},
//             body: body
//             // Send authorization headers to your backend
//             //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
//             )
//         .catchError(
//       (dynamic error) {
//         return false;
//       },
//     );



//     PaymentReportModel payment;
//     json.decode(response.body).forEach(
//       (dynamic item) {
//         payment = PaymentReportModel(
//           paymentId: item['paymentId'],
//           paidBy: item['paidBy'],
//           paidTo: item['paidTo'],
//           cancelledBy: item['cancelledBy'],
//           creditAmount: item['creditAmount'],
//           debitAmount: item['debitAmount'],
//           paymentType: EnumPaymentType<int>(item['paymentType'] ?? 0),
//           //paymentDate: DateTime.parse(item['paymentDate']),
//           //cancelledDate: DateTime.parse(item['cancelledDate']),
//           // paymentReference: item['paymentReference'],
//           // notes: item['notes'],
//         );

//          _paymentList.add(payment);
//       },
//     );

//     return _paymentList;
//   }
// }
