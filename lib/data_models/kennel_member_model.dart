import 'dart:core';

class KennelMemberModel {
  final String hasherId;
  String hashName;
  String firstName;
  String lastName;
  String displayName;
  final int dispPref;
  String photo;
  String qr_code;
  String qr_secret_code;

  KennelMemberModel({
    this.hasherId,
    this.hashName,
    this.firstName,
    this.lastName,
    this.displayName,
    this.dispPref,
    this.photo,
    this.qr_code,
    this.qr_secret_code
  });

  @override
  String toString() => '$displayName';
}
