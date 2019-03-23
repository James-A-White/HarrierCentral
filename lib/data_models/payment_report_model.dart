import 'dart:core';

import 'package:harrier_central/util/enums.dart';

class PaymentReportModel {
  PaymentReportModel({
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

  final String hasherEventMapId;
  final String userIdWhoPaid;
  final String paymentId;
  String paidBy;
  String paidTo;
  String cancelledBy;
  num creditAmount;
  num debitAmount;
  EnumPaymentType<int>paymentType;
  DateTime paymentDate;
  DateTime cancelledDate;
  String paymentReference;
  String notes;
  num creditRemaining;

  bool isTransactionInProgress = false;

  @override
  String toString() => '$paymentReference';
}
