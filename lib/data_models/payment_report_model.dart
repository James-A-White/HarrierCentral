import 'dart:core';

import 'package:harrier_central/util/enums.dart';

class PaymentReportModel {

final String paymentId;
final String paidBy;
final String paidTo;
final String cancelledBy;
final num creditAmount;
final num debitAmount;
final EnumPaymentType paymentType;
final DateTime paymentDate;
final DateTime cancelledDate;
final String paymentReference;
final String notes;

PaymentReportModel(
    {
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
    });

  @override
  String toString() => '$paymentReference';

}