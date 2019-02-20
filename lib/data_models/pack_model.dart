import 'dart:core';

class PackModel {

  final String eventId;
  final String hasherId;
  final int isFollowing;
  final int isMember;
  // final int isRsvped;
  String hasherEventMapId;
  int isHare;
  final int virginVisitorType;
  final DateTime userStartEvent;
  final DateTime userEndEvent;
  int rsvpState;
  int attendenceState;
  int isPaid;
  int paymentType;
  final String displayName;
  final String photo;
  int userRunCount;
  final int waitingForCount;
  final int atHashCount;
  final int onInCount;
  final int onTrailCount;
  final int paidCount;
  final double eventPrice;
  final String eventLocale;
  final int allowNegativeCredit;
  final double credit;
  final String currencySymbol;
  final int digitsAfterDecimal;

  PackModel(
    {
      this.eventId,
      this.hasherId,
      this.isFollowing,
      this.isMember,
      // this.isRsvped,
      this.hasherEventMapId,
      this.isHare,
      this.virginVisitorType,
      this.userStartEvent,
      this.userEndEvent,
      this.rsvpState,
      this.attendenceState,
      this.isPaid,
      this.paymentType,
      this.displayName,
      this.photo,
      this.userRunCount,
      this.waitingForCount,
      this.atHashCount,
      this.onInCount,
      this.onTrailCount,
      this.paidCount,
      this.eventPrice,
      this.eventLocale,
      this.allowNegativeCredit,
      this.credit,
      this.currencySymbol,
      this.digitsAfterDecimal,
    });

  @override
  String toString() => '$displayName';

  int _requestedRsvpState = -1;
  int _requestedHaringState = -1;
  int _requestedAttendenceState = -1;

  int get requestedRsvpState => _requestedRsvpState;
  int get requestedHaringState => _requestedHaringState;
  int get requestedAttendenceState => _requestedAttendenceState;

  set requestedRsvpState(int rsvpState) {
    this._requestedRsvpState = rsvpState;
  }

  set requestedHaringState(int haringState) {
    this._requestedHaringState = haringState;
  }

  set requestedAttendenceState(int attendenceState) {
    this._requestedAttendenceState = attendenceState;
  }

}