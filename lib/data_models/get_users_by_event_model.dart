import 'dart:core';

class GetUsersByEventModel {

  final String eventId;
  final String userId;
  final int isFollowing;
  final int isMember;
  final int isRsvped;
  final String hasherEventMapId;
  final int isHare;
  final int virginVisitorType;
  final DateTime userStartEvent;
  final DateTime userEndEvent;
  int rsvpState;
  int attendenceState;
  final int isPaid;
  final String displayName;
  final String photo;
  final int userRunCount;
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

  GetUsersByEventModel(
    {
      this.eventId,
      this.userId,
      this.isFollowing,
      this.isMember,
      this.isRsvped,
      this.hasherEventMapId,
      this.isHare,
      this.virginVisitorType,
      this.userStartEvent,
      this.userEndEvent,
      this.rsvpState,
      this.attendenceState,
      this.isPaid,
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

}