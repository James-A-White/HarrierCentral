import 'dart:core';

class JoinEventModel {

  final int attendingEvent;
  final int notAttendingEvent;
  final int maybeAttendingEvent;
  final int haresCount;

  JoinEventModel(
    {
        this.attendingEvent,
        this.notAttendingEvent,
        this.maybeAttendingEvent,
        this.haresCount,
    });

}