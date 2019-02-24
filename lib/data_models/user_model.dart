import 'dart:core';

class UserModel {

  // final int isRsvped;
  final DateTime userEndEvent;
  final DateTime userStartEvent;
  final double credit;
  final double eventPrice;
  final int allowNegativeCredit;
  final int atHashCount;
  final int digitsAfterDecimal;
  final int isFollowing;
  final int isMember;
  final int onInCount;
  final int onTrailCount;
  final int paidCount;
  final int virginVisitorType;
  final int waitingForCount;
  final String currencySymbol;
  final String displayName;
  final String email;
  final String eventId;
  final String eventLocale;
  final String facebookId;
  final String firstName;
  final String hasherId;
  final String hashName;
  final String lastName;
  final String photo;
  final String qrCode;
  final String qrSecretCode;
  int attendenceState;
  int isHare;
  int isPaid;
  int paymentType;
  int rsvpState;
  int userRunCount;
  String hasherEventMapId;

  UserModel(
    {
      // this.isRsvped,
      this.allowNegativeCredit,
      this.atHashCount,
      this.attendenceState,
      this.credit,
      this.currencySymbol,
      this.digitsAfterDecimal,
      this.displayName,
      this.email,
      this.eventId,
      this.eventLocale,
      this.eventPrice,
      this.facebookId,
      this.firstName,
      this.hasherEventMapId,
      this.hasherId,
      this.hashName,
      this.isFollowing,
      this.isHare,
      this.isMember,
      this.isPaid,
      this.lastName,
      this.onInCount,
      this.onTrailCount,
      this.paidCount,
      this.paymentType,
      this.photo,
      this.qrCode,
      this.qrSecretCode,
      this.rsvpState,
      this.userEndEvent,
      this.userRunCount,
      this.userStartEvent,
      this.virginVisitorType,
      this.waitingForCount,
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