import 'dart:core';

class GetPackModel {

  final String hasherId;
  final String hasherEventMapId;
  int userStatus;
  final String displayName;
  final String photo;
  int isHare;

  GetPackModel(
    {
        this.hasherId,
        this.hasherEventMapId,
        this.userStatus,
        this.displayName,
        this.photo,
        this.isHare,
    });

  @override
  String toString() => '$displayName';

}