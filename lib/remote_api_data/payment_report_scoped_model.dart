import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/data_models/payment_report_model.dart';

import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';

class PaymentReportScopedModel extends Model {
  final List<PaymentReportModel> _paymentReportsList = <PaymentReportModel>[];
  final List<PaymentReportModel> _paymentReportTotalsList =
      <PaymentReportModel>[];

  List<PaymentReportModel> get paymentReportsList => _paymentReportsList;
  List<PaymentReportModel> get paymentReportTotalsList =>
      _paymentReportTotalsList;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  void clearPaymentReportsList() {
    _paymentReportsList.clear();
    _paymentReportTotalsList.clear();
  }

  int getPaymentReportsListCount() {
    return _paymentReportsList.length;
  }

  int getPaymentReportTotalsListCount() {
    return _paymentReportTotalsList.length;
  }

  void addEditPaymentReportList(PaymentReportModel report) {
    if (_paymentReportsList.isNotEmpty) {
      final PaymentReportModel paymentReport = _paymentReportsList.firstWhere(
          (PaymentReportModel thisReport) =>
              thisReport.hasherEventMapId == report.hasherEventMapId,
          orElse: () => null);

      if (paymentReport != null) {
         if (paymentReport.paymentType != report.paymentType) {
          paymentReport.paymentType = report.paymentType;
        }

        if (paymentReport.paidBy != report.paidBy) {
          paymentReport.paidBy = report.paidBy;
        }

                if (paymentReport.creditAmount != report.creditAmount) {
          paymentReport.creditAmount = report.creditAmount;
        }

                if (paymentReport.debitAmount != report.debitAmount) {
          paymentReport.debitAmount = report.debitAmount;
        }

                if (paymentReport.paymentReference != report.paymentReference) {
          paymentReport.paymentReference = report.paymentReference;
        }

                if (paymentReport.notes != report.notes) {
          paymentReport.notes = report.notes;
        }
      } else {
        _paymentReportsList.add(report);
      }
    } else {
      _paymentReportsList.add(report);
    }
  }

  void addEditPaymentReportTotalsList(PaymentReportModel report) {
    if (_paymentReportTotalsList.isNotEmpty) {
      final PaymentReportModel paymentReport =
          _paymentReportTotalsList.firstWhere(
              (PaymentReportModel thisReport) =>
                  thisReport.paymentType.value == report.paymentType.value,
              orElse: () => null);

      if (paymentReport != null) {
        if (paymentReport.paymentType != report.paymentType) {
          paymentReport.paymentType = report.paymentType;
        }

        if (paymentReport.paidBy != report.paidBy) {
          paymentReport.paidBy = report.paidBy;
        }

                if (paymentReport.creditAmount != report.creditAmount) {
          paymentReport.creditAmount = report.creditAmount;
        }

                if (paymentReport.debitAmount != report.debitAmount) {
          paymentReport.debitAmount = report.debitAmount;
        }

                if (paymentReport.paymentReference != report.paymentReference) {
          paymentReport.paymentReference = report.paymentReference;
        }

                if (paymentReport.notes != report.notes) {
          paymentReport.notes = report.notes;
        }

        // if (paymentReport.lastName != member.lastName) {
        //   paymentReport.lastName = member.lastName;
        // }
        // if (paymentReport.hashName != member.hashName) {
        //   paymentReport.hashName = member.hashName;
        // }
        // if (paymentReport.photo != member.photo) {
        //   paymentReport.photo = member.photo;
        // }
        // if (paymentReport.displayName != member.displayName) {
        //   paymentReport.displayName = member.displayName;
        // }
        // // add fields here that might have been updated
        // if (ken.followingBool != kennel.followingBool) {ken.followingBool = kennel.followingBool;}
        // //if (ken.kennelName != kennel.kennelName) {ken.kennelName = kennel.kennelName;}
        // //if (ken.kennelShortName != kennel.kennelShortName) {ken.kennelShortName = kennel.kennelShortName;}
        // //if (ken.locationName != kennel.locationName) {ken.locationName = kennel.locationName;}
        // if (ken.isHomeKennel != kennel.isHomeKennel) {ken.isHomeKennel = kennel.isHomeKennel;}
        // if (ken.isMember != kennel.isMember) {ken.isMember = kennel.isMember;}
      } else {
        _paymentReportTotalsList.add(report);
      }
    } else {
      _paymentReportTotalsList.add(report);
    }
  }

  Future<dynamic> _getPaymentReports(
      {String eventId,
      String kennelId,
      String paidTo,
      String paidBy,
      int showAllTransactions}) async {
    eventId ??= '00000000-0000-0000-0000-000000000000';
    kennelId ??= '00000000-0000-0000-0000-000000000000';
    paidTo ??= '00000000-0000-0000-0000-000000000000';
    paidBy ??= '00000000-0000-0000-0000-000000000000';

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId, 'getPaymentReport');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennelId,
      'eventId': eventId,
      'showAllTransactions': (showAllTransactions ?? 0).toString(),
      'paidTo': paidTo,
      'paidBy': paidBy
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'get_payment_report',
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    return json.decode(response.body);
  }

  Future<void> getPaymentReportsFromBackend(
      int pageIndex, bool showLoadingIndicator, String eventId) async {
    if ((pageIndex == 1) && showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final dynamic paymentData = await _getPaymentReports(eventId: eventId);

    paymentReportTotalsList.clear();

    PaymentReportModel paymentReport; 
    paymentData.forEach(
      (dynamic item) {
        paymentReport = PaymentReportModel(
          hasherEventMapId: item['hasherEventMapId'],
          userIdWhoPaid: item['userIdWhoPaid'],
          paymentId: item['paymentId'],
          paidBy: item['paidBy'],
          paidTo: item['paidTo'],
          cancelledBy: item['cancelledBy'] ?? '',
          creditAmount: item['creditAmount'],
          debitAmount: item['debitAmount'],
          paymentType: EnumPaymentType<int>(item['paymentType'] ?? 0),
          paymentDate: item['paymentDate'] == null ? null : DateTime.parse(item['paymentDate']),
          cancelledDate: item['cancelledDate'] == null ? null : DateTime.parse(item['cancelledDate']),
          paymentReference: item['paymentReference'] ?? '',
          notes: item['notes'] ?? '',
          creditRemaining: item['creditRemaining'] ?? 0
        );

        if (paymentReport.paymentType.value < 100) {
          addEditPaymentReportList(paymentReport);
        } else {
          addEditPaymentReportTotalsList(paymentReport);
        }
      },
    );

    if (pageIndex == 1) {
      _isLoading = false;
    }

    notifyListeners();

    return null;
  }
}
