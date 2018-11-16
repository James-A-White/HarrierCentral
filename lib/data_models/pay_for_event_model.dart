import 'dart:core';

class PayForEventModel {

final String result;

final int waitingForCount;
final int atHashCount;
final int onInCount; 
final int onTrailCount;
final int paidCount;
final int buttonState;
final int totalRunsThisKennel;

PayForEventModel(
    {
        this.result,
        this.waitingForCount,
        this.atHashCount,
        this.onInCount,
        this.onTrailCount,
        this.paidCount,
        this.buttonState,
        this.totalRunsThisKennel,
    });

  @override
  String toString() => '$result';

}