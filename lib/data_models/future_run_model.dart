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

  int attendingEvent;
  int notAttendingEvent;
  int maybeAttendingEvent;
  int haresCount;

  String hareList;

  final double latitude;
  final double longitude;
  final String kennelLogo;
  DateTime eventStartDatetime;
  int daysUntilNextRun;
  final int friendsAttending;
  final int userStatus;
  int rsvpState;
  final int totalRunsThisKennel;
  final String kennelShortName;
  final int runSequence;
  int distanceToEvent;

  // set followingState(int newState) {
  //   followingBool = newState;
  // }

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

    this.attendingEvent,
    this.notAttendingEvent,
    this.maybeAttendingEvent,
    this.haresCount,

    this.hareList,

    this.latitude,
    this.longitude,
    this.kennelLogo,
    this.daysUntilNextRun,
    this.eventStartDatetime,
    this.friendsAttending,
    this.rsvpState,
    this.userStatus,
    this.totalRunsThisKennel,
    this.kennelShortName,
    this.runSequence,
    this.distanceToEvent,
  });

  int _requestedRsvpState = 0;

  int get requestedRsvpState => _requestedRsvpState;

  set requestedRsvpState(int rsvpState) {
    this._requestedRsvpState = rsvpState;
  }

  @override
  String toString() => '$eventName';
}
