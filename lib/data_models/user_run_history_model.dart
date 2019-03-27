import 'dart:convert';
import 'dart:core';

class UserEventHistoryModel {
  UserEventHistoryModel(
      {this.eventId,
      this.eventStartDatetime,
      this.eventEndDatetime,
      this.eventName,
      this.eventNumber,
      this.locationOneLineDesc,
      this.userEventCounterIncrement,
      this.isHare,
      this.totalRunsThisKennel,
      this.totalRunsAllKennels,
      this.totalHaringThisKennel,
      this.userStartEvent,
      this.rsvpState,
      this.attendenceState,
      this.canEditRunAttendence});

  final String eventId;
  final DateTime eventStartDatetime;
  final DateTime eventEndDatetime;
  final String eventName;
  final int eventNumber;
  final String locationOneLineDesc;
  final int userEventCounterIncrement;
  int isHare;
  int totalRunsThisKennel;
  final int totalRunsAllKennels;
  int totalHaringThisKennel;
  final DateTime userStartEvent;
  final int rsvpState;
  int attendenceState;
  final int canEditRunAttendence;

  bool isLoading = false;

  static List<UserEventHistoryModel> itemsFromJson(String jsonResult) {
    final List<UserEventHistoryModel> items = <UserEventHistoryModel>[];

    UserEventHistoryModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = UserEventHistoryModel(
          eventId: jsonItem['eventId'],
          eventStartDatetime: jsonItem['eventStartDatetime'] == null
              ? null
              : DateTime.parse(jsonItem['eventStartDatetime']),
          eventEndDatetime: jsonItem['eventEndDatetime'] == null
              ? null
              : DateTime.parse(jsonItem['eventEndDatetime']),
          eventName: jsonItem['eventName'],
          eventNumber: jsonItem['eventNumber'],
          locationOneLineDesc: jsonItem['locationOneLineDesc'],
          userEventCounterIncrement: jsonItem['userEventCounterIncrement'],
          isHare: jsonItem['isHare'],
          totalRunsThisKennel: jsonItem['totalRunsThisKennel'],
          totalRunsAllKennels: jsonItem['totalRunsAllKennels'],
          totalHaringThisKennel: jsonItem['totalHaringThisKennel'],
          userStartEvent: jsonItem['userStartEvent'] == null
              ? null
              : DateTime.parse(jsonItem['userStartEvent']),
          rsvpState: jsonItem['rsvpState'],
          attendenceState: jsonItem['attendenceState'],
          canEditRunAttendence: jsonItem['canEditRunAttendence'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}
