import 'dart:core';

class FutureRun {
  final String eventId;
  final String kennelId;
  final String eventName;
  int eventNumber;
  final String locationOneLineDesc;
  final String eventDescription;

  final double eventPriceForMembers;
  final double eventPriceForNonMembers;
  final String eventCurrencyType;

  final String currencySymbol;
  final int digitsAfterDecimal;

  final String eventImage;
  final String eventShortDesc;
  final String locationCity;
  final String locationStreet;
  final String locationPostCode;

  int rsvpYesCount;
  int rsvpNoCount;
  int rsvpMaybeCount;
  int haresCount;

  String hareList;

  final double latitude;
  final double longitude;
  final String kennelLogo;
  DateTime eventStartDatetime;
  int daysUntilNextRun;
  final int friendsAttending;

  int rsvpState;
  int attendenceState;
  int isHare;

  final int totalRunsThisKennel;
  final String kennelShortName;
  final int runSequence;
  int distanceToEvent;

  // state
  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;

  set isExpanded(bool isExpanded) {
    this._isExpanded = isExpanded;
  }


  FutureRun({
    this.eventId,
    this.kennelId,
    this.eventName,
    this.eventNumber,
    this.locationOneLineDesc,
    this.eventDescription,
    this.eventPriceForMembers,
    this.eventPriceForNonMembers,
    this.eventCurrencyType,
    this.currencySymbol,
    this.digitsAfterDecimal,
    this.eventImage,
    this.eventShortDesc,
    this.locationCity,
    this.locationStreet,
    this.locationPostCode,

    this.rsvpYesCount,
    this.rsvpNoCount,
    this.rsvpMaybeCount,
    this.haresCount,

    this.hareList,

    this.latitude,
    this.longitude,
    this.kennelLogo,
    this.daysUntilNextRun,
    this.eventStartDatetime,
    this.friendsAttending,
    this.rsvpState,
    this.attendenceState,
    this.isHare,
    this.totalRunsThisKennel,
    this.kennelShortName,
    this.runSequence,
    this.distanceToEvent,

  });

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

  @override
  String toString() => '$eventName';
}
