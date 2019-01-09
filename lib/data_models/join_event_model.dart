import 'dart:core';

class JoinEventModel {

  final int rsvpYesCount;
  final int rsvpNoCount;
  final int rsvpMaybeCount;
  final int haresCount;

  JoinEventModel(
    {
        this.rsvpYesCount,
        this.rsvpNoCount,
        this.rsvpMaybeCount,
        this.haresCount,
    });

}