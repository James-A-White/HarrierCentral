// import 'dart:core';

// import 'package:harrier_central/util/constants.dart';

// class PlannedRun {

//    PlannedRun({
//     this.eventId,
//     this.kennelId,
//     this.eventName,
//     this.eventNumber,
//     this.locationOneLineDesc,
//     this.eventDescription,
//     this.eventPriceForMembers,
//     this.eventPriceForNonMembers,
//     this.eventCurrencyType,
//     this.currencySymbol,
//     this.digitsAfterDecimal,
//     this.eventImage,
//     this.eventShortDesc,
//     this.locationCity,
//     this.locationStreet,
//     this.locationPostCode,

//     this.rsvpYesCount,
//     this.rsvpNoCount,
//     this.rsvpMaybeCount,
//     this.haresCount,

//     this.hareList,

//     this.latitude,
//     this.longitude,
//     this.kennelLogo,
//     this.daysUntilNextRun,
//     this.eventStartDatetime,
//     this.friendsAttending,
//     this.rsvpState,
//     this.attendenceState,
//     this.isHare,
//     this.totalRunsThisKennel,
//     this.kennelShortName,
//     this.runSequence,
//     this.distanceToEvent,
//     this.mismanagementRoleFlags,

//     // HC3
//     this.isVisible

//   });

//   final String eventId;
//   final String kennelId;
//   final String eventName;
//   int eventNumber;
//   final String locationOneLineDesc;
//   final String eventDescription;

//   final num eventPriceForMembers;
//   final num eventPriceForNonMembers;
//   final String eventCurrencyType;

//   final String currencySymbol;
//   final int digitsAfterDecimal;

//   final String eventImage;
//   final String eventShortDesc;
//   final String locationCity;
//   final String locationStreet;
//   final String locationPostCode;

//   int rsvpYesCount;
//   int rsvpNoCount;
//   int rsvpMaybeCount;
//   int haresCount;

//   String hareList;

//   final double latitude;
//   final double longitude;
//   final String kennelLogo;
//   DateTime eventStartDatetime;
//   int daysUntilNextRun;
//   final int friendsAttending;

//   int rsvpState;
//   int attendenceState;
//   int isHare;

//   int isVisible;

//   final int totalRunsThisKennel;
//   final String kennelShortName;
//   final int runSequence;
//   int distanceToEvent;

//   int mismanagementRoleFlags;

//   bool  isExpanded = false;

 

//   int requestedRsvpState = -1;
//   int requestedHaringState = -1;
//   int requestedAttendenceState = -1;

//      bool get mmAuthAllowEditRsvp {
//     return (mismanagementRoleFlags & mmAuthAllowEditRsvpFlag) != 0;
//   }

//   bool get mmAuthAllowCheckInAndOut {
//     return (mismanagementRoleFlags & mmAuthAllowCheckInAndOutFlag) != 0;
//   }

//   bool get mmAuthAllowHashCash {
//     return (mismanagementRoleFlags & mmAuthAllowHashCashFlag) != 0;
//   }

//   bool get mmAuthShowCheckInSnackbar {
//     return (mismanagementRoleFlags & (mmAuthAllowEditRsvpFlag | mmAuthAllowHashCashFlag | mmAuthAllowCheckInAndOutFlag)) != 0;
//   }

//   bool get mmAuthAllowAddNewMember {
//     return (mismanagementRoleFlags & mmAuthAllowAddNewMemberFlag) != 0;
//   }

//   bool get hasMmPrivileges {
//     return mismanagementRoleFlags != 0;
//   }

//   // int get requestedRsvpState => _requestedRsvpState;
//   // int get requestedHaringState => _requestedHaringState;
//   // int get requestedAttendenceState => _requestedAttendenceState;

//   // set requestedRsvpState(int rsvpState) {
//   //   _requestedRsvpState = rsvpState;
//   // }

//   // set requestedHaringState(int haringState) {
//   //   _requestedHaringState = haringState;
//   // }

//   // set requestedAttendenceState(int attendenceState) {
//   //   _requestedAttendenceState = attendenceState;
//   // }

//   @override
//   String toString() => '$eventName';
// }
