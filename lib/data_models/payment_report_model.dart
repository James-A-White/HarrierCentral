import 'dart:core';

import 'package:harrier_central/util/enums.dart';

class PaymentReportModel {

final String hasherEventMapId;
final String userIdWhoPaid;
final String paymentId;
String paidBy;
String paidTo;
String cancelledBy;
num creditAmount;
num debitAmount;
EnumPaymentType paymentType;
DateTime paymentDate;
DateTime cancelledDate;
String paymentReference;
String notes;
num creditRemaining;

PaymentReportModel(
    {
      this.hasherEventMapId,
      this.userIdWhoPaid,
      this.paymentId,
      this.paidBy,
      this.paidTo,
      this.cancelledBy,
      this.creditAmount,
      this.debitAmount,
      this.paymentType,
      this.paymentDate,
      this.cancelledDate,
      this.paymentReference,
      this.notes,
      this.creditRemaining,
    });

  @override
  String toString() => '$paymentReference';

}