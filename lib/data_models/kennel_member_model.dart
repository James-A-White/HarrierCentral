import 'dart:core';

class GetKennelMembersModel {
  final String hasherId;
  String hashName;
  String firstName;
  String lastName;
  String displayName;
  final int dispPref;
  String photo;

  GetKennelMembersModel({
    this.hasherId,
    this.hashName,
    this.firstName,
    this.lastName,
    this.displayName,
    this.dispPref,
    this.photo,
  });

  @override
  String toString() => '$displayName';
}
