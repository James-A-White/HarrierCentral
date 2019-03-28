import 'dart:convert';
import 'dart:core';

class LiteEvent {
  LiteEvent(
      {this.eventId,
      this.eventStartDatetime,
      this.eventEndDatetime,
      this.eventName,
      this.eventNumber,
      this.locationOneLineDesc,
      this.userEventCounterIncrement,
      this.eventFacebookId,
      this.isVisible,
      this.isCountedRun,
      this.absoluteEventNumber,
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
  int eventNumber;
  final String locationOneLineDesc;
  final int userEventCounterIncrement;
  final String eventFacebookId;
  int isVisible;
  int isCountedRun;
  int absoluteEventNumber;
  int isHare;
  int totalRunsThisKennel;
  final int totalRunsAllKennels;
  int totalHaringThisKennel;
  final DateTime userStartEvent;
  final int rsvpState;
  int attendenceState;
  final int canEditRunAttendence;

  bool isLoading = false;

  static List<LiteEvent> itemsFromJson(String jsonResult) {
    final List<LiteEvent> items = <LiteEvent>[];

    LiteEvent item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = LiteEvent(
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
          eventFacebookId: jsonItem['eventFacebookId'],
          isVisible: jsonItem['isVisible'],
          isCountedRun: jsonItem['isCountedRun'],
          absoluteEventNumber: jsonItem['absoluteEventNumber'],
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
