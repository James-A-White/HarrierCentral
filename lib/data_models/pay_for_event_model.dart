import 'dart:core';

class PayForEventModel {
  PayForEventModel({
    this.result,
    this.waitingForCount,
    this.atHashCount,
    this.onInCount,
    this.onTrailCount,
    this.paidCount,
    this.buttonState,
    this.totalRunsThisKennel,
    this.isPaid,
    this.hasherEventMapId,
  });

  final String result;
  final int waitingForCount;
  final int atHashCount;
  final int onInCount;
  final int onTrailCount;
  final int paidCount;
  final int buttonState;
  final int totalRunsThisKennel;
  final int isPaid;
  final String hasherEventMapId;

  @override
  String toString() => '$result';
}
