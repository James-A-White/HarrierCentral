import 'dart:core';

class JoinEventModel {

  final int rsvpYesCount;
  final int rsvpNoCount;
  final int rsvpMaybeCount;
  final int haresCount;
  final int totalRunsThisKennel;
  final int totalRunsAllKennels;

  JoinEventModel(
    {
        this.rsvpYesCount,
        this.rsvpNoCount,
        this.rsvpMaybeCount,
        this.haresCount,
        this.totalRunsThisKennel,
        this.totalRunsAllKennels
    });

}