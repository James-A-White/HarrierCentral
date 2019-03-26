import 'dart:convert';
import 'dart:core';

class UserRunHistoryModel {
  UserRunHistoryModel(
      {this.eventId,
      this.eventStartDatetime,
      this.eventEndDatetime,
      this.eventName,
      this.userEventCounterIncrement,
      this.isHare,
      this.totalRunsThisKennel,
      this.totalRunsAllKennels,
      this.userStartEvent,
      this.rsvpState,
      this.attendenceState});

  final String eventId;
  final DateTime eventStartDatetime;
  final DateTime eventEndDatetime;
  final String eventName;
  final int userEventCounterIncrement;
  final int isHare;
  final int totalRunsThisKennel;
  final int totalRunsAllKennels;
  final DateTime userStartEvent;
  final int rsvpState;
  final int attendenceState;

  static List<UserRunHistoryModel> itemsFromJson(String jsonResult) {
    final List<UserRunHistoryModel> items = <UserRunHistoryModel>[];

    UserRunHistoryModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = UserRunHistoryModel(
          eventId: jsonItem['eventId'],
          eventStartDatetime: jsonItem['eventStartDatetime'] == null ? null : DateTime.parse(jsonItem['eventStartDatetime']),
          eventEndDatetime: jsonItem['eventEndDatetime'] == null ? null : DateTime.parse(jsonItem['eventEndDatetime']),
          eventName: jsonItem['eventName'],
          userEventCounterIncrement: jsonItem['userEventCounterIncrement'],
          isHare: jsonItem['isHare'],
          totalRunsThisKennel: jsonItem['totalRunsThisKennel'],
          totalRunsAllKennels: jsonItem['totalRunsAllKennels'],
          userStartEvent: jsonItem['userStartEvent'] == null ? null : DateTime.parse(jsonItem['userStartEvent']),
          rsvpState: jsonItem['rsvpState'],
          attendenceState: jsonItem['attendenceState'],
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
