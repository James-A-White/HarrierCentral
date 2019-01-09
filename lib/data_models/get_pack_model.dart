import 'dart:core';

class GetPackModel {

  final String hasherId;
  final String hasherEventMapId;
  int rsvpState;
  int attendenceState;
  final String displayName;
  final String photo;
  int isHare;

  GetPackModel(
    {
        this.hasherId,
        this.hasherEventMapId,
        this.rsvpState,
        this.attendenceState,
        this.displayName,
        this.photo,
        this.isHare,
    });

  @override
  String toString() => '$displayName';

}